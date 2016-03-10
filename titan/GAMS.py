# -*- coding: utf-8 -*-
"""
Created on Thu Jan 21 13:27:34 2016

@author: ererkka
"""

import os.path
import shutil

from tool import Tool, ToolInstance, DataFormat
from config import GAMS_EXECUTABLE


class GAMSModel(Tool):
    """Class for GAMS models
    """

    def __init__(self, name, description, path, gamsfile,
                 input_dir='', output_dir=''):
        """
        Args:
            name (str): Model name
            description (str): Model description
            path (str): Path to model or Git repository
            gamsfile (str): Path to main GAMS program (relative to `path`)
        """

        self.gamsfile = gamsfile
        self.GAMS_parameters = "Logoption=3"  # send LOG output to STDOUT

        super().__init__(name, description, path, gamsfile,
                         input_dir, output_dir)
        # Add .log and .lst files to list of outputs
        self.outfiles.append(os.path.splitext(gamsfile)[0] + '.log')
        self.outfiles.append(os.path.splitext(gamsfile)[0] + '.lst')

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

    def create_instance(self, cmdline_args=None):
        """Create an instance of the GAMS model

        Args:
            basedir (str): Where to put that instance
            cmdline_args (str): Extra command line arguments
        """

        instance = ToolInstance(self)
        # Tamper the command to call GAMS
        command = '{} "{}" Curdir="{}" {}'.format(GAMS_EXECUTABLE, self.gamsfile,
                                                  instance.basedir,
                                                  self.GAMS_parameters)
        if cmdline_args is not None:
            command += ' ' + cmdline_args
        instance.command = command
        return instance


GDX_DATA_FMT = DataFormat('GDX', 'gdx', is_binary=True)
GAMS_INC_FILE = DataFormat('GAMS inc file', 'inc')


