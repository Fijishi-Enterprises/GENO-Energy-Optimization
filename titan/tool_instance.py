"""
ToolInstance class definition.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   13.6.2017
"""

import os
import shutil
import glob
import logging
import tempfile
from PyQt5.QtCore import QObject, pyqtSignal, pyqtSlot
import qsubprocess
from helpers import create_output_dir_timestamp, create_dir


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
