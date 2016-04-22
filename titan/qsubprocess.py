"""
Module to handle running tools in a QProcess.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   27.1.2016
"""

from PyQt5.QtCore import QObject, QProcess, pyqtSlot, pyqtSignal
import logging


class QSubProcess(QObject):
    """Class to handle starting, running, and ending PyQt QProcess."""

    subprocess_finished_signal = pyqtSignal(int)

    def __init__(self, parent, tool):
        """Class constructor.

        Args:
            parent (TitanUI): Instance of Main UI class.
            tool (Tool): Tool to run in sub-process.
        """
        super().__init__()
        self._parent = parent
        self._running_tool = tool
        self._process_failed = False
        self._process = QProcess()

    # noinspection PyUnresolvedReferences, PyArgumentList
    def start_process(self, command):
        """Start the execution of a tool in a QProcess.
        
        Args:
            command: Run command
        """
        self._parent.add_msg_signal.emit("<%s>" % command, 0)
        self._process.started.connect(self.process_started)
        self._process.readyReadStandardOutput.connect(self.on_ready_stdout)
        self._process.readyReadStandardError.connect(self.on_ready_stderr)
        self._process.finished.connect(self.process_finished)
        self._process.error.connect(self.on_process_error)
        self._process.start(command)
        if not self._process.waitForStarted(msecs=10000):
            self._process_failed = True
            self._parent.add_err_msg_signal.emit('*** Launching sub-process failed. ***')

    @pyqtSlot()
    def process_started(self):
        """ Run when sub-process is started. """
        self._parent.add_msg_signal.emit('*** Sub-process for tool <%s> started ***'
                                         % self._running_tool.name, 0)
        self._parent.add_msg_signal.emit('Process pid: %d ' % self._process.processId(), 0)

    @pyqtSlot()
    def process_finished(self):
        """ Run when sub-process is finished. """
        self._parent.add_msg_signal.emit('*** Sub-process finished ***', 0)
        out = str(self._process.readAllStandardOutput(), 'utf-8')
        if out is not None:
            self._parent.add_proc_msg_signal.emit(out.strip())
        # Get GAMS exit status (Normal or crash)
        gams_exit_status = self._process.exitStatus()
        # Get GAMS exit code (return code)
        gams_exit_code = self._process.exitCode()
        # Delete GAMS QProcess
        self._process.deleteLater()
        self._process = None
        self._parent.add_msg_signal.emit("GAMS return code:{0} & Sub-process exit status:{1}"
                                         .format(gams_exit_code, gams_exit_status), 0)
        self.subprocess_finished_signal.emit(gams_exit_code)

    @pyqtSlot(int)
    def on_process_error(self, process_error):
        logging.error("Error in QProcess: %s" % process_error)
        self._parent.add_err_msg_signal.emit('Process State: %d' % self._process.state())
        self._parent.add_err_msg_signal.emit('Process Error: %d' % self._process.error())

    @pyqtSlot()
    def on_ready_stdout(self):
        """ Prints sub-process' stdout. """
        out = str(self._process.readAllStandardOutput(), 'utf-8')
        self._parent.add_proc_msg_signal.emit(out.strip())

    @pyqtSlot()
    def on_ready_stderr(self):
        """ Prints sub-process' stderr """
        out = str(self._process.readAllStandardError(), 'utf-8')
        self._parent.add_proc_err_msg_signal.emit(out.strip())
