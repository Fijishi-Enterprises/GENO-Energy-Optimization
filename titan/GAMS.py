# -*- coding: utf-8 -*-
"""
Created on Thu Jan 21 13:27:34 2016

@author: ererkka
"""

import os.path
import shutil

from .model import Model, DataFormat

# Constants
GAMS_EXECUTABLE = 'gams'


class GAMSModel(Model):
    """Class for GAMS models
    """

    def __init__(self, name, description, gamsfile,
                 input_dir='', output_dir=''):
        """
        Args:
            name (str): Model name
            description (str): Model description
            gamsfile (str): Path to GAMS program
        """

        self.gamsfile = gamsfile
        basedir = os.path.split(gamsfile)[0]
        GAMS_parameters = "Logoption=2"  # send LOG output to file
        command = '{} "{}" Curdir="{}" {}'.format(GAMS_EXECUTABLE, gamsfile,
                                                  basedir, GAMS_parameters)
        input_dir = os.path.join(basedir, input_dir)
        output_dir = os.path.join(basedir, output_dir)
        super().__init__(name, description, command, input_dir, output_dir)
        self.basedir = basedir  # Replace basedir
        self.logfile = os.path.splitext(gamsfile)[0] + '.log'
        self.lstfile = os.path.splitext(gamsfile)[0] + '.lst'

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

    def copy_output(self, dst_dir):
        ret = super().copy_output(dst_dir)
        try:
            shutil.copy(self.lstfile, dst_dir)
        except:
            ret = False
        return ret


GDX_DATA_FMT = DataFormat('GDX', 'gdx', binary=True)
GAMS_INC_FILE = DataFormat('GAMS inc file', 'inc')


