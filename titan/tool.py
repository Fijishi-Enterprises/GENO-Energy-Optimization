"""
Tool class definition.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   26.10.2015
"""

import os
import logging
from metaobject import MetaObject
from config import REQUIRED_KEYS, OPTIONAL_KEYS, LIST_REQUIRED_KEYS
from tool_instance import ToolInstance


class Tool(MetaObject):
    """Class for defining a tool"""

    def __init__(self, name, description, path, files,
                 datafiles=None, datafiles_opt=None,
                 outfiles=None, short_name=None,
                 logfile=None, cmdline_args=None):
        """Class constructor.

        Args:
            name (str): Name of the tool
            description (str): Short description of the tool
            path (str): Path to tool
            files (str): List of files belonging to the tool (relative to 'path')
            datafiles (list, optional): List of required data files
            datafiles_opt (list, optional): List of optional data files (wildcards may be used)
            outfiles (list, optional): List of output files (wildcards may be used)
            short_name (str, optional): Short name for the tool
            logfile (str, optional): Log file name (relative to 'path')
            cmdline_args (str, optional): Tool command line arguments (read from tool definition file)
        """
        super().__init__(name, description, short_name)
        if not os.path.exists(path):
            pass  # TODO: Do something here
        else:
            self.path = path
        self.files = files
        self.cmdline_args = cmdline_args
        self.datafiles = set(datafiles) if datafiles else set()
        self.datafiles_opt = set(datafiles_opt) if datafiles_opt else set()
        self.outfiles = set(outfiles) if outfiles else set()
        self.return_codes = {}
        self.def_file_path = ''  # Tool definition file path (JSON)

    def set_return_code(self, code, description):
        """Set a return code and associated text description for the tool.

        Args:
            code (int): Return code
            description (str): Description
        """
        self.return_codes[code] = description

    def set_def_path(self, path):
        """Set definition file path for tool.

        Args:
            path (str): Absolute path to the definition file.
        """
        self.def_file_path = path

    def get_def_path(self):
        """Returns tool definition file path."""
        return self.def_file_path

    def create_instance(self, ui, setup_cmdline_args, tool_output_dir, setup_name):
        """Create an instance of the tool.

        Args:
            ui (TitanUI): Titan GUI instance
            setup_cmdline_args (str): Extra command line arguments
            tool_output_dir (str): Output directory for tool
            setup_name (str): Short name of Setup that calls this method
        """
        return ToolInstance(self, ui, tool_output_dir, setup_name)

    def append_cmdline_args(self, command, setup_cmdline_args):
        """Append command line arguments to a command.

        Args:
            command (str): Tool command
            setup_cmdline_args (str): Extra Setup command line args
        """
        if (setup_cmdline_args is not None) and (not setup_cmdline_args == ''):
            if (self.cmdline_args is not None) and (not self.cmdline_args == ''):
                command += ' ' + self.cmdline_args + ' ' + setup_cmdline_args
            else:
                command += ' ' + setup_cmdline_args
        else:
            if (self.cmdline_args is not None) and (not self.cmdline_args == ''):
                command += ' ' + self.cmdline_args
        return command

    def debug(self, *args, **kwargs):
        """Debug method to be implemented in subclasses."""
        pass

    @staticmethod
    def check_definition(data, ui,
                         required=None, optional=None, list_required=None):
        """Check a dict containing tool definition.

        Args:
            data (dict): Dictionary of tool definitions
            ui (TitanUI): Titan GUI instance
            required (list): required keys
            optional  (list): optional keys
            list_required (list): keys that need to be lists

        Returns:
            dict or None if there was a problem in the tool definition file
        """
        # Required and optional keys in definition file
        if required is None:
            required = REQUIRED_KEYS
        if optional is None:
            optional = OPTIONAL_KEYS
        if list_required is None:
            list_required = LIST_REQUIRED_KEYS
        kwargs = {}
        for p in required + optional:
            try:
                kwargs[p] = data[p]
            except KeyError:
                if p in required:
                    ui.add_msg_signal.emit(
                        "Required keyword '{0}' missing".format(p), 2)
                    logging.error("Required keyword '{0}' missing".format(p))
                    return None
                else:
                    # logging.info("Optional keyword '{0}' missing".format(p))
                    pass
            # Check that some variables are lists
            if p in list_required:
                try:
                    if not isinstance(data[p], list):
                        ui.add_msg_signal.emit(
                            "Keyword '{0}' value must be a list".format(p), 2)
                        logging.error(
                            "Keyword '{0}' value must be a list".format(p))
                        return None
                except KeyError:
                    pass
        return kwargs
