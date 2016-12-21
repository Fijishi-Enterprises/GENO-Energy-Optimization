"""
Tool, ToolInstance and related classes.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   26.10.2015
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
from config import WORK_DIR
from metaobject import MetaObject
from helpers import create_dir, create_output_dir_timestamp


class Tool(MetaObject):
    """Class for defining a tool"""
    def __init__(self, name, description, path, files,
                 infiles=None, infiles_opt=None,
                 outfiles=None, short_name=None,
                 logfile=None, cmdline_args=None):
        """Class constructor.

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
        self.infiles = set(infiles) if infiles else set()
        self.infiles_opt = set(infiles_opt) if infiles_opt else set()
        self.outfiles = set(outfiles) if outfiles else set()
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

    def create_instance(self, ui, cmdline_args, tool_output_dir, setup_name):
        """Create an instance of the tool.

        Args:
            ui (TitanUI): Titan GUI instance
            cmdline_args (str): Extra command line arguments
            tool_output_dir (str): Output directory for tool
            setup_name (str): Short name of Setup that calls this method
        """
        if cmdline_args is not None:
            if self.cmdline_args is not None:
                cmdline_args += ' ' + self.cmdline_args
        else:
            cmdline_args = self.cmdline_args
        return ToolInstance(self, ui, cmdline_args, tool_output_dir, setup_name)

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

    def get_def_path(self):
        """Get definition file path of tool."""
        return self.def_file_path


class ToolInstance(QObject):
    """Class for Tool instances."""

    instance_finished_signal = pyqtSignal(int, name="instance_finished_signal")

    def __init__(self, tool, ui, cmdline_args, tool_output_dir, setup_name):
        """Tool instance constructor.

        Args:
            tool (Tool): Which tool this instance implements
            ui (TitanUI): Titan GUI instance
            cmdline_args (str, optional): Extra command line arguments
            tool_output_dir (str): Tool output directory
            setup_name (str): Short name of Setup that creates this instance
        """
        super().__init__()
        self.tool = tool
        self.ui = ui
        self.tool_process = None
        self.tool_output_dir = tool_output_dir
        self.basedir = tempfile.mkdtemp(dir=WORK_DIR,
                                        prefix=self.tool.short_name + '__')
        self.setup_name = setup_name
        self.command = os.path.join(self.basedir, tool.main_prgm)
        if cmdline_args is not None or cmdline_args is not "":
            self.command += ' ' + cmdline_args
        self.infiles = [os.path.join(self.basedir, f) for f in tool.infiles]
        self.infiles_opt = [os.path.join(self.basedir, f) for f in tool.infiles_opt]
        self.outfiles = [os.path.join(self.basedir, f) for f in tool.outfiles]
        self.make_work_output_dirs()
        # Checkout Tool
        if not self._checkout:
            raise OSError("Could not create tool instance")

    @property
    def _checkout(self):
        """Copy Tool files to work directory."""
        logging.info("Copying Tool '{}' to work directory".format(self.tool.name))
        self.ui.add_msg_signal.emit("Copying Tool '{}' to work directory".format(self.tool.name), 0)
        for filepath in self.tool.files:
            dirname, file_pattern = os.path.split(filepath)
            src_dir = os.path.join(self.tool.path, dirname)
            dst_dir = os.path.join(self.basedir, dirname)
            # Create the destination directory
            try:
                os.makedirs(dst_dir, exist_ok=True)
            except OSError as e:
                logging.error(e)
                self.ui.add_msg_signal.emit("Making directory '{}' failed".format(dst_dir), 2)
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
                        self.ui.add_msg_signal.emit("Copying file '{}' failed".format(src_file), 2)
                        return False
        logging.info("Finished copying Tool '{}'".format(self.tool.name))
        self.ui.add_msg_signal.emit("Done", 1)
        return True

    def execute(self, ui):
        """Start executing tool instance in QProcess.

        Args:
            ui (TitanUI): User interface
        """
        self.tool_process = qsubprocess.QSubProcess(ui, self.tool)
        self.tool_process.subprocess_finished_signal.connect(self.tool_finished)
        logging.debug("Starting Tool: '%s'" % self.tool.name)
        # Start running model in sub-process
        self.tool_process.start_process(self.command)

    @pyqtSlot(int, name="tool_finished")
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
            # Get timestamp when tool finished
            output_dir_timestamp = create_output_dir_timestamp()
            # Create an output folder with timestamp and copy output directly there
            result_path = create_dir(os.path.abspath(os.path.join(
                self.tool_output_dir, self.setup_name + output_dir_timestamp)))
            if not result_path:
                self.ui.add_msg_signal.emit("Error creating timestamped result directory. "
                                            "Tool output files not copied. "
                                            "Check permissions of Setup folders", 2)
                return
            # TODO: If Tool fails, either don't copy output files or copy them to [FAILED] folder
            if not self.copy_output(result_path):
                logging.error("Copying output files to folder '{0}' failed".format(result_path))
                self.ui.add_msg_signal.emit("Copying output files of Tool '{0}' to directory '{1}' failed"
                                            .format(self.tool.name, result_path), 2)
            else:
                logging.debug("Output files copied to <%s>" % result_path)
                self.ui.add_msg_signal.emit("Tool '{0}' output files copied to '{1}'"
                                            .format(self.tool.name, result_path), 0)
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

    def make_work_output_dirs(self):
        """Make sure that work directory has the necessary output directories for Tool output files.
        Checks only "outfiles" list. Alternatively you can add directories to "files" list in the tool definition file.

        Returns:
            Boolean value depending on operation success.
        """
        for path in self.tool.outfiles:
            dirname, file_pattern = os.path.split(path)
            if dirname == '':
                continue
            dst_dir = os.path.join(self.basedir, dirname)
            # Create the destination directory
            if not os.path.isdir(dst_dir):
                try:
                    os.makedirs(dst_dir, exist_ok=True)
                except OSError as e:
                    logging.error(e)
                    self.ui.add_msg_signal.emit("Making directory '{}' failed".format(dst_dir), 2)
                    return False
                logging.debug("Created output directory <{0}>".format(dst_dir))
        return True


class MyEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, set):
            return list(o)
        try:
            return o.__dict__
        except AttributeError:
            pass
