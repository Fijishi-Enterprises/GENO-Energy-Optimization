"""
GAMSModel class.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.01.2016
"""

import os.path
import json
import logging
from collections import OrderedDict
from tool import Tool
from configuration import ConfigurationParser
from config import GAMS_EXECUTABLE, CONFIGURATION_FILE


class GAMSModel(Tool):
    """Class for GAMS Tools."""
    def __init__(self, name, description, path, files,
                 infiles=None, infiles_opt=None, outfiles=None,
                 short_name=None, cmdline_args=None):
        """Class constructor.

        Args:
            name (str): GAMS Tool name
            description (str): GAMS Tool description
            files (str): List of files belonging to the tool (relative to 'path')
                         First file in the list is the main GAMS program.
            infiles (list, optional): List of required input files
            infiles_opt (list, optional): List of optional input files (wildcards may be used)
            outfiles (list, optional): List of output files (wildcards may be used)
            short_name (str, optional): Short name for the GAMS tool
            cmdline_args (str, optional): GAMS tool command line arguments (read from tool definition file)
        """
        super().__init__(name, description, path, files,
                         infiles, infiles_opt, outfiles, short_name,
                         cmdline_args=cmdline_args)
        # Split main_prgm to main_dir and main_prgm
        # because GAMS needs to run in the directory of the main program
        self.main_dir, self.main_prgm = os.path.split(self.main_prgm)
        self.gams_options = OrderedDict()
        # Add .lst file to list of output files
        self.outfiles.add(os.path.splitext(self.main_prgm)[0] + '.lst')
        self.return_codes = {
            0: "normal return",
            1: "solver is to be called the system should never return this number",
            2: "there was a compilation error",
            3: "there was an execution error",
            4: "system limits were reached",
            5:  "there was a file error",
            6:  "there was a parameter error",
            7:  "there was a licensing error",
            8:  "there was a GAMS system error",
            9:  "GAMS could not be started",
            10: "out of memory",
            11: "out of disk",
            62097: "simulation interrupted by user"  # Not official
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
        self.update_gams_options('logoption', logoption_value)
        self.update_gams_options('cerr', cerr_value)
        gams_option_list = list(self.gams_options.values())
        # Update logfile to instance outfiles
        logfile = os.path.splitext(self.main_prgm)[0] + '.log'
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
        command = '{} "{}" Curdir="{}" {}'.format(gams_exe_path,
                                                  self.main_prgm,
                                                  os.path.join(instance.basedir, self.main_dir),
                                                  ' '.join(gams_option_list))
        if (setup_cmdline_args is not None) and (not setup_cmdline_args == ''):
            if (self.cmdline_args is not None) and (not self.cmdline_args == ''):
                command += ' ' + self.cmdline_args + ' ' + setup_cmdline_args
            else:
                command += ' ' + setup_cmdline_args
        else:
            if (self.cmdline_args is not None) and (not self.cmdline_args == ''):
                command += ' ' + self.cmdline_args
        # Update instance command
        instance.command = command
        return instance

    @staticmethod
    def load(jsonfile, ui):
        """Create a GAMSModel according to a tool definition file.

        Args:
            jsonfile (str): Path of the tool definition file
            ui (TitanUI): Titan GUI instance

        Returns:
            GAMSModel instance or None if there was a problem in the tool definition file.
        """
        with open(jsonfile, 'r') as fp:
            try:
                json_data = json.load(fp)
            except ValueError:
                ui.add_msg_signal.emit("Tool definition file not valid", 2)
                logging.exception("Loading JSON data failed")
                return None
        # Find required and optional arguments
        required = ['name', 'description', 'files']
        optional = ['short_name', 'infiles', 'infiles_opt',
                    'outfiles', 'cmdline_args']
        list_required = ['files', 'infiles', 'infiles_opt', 'outfiles']
        # Construct keyword arguments
        kwargs = {}
        for p in required + optional:
            try:
                kwargs[p] = json_data[p]
            except KeyError:
                if p in required:
                    ui.add_msg_signal.emit("Required keyword '{0}' missing".format(p), 2)
                    logging.error("Required keyword '{0}' missing".format(p))
                    return None
                else:
                    # logging.info("Optional keyword '{0}' missing".format(p))
                    pass
            # Check that some variables are lists
            if p in list_required:
                try:
                    if not isinstance(json_data[p], list):
                        ui.add_msg_signal.emit("Keyword '{0}' value must be a list".format(p), 2)
                        logging.error("Keyword '{0}' value must be a list".format(p))
                        return None
                except KeyError:
                    pass
        # Infer path from JSON file
        kwargs['path'] = os.path.dirname(jsonfile)
        # Return a GAMSModel instance
        return GAMSModel(**kwargs)
