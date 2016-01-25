"""
File defines Model class and related classes

:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   26/10/2015
"""

import os
import shutil
from tools import run, run2, copy_files
from config import GAMS_EXECUTABLE, CONFIG_INPUT_DIR_BASE, CONFIG_OUTPUT_DIR_BASE


class MetaObject(object):

    def __init__(self, name, description):
        self.name = name
        self.description = description

    def get_short_name(self):
        return self.name.lower().replace(' ', '_')


class Model(MetaObject):
    """Abstract class for models."""

    def __init__(self, name, description, command,
                 input_dir='', output_dir=''):
        """Model constructor.
        Args:
            name (str): Name of the model
            description (str): Short description of the model
            command (str): Command executable
            input_dir (str): Input file directory (absolute or relative to command)
            output_dir (str): Output file directory (absolute or relative to command)
        """
        super().__init__(name, description)
        if not os.path.exists(command):
            pass #TODO: Do something here
        self.command = command
        self.logfile = ''
        self.basedir = os.path.split(command)[0]
        self.input_dir = os.path.join(self.basedir, input_dir)
        self.output_dir = os.path.join(self.basedir, output_dir)
        self.inputs = []
        self.input_format = None
        self.outputs = []
        self.output_format = None
        self.return_codes = {}

    def set_logfile(self, logfile):
        self.logfile = logfile

    def add_input(self, parameter):
        """Add input parameter for model.

        Args:
            parameter (DataParameter): Data parameter object
        """
        self.inputs.append(parameter)

    def add_output(self, parameter):
        """Add output parameter for model.

        Args:
            parameter (DataParameter): Data parameter object
        """
        self.outputs.append(parameter)

    def set_return_code(self, code, description):
        """
        Args:
            code (int): Return code
            description (str): Description
        """
        self.return_codes[code] = description

    def copy_input(self, src_dir):
        """Copy output of model somewhere.

        Args:
            src_dir (str): Source directory
        """
        copy_files(src_dir, self.input_dir, self.output_format.extension)

    def copy_output(self, dst_dir):
        """Copy output of model somewhere.

        Args:
            dst_dir (str): Destination directory
        """
        copy_files(self.output_dir, dst_dir, self.output_format.extension)
        if self.logfile is not None:
            shutil.copy(self.logfile, dst_dir)


class ModelConfig(MetaObject):
    """Class for model configuration

    Attributes:
        cmd_line_arguments (str): Extra command line arguments for the model
    """

    def __init__(self, name, description, model):
        """ModelConfig constructor.

        Args:
            name (str): Name of model configuration
            description (str): Description
            model (Model): The model this config applies to.
        """
        super().__init__(name, description)

        self.model = model

        self.cmd_line_arguments = ''

        self.input_dir = os.path.join(CONFIG_INPUT_DIR_BASE,
                                      self.model.get_short_name(),
                                      self.get_short_name())
        os.makedirs(self.input_dir, exist_ok=True)
        self.output_dir = os.path.join(CONFIG_OUTPUT_DIR_BASE,
                                       self.model.get_short_name(),
                                       self.get_short_name())
        os.makedirs(self.output_dir, exist_ok=True)

    def create_input(self):
        """Create input files for this model configuration."""
        pass

    def run(self):
        """Execute this model configuration."""

        self.model.copy_input(self.input_dir)

        command = '{} {}'.format(self.model.command, self.cmd_line_arguments)

        ret = run(command)

        try:
            out = self.model.return_codes[ret]
        except KeyError:
            out = ''
        finally:
            print(out)

        self.model.copy_output(self.output_dir)


class Dimension(MetaObject):
    """Data dimension."""

    def __init__(self, name, description):
        """

        :param name:
        :param description:
        :return:
        """
        super().__init__(name, description)


class DataFormat(object):
    """Class for defining data storage formats."""

    def __init__(self, name, extension):
        """
        Args:
            name (str): Name of data format
            extension (str): File name extension
        """
        self.name = name
        self.extension = extension


class DataParameter(MetaObject):
    """Class for data parameters
    """

    def __init__(self, name, description, units, indices=[]):
        """
        Args:
            name (str): Name of parameter
            description (str): Description
            units (str): Units of measure
            indices (list): List of indices (Dimension objects)
        """
        super().__init__(name, description)
        self.units = units
        self.indices = indices

    def get_dimension(self):
        return len(self.dimensions)


class GAMSModel(Model):
    """Class for GAMS models."""

    def __init__(self, name, description, gamsfile,
                 input_dir='', output_dir=''):
        """GAMS Model Constructor.

        Args:
            name (str): Name of the model
            description (str): Short description of the model
            gamsfile: GAMS exe file path
            input_dir (str): Input file directory (absolute or relative to command)
            output_dir (str): Output file directory (absolute or relative to command)
        """
        self.gamsfile = gamsfile
        basedir = os.path.split(gamsfile)[0]
        gams_parameters = "Logoption=3"
        # Logoption parameter options
        # 0	suppress LOG output
        # 1	LOG output to screen (default)
        # 2	send LOG output to file
        # 3	writes LOG output to standard output
        command = '{} "{}" Curdir="{}" {}'.format(GAMS_EXECUTABLE,
                                                  self.gamsfile, basedir,
                                                  gams_parameters)
        input_dir = os.path.join(basedir, input_dir)
        output_dir = os.path.join(basedir, output_dir)
        super().__init__(name, description, command, input_dir, output_dir)
        self.basedir = basedir  # Replace basedir
        self.logfile = os.path.splitext(gamsfile)[0] + '.log'
        self.lstfile = os.path.splitext(gamsfile)[0] + '.lst'

    def copy_output(self, dst_dir):
        super().copy_output(dst_dir)
        shutil.copy(self.lstfile, dst_dir)
