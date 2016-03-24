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
from project import SceletonProject
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
        self._project = SceletonProject('project 1', 'a test project')
        self._setups = dict()
        self._setuptree = None
        self._running_setuptree = None
        self._setuptree_list = list()  # Used to store multiple SetupTrees (branches)
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
        self.ui.pushButton_create_setuptree_1.clicked.connect(self.create_setuptree_for_base_setup_a)
        self.ui.pushButton_create_setuptree_2.clicked.connect(self.create_setuptree_for_invest_mip)
        self.ui.pushButton_create_setuptree_3.clicked.connect(self.create_two_setuptrees)
        self.ui.pushButton_execute.clicked.connect(self.execute_all)
        self.ui.pushButton_dummy1.clicked.connect(self.dummy1_button)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)

    def create_setuptree_for_base_setup_a(self):
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
        self._setups['base'] = Setup('base', 'The base setup', 
                                     project=self._project)
        # Create Setup A, with Base setup as parent
        self._setups['setup A'] = Setup('setup A', 'test setup A', 
                                        project=self._project,                                        
                                        parent=self._setups['base'])
        # Add model 'magic' to setup 'Setup A'
        if not self._setups['setup A'].add_tool(self._tools['magic'], 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding a tool to 'setup A' failed\n")
            logging.error("Adding a model to Setup failed")
            return
        self.add_msg_signal.emit("Building SetupTree")
        # Create a SetupTree starting from Setup A
        self._setuptree = SetupTree('Setup Tree A', 'SetupTree to run Setup A and base setups', self._setups['setup A'])
        self._setuptree_list.append(self._setuptree)

    def create_setuptree_for_invest_mip(self):
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

        self._setups['invest'] = Setup('invest', 'Do investments', 
                                       project=self._project)
        self._setups['invest'].add_input(self._tools['magic'])
        self._setups['invest'].add_tool(self._tools['magic'],
                                        cmdline_args='--INVEST=yes --USE_MIP=yes')
        self._setups['MIP'] = Setup('MIP', 'Operation with MIP model',
                                    project=self._project,
                                    parent=self._setups['invest'])
        self._setups['MIP'].add_input(self._tools['magic'])
        self._setups['MIP'].add_tool(self._tools['magic'],
                                     cmdline_args='--USE_MIP=yes')
        # Create a SetupTree for this run
        self._setuptree = SetupTree('Setup Tree MIP', "SetupTree to run 'invest' and 'MIP' setups", self._setups['MIP'])
        self._setuptree_list.append(self._setuptree)

    def create_two_setuptrees(self):
        """Creates 'invest' and 'LP' branch in SetupTree."""
        # TODO: Create two SetupTrees i.e. two branches.
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

        self._setups['invest'] = Setup('invest', 'Do investments',
                                       project=self._project)
        self._setups['invest'].add_input(self._tools['magic'])
        self._setups['invest'].add_tool(self._tools['magic'],
                                        cmdline_args='--INVEST=yes --USE_MIP=yes')
        self._setups['MIP'] = Setup('MIP', 'Operation with MIP model',
                                    project=self._project,
                                    parent=self._setups['invest'])
        self._setups['MIP'].add_input(self._tools['magic'])
        self._setups['MIP'].add_tool(self._tools['magic'],
                                     cmdline_args='--USE_MIP=yes')
        self._setups['LP'] = Setup('LP', 'Operation with LP model ',
                                   project=self._project,
                                   parent=self._setups['invest'])
        self._setups['LP'].add_tool(self._tools['magic'],
                                    cmdline_args='--USE_MIP=no')
        # Create a SetupTree for this run
        setuptree_lp = SetupTree('Setup Tree LP', "SetupTree to run 'invest' and 'LP' setups", self._setups['LP'])
        setuptree_mip = SetupTree('Setup Tree MIP', "SetupTree to run 'invest' and 'LP' setups", self._setups['MIP'])
        self._setuptree_list.append(setuptree_lp)
        self._setuptree_list.append(setuptree_mip)

    def execute_all(self):
        """Run all SetupTrees in setuptree_list."""
        if not self._setuptree_list:
            self.add_msg_signal.emit("No SetupTree List available")
            return
        self.add_msg_signal.emit("*** Starting simulation with {0} SetupTree(s) ***".format(len(self._setuptree_list)))
        # Get the first SetupTree from list and start it.
        # Note: Pop() without index returns the last item in the list.
        self._running_setuptree = self._setuptree_list.pop()
        self.add_msg_signal.emit("*** Executing SetupTree <{0}> with {1} Setups ***"
                                 .format(self._running_setuptree.name, self._running_setuptree.n))
        # Connect run finished signal between SetupTree and Titan_UI
        self._running_setuptree.setuptree_finished_signal.connect(self.execute_finished)
        self._running_setuptree.run()

    @pyqtSlot()
    def execute_finished(self):
        """Clean up after a SetupTree has finished."""
        logging.debug("SetupTree <{}> finished".format(self._running_setuptree.name))
        self._running_setuptree = None
        try:
            # Run the next SetupTree
            self._running_setuptree = self._setuptree_list.pop()
        except IndexError:
            self.add_msg_signal.emit("\n*** All SetupTrees finished. Cleaning up. ***\n")
            self._tools.clear()
            self._setups.clear()
            self._setuptree = None
            self._setuptree_list.clear()
            return
        logging.debug("Executing SetupTree <{}>".format(self._running_setuptree.name))
        self.add_msg_signal.emit("\n*** Executing SetupTree <{0}> with {1} Setups ***"
                                 .format(self._running_setuptree.name, self._running_setuptree.n))
        self._running_setuptree.setuptree_finished_signal.connect(self.execute_finished)
        self._running_setuptree.run()

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

    @pyqtSlot()
    def dummy1_button(self):
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
