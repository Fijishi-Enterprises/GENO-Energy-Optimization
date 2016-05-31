"""
File defines Tool class and related classes.

:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   26/10/2015
"""

import os
import shutil
import glob
import logging
import json
import tempfile
from copy import copy
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot
import qsubprocess
from config import INPUT_STORAGE_DIR, OUTPUT_STORAGE_DIR, WORK_DIR, IGNORE_PATTERNS
from metaobject import MetaObject
from tools import create_dir

                   
class MyEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, set):
            return list(o)
        try:
            return o.__dict__
        except AttributeError:
            pass


class Tool(MetaObject):
    """Class for defining a tool"""

    def __init__(self, name, description, path, main_prgm,
                 short_name=None,
                 input_dir='.', output_dir='.', logfile=None,
                 cmdline_args=None):
        """Tool constructor.

        Args:
            name (str): Name of the tool
            description (str): Short description of the tool
            path (str): Path to tool or Git repository
            main_prgm (str): Main program file (relative to `path`)
            short_name (str, optional): Short name for the tool
            input_dir (str, optional): Input file directory (relative to `path`)
            output_dir (str, optional): Output file directory (relative to `path`)
            logfile (str, optional): Log file name (relative to `path`)
            cmdline_args (str, optional): Command line arguments
        """
        super().__init__(name, description, short_name)
        if not os.path.exists(path):
            pass  # TODO: Do something here
        else:
            self.path = path
        self.main_prgm = main_prgm
        self.cmdline_args = cmdline_args
        self.input_dir = input_dir
        self.output_dir = output_dir
        self.outfiles = [os.path.join(output_dir, '*')]
        if logfile is not None:
            self.outfiles.append(logfile)
        self.dimensions = {}
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
        """Add input data format to the tool.

        Args:
            format_type (DataFormat): Data format
        """
        self.input_formats.add(format_type)

    def add_output_format(self, format_type):
        """Add output data format to the tool.

        Args:
            format_type (DataFormat): Data format
        """
        self.output_formats.add(format_type)

    def get_input_file_extensions(self):
        return [fmt.extension for fmt in self.input_formats]

    def get_output_file_extensions(self):
        return [fmt.extension for fmt in self.output_formats]

    def set_return_code(self, code, description):
        """Set a return code and associated text description for the tool.

        Args:
            code (int): Return code
            description (str): Description
        """
        self.return_codes[code] = description

    def create_instance(self, cmdline_args=None, tool_output_dir=''):
        """Create an instance of the tool.

        Args:
            cmdline_args (str): Extra command line arguments
            tool_output_dir (str): Output directory for tool
        """
        if cmdline_args is not None:
            if self.cmdline_args is not None:
                cmdline_args += ' ' + self.cmdline_args
        else:
            cmdline_args = self.cmdline_args

        return ToolInstance(self, cmdline_args, tool_output_dir)
        
    def save(self):
        """Save tool object to disk
        """
        
        the_dict = copy(self.__dict__)

        jsonfile = os.path.join(self.path,
                                '{}.json'.format(self.short_name))
        with open(jsonfile, 'w') as fp:
            json.dump(the_dict, fp, indent=4, cls=MyEncoder)


