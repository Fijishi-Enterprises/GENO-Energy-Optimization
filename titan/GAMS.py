"""
GAMSModel class.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.01.2016
"""

import os.path
import logging
from collections import OrderedDict
from tool import Tool
from configuration import ConfigurationParser
from config import GAMS_EXECUTABLE, CONFIGURATION_FILE


class GAMSModel(Tool):
    """Class for GAMS Tools."""
    def __init__(self, name, description, path, files,
                 datafiles=None, datafiles_opt=None, outfiles=None,
                 short_name=None, cmdline_args=None):
        """Class constructor.

        Args:
            name (str): GAMS Tool name
            description (str): GAMS Tool description
            path (str): Path
            files (str): List of files belonging to the tool (relative to 'path')
                         First file in the list is the main GAMS program.
            datafiles (list, optional): List of required data files
            datafiles_opt (list, optional): List of optional data files (wildcards may be used)
            outfiles (list, optional): List of output files (wildcards may be used)
            short_name (str, optional): Short name for the GAMS tool
            cmdline_args (str, optional): GAMS tool command line arguments (read from tool definition file)
        """
        super().__init__(name, description, path, files,
                         datafiles, datafiles_opt, outfiles, short_name,
                         cmdline_args=cmdline_args)
        self.main_prgm = files[0]
        # Add .lst file to list of output files
        self.lst_file = os.path.splitext(self.main_prgm)[0] + '.lst'
        self.outfiles.add(self.lst_file)
        # Split main_prgm to main_dir and main_prgm
        # because GAMS needs to run in the directory of the main program
        self.main_dir, self.main_prgm = os.path.split(self.main_prgm)
        self.gams_options = OrderedDict()
        self.return_codes = {
            0: "Normal return",
            1: "Solver is to be called the system should never return this number",  # ??
            2: "There was a compilation error",
            3: "There was an execution error",
            4: "System limits were reached",
            5: "There was a file error",
            6: "There was a parameter error",
            7: "There was a licensing error",
            8: "There was a GAMS system error",
            9: "GAMS could not be started",
            10: "Out of memory",
            11: "Out of disk",
            62097: "Simulation interrupted by user"  # Not official
        }

    def __repr__(self):
        return "GAMSModel('{}')".format(self.name)

    def update_gams_options(self, key, value):
        """Update GAMS command line options. 'cerr and 'logoption' keywords supported.

        Args:
            key: Option name
            value: Option value
        """
        # Supported GAMS logoption values
        # 3 writes LOG output to standard output
        # 4 writes LOG output to a file and standard output  [Not supported in GAMS v24.0]
        if key == 'logoption' or key == 'cerr':
            self.gams_options[key] = "{0}={1}".format(key, value)
        else:
            logging.error("Updating GAMS options failed. Unknown key: {}".format(key))

    def create_instance(self, ui, setup_cmdline_args, tool_output_dir, setup_name):
        """Create an instance of the GAMS model

        Args:
            ui (TitanUI): Titan GUI window
            setup_cmdline_args (str): Extra Setup command line arguments
            tool_output_dir (str): Tool output directory
            setup_name (str): Short name of Setup that owns this Tool
        """
        # Let Tool class create the ToolInstance
        instance = super().create_instance(ui, setup_cmdline_args, tool_output_dir, setup_name)
        # Use gams.exe according to the selected GAMS directory in settings
        # TODO: Use config object loaded in TitanUI instead of making a new ConfigurationParser
        configs = ConfigurationParser(CONFIGURATION_FILE)
        configs.load()
        # Read needed settings from config file
        gams_path = configs.get('general', 'gams_path')
        logoption_value = configs.get('settings', 'logoption')
        cerr_value = configs.get('settings', 'cerr')
        gams_exe_path = GAMS_EXECUTABLE
        if not gams_path == '':
            gams_exe_path = os.path.join(gams_path, GAMS_EXECUTABLE)
        # General GAMS options
        if logoption_value == '':  # If logoption is missing from .conf file
            logoption_value = 3
        if cerr_value == '':  # If cerr is missing from .conf file
            cerr_value = 1
        self.update_gams_options('logoption', logoption_value)
        self.update_gams_options('cerr', cerr_value)
        gams_option_list = list(self.gams_options.values())
        # Update logfile to instance outfiles
        logfile = os.path.splitext(self.files[0])[0] + '.log'
        logfile_path = os.path.join(instance.basedir, logfile)
        if logoption_value == '3':
            # Remove path for <TOOLNAME>.log from outfiles if present
            for out in instance.outfiles:
                if os.path.basename(out) == logfile:
                    try:
                        instance.outfiles.remove(out)
                        logging.debug("Removed path '{}' from outfiles".format(out))
                    except ValueError:
                        logging.exception("Tried to remove path '{}' but failed".format(out))
        elif logoption_value == '4':
            # Add <TOOLNAME>.log file to outfiles
            instance.outfiles.append(logfile_path)  # TODO: Instance outfiles is a list, tool outfiles is a set
        else:
            logging.error("Unknown value for logoption: {}".format(logoption_value))
        # Create run command for GAMS
        # command = '{} "{}" {}'.format(gams_exe_path,
        #                                           self.main_prgm,
        #                                           ' '.join(gams_option_list))
        self.main_dir = instance.basedir  # TODO: Get rid of self.main_dir
        command = '{} "{}" Curdir="{}" {}'.format(gams_exe_path,
                                                  self.main_prgm,
                                                  self.main_dir,
                                                  ' '.join(gams_option_list))
        # Update instance command
        instance.command = self.append_cmdline_args(command, setup_cmdline_args)
        return instance

    def debug(self, ui, path, tool_short_name):
        """Make GAMS project file.

        Args:
            ui (TitanUI): Titan GUI instance
            path (str): Base path to tool files
            tool_short_name (str): Tool short name
        """
        prj_file_path = os.path.join(path, tool_short_name + "AutoCreated.gpr")
        if not self.make_gams_project_file(prj_file_path):
            ui.add_msg_signal.emit("Failed to make GAMS project file", 2)
        else:
            # Add anchor where user can go directly to GAMS
            gams_anchor = "<a href='file:///" + prj_file_path + "'>Click here to debug Tool in GAMS</a>"
            ui.add_msg_signal.emit(gams_anchor, 0)

    @staticmethod
    def load(path, data, ui):
        """Create a GAMSModel according to a tool definition.

        Args:
            path (str): Base path to tool files
            data (dict): Dictionary of tool definitions
            ui (TitanUI): Titan GUI instance

        Returns:
            GAMSModel instance or None if there was a problem in the tool definition file.
        """
        kwargs = GAMSModel.check_definition(data, ui)
        if kwargs is not None:
            # Return a Executable model instance
            return GAMSModel(path=path, **kwargs)
        else:
            return None

    def make_gams_project_file(self, filepath):
        """Make a GAMS project file for debugging, which opens GAMSIDE with the .lst file open.

        Args:
            filepath (str): Path where the project file is stored

        Returns:
            Boolean variable depending on operation success
        """
        lst_file_path = os.path.join(os.path.split(filepath)[0], self.lst_file)
        # logging.debug("List file path: {0}".format(lst_file_path))
        # logging.debug("Project file path: {0}".format(filepath))
        # Write GAMS project file
        try:
            with open(filepath, 'w') as f:
                f.write('[PROJECT]\n\n')
                f.write('[OPENWINDOW_1]\n')
                f.write("FILE0=" + lst_file_path + '\n')
                f.write('MAXIM=0\n')
                f.write('TOP=0\n')
                f.write('LEFT=0\n')
                f.write('HEIGHT=600\n')
                f.write('WIDTH=1000\n')
        except OSError:
            logging.error("Failed to write GAMS project file: {0}".format(filepath))
            return False
        return True


