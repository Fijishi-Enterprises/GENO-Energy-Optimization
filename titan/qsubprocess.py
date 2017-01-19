"""
Module to handle running tools in a QProcess.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   27.1.2016
"""

from PyQt5.QtCore import QObject, QProcess, pyqtSlot, pyqtSignal
import logging


class QSubProcess(QObject):
    """Class to handle starting, running, and finishing PyQt5 QProcesses."""

    subprocess_finished_signal = pyqtSignal(int, name='subprocess_finished_signal')

    def __init__(self, ui, tool):
        """Class constructor.

        Args:
            ui (TitanUI): Instance of Main UI class.
            tool (Tool): Tool to run in sub-process.
        """
        super().__init__()
        self._ui = ui
        self._running_tool = tool
        self._process_failed = False
        self._user_stopped = False
        self._process = QProcess(self)

    # noinspection PyUnresolvedReferences
    def start_process(self, command):
        """Start the execution of a tool in a QProcess.

        Args:
            command: Run command
        """
        self._ui.add_msg_signal.emit("Command: <i>{0}</i>".format(command), 0)
        self._process.started.connect(self.process_started)
        self._process.readyReadStandardOutput.connect(self.on_ready_stdout)
        self._process.readyReadStandardError.connect(self.on_ready_stderr)
        self._process.finished.connect(self.process_finished)
        self._process.error.connect(self.on_process_error)  # errorOccurred available in Qt 5.6
        self._process.stateChanged.connect(self.on_state_changed)
        self._process.start(command)
        if not self._process.waitForStarted(msecs=10000):
            # TODO: Do something if process fails to start
            self._process_failed = True
            self._ui.add_msg_signal.emit('*** Launching subprocess failed ***', 2)

    @pyqtSlot(name='process_started')
    def process_started(self):
        """Run when subprocess has started."""
        self._ui.add_msg_signal.emit("*** Subprocess for Tool <b>{0}</b> started ***"
                                     .format(self._running_tool.name), 0)

    @pyqtSlot('QProcess::ProcessState', name='on_state_changed')
    def on_state_changed(self, new_state):
        """Runs when QProcess state changes.

        Args:
            new_state (QProcess::ProcessState): Process state number
        """
        logging.debug("stateChanged: QProcess state is now {0}".format(new_state))

    @pyqtSlot('QProcess::ProcessError', name='on_process_error')
    def on_process_error(self, process_error):
        """Run if there is an error in the running QProcess.

        Args:
            process_error (QProcess::ProcessError): Process error number
        """
        logging.debug("errorOccurred {0}: QProcess state is now {1}".format(process_error, self._process.state()))

    def terminate_process(self):
        """Shutdown simulation in a QProcess."""
        # self._ui.add_msg_signal.emit("<br/>Stopping GAMS process nr. {0}".format(self._process.processId()), 0)
        logging.debug("Terminating QProcess nr.{0}. ProcessState:{1} and ProcessError:{2}"
                      .format(self._process.processId(), self._process.state(), self._process.error()))
        self._user_stopped = True
        try:
            self._process.close()
        except Exception as ex:
            logging.exception("Exception in closing QProcess: {}".format(ex))

    @pyqtSlot(name='process_finished')
    def process_finished(self):
        """Run when subprocess has finished."""
        if not self._user_stopped:
            out = str(self._process.readAllStandardOutput(), 'utf-8')
            if out is not None:
                self._ui.add_proc_msg_signal.emit(out.strip())
            # Get GAMS exit status (Normal or crash)
            gams_exit_status = self._process.exitStatus()
            # Get GAMS exit code (return code)
            gams_exit_code = self._process.exitCode()
            # Delete GAMS QProcess
            self._process.deleteLater()
            self._process = None
            self._ui.add_msg_signal.emit("*** Subprocess finished -- Exit status: {0} ***".format(gams_exit_status), 0)
            self.subprocess_finished_signal.emit(gams_exit_code)
        else:
            # Get GAMS exit code (return code)
            gams_exit_code = self._process.exitCode()
            # Delete QProcess
            self._process.deleteLater()
            self._process = None
            self._ui.add_msg_signal.emit("*** Stopping subprocess ***", 0)
            self.subprocess_finished_signal.emit(gams_exit_code)

    @pyqtSlot(name='on_ready_stdout')
    def on_ready_stdout(self):
        """Print subprocess stdout."""
        out = str(self._process.readAllStandardOutput(), 'utf-8')
        self._ui.add_proc_msg_signal.emit(out.strip())

    @pyqtSlot(name='on_ready_stderr')
    def on_ready_stderr(self):
        """Print subprocess stderr."""
        out = str(self._process.readAllStandardError(), 'utf-8')
        self._ui.add_proc_err_msg_signal.emit(out.strip())
