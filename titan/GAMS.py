# -*- coding: utf-8 -*-
"""
Created on Thu Jan 21 13:27:34 2016

@author: ererkka
"""

import os.path
import json

from tool import Tool, ToolInstance, DataFormat, DataParameter
from config import GAMS_EXECUTABLE


class GAMSModel(Tool):
    """Class for GAMS models."""

    def __init__(self, parent, name, description, path, gamsfile,
                 short_name=None,
                 input_dir='', output_dir=''):
        """Class constructor.

        Args:
            parent: Parent class
            name (str): Model name
            description (str): Model description
            gamsfile (str): Path to main GAMS program (relative to `path`)
            short_name (str, optional): Short name for the model
            input_dir: Input directory path
            output_dir: Output directory path
        """
        # TODO: Clean up constructor.
        self.parent = parent
        self.gamsfile = gamsfile
        self.model_path = path
        super().__init__(parent, name, description, self.model_path, gamsfile,
                         short_name, input_dir, output_dir)
        self.GAMS_parameters = "Logoption=3"  # send LOG output to STDOUT
        # Add .log and .lst files to list of outputs
        self.outfiles.append(os.path.join(path, os.path.splitext(gamsfile)[0] + '.log'))
        self.outfiles.append(os.path.join(path, os.path.splitext(gamsfile)[0] + '.lst'))
        # Logoption options
        # 0 suppress LOG output
        # 1 LOG output to screen (default)
        # 2 send LOG output to file
        # 3 writes LOG output to standard output
        # 4 writes LOG output to a file and standard output  # Not supported

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

    def create_instance(self, cmdline_args=None, tool_output_dir=''):
        """Create an instance of the GAMS model

        Args:
            cmdline_args (str): Extra command line arguments
            tool_output_dir (str): Tool output directory
        """
        instance = ToolInstance(self, cmdline_args, tool_output_dir)
        # Tamper the command to call GAMS
        command = '{} "{}" Curdir="{}" {}'.format(GAMS_EXECUTABLE, self.gamsfile,
                                                  instance.basedir,
                                                  self.GAMS_parameters)
        if cmdline_args is not None:
            command += ' ' + cmdline_args
        instance.command = command
        return instance
           
    @staticmethod
    def load(jsonfile):
        """Load a tool description from a file"""
        with open(jsonfile, 'r') as fp:
            data = json.load(fp)
            gm = GAMSModel(data['name'], data['description'],
                           data['path'], data['gamsfile'],
                           data['short_name'], 
                           data['input_dir'], data['output_dir'])
            gm.inputs = set([DataParameter(obj['name'], obj['description'],
                                           obj['units'], obj['indices']) 
                             for obj in data['inputs']])
                
            return gm
            
            


GDX_DATA_FMT = DataFormat('GDX', 'gdx', is_binary=True)
GAMS_INC_FILE = DataFormat('GAMS inc file', 'inc')
