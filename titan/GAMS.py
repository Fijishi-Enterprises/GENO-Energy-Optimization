# -*- coding: utf-8 -*-
"""
Created on Thu Jan 21 13:27:34 2016

@author: ererkka
"""

import os.path
import json

from tool import Tool, ToolInstance, DataFormat, Dimension, DataParameter,\
                 CSV_DATA_FMT
from config import GAMS_EXECUTABLE


class GAMSModel(Tool):
    """Class for GAMS models."""

    def __init__(self, name, description, path, main_prgm,
                 short_name=None,
                 input_dir='.', output_dir='.',
                 cmdline_args=None):
        """Class constructor.

        Args:
            name (str): Model name
            description (str): Model description
            gamsfile (str): Path to main GAMS program (relative to `path`)
            short_name (str, optional): Short name for the model
            input_dir: Input directory path
            output_dir: Output directory path
            cmdline_args (str, optional): GAMS command line arguments
        """
        # TODO: Clean up constructor.
        super().__init__(name, description, path, main_prgm,
                         short_name, input_dir, output_dir,
                         cmdline_args=cmdline_args)
        self.GAMS_parameters = "Logoption=3"  # send LOG output to STDOUT
        # Add .log and .lst files to list of outputs
        self.outfiles.append(os.path.join(path, os.path.splitext(main_prgm)[0] + '.log'))
        self.outfiles.append(os.path.join(path, os.path.splitext(main_prgm)[0] + '.lst'))
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
        command = '{} "{}" Curdir="{}" {}'.format(GAMS_EXECUTABLE, self.main_prgm,
                                                  instance.basedir,
                                                  self.GAMS_parameters)
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
    def load(jsonfile):
        """Load a tool description from a file"""
        with open(jsonfile, 'r') as fp:
            json_data = json.load(fp)

        # Find required and optional arguments
        required = ['name', 'description', 'main_prgm']
        optional = ['short_name', 'input_dir', 'output_dir', 'cmdline_args']

        # Construct keyword arguments
        kwargs = {}
        for p in required + optional:
            try:
                kwargs[p] = json_data[p]
            except KeyError:
                if p in required:
                    # TODO: Do something smart
                    raise
                else:
                    pass

        kwargs['path'] = os.path.dirname(jsonfile)  # Infer path form JSON file

        # Create a GAMSModel instance
        model = GAMSModel(**kwargs)

        # Define other attributes
        try:
            model.dimensions = json_data['dimensions']
        except KeyError:
            pass

        for p in ['inputs', 'outputs']:
            try:
                data = json_data[p]
            except KeyError:
                pass
            else:
                setattr(model, p, set([DataParameter(p['name'], p['description'],
                                                     p['units'], p['indices'])
                                       for p in data]))

        for p in ['input_formats', 'output_formats']:
            try:
                formats = json_data[p]
            except KeyError:
                pass
            else:
                setattr(model, p, set([eval(fmt) for fmt in formats]))

        return model
            

GDX_DATA_FMT = DataFormat('GDX', 'gdx', is_binary=True)
GAMS_INC_FILE = DataFormat('GAMS inc file', 'inc')
