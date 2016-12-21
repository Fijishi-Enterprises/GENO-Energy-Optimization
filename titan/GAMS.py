"""
GAMSModel class.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.01.2016
"""

import os.path
import json
import logging

from tool import Tool, ToolInstance
from config import GAMS_EXECUTABLE


class GAMSModel(Tool):
    """Class for GAMS models."""
    def __init__(self, name, description, path, files,
                 infiles=None, infiles_opt=None, outfiles=None,
                 short_name=None, cmdline_args=None):
        """Class constructor.

        Args:
            name (str): Model name
            description (str): Model description
            files (str): List of files belonging to the model (relative to `path`)
                         First file in the list is the main GAMS program.
            infiles (list, optional): List of required input files
            infiles_opt (list, optional): List of optional input files (wildcards may be used)
            outfiles (list, optional): List of output files (wildcards may be used)
            short_name (str, optional): Short name for the model
            cmdline_args (str, optional): GAMS command line arguments
        """
        super().__init__(name, description, path, files,
                         infiles, infiles_opt, outfiles, short_name,
                         cmdline_args=cmdline_args)
        # Split main_prgm to main_dir and main_prgm
        # because GAMS needs to run in the directory of the main program
        self.main_dir, self.main_prgm = os.path.split(self.main_prgm)
        self.GAMS_parameters = ['Cerr=1',  # Stop on first compilation error
                                'Logoption=3']  # Send LOG output to STDOUT
        # Logoption options
        # 0 suppress LOG output
        # 1 LOG output to screen (default)
        # 2 send LOG output to file
        # 3 writes LOG output to standard output
        # 4 writes LOG output to a file and standard output  [Not supported]

        # Add .log and .lst files to list of outputs
        self.outfiles.add(os.path.splitext(self.main_prgm)[0] + '.log')
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
            11: "out of disk"
        }

    def __repr__(self):
        return "GAMSModel('{}')".format(self.name)

    def create_instance(self, ui, cmdline_args, tool_output_dir, setup_name):
        """Create an instance of the GAMS model

        Args:
            ui (TitanUI): Titan GUI window
            cmdline_args (str): Extra command line arguments
            tool_output_dir (str): Tool output directory
            setup_name (str): Short name of Setup that owns this Tool
        """
        instance = ToolInstance(self, ui, cmdline_args, tool_output_dir, setup_name)
        # Tamper the command to call GAMS
        command = '{} "{}" Curdir="{}" {}'.format(GAMS_EXECUTABLE,
                                                  self.main_prgm,
                                                  os.path.join(instance.basedir, self.main_dir),
                                                  ' '.join(self.GAMS_parameters))
        if cmdline_args is not None:
            if self.cmdline_args is not None:
                command += ' ' + self.cmdline_args + ' ' + cmdline_args
            else:
                command += ' ' + cmdline_args
        else:
            if self.cmdline_args is not None:
                command += self.cmdline_args

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
