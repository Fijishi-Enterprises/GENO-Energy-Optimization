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
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot
import qsubprocess
from metaobject import MetaObject
from helpers import create_dir, create_output_dir_timestamp


class Tool(MetaObject):
    """Class for defining a tool"""

    def __init__(self, name, description, path, files,
                 datafiles=None, datafiles_opt=None,
                 outfiles=None, short_name=None,
                 logfile=None, cmdline_args=None):
        """Class constructor.

        Args:
            name (str): Name of the tool
            description (str): Short description of the tool
            path (str): Path to tool
            files (str): List of files belonging to the tool (relative to 'path')
            datafiles (list, optional): List of required data files
            datafiles_opt (list, optional): List of optional data files (wildcards may be used)
            outfiles (list, optional): List of output files (wildcards may be used)
            short_name (str, optional): Short name for the tool
            logfile (str, optional): Log file name (relative to 'path')
            cmdline_args (str, optional): Tool command line arguments (read from tool definition file)
        """
        super().__init__(name, description, short_name)
        if not os.path.exists(path):
            pass  # TODO: Do something here
        else:
            self.path = path
        self.files = files
        self.cmdline_args = cmdline_args
        self.datafiles = set(datafiles) if datafiles else set()
        self.datafiles_opt = set(datafiles_opt) if datafiles_opt else set()
        self.outfiles = set(outfiles) if outfiles else set()
        self.return_codes = {}
        self.def_file_path = ''  # Tool definition file path (JSON)

    def set_return_code(self, code, description):
        """Set a return code and associated text description for the tool.

        Args:
            code (int): Return code
            description (str): Description
        """
        self.return_codes[code] = description

    def set_def_path(self, path):
        """Set definition file path for tool.

        Args:
            path (str): Absolute path to the definition file.
        """
        self.def_file_path = path

    def get_def_path(self):
        """Returns tool definition file path."""
        return self.def_file_path

    def create_instance(self, ui, setup_cmdline_args, tool_output_dir, setup_name):
        """Create an instance of the tool.

        Args:
            ui (TitanUI): Titan GUI instance
            setup_cmdline_args (str): Extra command line arguments
            tool_output_dir (str): Output directory for tool
            setup_name (str): Short name of Setup that calls this method
        """
        return ToolInstance(self, ui, tool_output_dir, setup_name)

    def append_cmdline_args(self, command, setup_cmdline_args):
        """Append command line arguments to a command.

        Args:
            command (str): Tool command
            setup_cmdline_args (str): Extra Setup command line args
        """
        if (setup_cmdline_args is not None) and (not setup_cmdline_args == ''):
            if (self.cmdline_args is not None) and (not self.cmdline_args == ''):
                command += ' ' + self.cmdline_args + ' ' + setup_cmdline_args
            else:
                command += ' ' + setup_cmdline_args
        else:
            if (self.cmdline_args is not None) and (not self.cmdline_args == ''):
                command += ' ' + self.cmdline_args
        return command

    def debug(self, *args, **kwargs):
        """Debug method to be implemented in subclasses."""
        pass

    @staticmethod
    def check_definition(data, ui,
                         required=None, optional=None, list_required=None):
        """Check a dict containing tool definition.

        Args:
            data (dict): Dictionary of tool definitions
            ui (TitanUI): Titan GUI instance
            required (list): required keys
            optional  (list): optional keys
            list_required (list): keys that need to be lists

        Returns:
            dict or None if there was a problem in the tool definition file
        """

        # Required and optional keys in definition file
        if required is None:
            required = Tool.required_keys
        if optional is None:
            optional = Tool.optional_keys
        if list_required is None:
            list_required = Tool.list_required_keys

        kwargs = {}
        for p in required + optional:
            try:
                kwargs[p] = data[p]
            except KeyError:
                if p in required:
                    ui.add_msg_signal.emit(
                        "Required keyword '{0}' missing".format(p), 2)
                    logging.error("Required keyword '{0}' missing".format(p))
                    return None
                else:
                    # logging.info("Optional keyword '{0}' missing".format(p))
                    pass
            # Check that some variables are lists
            if p in list_required:
                try:
                    if not isinstance(data[p], list):
                        ui.add_msg_signal.emit(
                            "Keyword '{0}' value must be a list".format(p), 2)
                        logging.error(
                            "Keyword '{0}' value must be a list".format(p))
                        return None
                except KeyError:
                    pass
        return kwargs

    # Required and optional keys in definition
    required_keys = ['name', 'description', 'files']
    optional_keys = ['short_name', 'datafiles', 'datafiles_opt',
                     'outfiles', 'cmdline_args']
    list_required_keys = ['files', 'datafiles',
                          'datafiles_opt', 'outfiles']  # These should be lists


