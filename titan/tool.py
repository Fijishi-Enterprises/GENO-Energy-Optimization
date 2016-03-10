"""
File defines Tool class and related classes

:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   26/10/2015
"""

import os
import shutil
import glob
import logging
from copy import copy
from collections import OrderedDict
import json
from collections import namedtuple
import tempfile

from tools import run, copy_files
from config import INPUT_STORAGE_DIR, OUTPUT_STORAGE_DIR, WORK_DIR, \
                   IGNORE_PATTERNS


class MetaObject(object):
    """Class for an object which has a name and some description

    Attributes:
        name (str): The name of the object
        short_name (str): Short name that can be used in file names etc.
        description (str): Description of the object
    """

    def __init__(self, name, description):
        self.name = name
        self.short_name = name.lower().replace(' ', '_')
        self.description = description


class Tool(MetaObject):
    """Class for defining a tool"""

    def __init__(self, name, description, path, main_prgm,
                 input_dir='', output_dir='', logfile=None):
        """Tool constructor

        Args:
            name (str): Name of the tool
            description (str): Short description of the tool
            path (str): Path to tool or Git repository
            main_prgm (str): Main program file (relative to `path`)
            input_dir (str, optional): Input file directory (relative to `path`)
            output_dir (str, optional): Output file directory (relative to `path`)
            logfile (str, optional): Log file name (relative to `path`)
        """
        super().__init__(name, description)
        if not os.path.exists(path):
            pass  # TODO: Do something here
        else:
            self.path = path
        self.main_prgm = main_prgm
        self.input_dir = input_dir
        self.outfiles = [os.path.join(output_dir, '*')]
        if logfile is not None:
            self.outfiles.append(logfile)
        self.inputs = set()
        self.input_formats = set()
        self.outputs = set()
        self.output_formats = set()
        self.return_codes = {}

    def add_input(self, parameter):
        """Add input parameter for tool.

        Args:
            parameter (DataParameter): Data parameter object
        """
        self.inputs.add(parameter)

    def add_output(self, parameter):
        """Add output parameter for tool.

        Args:
            parameter (DataParameter): Data parameter object
        """
        self.outputs.add(parameter)

    def add_input_format(self, format_type):
        """Add input data format to the tool

        Args:
            format_type (DataFormat): Data format
        """
        self.input_formats.add(format_type)

    def add_output_format(self, format_type):
        """Add output data format to the tool

        Args:
            format_type (DataFormat): Data format
        """
        self.output_formats.add(format_type)

    def get_input_file_extensions(self):
        return [fmt.extension for fmt in self.input_formats]

    def get_output_file_extensions(self):
        return [fmt.extension for fmt in self.output_formats]

    def set_return_code(self, code, description):
        """Set a return code and associated text description for the tool

        Args:
            code (int): Return code
            description (str): Description
        """
        self.return_codes[code] = description

    def create_instance(self, cmdline_args=None):
        """Create an instance of the tool

        Args:
            cmdline_args (str): Extra command line arguments
        """

        return ToolInstance(self, cmdline_args)


class ToolInstance(object):
    """Class for Tool instances
    """

    def __init__(self, tool, cmdline_args=None):
        """
        Args:
            tool (Tool): Which tool this instance implements
            cmdline_args (str, optional): Extra command line arguments
        """

        self.tool = tool
        self.basedir = self._checkout()
        self.command = os.path.join(self.basedir, tool.main_prgm)
        if cmdline_args is not None:
            self.command += ' ' + cmdline_args
        self.input_dir = os.path.join(self.basedir, tool.input_dir)
        self.outfiles = [os.path.join(self.basedir, f) for f in tool.outfiles]

    def _checkout(self):
        """Copy tool to a temporary directory
        """
        basedir = os.path.join(WORK_DIR,
                               '{}__{}'.format(self.tool.short_name,
                                         next(tempfile._get_candidate_names())))
        return shutil.copytree(self.tool.path, basedir,
                        ignore=shutil.ignore_patterns(*IGNORE_PATTERNS))

    def execute(self, target_dir):
        """Create a copy of the tool somewhere

        Args:
            target_dir (str): Target directory for output

        Returns:
            basedir (str): Path to tool instance base directory
        """
        # Make a copy of the tool and execute
        ret = run(self.command)

        try:
            out = self.tool.return_codes[ret]
        except KeyError:
            out = ''
        finally:
            logging.info("{} status: {}".format(self.tool.name, out))

        if ret == 0:
            self.copy_output(os.path.join(target_dir, self.tool.short_name))
            return True
        else:
            return False

    def remove(self):
        """Remove the tool instance files
        """
        shutil.rmtree(self.basedir, ignore_errors=True)

    def copy_output(self, target_dir):
            """Save output of a tool instance

            Args:
                tool_instance (ToolInstance):

            Returns:
                ret (bool): Operation success
            """

            count = 0
            for pattern in self.outfiles:
                for fname in glob.glob(pattern):
                    shutil.copy(fname, target_dir)
                    count += 1

            return True if count > 0 else False