def write_inc(filepath, symbol, keys, values, append=False):
    """Write a GAMS include file.

    Args:
        filepath (str): File path
        symbol (str): Symbol name
        keys (list of tuples): Keys
        values (list): Values
        append (bool): Append to existing file

    Raises:
        OSError

    Returns:
        Number of lines written.
    """
    if append:
        fmode = 'a'
    else:
        fmode = 'w'
    n = 0  # Number of lines written
    with open(filepath, mode=fmode) as dfile:
            if not append:
                dfile.write("$offlisting\n")
                dfile.write('* {}\n'.format(symbol))
            for key, val in zip(keys, values):
                r = '.'.join(map(str, key))
                if val is not None:
                    if isinstance(val, str):  # Quote explanatory text
                        val = '"{}"'.format(val)
                    r += ' {}'.format(val)
                dfile.write(r + '\n')
                n += 1
    return n+2


def write_gdx(filepath, symbol, keys, values, append=False):
    """Write a GAMS Data eXchange (GDX) file.

    Args:
        filepath (str): File path
        symbol (str): Symbol name
        keys (list of tuples): Keys
        values (list): Values
        append (bool): Append to existing file

    Raises:
        OSError
        ImportError

    Returns:
        None
    """
    try:
        from gdx2py import GdxFile
    except ImportError:
        raise ImportError("GDX support not available")
    if append:
        fmode = 'a'
    else:
        fmode = 'w'
    with GdxFile(filepath, mode=fmode) as f:
        f[symbol] = (keys, values)
    return None