class ExecutableTool(Tool):
    """Class for any executable tools"""

    def __init__(self, name, description, path, files, command=None,
                 datafiles=None, datafiles_opt=None, outfiles=None,
                 short_name=None, logfile=None, cmdline_args=None):

        super().__init__(name, description, path, files, datafiles,
                         datafiles_opt, outfiles, short_name, logfile,
                         cmdline_args)
        self.command = command
        self.return_codes = {0: "Normal return"}

    def create_instance(self, ui, setup_cmdline_args, tool_output_dir, setup_name):
        """Create an instance of the ExecutableTool

        Args:
            ui (TitanUI): Titan GUI window
            setup_cmdline_args (str): Extra Setup command line arguments
            tool_output_dir (str): Tool output directory
            setup_name (str): Short name of Setup that owns this Tool
        """
        # Let Tool class create the ToolInstance
        instance = super().create_instance(ui, setup_cmdline_args,
                                           tool_output_dir, setup_name)

        # Get command
        if self.command is not None:
            command = self.command
        else:
            if os.name == 'nt':
                command = 'CMD /C {}'.format(self.files[0])
            else:
                command = './{}'.format(self.files[0])

        # Update instance command
        instance.command = self.append_cmdline_args(command, setup_cmdline_args)
        return instance

    @staticmethod
    def load(path, data, ui):
        """Create ExecutableTool according to a tool definition.

        Args:
            path (str): Base path to tool files
            data (dict): Dictionary of tool definitions
            ui (TitanUI): Titan GUI instance

        Returns:
            ExecutableTool instance or None if there was a problem in the tool definition file.
        """

        kwargs = ExecutableTool.check_definition(data, ui,
                                                 optional=Tool.optional_keys + ['command'])
        if kwargs is not None:
            # Return an Executable Tool instance
            return ExecutableTool(path=path, **kwargs)
        else:
            return None


