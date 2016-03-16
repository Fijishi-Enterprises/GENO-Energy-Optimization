"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
from PyQt5.QtCore import pyqtSignal, pyqtSlot, QProcess
from PyQt5.QtWidgets import QMainWindow, QApplication
from ui.main import Ui_MainWindow
from tool import Dimension, DataParameter, Setup, NewSetup
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE, OldGAMSModel
from config import ERROR_TEXT_COLOR, MAGIC_MODEL_PATH


class TitanUI(QMainWindow):
    """Class for application main GUI functions."""

    # Custom PyQt signals
    add_msg_signal = pyqtSignal(str)
    add_err_msg_signal = pyqtSignal(str)
    add_proc_msg_signal = pyqtSignal(str)
    add_proc_err_msg_signal = pyqtSignal(str)

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
        self._tools = dict()
        self._models = dict()
        self._setups = dict()
        # Setup general stuff
        self.create_model()
        self.connect_signals()

    @pyqtSlot()
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
        self.ui.pushButton_run_setup1.clicked.connect(self.run_setup)
        self.ui.pushButton_run_setup2.clicked.connect(self.model_run)
        self.ui.pushButton_create_models.clicked.connect(self.create_model)
        self.ui.pushButton_test.clicked.connect(self.test_button)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)

    def run_setup(self):
        """Create models and setup."""
        # Create model
        self._models['magic'] = OldGAMSModel(self, 'M A G I C   Power Scheduling Problem',
                                          """A number of power stations are committed to meet demand
                                          for a particular day. Three types of generators having
                                          different operating characteristics are available. Generating
                                          units can be shut down or operate between minimum and maximum
                                          output levels. Units can be started up or closed down in
                                          every demand block.""",
                                          MAGIC_MODEL_PATH, 'magic.gms', input_dir='input', output_dir='output')
        # Add input&output formats for model
        self._models['magic'].add_input_format(GDX_DATA_FMT)
        self._models['magic'].add_input_format(GAMS_INC_FILE)
        self._models['magic'].add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameter for model
        self._models['magic'].add_input(data)
        # Create Base Setup
        self._setups['base'] = NewSetup('base', 'The base setup')
        # Create Setup A, with Base setup as parent
        self._setups['setup A'] = NewSetup('setup A', 'test setup A', parent=self._setups['base'])
        # Add model 'magic' to setup 'Setup A'
        if not self._setups['setup A'].add_model(self._models['magic'], 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding a model to 'setup A' failed\n")
            logging.error("Adding a model to Setup failed")
            return
        # Execute Setup.
        self.add_msg_signal.emit("Starting setup A")
        self._setups['setup A'].execute()

    @pyqtSlot(str)
    def add_msg(self, msg):
        """Writes given message to main textBrowser.

        Args:
            msg (str): String written to TextBrowser
        """
        self.ui.textBrowser_main.append(msg)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str)
    def add_err_msg(self, message):
        """Writes given error message to main textBrowser with error text color.

        Args:
            message: The error message to be written.
        """
        old_color = self.ui.textBrowser_main.textColor()
        self.ui.textBrowser_main.setTextColor(ERROR_TEXT_COLOR)
        self.ui.textBrowser_main.append(message)
        self.ui.textBrowser_main.setTextColor(old_color)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str)
    def add_proc_msg(self, msg):
        """Writes given message to process output textBrowser.

        Args:
            msg (str): String written to TextBrowser
        """
        self.ui.textBrowser_process_output.append(msg)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str)
    def add_proc_err_msg(self, msg):
        """Writes given message to main textBrowser.

        Args:
            msg (str): String written to TextBrowser
        """
        self.ui.textBrowser_main.append(msg)
        # noinspection PyArgumentList
        QApplication.processEvents()

    def create_model(self):
        """Create and set up configuration for the model."""

        self._tools['magic'] = GAMSModel(self, 'MAGIC',
                     """M A G I C   Power Scheduling Problem
A number of power stations are committed to meet demand for a particular
day. three types of generators having different operating characteristics
are available.  Generating units can be shut down or operate between
minimum and maximum output levels.  Units can be started up or closed down
in every demand block.""",
                    MAGIC_MODEL_PATH, 'magic.gms',
                    input_dir='input', output_dir='output')

        self._tools['magic'].add_input_format(GDX_DATA_FMT)
        self._tools['magic'].add_input_format(GAMS_INC_FILE)
        self._tools['magic'].add_output_format(GDX_DATA_FMT)

        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])

        self._tools['magic'].add_input(data)
        self._tools['magic'].add_output(data)

        self._setups['invest'] = Setup('invest', 'Do investements')
        self._setups['invest'].add_input(self._tools['magic'])
        self._setups['invest'].add_tool(self._tools['magic'],
                                        cmdline_args='--INVEST=yes --USE_MIP=yes')

        self._setups['MIP'] = Setup('MIP', 'Operation with MIP model',
                                    parent=self._setups['invest'])
        self._setups['MIP'].add_input(self._tools['magic'])
        self._setups['MIP'].add_tool(self._tools['magic'],
                                      cmdline_args='--USE_MIP=yes')

        self._setups['LP'] = Setup('MIP', 'Operation with LP model ',
                                    parent=self._setups['invest'])
        self._setups['LP'].add_tool(self._tools['magic'],
                                      cmdline_args='--USE_MIP=no')

    def model_run(self):
        """Start running test model."""
        self.add_msg_signal.emit("Running setup 'MIP'")
        self.running_process = 'MIP'

        self.processes['MIP'] = QProcess()
        self.processes['MIP'].started.connect(self.magic_started)
        self.processes['MIP'].readyReadStandardOutput.connect(self.on_ready_stdout)
        self.processes['MIP'].readyReadStandardError.connect(self.on_ready_stderr)
        self.processes['MIP'].finished.connect(self.magic_finished)
        self._setups['MIP'].execute()
        if not self.processes['MIP'].waitForStarted(msecs=10000):
            self._simulation_failed = True
            self.add_err_msg_signal.emit(
                '*** Launching model failed. ***\nCheck that gams is '
                'included in the PATH variable.')

    def magic_started(self):
        """ Run when sub-process is started. """
        self.add_msg_signal.emit('*** Model sub-process started ***')
        self.add_msg_signal.emit('Process pid: %d' % self.processes['MIP'].pid())

    def magic_finished(self):
        """ Run when sub-process is finished. """
        out = str(self.processes['MIP'].readAllStandardOutput(), 'utf-8')
        if out is not None:
            self.add_proc_msg_signal.emit(out.strip())
        # Get GAMS exit status (Normal or crash)
        gams_exit_status = self.processes['MIP'].exitStatus()
        # Get GAMS exit code (return code)
        gams_exit_code = self.processes['MIP'].exitCode()
        # Delete GAMS QProcess
        self.processes['MIP'].deleteLater()
        self.processes['MIP'] = None
        self.running_process = ''
        self.add_msg_signal.emit("GAMS exit status:%s" % gams_exit_status)
        #try:
        #    gams_return_msg = GAMS_RETURN_CODES[gams_exit_code]
        #except KeyError:
        #    gams_return_msg = "Unknown return message from GAMS"
        #self.add_msg_signal.emit("GAMS exit code:%s (%s)" % (gams_exit_code, gams_return_msg))
        # noinspection PyArgumentList
        QApplication.processEvents()

    def test_button(self):
        logging.debug("test")
        self.add_msg_signal.emit("teste")
        logging.debug("test2")

    def closeEvent(self, event=None):
        """Method for handling application exit.

        Args:
             event (QEvent): PyQt event
        """

        # Remove working files
        for _, setup in self._setups.items():
            setup.cleanup()
        logging.debug("Thank you for choosing Titan. Bye bye.")
        # noinspection PyArgumentList
        QApplication.quit()
