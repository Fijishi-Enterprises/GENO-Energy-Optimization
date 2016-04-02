"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
from PyQt5.QtCore import pyqtSignal, pyqtSlot, QModelIndex
from PyQt5.QtWidgets import QMainWindow, QApplication
from ui.main import Ui_MainWindow
from project import SceletonProject
from models import SetupModel, SetupTreeListModel
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
        self._running_setup = None
        self._setuptree_list = list()  # Used to store multiple SetupTrees (branches)
        self._root = None  # Root node for Setup Graph Model
        # self.model_listview = None
        self.setuptree_model = None
        self.setup_model = None
        self.tool_model = None
        self.setupmodel = None
        # Initialize general things
        self.connect_signals()
        self.init_views()

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
        self.ui.pushButton_execute.clicked.connect(self.run_selected_setup)
        self.ui.pushButton_dummy1.clicked.connect(self.test_setupmodel)
        self.ui.pushButton_add.clicked.connect(self.get_selected_setup)
        self.ui.pushButton_clear_listview.clicked.connect(self.remove_selected_setup)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)
        self.ui.listView_setuptrees.pressed.connect(self.dummy1_button)
        self.ui.treeView_setups.pressed.connect(self.get_clicked_setup)

    def init_views(self):
        """Create data models for GUI views."""
        self.setuptree_model = SetupTreeListModel()
        self.setup_model = SetupTreeListModel()
        self.tool_model = SetupTreeListModel()
        # Make root for SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        self.setupmodel = SetupModel(self._root)
        # Set model into treeView
        self.ui.treeView_setups.setModel(self.setupmodel)
        self.ui.listView_setuptrees.setModel(self.setuptree_model)
        self.ui.listView_setups.setModel(self.setup_model)
        self.ui.listView_tools.setModel(self.tool_model)
        # self.model_listview = QStandardItemModel(self.ui.listView_setuptreelist)

    def remove_selected_setup(self):
        """Removes selected Setup (and all of it's children) from SetupModel."""
        setup = self.get_selected_setup()
        if not setup:
            self.add_msg_signal.emit("No Setup selected")
            return
        self.add_msg_signal.emit("Removing Setup '%s' (NA)" % setup.name)
        # TODO: Implement removeRows() in SetupModel

    def create_setuptree_for_base_setup_a(self):
        """Create two Setups ('base' and 'setup a') and associate tool Magic with Setup A."""
        # Create tool
        self._tools['magic'] = GAMSModel(self, 'OLD MAGIC',
                                         """A number of power stations are committed to meet demand
                                         for a particular day. Three types of generators having
                                         different operating characteristics are available. Generating
                                         units can be shut down or operate between minimum and maximum
                                         output levels. Units can be started up or closed down in
                                         every demand block.""",
                                         OLD_MAGIC_MODEL_PATH, 'magic.gms',
                                         input_dir='input', output_dir='output')
        # Add input&output formats for tool
        self._tools['magic'].add_input_format(GDX_DATA_FMT)
        self._tools['magic'].add_input_format(GAMS_INC_FILE)
        self._tools['magic'].add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameter for tool
        self._tools['magic'].add_input(data)
        # Create Base Setup
        self._setups['base'] = Setup('base', 'The base setup', 
                                     project=self._project, parent=self._root)
        # Create Setup A, with Base setup as parent
        self._setups['setup A'] = Setup('setup A', 'test setup A',
                                        project=self._project,
                                        parent=self._setups['base'])
        self._setups['setup B'] = Setup('setup B', 'test setup B',
                                        project=self._project,
                                        parent=self._setups['base'])
        self._setups['setup C'] = Setup('setup C', 'test setup C',
                                        project=self._project,
                                        parent=self._setups['setup A'])
        # Add tool 'magic' to setup 'Setup A'
        if not self._setups['setup A'].add_tool(self._tools['magic'], 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding a tool to 'setup A' failed\n")
            logging.error("Adding a model to Setup failed")
            return
        self.add_msg_signal.emit("Building SetupTree A")
        # Create a SetupTree starting from Setup A
        self._setuptree = SetupTree('Setup Tree A', 'SetupTree to run Setup A and base setups', self._setups['setup A'])
        self._setuptree_list.append(self._setuptree)
        # Add data into PyQt models
        self.setup_model.add_data(self._setups['base'])
        self.setup_model.add_data(self._setups['setup A'])
        self.tool_model.add_data(self._tools['magic'])
        self.setuptree_model.add_data(self._setuptree)
        root_print = self._root.log()
        logging.debug("root print:\n%s" % root_print)

    def test_setupmodel(self):
        # Create tool
        self._tools['magic'] = GAMSModel(self, 'OLD MAGIC',
                                         """A number of power stations are committed to meet demand
                                         for a particular day. Three types of generators having
                                         different operating characteristics are available. Generating
                                         units can be shut down or operate between minimum and maximum
                                         output levels. Units can be started up or closed down in
                                         every demand block.""",
                                         OLD_MAGIC_MODEL_PATH, 'magic.gms',
                                         input_dir='input', output_dir='output')
        # Add input&output formats for tool
        self._tools['magic'].add_input_format(GDX_DATA_FMT)
        self._tools['magic'].add_input_format(GAMS_INC_FILE)
        self._tools['magic'].add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameter for tool
        self._tools['magic'].add_input(data)
        # ----------------- Adding a Setup to data model -------------------:
        # Option 1: Create Setup with the wanted parent
        # Option 2: Create Setup with no parent and use insert_child() to associate Setup to model
        # Add Base Setup
        if not self.setupmodel.insert_setup('BASE', 'The base setup', self._project, 0):
            logging.error("Adding Base to model failed")
            return
        # Add A
        base_index = self.setupmodel.index(0, 0, QModelIndex())
        if not self.setupmodel.insert_setup('A', 'Setup A', self._project, 0, base_index):
            logging.error("Adding A to model failed")
            return
        # Add B
        base_index = self.setupmodel.index(0, 0, QModelIndex())
        if not self.setupmodel.insert_setup('B', 'Setup B', self._project, 0, base_index):
            logging.error("Adding B to model failed")
            return
        # Add C
        a_index = self.setupmodel.index(1, 0, base_index)  # A is on second row because B is now on first row
        if not self.setupmodel.insert_setup('C', 'Setup C', self._project, 0, a_index):
            logging.error("Adding C to model failed")
            return
        # Add another Base
        if not self.setupmodel.insert_setup('BASE 2', 'Another base setup', self._project, 0):
            logging.error("Adding Base to model failed")
            return
        # Add tool 'magic' to setup 'A'
        a_ind = self.setupmodel.index(1, 0, base_index)
        a = self.setupmodel.get_setup(a_ind)
        if not a.add_tool(self._tools['magic'], 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding 'magic' tool to 'A' failed\n")
            logging.error("Adding a model to Setup failed")
            return

    def run_selected_setup(self):
        """Start executing selected Setup and all it's parents."""
        # Get selected Setup from QTreeView
        self._running_setup = self.get_selected_setup()
        if not self._running_setup:
            self.add_msg_signal.emit("Select a Setup and try again.\n")
            return
        # Connect setup_finished_signal to some slot in this class
        self._running_setup.setup_finished_signal.connect(self.setup_finished)
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("\nStarting Setup '%s'" % self._running_setup.name)
        self._running_setup.execute()

    @pyqtSlot()
    def setup_finished(self):
        """Start executing finished Setup's parent or end run if all Setup are ready."""
        logging.debug("Setup <{0}> ready".format(self._running_setup.name))
        self.add_msg_signal.emit("Setup '%s' ready" % self._running_setup.name)
        # Emit dataChanged signal to QtreeView because is_ready is now updated.
        self.setupmodel.emit_data_changed()
        # Disconnect signal to make sure it is not connected to multiple Setups
        try:
            self._running_setup.setup_finished_signal.disconnect()
        except TypeError:  # Just in case
            # logging.warning("setup_finished_signal not connected")
            pass
        self._running_setup = self._running_setup.parent()
        if self._running_setup.is_root:
            logging.debug("All Setups ready")
            self.add_msg_signal.emit("All Setups ready")
            self._running_setup = None
            return
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("Starting Setup '%s'" % self._running_setup.name)
        # Connect setup_finished_signal to this same slot
        self._running_setup.setup_finished_signal.connect(self.setup_finished)
        self._running_setup.execute()

    @pyqtSlot()
    def get_selected_setup(self):
        """Get selected Setup in the Setup QTreeView.

        Returns:
            Setup pointed by the selected item or None if something went wrong.
        """
        try:
            index = self.ui.treeView_setups.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return None
        if not index.isValid():
            return None
        row = index.row()
        column = index.column()
        setup = index.internalPointer()
        self.add_msg_signal.emit("Pressed item row:%s column:%s setup name:%s" % (row, column, setup.name))
        return setup

    def create_setuptree_for_invest_mip(self):
        """Create 'invest' and 'MIP' setups."""
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
                                       project=self._project, parent=self._root)
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
        self.add_msg_signal.emit("Building SetupTree MIP")
        self._setuptree = SetupTree('Setup Tree MIP', "SetupTree to run 'invest' and 'MIP' setups", self._setups['MIP'])
        self.setuptree_model.add_data(self._setuptree)
        self._setuptree_list.append(self._setuptree)

    def create_two_setuptrees(self):
        """Creates 'invest' -> 'LP' branch and 'invest' -> MIP branches
         and puts them into a SetupTree List."""
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
                                       project=self._project, parent=self._root)
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
        self.add_msg_signal.emit("Building SetupTree LP")
        setuptree_lp = SetupTree('Setup Tree LP', "SetupTree to run 'invest' and 'LP' setups", self._setups['LP'])
        self.add_msg_signal.emit("Building SetupTree MIP")
        setuptree_mip = SetupTree('Setup Tree MIP', "SetupTree to run 'invest' and 'LP' setups", self._setups['MIP'])
        self.setuptree_model.add_data(setuptree_lp)
        self.setuptree_model.add_data(setuptree_mip)
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

    @pyqtSlot("QModelIndex")
    def dummy1_button(self, index):
        if not index.isValid():
            return
        row = index.row()
        self.add_msg_signal.emit("Selected item row %s" % row)
        logging.debug("clicked index:%s" % index)
        # item = self.ui.listView_setuptreelist.model().itemFromIndex(index)
        # d = item.data(Qt.UserRole)
        # logging.debug("item data:%s" % d)
        # try:
        #     data = self.ui.listView_setuptreelist.model().itemData(index)
        # except Exception as e:
        #     self.add_msg_signal.emit("teste: %s." % e.args[0])
        logging.debug("test2")

    def add_item(self):

        # Adding a Setup to model:
        # Option 1: Create Setup with the wanted parent
        # Option 2: Create Setup with no parent and use insert_child() to associate Setup to model
        setup_a_index = self.setupmodel.index(0, 0, QModelIndex())
        retval = self.setupmodel.insert_setup('setup D', 'test setup D', self._project, 0, setup_a_index)
        if not retval:
            logging.error("Adding Setup to model failed")
            return
        logging.debug("Setup added successfully")

    @pyqtSlot("QModelIndex")
    def get_clicked_setup(self, index):
        """Test method.

        Args:
            index (QModelIndex): Index of the selected item.

        Returns:
            Nothing.
        """
        if not index.isValid():
            return
        row = index.row()
        column = index.column()
        setup = index.internalPointer()
        # self.add_msg_signal.emit("Pressed item row:%s column:%s setup name:%s" % (row, column, setup.name))
        logging.debug("Pressed item row:%s column:%s setup name:%s" % (row, column, setup.name))

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
