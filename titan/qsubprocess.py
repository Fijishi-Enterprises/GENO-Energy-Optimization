"""
Module to handle running setups in a QProcess.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   27.1.2016
"""

from PyQt5.QtCore import QProcess
import logging


class QSubProcess:
    """Class to handle starting, running, and ending PyQt QProcess."""
    def __init__(self, parent, setup):
        """Class constructor.

        Args:
            parent (TitanUI): Instance of Main UI class.
            setup (Setup): running setup.
        """
        self._parent = parent
        self._running_setup = setup
        self._process_failed = False
        self._process = QProcess()

    # noinspection PyUnresolvedReferences, PyArgumentList
    def start_process(self, command):
        """Start the execution of a model in a QProcess.
        
        Args:
            command: Run command
        """
        self._parent.add_msg_signal.emit("<%s>" % command)
        self._process.started.connect(self.process_started)
        self._process.readyReadStandardOutput.connect(self.on_ready_stdout)
        self._process.readyReadStandardError.connect(self.on_ready_stderr)
        self._process.finished.connect(self.process_finished)
        self._process.start(command)
        if not self._process.waitForStarted(msecs=10000):
            self._process_failed = True
            self._parent.add_err_msg_signal.emit('*** Launching sub-process failed. ***')

    def process_started(self):
        """ Run when sub-process is started. """
        self._parent.add_msg_signal.emit('*** Running setup <%s> in sub-process started ***' % self._running_setup.name)
        self._parent.add_msg_signal.emit('Process pid: %d' % self._process.processId())

    def process_finished(self):
        """ Run when sub-process is finished. """
        self._parent.add_msg_signal.emit('*** Setup process finished ***')
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
        self._parent.add_msg_signal.emit("GAMS exit status:%s" % gams_exit_status)
        return_codes = self._running_setup.running_model.return_codes
        try:
            gams_return_msg = return_codes[gams_exit_code]
        except KeyError:
            gams_return_msg = "Unknown return message from GAMS"
        self._parent.add_msg_signal.emit("GAMS exit code:%s (%s)" % (gams_exit_code, gams_return_msg))
        self._running_setup.model_finished(gams_exit_code)

    def on_ready_stdout(self):
        """ Prints sub-process' stdout. """
        out = str(self._process.readAllStandardOutput(), 'utf-8')
        self._parent.add_proc_msg_signal.emit(out.strip())

    def on_ready_stderr(self):
        """ Prints sub-process' stderr """
        out = str(self._process.readAllStandardError(), 'utf-8')
        self._parent.add_proc_err_msg_signal.emit(out.strip())
