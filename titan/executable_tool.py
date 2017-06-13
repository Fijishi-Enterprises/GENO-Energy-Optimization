"""
ExecutableTool class definition.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   13.6.2017
"""

import os
from tool import Tool
from config import OPTIONAL_KEYS


class ExecutableTool(Tool):
    """Class for any executable tool."""
    def __init__(self, name, description, path, files, command=None,
                 datafiles=None, datafiles_opt=None, outfiles=None,
                 short_name=None, logfile=None, cmdline_args=None):

        super().__init__(name, description, path, files, datafiles,
                         datafiles_opt, outfiles, short_name, logfile,
                         cmdline_args)
        self.command = command
        self.return_codes = {0: "Normal return"}

    def create_instance(self, ui, setup_cmdline_args, tool_output_dir, setup_name):
        """Create an instance of the ExecutableTool

        Args:
            ui (TitanUI): Titan GUI window
            setup_cmdline_args (str): Extra Setup command line arguments
            tool_output_dir (str): Tool output directory
            setup_name (str): Short name of Setup that owns this Tool
        """
        # Let Tool class create the ToolInstance
        instance = super().create_instance(ui, setup_cmdline_args,
                                           tool_output_dir, setup_name)

        # Get command
        if self.command is not None:
            command = self.command
        else:
            if os.name == 'nt':
                command = 'CMD /C {}'.format(self.files[0])
            else:
                command = './{}'.format(self.files[0])

        # Update instance command
        instance.command = self.append_cmdline_args(command, setup_cmdline_args)
        return instance

    @staticmethod
    def load(path, data, ui):
        """Create ExecutableTool according to a tool definition.

        Args:
            path (str): Base path to tool files
            data (dict): Dictionary of tool definitions
            ui (TitanUI): Titan GUI instance

        Returns:
            ExecutableTool instance or None if there was a problem in the tool definition file.
        """

        kwargs = ExecutableTool.check_definition(data, ui,
                                                 optional=OPTIONAL_KEYS + ['command'])
        if kwargs is not None:
            # Return an Executable Tool instance
            return ExecutableTool(path=path, **kwargs)
        else:
            return None
