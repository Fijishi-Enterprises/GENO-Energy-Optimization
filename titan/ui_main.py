"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
from PyQt5 import QtGui, QtCore, QtWidgets
from ui.main import Ui_MainWindow
from model import Dimension, DataParameter, Setup
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE
from config import ERROR_TEXT_COLOR, MAGIC_MODEL_PATH


class TitanUI(QtWidgets.QMainWindow):
    """Class for application main GUI functions."""

    # Custom PyQt signals
    add_msg_signal = QtCore.pyqtSignal(str)
    add_err_msg_signal = QtCore.pyqtSignal(str)
    add_proc_msg_signal = QtCore.pyqtSignal(str)
    add_proc_err_msg_signal = QtCore.pyqtSignal(str)

    def __init__(self):
        """ Initialize GUI """
        super().__init__()
        # Set number formatting to use user's default settings
        locale.setlocale(locale.LC_NUMERIC, '')
        # Setup the user interface from Qt Creator files
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        # Class variables
        self._simulation_failed = False
        self.processes = dict()
        self.running_process = ''
        self._models = dict()
        self._setups = dict()
        # Setup general stuff
        self.connect_signals()

    @QtCore.pyqtSlot()
    def set_debug_level(self):
        """Control application debug messages."""
        if self.sender().checkState():
            logging.getLogger().setLevel(level=logging.DEBUG)
        else:
            logging.getLogger().setLevel(level=logging.INFO)

    def connect_signals(self):
        """Connect PyQt signals."""
        # Custom signals
        self.add_msg_signal.connect(self.add_msg)
        self.add_err_msg_signal.connect(self.add_err_msg)
        self.add_proc_msg_signal.connect(self.add_proc_msg)
        self.add_proc_err_msg_signal.connect(self.add_proc_err_msg)
        # Menu actions
        self.ui.action_quit.triggered.connect(self.closeEvent)
        # Widgets
        self.ui.pushButton_start.clicked.connect(self.create_model)
        self.ui.pushButton_test.clicked.connect(self.test_button)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)

    @QtCore.pyqtSlot(str)
    def add_msg(self, msg):
        """Writes given message to main textBrowser.

        Args:
            msg (str): String written to TextBrowser
        """
        self.ui.textBrowser_main.append(msg)
        QtWidgets.QApplication.processEvents()

    @QtCore.pyqtSlot(str)
    def add_err_msg(self, message):
        """ Writes given error message to main textBrowser with error text color.

        Args:
            message: The error message to be written.
        """
        old_color = self.ui.textBrowser_main.textColor()
        self.ui.textBrowser_main.setTextColor(ERROR_TEXT_COLOR)
        self.ui.textBrowser_main.append(message)
        self.ui.textBrowser_main.setTextColor(old_color)
        QtWidgets.QApplication.processEvents()

    @QtCore.pyqtSlot(str)
    def add_proc_msg(self, msg):
        """Writes given message to process output textBrowser.

        Args:
            msg (str): String written to TextBrowser
        """
        self.ui.textBrowser_process_output.append(msg)
        QtWidgets.QApplication.processEvents()

    @QtCore.pyqtSlot(str)
    def add_proc_err_msg(self, msg):
        """Writes given message to main textBrowser.

        Args:
            msg (str): String written to TextBrowser
        """
        self.ui.textBrowser_main.append(msg)
        QtWidgets.QApplication.processEvents()

    def create_model(self):
        """Create and set up configuration for the model."""

        self._models['magic'] = GAMSModel('M A G I C   Power Scheduling Problem',
                     """A number of power stations are committed to meet demand for a particular
day. three types of generators having different operating characteristics
are available.  Generating units can be shut down or operate between
minimum and maximum output levels.  Units can be started up or closed down
in every demand block.""",
                      MAGIC_MODEL_PATH, input_dir='input', output_dir='output')

        self._models['magic'].add_input_format(GDX_DATA_FMT)
        self._models['magic'].add_input_format(GAMS_INC_FILE)
        self._models['magic'].add_output_format(GDX_DATA_FMT)

        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])

        self._models['magic'].add_input(data)

        self._setups['base'] = Setup('base', 'The base setup')

        self._setups['setup A'] = Setup('setup A', 'test setup A', 
                                        parent=self._setups['base'])
        self._setups['setup A'].add_model(self._models['magic'], 'MIP=CPLEX')
        
        self.model_run()

    def model_run(self):
        """Start running test model."""

        

        #command = '{} {}'.format(self._models['fuel_mdl'].command, self._configs['test_config'].cmd_line_arguments)
        # ret = run(command)
        self.add_msg_signal.emit("Running setup A")
        self.running_process = 'setup A'

        self.processes['setup A'] = QtCore.QProcess()
        self.processes['setup A'].started.connect(self.magic_started)
        self.processes['setup A'].readyReadStandardOutput.connect(self.on_ready_stdout)
        self.processes['setup A'].readyReadStandardError.connect(self.on_ready_stderr)
        self.processes['setup A'].finished.connect(self.magic_finished)
        #self.processes['setup A'].start(command)
        self._setups['setup A'].execute()
        if not self.processes['setup A'].waitForStarted(msecs=10000):
            self._simulation_failed = True
            self.add_err_msg_signal.emit(
                '*** Launching Fuel model failed. ***\nCheck that gams is '
                'included in the  PATH variable.')

    def magic_started(self):
        """ Run when sub-process is started. """
        self.add_msg_signal.emit('*** Fuel scheduling model sub-process started ***')
        self.add_msg_signal.emit('Process pid: %d' % self.processes['setup A'].pid())

    def magic_finished(self):
        """ Run when sub-process is finished. """
        out = str(self.processes['setup A'].readAllStandardOutput(), 'utf-8')
        if out is not None:
            self.add_proc_msg_signal.emit(out.strip())
        # Get GAMS exit status (Normal or crash)
        gams_exit_status = self.processes['setup A'].exitStatus()
        # Get GAMS exit code (return code)
        gams_exit_code = self.processes['setup A'].exitCode()
        # Delete GAMS QProcess
        self.processes['setup A'].deleteLater()
        self.processes['setup A'] = None
        self.running_process = ''
        self.add_msg_signal.emit("GAMS exit status:%s" % gams_exit_status)
        #try:
        #    gams_return_msg = GAMS_RETURN_CODES[gams_exit_code]
        #except KeyError:
        #    gams_return_msg = "Unknown return message from GAMS"
        self.add_msg_signal.emit("GAMS exit code:%s (%s)" % (gams_exit_code, gams_return_msg))
        #self._models['fuel_mdl'].copy_output(self._configs['test_config'].output_dir)

    def test_button(self):
        logging.debug("test")
        self.add_msg_signal.emit("teste")

    def closeEvent(self, event=None):
        """Method for handling application exit.

        Args:
             event: PyQt event
        """
        logging.debug("Thank you for choosing Titan. Bye bye.")
        QtWidgets.QApplication.quit()

    def on_ready_stdout(self):
        """ Prints sub-process' stdout. """
        out = str(self.processes[self.running_process].readAllStandardOutput(), 'utf-8')
        self.add_proc_msg_signal.emit(out.strip())

    def on_ready_stderr(self):
        """ Prints sub-process' stderr """
        out = str(self.processes[self.running_process].readAllStandardError(), 'utf-8')
        self.add_proc_err_msg_signal.emit(out.strip())
