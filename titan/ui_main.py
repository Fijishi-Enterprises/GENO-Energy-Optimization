"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
from PyQt5.QtCore import pyqtSignal, pyqtSlot
from PyQt5.QtWidgets import QMainWindow, QApplication
from ui.main import Ui_MainWindow
from tool import Dimension, DataParameter, Setup, SetupTree
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE
from config import ERROR_TEXT_COLOR, MAGIC_MODEL_PATH, OLD_MAGIC_MODEL_PATH


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
        self._setups = dict()
        self.setup_tree = None
        # Initialize general things
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
        self.ui.pushButton_run_setup1.clicked.connect(self.run_setups_with_old_magic_tool)
        self.ui.pushButton_run_setup2.clicked.connect(self.run_setups_invest_mip_lp)
        self.ui.pushButton_create_models.clicked.connect(self.create_setups_for_invest_mip_lp)
        self.ui.pushButton_test.clicked.connect(self.test_button)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)

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

    def run_setups_with_old_magic_tool(self):
        """Create models and setup."""
        # Create model
        self._tools['magic'] = GAMSModel(self, 'OLD MAGIC',
                                         """A number of power stations are committed to meet demand
                                         for a particular day. Three types of generators having
                                         different operating characteristics are available. Generating
                                         units can be shut down or operate between minimum and maximum
                                         output levels. Units can be started up or closed down in
                                         every demand block.""",
                                         OLD_MAGIC_MODEL_PATH, 'magic.gms',
                                         input_dir='input', output_dir='output')
        # Add input&output formats for model
        self._tools['magic'].add_input_format(GDX_DATA_FMT)
        self._tools['magic'].add_input_format(GAMS_INC_FILE)
        self._tools['magic'].add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameter for model
        self._tools['magic'].add_input(data)
        # Create Base Setup
        self._setups['base'] = Setup('base', 'The base setup')
        # Create Setup A, with Base setup as parent
        self._setups['setup A'] = Setup('setup A', 'test setup A', parent=self._setups['base'])
        # Add model 'magic' to setup 'Setup A'
        if not self._setups['setup A'].add_tool(self._tools['magic'], 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding a tool to 'setup A' failed\n")
            logging.error("Adding a model to Setup failed")
            return
        # Create a SetupTree for this run
        self.setup_tree = SetupTree('Setup Tree', 'SetupTree to run Setup A and base setups', self._setups['setup A'])
        # Execute SetupTree
        self.add_msg_signal.emit("Executing Setup Tree\n{0}".format(self.setup_tree.setup_dict))
        self.add_msg_signal.emit("setup A object:%s" % self._setups['setup A'])
        self.add_msg_signal.emit("base setup object:%s" % self._setups['base'])
        # Connect signal between Setup and SetupTree classes
        self._setups['setup A'].setup_finished_signal.connect(self.setup_tree.execute_next)
        self._setups['base'].setup_finished_signal.connect(self.setup_tree.execute_next)
        self.setup_tree.execute_next()

        # Get first executed setup
        # setup_to_execute = self.setup_tree.get_next_setup()
        # while setup_to_execute is not None:
        #     setup_to_execute.execute()
        #     setup_to_execute = self.setup_tree.get_next_setup()

        # Execute setup
        # self._setups['setup A'].execute()

    def cleanup(self):
        self._tools = None
        self._setups = None

    def create_setups_for_invest_mip_lp(self):
        """Create tool and invest, MIP and LP setups."""
        self._tools['magic'] = GAMSModel(self, 'MAGIC',
                                         """M A G I C   Power Scheduling Problem
                                         A number of power stations are committed
                                         to meet demand for a particular day. three
                                         types of generators having different
                                         operating characteristics are available.
                                         Generating units can be shut down or operate
                                         between minimum and maximum output levels.
                                         Units can be started up or closed down in
                                         every demand block.""",
                                         MAGIC_MODEL_PATH, 'magic.gms', input_dir='input',
                                         output_dir='output')

        self._tools['magic'].add_input_format(GDX_DATA_FMT)
        self._tools['magic'].add_input_format(GAMS_INC_FILE)
        self._tools['magic'].add_output_format(GDX_DATA_FMT)

        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])

        self._tools['magic'].add_input(data)
        self._tools['magic'].add_output(data)

        self._setups['invest'] = Setup('invest', 'Do investments')
        self._setups['invest'].add_input(self._tools['magic'])
        self._setups['invest'].add_tool(self._tools['magic'],
                                        cmdline_args='--INVEST=yes --USE_MIP=yes')

        self._setups['MIP'] = Setup('MIP', 'Operation with MIP model',
                                    parent=self._setups['invest'])
        self._setups['MIP'].add_input(self._tools['magic'])
        self._setups['MIP'].add_tool(self._tools['magic'],
                                     cmdline_args='--USE_MIP=yes')

        self._setups['LP'] = Setup('LP', 'Operation with LP model ',
                                   parent=self._setups['invest'])
        # self._setups['LP'] = Setup('LP', 'Operation with LP model ',
        #                            parent=self._setups['invest'])
        self._setups['LP'].add_tool(self._tools['magic'],
                                    cmdline_args='--USE_MIP=no')

    def run_setups_invest_mip_lp(self):
        """Start running setups invest, MIP and LP."""
        if not self._setups:
            self.add_msg_signal.emit("No setups to run.")
            return
        self.add_msg_signal.emit("Running Setups 'invest', 'MIP', and 'LP'")
        # self._setups['MIP'].execute()
        # self._setups['LP'].execute()

        # Create a SetupTree for this run
        self.setup_tree = SetupTree('Setup Tree', "SetupTree to run 'invest' and 'MIP' setups", self._setups['MIP'])
        # Execute SetupTree
        self.add_msg_signal.emit("Executing Setup Tree\n{0}".format(self.setup_tree.setup_dict))
        self.add_msg_signal.emit("invest setup object:%s" % self._setups['invest'])
        self.add_msg_signal.emit("MIP setup object:%s" % self._setups['MIP'])
        # Connect signal between Setup and SetupTree classes
        self._setups['invest'].setup_finished_signal.connect(self.setup_tree.execute_next)
        self._setups['MIP'].setup_finished_signal.connect(self.setup_tree.execute_next)
        # Get first executed setup
        self.setup_tree.execute_next()

        # Restore initial state
        # TODO: Clean up models and setups after execute somehow.
        # self.cleanup()

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
