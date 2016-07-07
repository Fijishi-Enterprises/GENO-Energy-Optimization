"""
File defines Tool class and related classes.

:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   26/10/2015
"""

import os
import shutil
import glob
import fnmatch
import logging
import json
import tempfile
from copy import copy
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot
import qsubprocess
from config import INPUT_STORAGE_DIR, OUTPUT_STORAGE_DIR, WORK_DIR
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

    def __init__(self, name, description, path, files,
                 infiles=[], infiles_opt=[],
                 outfiles=[], short_name=None,
                 logfile=None, cmdline_args=None):
        """Tool constructor.

        Args:
            name (str): Name of the tool
            description (str): Short description of the tool
            path (str): Path to tool or Git repository
            files (str): List of files belonging to the tool (relative to `path`)
                         First file in the list is the main program file.
            infiles (list, optional): List of required input files
            infiles_opt (list, optional): List of optional input files (wildcards may be used)
            outfiles (list, optional): List of output files (wildcards may be used)
            short_name (str, optional): Short name for the tool
            logfile (str, optional): Log file name (relative to `path`)
            cmdline_args (str, optional): Command line arguments
        """
        super().__init__(name, description, short_name)
        if not os.path.exists(path):
            pass  # TODO: Do something here
        else:
            self.path = path
        self.files = files
        self.main_prgm = files[0]
        self.cmdline_args = cmdline_args
        self.infiles = set(infiles)
        self.infiles_opt = set(infiles_opt)
        self.outfiles = set(outfiles)
        if logfile is not None:
            self.outfiles.add(logfile)
        self.return_codes = {}
        self.def_file_path = ''  # Tool definition file path (JSON)

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
        
    def load(self):
        # TODO
        pass

    def save(self):
        """[OBSOLETE] Save tool object to disk."""
        the_dict = copy(self.__dict__)
        jsonfile = os.path.join(self.path,
                                '{}.json'.format(self.short_name))
        with open(jsonfile, 'w') as fp:
            json.dump(the_dict, fp, indent=4, cls=MyEncoder)

    def set_def_path(self, path):
        """Set definition file path for tool.

        Args:
            path (str): Absolute path to the definition file.
        """
        self.def_file_path = path


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
        self.basedir = tempfile.mkdtemp(dir=WORK_DIR,
                                        prefix=self.tool.short_name + '__')
        if not self._checkout:
            raise OSError("Could not create tool instance")
        self.command = os.path.join(self.basedir, tool.main_prgm)
        if cmdline_args is not None:
            self.command += ' ' + cmdline_args
        self.infiles = [os.path.join(self.basedir, f) for f in tool.infiles]
        self.infiles_opt = [os.path.join(self.basedir, f) for f in tool.infiles_opt]
        self.tool_output_dir = tool_output_dir
        self.outfiles = [os.path.join(self.basedir, f) for f in tool.outfiles]

    @property
    def _checkout(self):
        """Copy the tool files to the instance base directory"""
        for filepath in self.tool.files:
            dirname, file_pattern = os.path.split(filepath)
            src_dir = os.path.join(self.tool.path, dirname)
            dst_dir = os.path.join(self.basedir, dirname)
            # Create the destination directory
            try:
                os.makedirs(dst_dir, exist_ok=True)
            except OSError as e:
                logging.error(e)
                return False
            # Copy file if necessary
            if file_pattern:
                for src_file in glob.glob(os.path.join(src_dir, file_pattern)):
                    dst_file = os.path.join(dst_dir, os.path.basename(src_file))
                    logging.debug("Copying file {} to {}".format(src_file, dst_file))
                    try:
                        shutil.copyfile(src_file, dst_file)
                    except OSError as e:
                        logging.error(e)
                        return False
        logging.debug("Copied all files for tool '{}'".format(self.tool.name))
        return True

    def execute(self, ui):
        """Start executing tool instance in QProcess.

        Args:
            ui (QMainWindow): User interface
        """
        self.tool_process = qsubprocess.QSubProcess(ui, self.tool)
        self.tool_process.subprocess_finished_signal.connect(self.tool_finished)
        logging.debug("Starting Tool: '%s'" % self.tool.name)
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
            logging.debug("Tool '%s' finished. GAMS Return code:%d. Message: %s" % (self.tool.name, ret, return_msg))
        except KeyError:
            logging.error("Unknown return code")
        finally:
            # TODO: Check that copy_output works. invest and MIP output folders are now the same.
            if not self.copy_output(self.tool_output_dir):
                logging.error("Copying output files to folder '{0}' failed".format(self.tool_output_dir))
            else:
                logging.debug("Output files copied to <%s>" % self.tool_output_dir)
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
        self.tool = None
        self.cmdline_args = ""
        self.tool_instances = []
        self.is_ready = False
        self._setup_process = None
        self._running_tool = None
        # Create path to setup input directory (except for root)
        if not self.is_root:
            self.input_dir = os.path.join(project.project_dir, INPUT_STORAGE_DIR,
                                          self.short_name)
            self.output_dir = self.input_dir
            create_dir(self.input_dir)
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

    def attach_tool(self, tool, cmdline_args=""):
        """Attach a tool to this Setup.

        Args:
            tool (Tool): The tool to be used in this process
            cmdline_args (str, optional): Extra command line arguments for this tool
        """
        # Create path for setup output directory
        self.output_dir = os.path.join(self.project.project_dir,
                                       OUTPUT_STORAGE_DIR,
                                       self.short_name)
        create_dir(self.output_dir)
        if self.tool is not None:
            logging.info("Replacing tool '{0}' with tool '{1}' in Setup '{2}'"
                            .format(self.tool.name, tool.name, self.name))
        self.tool = tool
        self.cmdline_args = cmdline_args
        logging.debug("Tool '{0}' with cmdline args '{1}' added to Setup '{2}'"
                      .format(self.tool.name, self.cmdline_args, self.name))
        return True

    def detach_tool(self):
        """Remove Tool and command line arguments from Setup.
        Used when Tool is changed."""
        self.tool = None
        self.cmdline_args = ""
        # TODO: Add cleanup of output dir

    def get_input_files(self):
        """Get list of all input files in this setup."""
        return os.listdir(self.input_dir)

    def get_output_files(self):
        """Get list of all output files in this setup.
        Lists input files if there is no tool."""
        return os.listdir(self.output_dir)

    def find_input_file(self, fname, is_ancestor=False):
        """Find a given input file in the setup hierarchy

        Args:
            fname (str): Input file name or pattern
            is_ancestor (bool): Specifies if looking at an ancestor setup

        Returns:
            Full path to file
        """
        if self.is_root:
            return None

        # Look at own input
        if not is_ancestor:
            if fname in self.get_input_files():
                return os.path.join(self.input_dir, fname)
        # Look at ancestor's output
        else:
            if fname in self.get_output_files():
                return os.path.join(self.output_dir, fname)

        return self._parent.find_input_file(fname, is_ancestor=True)

    def find_input_files(self, pattern, is_ancestor=False, used_filenames=None):
        """Find all input files which match a pattern in the setup hierarchy.

        Args:
            pattern (str): Input file name or pattern
            is_ancestor (bool): Specifies if looking at an ancestor setup
            used_filenames (set): Set of filenames already used

        Returns:
            List of full paths to file
        """
        if self.is_root:
            return list()

        filenames = set() if not used_filenames else used_filenames
        filepaths = list()

        # Look in own input
        if not is_ancestor:
            src_files = self.get_input_files()
            src_dir = self.input_dir
        # ...or look in ancestors' output
        else:
            src_files = self.get_output_files()
            src_dir = self.output_dir

        # Search for files
        new_fnames = [f for f in fnmatch.filter(src_files, pattern)
                      if f not in filenames]
        filenames.update(new_fnames)
        filepaths += [os.path.join(src_dir, fname) for fname in new_fnames]

        # Recourse to parent
        filepaths += self._parent.find_input_files(pattern, is_ancestor=True,
                                                   used_filenames=filenames)

        return filepaths

    def save(self, path=''):
        """[OBSOLETE] Save Setup object to disk.

        Args:
            path (str): File save path (project dir)
        """
        if path == '':
            logging.error("No path given")
            return
        the_dict = {}
        if self._parent is not None:
            the_dict['parent'] = self._parent.short_name
        if self.tool:
            the_dict['processes'] = [self.tool.short_name]
        the_dict['is_ready'] = self.is_ready

        jsonfile = os.path.join(path,
                                '{}.json'.format(self.short_name))
        with open(jsonfile, 'w') as fp:
            json.dump(the_dict, fp, indent=4)

    def execute(self, ui):
        """Execute Setup.

        Args:
            ui (TitanUI): User interface
            output_dir_timestamp (str): String to add to output dir name
        """
        logging.info("Executing Setup '{}'".format(self.name))
        if self.is_ready:
            logging.debug("Setup '{}' ready. Starting next Setup".format(self.name))
            self.setup_finished_signal.emit()
            return
        # TODO: If the assigned Tool of Setup is not available in ToolModel then execution should fail.
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
            # logging.debug("Setup <%s> finished successfully. Setting is_ready to True" % self.name)
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
            tool_instance (ToolInstance): Tool instance. If not
                none, execution is done in tool directory.

        Returns:
            ret (bool): Operation success
        """
        if tool is None:
            return True

        if tool_instance:
            input_dir = tool_instance.basedir  # Run tool in work directory
        else:
            input_dir = tool.path  # Run tool in /tools/ directory

        # Process required and optional input files
        for filepath in tool.infiles | tool.infiles_opt:
            prefix, filename = os.path.split(filepath)
            dst_dir = os.path.join(input_dir, prefix)
            if '*' in filename:  # Deal with wildcards
                found_files = self.find_input_files(filename)
            else:
                found_file = self.find_input_file(filename)
                # Required file not found
                if filepath in tool.infiles and not found_file:
                    logging.debug("Could not find required input file '{}'"
                                  .format(filename))
                    return False
                # Construct a list
                found_files = [found_file] if found_file else []
            # Do copying
            for src_file in found_files:
                shutil.copy(src_file, dst_dir)
                logging.debug("Copied file '{}' to: {}".format(src_file, dst_dir))

        logging.debug("Copied input files for '{}'".format(tool.name))
        return True

    def cleanup(self):
        """Remove temporary files of the setup."""
        for t in self.tool_instances:
            t.remove()