class ToolInstance(QObject):
    """Class for Tool instances."""
    instance_finished_signal = pyqtSignal(int)

    def __init__(self, tool, cmdline_args=None, tool_output_dir=''):
        """Tool instance constructor.

        Args:
            tool (Tool): Which tool this instance implements
            cmdline_args (str, optional): Extra command line arguments
            tool_output_dir (str): Tool output directory
        """
        super().__init__()
        self.tool = tool
        self.tool_process = None
        self.basedir = self._checkout()
        self.command = os.path.join(self.basedir, tool.main_prgm)
        if cmdline_args is not None:
            self.command += ' ' + cmdline_args
        self.input_dir = os.path.join(self.basedir, tool.input_dir)
        self.tool_output_dir = tool_output_dir
        self.outfiles = [os.path.join(self.basedir, f) for f in tool.outfiles]

    def _checkout(self):
        """Copy tool to a temporary directory."""
        basedir = os.path.join(WORK_DIR, '{}__{}'.format(self.tool.short_name, next(tempfile._get_candidate_names())))
        return shutil.copytree(self.tool.path, basedir, ignore=shutil.ignore_patterns(*IGNORE_PATTERNS))

    def execute(self, ui):
        """Start executing tool instance in QProcess.

        Args:
            ui (QMainWindow): User interface
        """
        self.tool_process = qsubprocess.QSubProcess(ui, self.tool)
        self.tool_process.subprocess_finished_signal.connect(self.tool_finished)
        logging.debug("Starting model: '%s'" % self.tool.name)
        # Start running model in sub-process
        self.tool_process.start_process(self.command)

    @pyqtSlot(int)
    def tool_finished(self, ret):
        """Run when tool has finished processing. Copies output of tool
        to project output directory.

        Args:
            ret (int): Return code given by tool
        """
        try:
            return_msg = self.tool.return_codes[ret]
            logging.debug("GAMS Return code:%d. Message: %s" % (ret, return_msg))
        except KeyError:
            logging.debug("Unknown return code")
        finally:
            logging.debug("Tool '%s' finished." % self.tool.name)
            dst_folder = os.path.join(self.tool_output_dir, self.tool.short_name)
            # TODO: Check that copy_output works. invest and MIP output folders are now the same.
            if not self.copy_output(dst_folder):
                logging.error("Copying output files to folder '{0}' failed".format(dst_folder))
            else:
                logging.debug("Output files copied to <%s>" % dst_folder)
            # Emit signal to Setup that tool instance has finished with GAMS return code
            self.instance_finished_signal.emit(ret)

    def remove(self):
        """Remove the tool instance files."""
        shutil.rmtree(self.basedir, ignore_errors=True)

    def copy_output(self, target_dir):
            """Save output of a tool instance

            Args:
                target_dir (str): Copy destination

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
    """Class for setup."""

    setup_finished_signal = pyqtSignal()

    def __init__(self, name, description, project, parent=None):
        """Setup constructor.

        Args:
            name (str): Name of tool setup
            description (str): Description
            project (SceletonProject): The project this setup belongs to
            parent (Setup): Parent setup of this setup

        """
        super().__init__(name, description)
        self._parent = parent
        self._children = list()
        self.is_root = False
        if name == 'root':
            self.is_root = True
        self.project = project
        self.inputs = set()
        self.tool = None
        self.cmdline_args = ""
        self.tool_instances = []
        self.is_ready = False
        self._setup_process = None
        self._running_tool = None
        # Create paths to Setup input & output directories
        self.input_dir = os.path.join(project.project_dir, INPUT_STORAGE_DIR,
                                      self.short_name)
        self.output_dir = os.path.join(project.project_dir, OUTPUT_STORAGE_DIR,
                                       self.short_name)
        # Do not create directories for root Setup
        if not self.is_root:
            create_dir(self.input_dir)
            create_dir(self.output_dir)
        # If not root, add self to parent's children
        if parent is not None:
            parent._add_child(self)

    def _add_child(self, child):
        """Add children to Setup. Do not use outside this class!

        Args:
            child (Setup): Child Setup to add.
        """
        self._children.append(child)

    def insert_child(self, position, child):
        """Used to add children for Setup if it was created without parent.

        Args:
            position (int): Position to insert child Setup
            child (Setup): Setup to insert

        Returns:
            Boolean variable depending on operation's success
        """
        if position < 0 or position > len(self._children):
            logging.error("Invalid position")
            return False
        self._children.insert(position, child)
        child._parent = self
        return True

    def remove_child(self, position):
        if position < 0 or position > len(self._children):
            return False
        child = self._children.pop(position)
        child._parent = None
        return True

    def child(self, row):
        """Returns child Setup on given row.

        Args:
            row (int): Row number
        """
        try:
            ch = self._children[row]
        except IndexError:
            ch = None
        return ch

    def child_count(self):
        """Returns number of children."""
        return len(self._children)

    def parent(self):
        """Returns the parent of this Setup."""
        return self._parent

    def children(self):
        return self._children

    def row(self):
        if self._parent is not None:
            return self._parent._children.index(self)
        return 0

    def log(self, tab_level=-1):
        """Returns Setup representation as string."""
        output = ""
        tab_level += 1
        for i in range(tab_level):
            output += "\t"
        output += "|------" + self.short_name + "\n"
        for child in self._children:
            output += child.log(tab_level)
        tab_level -= 1
        output += "\n"
        return output

    def create_input(self):
        """Create input files for this tool setup."""
        raise NotImplementedError

    def add_input(self, tool):
        """Add inputs for a tool in this setup.

        Args:
            tool (Tool): The tool
        """
        self.inputs.add(tool)
        input_dir = os.path.join(self.input_dir, tool.short_name)
        if not os.path.exists(input_dir):
            create_dir(input_dir)

    def add_tool(self, tool, cmdline_args=""):
        """Add a tool to this setup.

        Args:
            tool (Tool): The tool to be used in this process
            cmdline_args (str, optional): Extra command line arguments for this tool
        """
        # TODO: When adding a model to a Setup, all its parents (at least Base) must have an input
        # TODO: folder with model name. e.g /input/base/magic
        # Add tool to Setup. If Setup already had a tool, it is replaced with the new one.
        # self.tools.update({tool: cmdline_args})
        if self.tool is not None:
            logging.warning("Replacing tool '{0}' with tool '{1}' in Setup '{2}'"
                            .format(self.tool.name, tool.name, self.name))
        self.tool = tool
        self.cmdline_args = cmdline_args
        # Create model input and output directories for the Setup
        input_dir = create_dir(self.input_dir, tool.short_name)
        output_dir = create_dir(self.output_dir, tool.short_name)
        if (input_dir is None) or (output_dir is None):
            return False
        logging.debug("Tool '{0}' with cmdline args '{1}' added to Setup '{2}'"
                      .format(self.tool.name, self.cmdline_args, self.name))
        return True

    def get_input_files(self, tool, file_fmt):
        """Get paths of input files of given format for tool in this setup

        Args:
            tool (Tool): The tool
            file_fmt (DataFormat): File format
        """
        # TODO: Get input for this tool from own input folder and parents.
        # If parent has a tool -> get output files
        # If parent has no tool -> get input files
        try:
            filenames = glob.glob(os.path.join(self.input_dir,
                                               tool.short_name,
                                               '*.{}'.format(file_fmt.extension)))
        except OSError:
            logging.error("OSError")
            if self.input_dir:
                logging.error("Setup <{0}> input dir:'{1}'".format(self.name, self.input_dir))
            return list()
        if self._parent is not None:
            if self.is_root:
                return filenames
            filenames += self._parent.get_input_files(tool, file_fmt)
            filenames += self._parent.get_output_files(tool, file_fmt)
        return filenames

    def get_output_files(self, tool, file_fmt):
        """Get paths of output files of given format for tool in this setup.

        Args:
            tool (Tool): The tool
            file_fmt (DataFormat): File format
        """

        filenames = glob.glob(os.path.join(self.output_dir,
                                           tool.short_name,
                                           '*.{}'.format(file_fmt.extension)))
        if self._parent is not None:
            filenames += self._parent.get_output_files(tool, file_fmt)
        return filenames

    def save(self, path=''):
        """Save setup object to disk.

        Args:
            path (str): File save path (project dir)
        """
        if path == '':
            logging.error("No path given")
            return
        the_dict = {}
        if self._parent is not None:
            the_dict['parent'] = self._parent.short_name
        # if len(self.tools) > 0:
        #     the_dict['processes'] = [p.tool.short_name for p in self.tools]
        if self.tool:
            the_dict['processes'] = [self.tool.short_name]
        the_dict['is_ready'] = self.is_ready

        jsonfile = os.path.join(path,
                                '{}.json'.format(self.short_name))
        with open(jsonfile, 'w') as fp:
            json.dump(the_dict, fp, indent=4)

    def execute(self, ui):
        """Execute this tool setup.

        Args:
            ui (QMainWindow): User interface
        """
        logging.info("Executing Setup '{}'".format(self.name))
        if self.is_ready:
            logging.debug("Setup '{}' ready. Starting next Setup in SetupTree".format(self.name))
            self.setup_finished_signal.emit()
            return
        # Get Setup tool and command line arguments
        if not self.tool:  # No tool in setup
            self.setup_finished(0)
            return
        instance = self.tool.create_instance(self.cmdline_args, self.output_dir)
        # Connect instance_finished_signal to setup_finished() method
        instance.instance_finished_signal.connect(self.setup_finished)
        self.tool_instances.append(instance)
        self.copy_input(self.tool, instance)
        instance.execute(ui)
        # Wait for instance_finished_signal to start setup_finished()

    @pyqtSlot(int)
    def setup_finished(self, ret):
        """Executed when tool has finished processing.

        Args:
            ret (int): Return code from sub-process

        Returns:
            True if tool was executed successfully, False otherwise
        """
        if ret == 0:
            logging.debug("Setup <%s> finished successfully. Setting is_ready to True" % self.name)
            self.is_ready = True
        else:
            logging.debug("Setup <%s> failed. is_ready is False" % self.name)
            self.is_ready = False
        # Run next Setup
        self.setup_finished_signal.emit()

    def copy_input(self, tool, tool_instance=None):
        """Copy input of a tool in this setup to a tool instance.

        Args:
            tool (Tool): The tool
            tool_instance (ToolInstance): Tool instance. If none, execution is done in tool directory.

        Returns:
            ret (bool): Operation success
        """
        if not tool_instance:
            dst_dir = tool.input_dir  # Run tool in /models/ directory
        else:
            dst_dir = tool_instance.input_dir  # Run tool in work directory
        for fmt in tool.input_formats:
            filenames = self.get_input_files(tool, fmt)
            # Just copy binary files
            if fmt.is_binary:
                for fname in filenames:
                    shutil.copy(fname, dst_dir)
                    logging.debug("Copied file '%s' to: <%s>" % (fname, dst_dir))
            # Concatenate other files
            else:
                outfilename = os.path.join(dst_dir,
                                           'changes.{}'.format(fmt.extension))
                # If setup has no parent, then create a new file
                if self._parent is None:
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
                    logging.debug("Created file '%s' to: <%s>" % (outfilename, dst_dir))

        logging.debug(("Copied input files for tool '{}'"
                       .format(tool.name)))

        return True

    @staticmethod
    def create_results_dir(path, name, simulation_failed=False):
        """ Creates a new directory for storing simulation results.

        Args:
            path (str): Path where the new directory should be created.
            name (str): Basename for the directory.
            simulation_failed (boolean): If True, concatenates '(Failed) ' to the result folder name.

        Returns:
            Absolute path to the new results directory or None if failed.

        The new directory is named as follows: "name-time_stamp". If a folder
        with the same name already exists an underscore and index number is
        added at the end of folder name.
        """
        # TODO: Use this method to create unique result directories for every run
        #  Check that the output directory is writable.
        if not os.access(path, os.W_OK):
            logging.error('Results folder missing.')
            return None
        #  Add timestamp to filename.
        try:
            stamp = datetime.datetime.fromtimestamp(time.time())
        except OverflowError:
            logging.error('Timestamp out of range.')
            return None
        dir_name = name + '-' + stamp.strftime('%Y-%m-%dT%H.%M.%S')
        if simulation_failed:
            dir_name = '(Failed) ' + dir_name
        results_path = path + os.sep + dir_name
        logging.debug('Output destination dir: %s' % results_path)
        #  Create a new directory for storing results.
        counter = 1
        while True:
            if not os.path.exists(results_path):
                os.makedirs(results_path)
                break
            else:
                results_path = (path + os.sep + dir_name + '_' +
                                str(counter))
                counter += 1
                if counter >= 1000:
                    logging.error('Unable to create results folder.')
                    return None
        logging.debug('Created results directory: %s' % results_path)
        return results_path

    def cleanup(self):
        """Remove temporary files of the setup."""
        for t in self.tool_instances:
            t.remove()


class Dimension(object):
    """Data dimension."""
    def __init__(self, name, description):
        """Constructor.

        Args:
            name: Dimension name.
            description: Dimension description.

        """
        self.name = name
        self.description = description
        self.data = []
        
    def __repr__(self):        
        return "Dimension('{}', '{}')".format(self.name, self.description)
        

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
        
    def __repr__(self):
        return ("DataFormat('{}', '{}', is_binary={})"
                .format(self.name, self.extension, self.is_binary))
        
CSV_DATA_FMT = DataFormat('Comma separated values', 'csv')


class DataParameter(object):
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
        self.name = name
        self.description = description
        self.units = units
        self.indices = indices
        
    def __repr__(self):        
        return ("DataParameter('{}', '{}', '{}', {})"
                .format(self.name, self.description,
                        self.units, self.indices))

    def get_dimension(self):
        return len(self.indices)
