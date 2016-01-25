"""
File defines Model class and related classes

:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   26/10/2015
"""

import os
import shutil
import glob
import logging
from collections import OrderedDict
import json

from tools import run, copy_files
from config import INPUT_STORAGE_DIR, OUTPUT_STORAGE_DIR


class MetaObject(object):

    def __init__(self, name, description):
        self.name = name
        self.short_name = name.lower().replace(' ', '_')
        self.description = description


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
            pass  # TODO: Do something here
        self.command = command
        self.logfile = ''
        self.basedir = os.path.split(command)[0]
        self.input_dir = os.path.join(self.basedir, input_dir)
        self.output_dir = os.path.join(self.basedir, output_dir)
        self.inputs = []
        self.input_formats = set()
        self.outputs = []
        self.output_formats = set()
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

    def add_input_format(self, format_type):
        """Add input data format to the model

        Args:
            format_type (DataFormat): Data format
        """
        self.input_formats.add(format_type)

    def add_output_format(self, format_type):
        """Add output data format to the model

        Args:
            format_type (DataFormat): Data format
        """
        self.output_formats.add(format_type)

    def get_input_file_extensions(self):
        return [fmt.extension for fmt in self.input_formats]

    def get_output_file_extensions(self):
        return [fmt.extension for fmt in self.output_formats]

    def set_return_code(self, code, description):
        """Set a return code and associated text description for the model

        Args:
            code (int): Return code
            description (str): Description
        """
        self.return_codes[code] = description

    def copy_input(self, src_dir):
        """Copy input of the model from somewhere.

        Args:
            src_dir (str): Source directory

        Returns:
            ret (bool): Operation success
        """
        return copy_files(src_dir, self.input_dir,
                      includes=['*.{}'.format(ext)
                                for ext
                                in self.get_input_file_extensions()]) > 0

    def copy_output(self, dst_dir):
        """Copy output of the model to somewhere.

        Args:
            dst_dir (str): Destination directory

        Returns:
            ret (bool): Operation success
        """

        ret = False

        ret = copy_files(self.output_dir, dst_dir,
                         includes=['*.{}'.format(ext)
                                   for ext
                                   in self.get_output_file_extensions()]) > 0

        if self.logfile is not None:
            try:
                shutil.copy(self.logfile, dst_dir)
            except:
                ret = False
            else:
                ret = True

        return ret


class Setup(MetaObject):
    """Class for setup

    """

    def __init__(self, name, description, parent=None):
        """Setup constructor.

        Args:
            name (str): Name of model setup
            description (str): Description
            parent (ModelSetup): Parent setup of this setup

        """
        super().__init__(name, description)
        self.parent = parent
        self.models = OrderedDict()
        self.is_ready = False

        # Create input and output directories
        self.input_dir = os.path.join(INPUT_STORAGE_DIR, self.short_name)
        os.makedirs(self.input_dir, exist_ok=True)
        self.output_dir = os.path.join(OUTPUT_STORAGE_DIR, self.short_name)
        os.makedirs(self.output_dir, exist_ok=True)

    def create_input(self):
        """Create input files for this model setup
        """
        pass

    def add_model(self, model, cmd_line_arguments=''):
        """Add model to this setup

        Args:
            model (Model): The model to be used in this setup
            cmd_line_arguments (str, optional): Extra command line arguments for the model
        """

        self.models.update({model: cmd_line_arguments})

        # Create input and output directories
        input_dir = os.path.join(self.input_dir,
                                 model.short_name)
        os.makedirs(input_dir, exist_ok=True)
        output_dir = os.path.join(self.output_dir,
                                  model.short_name)
        os.makedirs(self.output_dir, exist_ok=True)

    def get_input_files(self, model, file_fmt):
        """Get paths of input files of given format for model in this setup

        Args:
            model (Model): The model
            file_fmt (DataFormat): Collect only binary files
        """

        filenames = glob.glob(os.path.join(self.input_dir,
                                           model.short_name,
                                           '*.{}'.format(file_fmt.extension)))
        if self.parent is not None:
            filenames += self.parent.get_input_files(model, file_fmt)

        return filenames

    def save(self):
        """Save setup object to disk
        """

        the_dict = {}
        if self.parent is not None:
            the_dict['parent'] = self.parent.short_name
        if len(self.models) > 0:
            the_dict['models'] = [mdl.short_name for mdl in self.models.keys()]
        the_dict['is_ready'] = self.is_ready

        jsonfile = os.path.join(INPUT_STORAGE_DIR,
                                '{}.json'.format(self.short_name))
        with open(jsonfile, 'w') as fp:
            json.dump(the_dict, fp, indent=4)

    def execute(self):
        """Execute this model setup
        """

        if self.parent is not None:
            if not self.parent.execute():
                return False

        if not self.is_ready:
            logging.info("Executing setup '{}'".format(self.name))
        else:
            return True

        for mdl in self.models.keys():
            for fmt in mdl.input_formats:
                filenames = self.get_input_files(mdl, fmt)
                # Just copy binary files
                if fmt.binary:
                    for fname in filenames:
                        shutil.copy(fname, mdl.input_dir)
                # Concatenate other files
                else:
                    outfilename = os.path.join(mdl.input_dir,
                                               'changes.{}'.format(fmt.extension))
                    with open(outfilename, 'w') as outfile:
                        for fname in reversed(filenames):
                            with open(fname, 'r') as readfile:
                                shutil.copyfileobj(readfile, outfile)
                        # Separate with a blank line
                        outfile.write('\n')

                    logging.debug(("Copied input files for model '{}'"
                                     .format(mdl.name)))

            command = '{} {}'.format(mdl.command, self.models[mdl])
            ret = run(command)

            try:
                out = mdl.return_codes[ret]
            except KeyError:
                out = ''
            finally:
                logging.info("{} status: {}".format(mdl.name, out))

            if ret == 0:
                mdl.copy_output(os.path.join(self.output_dir,
                                         mdl.short_name))
                self.is_ready = True
            else:
                return False

        return True


class Dimension(MetaObject):
    """Data dimension."""

    def __init__(self, name, description):
        """

        :param name:
        :param description:
        :return:
        """
        super().__init__(name, description)

        self.data = []


class DataFormat(object):
    """Class for defining data storage formats."""

    def __init__(self, name, extension, binary=False):
        """
        Args:
            name (str): Name of data format
            extension (str): File name extension
        """
        self.name = name
        self.extension = extension
        self.binary = binary


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
        return len(self.indices)