class ToolInstance(QObject):
    """Class for Tool instances."""

    instance_finished_signal = pyqtSignal(int, name="instance_finished_signal")

    def __init__(self, tool, ui, tool_output_dir, setup_name):
        """Tool instance constructor.

        Args:
            tool (Tool): Tool for which this instance is created
            ui (TitanUI): Titan GUI instance
            tool_output_dir (str): Tool output directory
            setup_name (str): Short name of Setup that creates this instance
        """
        super().__init__()
        self.tool = tool
        self.ui = ui
        self.tool_process = None
        self.tool_output_dir = tool_output_dir
        wrk_dir = ui.current_project().work_dir
        self.basedir = tempfile.mkdtemp(dir=wrk_dir,
                                        prefix=self.tool.short_name + '__')
        self.setup_name = setup_name
        self.command = ''  # command is created after ToolInstance is initialized
        self.datafiles = [os.path.join(self.basedir, f) for f in tool.datafiles]
        self.datafiles_opt = [os.path.join(self.basedir, f) for f in tool.datafiles_opt]
        self.outfiles = [os.path.join(self.basedir, f) for f in tool.outfiles]
        # Check that required output directories are created
        self.make_work_output_dirs()
        # Checkout Tool
        if not self._checkout:
            raise OSError("Could not create tool instance")

    @property
    def _checkout(self):
        """Copy Tool files to work directory."""
        n_copied_files = 0
        logging.info("Copying Tool '{}' to work directory".format(self.tool.name))
        self.ui.add_msg_signal.emit("*** Copying Tool <b>{}</b> to work directory ***".format(self.tool.name), 0)
        for filepath in self.tool.files:
            dirname, file_pattern = os.path.split(filepath)
            src_dir = os.path.join(self.tool.path, dirname)
            dst_dir = os.path.join(self.basedir, dirname)
            # Create the destination directory
            try:
                os.makedirs(dst_dir, exist_ok=True)
            except OSError as e:
                logging.error(e)
                self.ui.add_msg_signal.emit("Making directory <b>{0}</b> failed".format(dst_dir), 2)
                return False
            # Copy file if necessary
            if file_pattern:
                for src_file in glob.glob(os.path.join(src_dir, file_pattern)):
                    dst_file = os.path.join(dst_dir, os.path.basename(src_file))
                    logging.debug("Copying file {} to {}".format(src_file, dst_file))
                    try:
                        shutil.copyfile(src_file, dst_file)
                        n_copied_files += 1
                    except OSError as e:
                        logging.error(e)
                        self.ui.add_msg_signal.emit("Copying file <b>{0}</b> to <b>{1}</b> failed"
                                                    .format(src_file, dst_file), 2)
                        return False
        if n_copied_files == 0:
            self.ui.add_msg_signal.emit("Warning: No files copied", 3)
        else:
            self.ui.add_msg_signal.emit("\tCopied <b>{0}</b> file(s)".format(n_copied_files), 0)
        self.ui.add_msg_signal.emit("Done", 1)
        return True

    def execute(self, ui):
        """Start executing tool instance in QProcess.

        Args:
            ui (TitanUI): User interface
        """
        self.tool_process = qsubprocess.QSubProcess(ui, self.tool)
        self.tool_process.subprocess_finished_signal.connect(self.tool_finished)
        logging.debug("Starting Tool '{0}'".format(self.tool.name))
        # Start running model in sub-process
        self.tool_process.start_process(self.command, workdir=self.basedir)

    def debug(self, *args, **kwargs):
        self.tool.debug(*args, **kwargs)

    @pyqtSlot(int, name="tool_finished")
    def tool_finished(self, ret):
        """Run when tool has finished processing. Copies output of tool
        to project output directory.

        Args:
            ret (int): Return code given by tool
        """
        self.tool_process = None
        tool_failed = True
        try:
            return_msg = self.tool.return_codes[ret]
            logging.debug("Tool '{0}' finished. Return code:{1}. Message: {2}".format(self.tool.name, ret, return_msg))
            if ret == 0:
                tool_failed = False
                self.ui.add_msg_signal.emit("\tReturn code: {0}. Message: '{1}'".format(ret, return_msg), 0)
            else:
                self.ui.add_msg_signal.emit("\tReturn code: {0}. Message: '{1}'".format(ret, return_msg), 2)
        except KeyError:
            logging.error("Unknown return code: {0}".format(ret))
            self.ui.add_msg_signal.emit("\tUnknown return code ({0})".format(ret), 2)
        finally:
            if ret == 62097:
                # If user terminated execution
                self.ui.add_msg_signal.emit("\tTool <b>{0}</b> execution stopped".format(self.tool.name), 0)
                self.instance_finished_signal.emit(ret)
                return
            self.ui.add_msg_signal.emit("Done", 1)
            # Get timestamp when tool finished
            output_dir_timestamp = create_output_dir_timestamp()
            # Create an output folder with timestamp and copy output directly there
            if tool_failed:
                result_path_str = os.path.abspath(os.path.join(self.tool_output_dir, 'failed', output_dir_timestamp))
            else:
                result_path_str = os.path.abspath(os.path.join(self.tool_output_dir, output_dir_timestamp))
            result_path = create_dir(result_path_str)
            if not result_path:
                self.ui.add_msg_signal.emit("Error creating timestamped result directory. "
                                            "Tool output files not copied. "
                                            "Check permissions of Setup folders", 2)
                self.instance_finished_signal.emit(9999)
                return
            self.ui.add_msg_signal.emit("*** Saving result files ***", 0)
            saved_files, failed_files = self.copy_output(result_path)
            if len(saved_files) == 0:
                # If no files were saved
                logging.error("No files saved to result directory '{0}'".format(result_path))
                self.ui.add_msg_signal.emit("No files saved to result directory", 2)
                if len(failed_files) == 0:
                    # If there were no failed files either
                    logging.error("No failed files")
                    self.ui.add_msg_signal.emit("Warning: Check 'outfiles' parameter in tool definition file.", 3)
                    # TODO: Test this
                    self.instance_finished_signal.emit(ret)
            if len(saved_files) > 0:
                # If there are saved files
                self.ui.add_msg_signal.emit("The following result files were saved successfully", 0)
                for i in range(len(saved_files)):
                    fname = os.path.split(saved_files[i])[1]
                    self.ui.add_msg_signal.emit("\t{0}".format(fname), 0)
            if len(failed_files) > 0:
                # If some files failed
                self.ui.add_msg_signal.emit("The following result files were not found", 2)
                for i in range(len(failed_files)):
                    failed_fname = os.path.split(failed_files[i])[1]
                    self.ui.add_msg_signal.emit("\t{0}".format(failed_fname), 2)
            self.ui.add_msg_signal.emit("Done", 1)
            # Show result folder
            logging.debug("Result files saved to <{0}>".format(result_path))
            result_anchor = "<a href='file:///" + result_path + "'>" + result_path + "</a>"
            work_anchor = "<a href='file:///" + self.basedir + "'>" + self.basedir + "</a>"
            self.ui.add_msg_signal.emit("Result Directory: {}".format(result_anchor), 0)
            self.ui.add_msg_signal.emit("Work Directory: {}".format(work_anchor), 0)
            if tool_failed:
                self.tool.debug(self.ui, self.basedir, self.tool.short_name)
            # Emit signal to Setup that tool instance has finished with return code
            self.instance_finished_signal.emit(ret)

    def terminate_instance(self):
        """Terminate tool process execution."""
        if not self.tool_process:
            return
        self.tool_process.terminate_process()

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
            failed_files = list()
            saved_files = list()
            logging.debug("Saving result files to <{0}>".format(target_dir))
            for pattern in self.outfiles:
                # Check for wildcards in pattern
                if ('*' in pattern) or ('?' in pattern):
                    for fname in glob.glob(pattern):
                        logging.debug("Match for pattern <{0}> found. Saving file {1}".format(pattern, fname))
                        shutil.copy(fname, target_dir)
                        saved_files.append(fname)
                else:
                    if not os.path.isfile(pattern):
                        failed_files.append(pattern)
                        continue
                    logging.debug("Saving file {0}".format(pattern))
                    shutil.copy(pattern, target_dir)
                    saved_files.append(pattern)
            return saved_files, failed_files

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
                    self.ui.add_msg_signal.emit("Creating directory '{}' failed".format(dst_dir), 2)
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