class Setup(MetaObject):
    """Class for setup

    """

    def __init__(self, name, description, parent=None):
        """Setup constructor.

        Args:
            name (str): Name of tool setup
            description (str): Description
            parent (Setup): Parent setup of this setup

        """
        super().__init__(name, description)
        self.parent = parent
        self.inputs = set()
        self.tools = OrderedDict()
        self.tool_instances = []
        self.is_ready = False

        # Create input directory
        self.input_dir = os.path.join(INPUT_STORAGE_DIR, self.short_name)
        os.makedirs(self.input_dir, exist_ok=True)

        # Create output directory name
        self.output_dir = os.path.join(OUTPUT_STORAGE_DIR, self.short_name)

    def create_input(self):
        """Create input files for this tool setup
        """
        pass

    def add_input(self, tool):
        """Add inputs for a tool in this setup

        Args:
            tool (Tool): The tool
        """
        self.inputs.add(tool)
        input_dir = os.path.join(self.input_dir, tool.short_name)
        os.makedirs(input_dir, exist_ok=True)

    def add_tool(self, tool, cmdline_args=None):
        """Add a tool to this setup

        Args:
            tool (Tool): The tool to be used in this process
            cmdline_args (str, optional): Extra command line arguments for this tool
        """

        # Create input and output directories

        self.tools.update({tool: cmdline_args})
        os.makedirs(os.path.join(self.output_dir, tool.short_name),
                    exist_ok=True)

    def get_input_files(self, tool, file_fmt):
        """Get paths of input files of given format for tool in this setup

        Args:
            tool (Tool): The tool
            file_fmt (DataFormat): File format
        """

        filenames = glob.glob(os.path.join(self.input_dir,
                                           tool.short_name,
                                           '*.{}'.format(file_fmt.extension)))
        if self.parent is not None:
            filenames += self.parent.get_input_files(tool, file_fmt)
            filenames += self.parent.get_output_files(tool, file_fmt)

        return filenames

    def get_output_files(self, tool, file_fmt):
        """Get paths of output files of given format for tool in this setup

        Args:
            tool (Tool): The tool
            file_fmt (DataFormat): File format
        """

        filenames = glob.glob(os.path.join(self.output_dir,
                                           tool.short_name,
                                           '*.{}'.format(file_fmt.extension)))
        if self.parent is not None:
            filenames += self.parent.get_output_files(tool, file_fmt)

        return filenames

    def save(self):
        """Save setup object to disk
        """

        the_dict = {}
        if self.parent is not None:
            the_dict['parent'] = self.parent.short_name
        if len(self.tools) > 0:
            the_dict['processes'] = [p.tool.short_name for p in self.tools]
        the_dict['is_ready'] = self.is_ready

        jsonfile = os.path.join(INPUT_STORAGE_DIR,
                                '{}.json'.format(self.short_name))
        with open(jsonfile, 'w') as fp:
            json.dump(the_dict, fp, indent=4)

    def execute(self):
        """Execute this tool setup
        """

        if self.parent is not None:
            if not self.parent.execute():
                return False

        if not self.is_ready:
            logging.info("Executing setup '{}'".format(self.name))
        else:
            return True

        for tool, cmdline_args in self.tools.items():
            instance = tool.create_instance(cmdline_args)
            self.tool_instances.append(instance)
            self.copy_input(tool, instance)
            if not instance.execute(self.output_dir):
                return False

        self.is_ready = True
        return True

    def copy_input(self, tool, tool_instance):
        """Copy input of a tool in this setup to a tool instance

        Args:
            tool (Tool): The tool
            tool_instance (ToolInstance): Destination directory (input dir of tool instance)

        Returns:
            ret (bool): Operation success
        """

        for fmt in tool.input_formats:
            filenames = self.get_input_files(tool, fmt)
            # Just copy binary files
            if fmt.is_binary:
                for fname in filenames:
                    shutil.copy(fname, tool_instance.input_dir)
            # Concatenate other files
            else:
                outfilename = os.path.join(tool_instance.input_dir,
                                           'changes.{}'.format(fmt.extension))
                # If setup has no parent, then create a new file
                if self.parent is None:
                    mode = 'w'
                # otherwise, append to previous file
                else:
                    mode = 'w+'
                with open(outfilename, mode) as outfile:
                    for fname in reversed(filenames):
                        with open(fname, 'r') as readfile:
                            shutil.copyfileobj(readfile, outfile)
                    # Separate with a blank line
                    outfile.write('\n')

        logging.debug(("Copied input files for tool '{}'"
                       .format(tool.name)))

        return True

    def cleanup(self):
        """Remove temporary files of the setup
        """
        for t in self.tool_instances:
            t.remove()


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

    def __init__(self, name, extension, is_binary=False):
        """
        Args:
            name (str): Name of data format
            extension (str): File name extension
        """
        self.name = name
        self.extension = extension
        self.is_binary = is_binary


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
