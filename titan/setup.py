"""
Setup class.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   26.10.2015
"""

import os
import shutil
import fnmatch
import logging
from PyQt5.QtCore import pyqtSignal, pyqtSlot
from config import INPUT_STORAGE_DIR, OUTPUT_STORAGE_DIR
from metaobject import MetaObject
from helpers import create_dir, find_in_latest_output_folder


class Setup(MetaObject):
    """Setup class."""

    setup_finished_signal = pyqtSignal(name="setup_finished_signal")

    def __init__(self, name, description, project, parent=None):
        """Class constructor.

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
        n = len(self._children)
        if position < 0:  # NOTE: Removed or position > n
            logging.error("Invalid position. Setup:{2} Position:{0} nr of children:{1}".format(position, n, self.name))
            return False
        self._children.insert(position, child)
        child._parent = self
        return True

    def remove_child(self, position):
        """Remove child Setup.

        Args:
            position (int): Position of removed child
        """
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
        """Returns the children of this Setup."""
        return self._children

    def row(self):
        """Returns the row on which this Setup is located."""
        if self._parent is not None:
            return self._parent._children.index(self)
        return 0

    def log(self, tab_level=-1):
        """[OBSOLETE] Returns Setup structure as a string.

        Args:
            tab_level (int): Tab level
        """
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
            cmdline_args (str, optional): Additional Setup command line arguments for the attached tool

        Returns:
            True if successful, False if not
        """
        # Create path for setup output directory
        self.output_dir = os.path.join(self.project.project_dir,
                                       OUTPUT_STORAGE_DIR,
                                       self.short_name)
        if not create_dir(self.output_dir):
            logging.error("Could not create output directory '{0}' for Setup '{1}'".format(self.output_dir, self.name))
            return False
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
        # Make input the same as output again so that finding files works correctly
        self.output_dir = self.input_dir
        # TODO: Add cleanup of output dir

    def get_input_files(self):
        """Get list of all input files in this Setup."""
        return os.listdir(self.input_dir)

    def get_output_files(self):
        """Get list of all output files in this Setup.
        Lists input files if there is no tool."""
        return os.listdir(self.output_dir)

    def find_input_file(self, fname, is_ancestor=False):
        """Find a given input file in the setup hierarchy.

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
        # Look from ancestor's output
        # If ancestor has no Tool, then its output directory is the same as its input directory
        elif not self.tool:  # Same as self.output_dir == self.input_dir:
            if fname in self.get_output_files():
                return os.path.join(self.output_dir, fname)
        # If ancestor has a Tool, then files must be searched from the most recent output directory
        else:
            folders = self.get_output_files()
            # Find file in the output folder with the most recent timestamp
            latest_folder_path = find_in_latest_output_folder(self.short_name, self.output_dir, folders, fname)
            if latest_folder_path:
                return os.path.join(latest_folder_path, fname)
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
        # ...or look from ancestor's output
        elif not self.tool:
            # Setup does not have a tool so input and output folders are the same
            src_files = self.get_output_files()
            src_dir = self.output_dir
        else:
            # Setup has a tool so look from the most recent output folder
            folders = self.get_output_files()
            # Get the most recent output folder file in the output folder with the most recent timestamp
            src_dir = find_in_latest_output_folder(self.short_name, self.output_dir, folders)
            if not src_dir:
                src_dir = ''
                src_files = list()
            else:
                src_files = os.listdir(src_dir)
        # logging.debug("Looking for files matching pattern '{0}' in source dir: '{1}'".format(pattern, src_dir))
        # Search for files
        new_fnames = [f for f in fnmatch.filter(src_files, pattern)
                      if f not in filenames]
        filenames.update(new_fnames)
        filepaths += [os.path.join(src_dir, fname) for fname in new_fnames]
        # Recourse to parent
        filepaths += self._parent.find_input_files(pattern, is_ancestor=True,
                                                   used_filenames=filenames)
        return filepaths

    def execute(self, ui):
        """Execute Setup.

        Args:
            ui (TitanUI): User interface
        """
        logging.info("Executing Setup '{}'".format(self.name))
        if self.is_ready:
            logging.debug("Setup '{}' ready. Starting next Setup".format(self.name))
            self.setup_finished_signal.emit()
            return
        # Get Setup tool and command line arguments
        if not self.tool:  # No tool in setup
            self.setup_finished(0)
            return
        try:
            instance = self.tool.create_instance(ui, self.cmdline_args, self.output_dir, self.short_name)
        except OSError:
            logging.error("Tool instance creation failed")
            ui.add_msg_signal.emit("Creating a Tool instance failed", 2)
            return
        # Connect instance_finished_signal to setup_finished() method
        instance.instance_finished_signal.connect(self.setup_finished)
        self.tool_instances.append(instance)
        if not self.copy_input(self.tool, ui, instance):
            ui.add_msg_signal.emit("Copying input files for Setup '{0}' failed".format(self.name), 2)
            return
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
            logging.debug("Setup <%s> failed" % self.name)
            self.is_ready = False
        # Run next Setup
        self.setup_finished_signal.emit()

    def copy_input(self, tool, ui, tool_instance=None):
        """Copy input of a tool in this setup to a tool instance.

        Args:
            tool (Tool): The tool
            ui (TitanUI): Titan UI
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
        ui.add_msg_signal.emit("Copying input files for Tool '{}' to work directory".format(tool.name), 0)
        logging.info("Copying input files for Tool '{}' to work directory".format(tool.name))
        # Process required and optional input files
        for filepath in tool.infiles | tool.infiles_opt:
            prefix, filename = os.path.split(filepath)
            dst_dir = os.path.join(input_dir, prefix)
            # Create the destination directory
            try:
                os.makedirs(dst_dir, exist_ok=True)
            except OSError as e:
                logging.error(e)
                ui.add_msg_signal.emit("Creating directory '{0}' failed. Check permissions.".format(dst_dir), 2)
                return False
            if '*' in filename:  # Deal with wildcards
                found_files = self.find_input_files(filename)
            else:
                found_file = self.find_input_file(filename)
                # Required file not found
                if filepath in tool.infiles and not found_file:
                    logging.error("Could not find required input file '{}'".format(filename))
                    ui.add_msg_signal.emit("Required input file '{0}' not found".format(filename), 2)
                    return False
                # Construct a list
                found_files = [found_file] if found_file else []
            # Do copying
            for src_file in found_files:
                try:
                    ret = shutil.copy(src_file, dst_dir)
                    logging.debug("File '{}' copied to '{}'".format(src_file, ret))
                except OSError:
                    logging.error("Copying file '{}' to directory '{}' failed".format(src_file, dst_dir))
                    ui.add_msg_signal.emit("Copying file '{0}' to directory '{1}' failed."
                                           " Check directory permissions.".format(src_file, dst_dir), 2)
                    return False
        logging.info("Finished copying input files for Tool '{}'".format(tool.name))
        ui.add_msg_signal.emit("Done", 1)
        return True

    def cleanup(self):
        """Remove temporary files of the setup. Removes Tool instance directories."""
        # TODO: Check if this is needed
        for t in self.tool_instances:
            t.remove()
