"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
from PyQt5.QtCore import pyqtSignal, pyqtSlot, QModelIndex, Qt
from PyQt5.QtWidgets import QMainWindow, QApplication
from ui.main import Ui_MainWindow
from project import SceletonProject
from models import SetupModel, ToolProxyModel
from tool import Dimension, DataParameter, Setup
from tools import SetupTree
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE
from config import ERROR_TEXT_COLOR, MAGIC_MODEL_PATH, OLD_MAGIC_MODEL_PATH,\
                   MAGIC_INVESTMENTS_JSON, MAGIC_OPERATION_JSON
from widgets.setup_popup_widget import SetupPopupWidget
from widgets.context_menu_widget import ContextMenuWidget


class TitanUI(QMainWindow):
    """Class for application main GUI functions."""

    # Custom PyQt signals
    add_msg_signal = pyqtSignal(str)
    add_err_msg_signal = pyqtSignal(str)
    add_proc_msg_signal = pyqtSignal(str)
    add_proc_err_msg_signal = pyqtSignal(str)

    def __init__(self):
        """ Initialize GUI."""
        super().__init__()
        # Set number formatting to use user's default settings
        locale.setlocale(locale.LC_NUMERIC, '')
        # Setup the user interface from Qt Creator files
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        self.ui.treeView_setups.setContextMenuPolicy(Qt.CustomContextMenu)
        # Class variables
        self._project = SceletonProject('project 1', 'a test project')
        self._running_setup = None
        self._root = None  # Root node for SetupModel
        # self._base_index = None  # For Setup search algorithms. Moved to SetupModel class
        self.setup_model = None
        self.tool_proxy_model = None
        # Ref. for widgets
        self.setup_popup = None
        # Obsolete variables
        # self._simulation_failed = False  # Obsolete
        # self.processes = dict()  # Obsolete
        # self.running_process = ''  # Obsolete
        # self._tools = dict()  # Obsolete
        # self._setups = dict()  # Obsolete
        # self._setuptree = None  # Obsolete
        # self._running_setuptree = None  # Obsolete
        # self._setuptree_list = list()  # Used to store multiple SetupTrees (branches) (Obsolete)
        # self.setuptree_model = None  # Obsolete
        # self.setup_list_model = None  # Obsolete
        # self.tool_list_model = None  # Obsolete
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
        self.ui.pushButton_create_setups_1.clicked.connect(self.create_setups_1)
        self.ui.pushButton_create_setups_2.clicked.connect(self.create_setups_2)
        self.ui.pushButton_create_setups_3.clicked.connect(self.create_setups_3)
        self.ui.pushButton_create_test_setups.clicked.connect(self.create_test_setups)
        self.ui.pushButton_execute.clicked.connect(self.execute_setup)
        self.ui.pushButton_test.clicked.connect(self.print_next_generation)
        self.ui.pushButton_clear.clicked.connect(self.get_selected_setup_base_index)
        self.ui.pushButton_add_base.clicked.connect(self.open_setup_popup_from_button)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)
        self.ui.treeView_setups.pressed.connect(self.update_tool_view)
        self.ui.treeView_setups.customContextMenuRequested.connect(self.context_menu_configs)

    def context_menu_configs(self, pos):
        """ Context menu for the configuration tree.

        Args:
            pos: it is received from the customContextMenuRequested signal and
             it includes the mouse position.
        """
        global_pos = self.ui.treeView_setups.mapToGlobal(pos)
        if len(self.ui.treeView_setups.selectedIndexes()) == 0:
            ind = None
        else:
            ind = self.ui.treeView_setups.selectedIndexes()[0]
        menu = ContextMenuWidget(global_pos, ind)
        # option = ContextMenuWidget(global_pos).get_action()
        option = menu.get_action()
        logging.debug("%s" % option)
        if option == "Add Child":
            logging.debug("adding child")
            self.open_setup_popup(ind)
        elif option == "Add New Base":
            self.open_setup_popup()
        elif option == "Edit":
            logging.debug("Edit selected")
        elif option == "Execute":
            if ind is None:
                logging.debug("No Setup selected")
            else:
                logging.debug("Selected setup:%s" % ind.internalPointer().name)
                self.execute_setup()
        else:
            logging.debug("No selection made")

    def init_views(self):
        """Create data models for GUI views."""
        # Make root for SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        self.setup_model = SetupModel(self._root)
        # Set model into QTreeView
        self.ui.treeView_setups.setModel(self.setup_model)
        # Make Proxymodel to show tool associated with the selected Setup
        self.tool_proxy_model = ToolProxyModel(self.ui)
        self.tool_proxy_model.setSourceModel(self.setup_model)
        self.ui.listView_tools.setModel(self.tool_proxy_model)
        # TODO: Proxy model for input formats
        # TODO: Proxy model for output formats
        # TODO: Show input files of Setup directory
        # Obsolete models & views
        # self.setuptree_model = SetupTreeListModel()
        # self.setup_list_model = SetupTreeListModel()
        # self.tool_list_model = SetupTreeListModel()
        # self.ui.listVView_setuptrees.setModel(self.setuptree_model)
        # self.ui.listView_setups.setModel(self.setup_list_model)

    def open_setup_popup_from_button(self):
        """Show Setup creation popup
        Args:
            index (QModelIndex): Parent index of the new Setup
        """
        # Show Setup creation wizard
        index = None
        self.setup_popup = SetupPopupWidget(self, index)
        self.setup_popup.create_base_signal.connect(self.add_base)
        self.setup_popup.create_child_signal.connect(self.add_child)
        self.setup_popup.show()

    def open_setup_popup(self, index=None):
        """Show Setup creation popup
        Args:
            index (QModelIndex): Parent index of the new Setup
        """
        # Show Setup creation wizard
        self.setup_popup = SetupPopupWidget(self, index)
        self.setup_popup.create_base_signal.connect(self.add_base)
        self.setup_popup.create_child_signal.connect(self.add_child)
        self.setup_popup.show()

    @pyqtSlot(str, str)
    def add_base(self, name, description):
        try:
            self.setup_popup.create_base_signal.disconnect()
            self.setup_popup.create_child_signal.disconnect()
        except TypeError:
            pass
        self.setup_popup.close()
        self.setup_popup = None
        if name == '':
            self.add_msg_signal.emit("No name given. Try again.")
            return
        else:
            if not self.setup_model.insert_setup(name, description, self._project, 0):
                logging.error("Adding Base to model failed")
                return

    @pyqtSlot(str, str, "QModelIndex")
    def add_child(self, name, description, index):
        try:
            self.setup_popup.create_base_signal.disconnect()
            self.setup_popup.create_child_signal.disconnect()
        except TypeError:
            pass
        self.setup_popup.close()
        self.setup_popup = None
        if name == '':
            self.add_msg_signal.emit("No name given. Try again.")
            return
        else:
            if not self.setup_model.insert_setup(name, description, self._project, 0, index):
                logging.error("Adding Base to model failed")
                return

    def execute_setup(self):
        """Start executing selected Setup and all it's parents."""
        # Set index of base Setup for the model
        base = self.get_selected_setup_base_index()
        # Check if no Setup selected
        if not base:
            self.add_msg_signal.emit("No Setup selected.\n")
            return
        self.setup_model.set_base(base)
        # Set Base Setup as the first running Setup
        self._running_setup = self.setup_model.get_base().internalPointer()
        # Connect setup_finished_signal to setup_done slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("\nStarting Setup '%s'" % self._running_setup.name)
        self._running_setup.execute(self)

    @pyqtSlot()
    def setup_done(self):
        """Start executing finished Setup's parent or end run if all Setups are ready."""
        logging.debug("Setup <{0}> ready".format(self._running_setup.name))
        self.add_msg_signal.emit("Setup '%s' ready" % self._running_setup.name)
        # Emit dataChanged signal to QtreeView because is_ready has been updated
        self.setup_model.emit_data_changed()
        # Disconnect signal to make sure it is not connected to multiple Setups
        try:
            self._running_setup.setup_finished_signal.disconnect()
        except TypeError:  # Just in case
            # logging.warning("setup_finished_signal not connected")
            pass
        # Get next executed Setup
        next_setup = self.setup_model.get_next_setup(breadth_first=True)
        if not next_setup:
            logging.debug("All Setups ready")
            self.add_msg_signal.emit("All Setups ready")
            return
        self._running_setup = next_setup.internalPointer()
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("Starting Setup '%s'" % self._running_setup.name)
        # Connect setup_finished_signal to this same slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        self._running_setup.execute(self)

    def get_selected_setup_base_index(self):
        """Returns the index of the base Setup of the selected
        Setup in the Setup QTreeView or the selected Setup if it
        has no parent (Except for root). Returns None when nothing
        is selected or when index is not valid."""
        try:
            index = self.ui.treeView_setups.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return None
        if not index.isValid():
            return None
        setup = index.internalPointer()
        if setup.parent().name == 'root':
            # base = setup
            base_index = index
        else:
            # base = setup.parent()
            base_index = index.parent()
            while base_index.internalPointer().parent().name is not 'root':
                # base = base.parent()
                base_index = base_index.parent()
        # self.add_msg_signal.emit("Base Setup '{}'".format(base.name))
        self.add_msg_signal.emit("Base Setup from Index: '{}'".format(base_index.internalPointer().name))
        return base_index

    def print_next_generation(self):
        """Get selected Setup's siblings in the Setup QTreeView.

        Returns:
            Setup and it's siblings pointed by the selected item or None if something went wrong.
        """
        try:
            index = self.ui.treeView_setups.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return None
        if not index.isValid():
            return None
        setup = index.internalPointer()
        next_gen = self.get_next_generation(index)
        if not next_gen:
            self.add_msg_signal.emit("Next generation not found")
            return None
        self.add_msg_signal.emit("Finding next generation of Setup '%s'" % setup.name)
        for ind in next_gen:
            self.add_msg_signal.emit("Setup '%s' on next row" % ind.internalPointer().name)

    def get_selected_setup_siblings(self):
        """Get selected Setup's siblings in the Setup QTreeView.

        Returns:
            Setup and it's siblings pointed by the selected item or None if something went wrong.
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
        siblings = self.setup_model.get_siblings(index)
        if not siblings:
            self.add_msg_signal.emit("No siblings found")
            return None
        for ind in siblings:
            self.add_msg_signal.emit("Setups on current row:%s" % ind.internalPointer().name)

    def remove_selected_setup(self):
        """Removes selected Setup (and all of it's children) from SetupModel."""
        setup = self.get_selected_setup()
        if not setup:
            self.add_msg_signal.emit("No Setup selected")
            return
        self.add_msg_signal.emit("Removing Setup '%s' (NA)" % setup.name)
        # TODO: Implement removeRows() in SetupModel

    def create_setups_1(self):
        """Create two Setups ('base' and 'setup a') and associate tool Magic with Setup A."""
        # Create tool
        tool = GAMSModel('OLD MAGIC',
                         """A number of power stations are committed to meet demand
                         for a particular day. Three types of generators having
                         different operating characteristics are available. Generating
                         units can be shut down or operate between minimum and maximum
                         output levels. Units can be started up or closed down in
                         every demand block.""",
                         OLD_MAGIC_MODEL_PATH, 'magic.gms',
                         input_dir='input', output_dir='output')
        # Add input&output formats for tool
        tool.add_input_format(GDX_DATA_FMT)
        tool.add_input_format(GAMS_INC_FILE)
        tool.add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameter for tool
        tool.add_input(data)
        # Add Base Setup
        if not self.setup_model.insert_setup('base', 'The base setup', self._project, 0):
            logging.error("Adding 'base' to model failed")
            return
        # Add A
        base_index = self.setup_model.index(0, 0, QModelIndex())
        if not self.setup_model.insert_setup('setup A', 'test setup A', self._project, 0, base_index):
            logging.error("Adding 'setup A' to model failed")
            return
        # Add tool 'magic' to setup 'Setup A'
        a_ind = self.setup_model.index(0, 0, base_index)
        setup_a = self.setup_model.get_setup(a_ind)
        if not setup_a.add_tool(tool, 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding a tool to 'setup A' failed\n")
            logging.error("Adding a tool to Setup setup 'A' failed")
            return
        # root_print = self._root.log()
        # logging.debug("root print:\n%s" % root_print)

    def create_setups_2(self):
        """Create 'invest' and 'MIP' setups."""

        # Load model definitions
        magic_invest = GAMSModel.load(MAGIC_INVESTMENTS_JSON)
        magic_operation = GAMSModel.load(MAGIC_OPERATION_JSON)

        # Add Invest Setup
        if not self.setup_model.insert_setup('invest', 'Do investments', self._project, 0):
            logging.error("Adding 'invest' to model failed")
            return
        invest_ind = self.setup_model.index(0, 0, QModelIndex())
        invest = self.setup_model.get_setup(invest_ind)
        invest.add_input(magic_invest)
        invest.add_tool(magic_invest, "--USE_MIP=yes")
        # Add MIP
        if not self.setup_model.insert_setup('MIP', 'Operation with MIP model', self._project, 0, invest_ind):
            logging.error("Adding 'MIP' to model failed")
            return
        mip_index = self.setup_model.index(0, 0, invest_ind)
        mip = self.setup_model.get_setup(mip_index)
        mip.add_input(magic_operation)
        mip.add_tool(magic_operation, cmdline_args="--USE_MIP=yes")

    def create_setups_3(self):
        """Creates 'invest' -> 'LP' branch and 'invest' -> MIP branches
         and puts them into a SetupTree List."""

        # Load model definitions
        magic_invest = GAMSModel.load(MAGIC_INVESTMENTS_JSON)
        magic_operation = GAMSModel.load(MAGIC_OPERATION_JSON)

        # Add Invest Setup
        if not self.setup_model.insert_setup('invest', 'Do investments', self._project, 0):
            logging.error("Adding 'invest' to model failed")
            return
        invest_ind = self.setup_model.index(0, 0, QModelIndex())
        invest = self.setup_model.get_setup(invest_ind)
        invest.add_input(magic_invest)
        invest.add_tool(magic_invest, cmdline_args="--USE_MIP=yes")
        # Add MIP as child of invest
        if not self.setup_model.insert_setup('MIP', 'Operation with MIP model', self._project, 0, invest_ind):
            logging.error("Adding 'MIP' to model failed")
            return
        mip_index = self.setup_model.index(0, 0, invest_ind)
        mip = self.setup_model.get_setup(mip_index)
        mip.add_input(magic_operation)
        mip.add_tool(magic_operation, cmdline_args='--USE_MIP=yes')

        # Add LP as child of invest
        if not self.setup_model.insert_setup('LP', 'Operation with LP model', self._project, 0, invest_ind):
            logging.error("Adding 'LP' to model failed")
            return
        lp_index = self.setup_model.index(0, 0, invest_ind)
        lp = self.setup_model.get_setup(lp_index)
        lp.add_tool(magic_operation, cmdline_args='--USE_MIP=no')

    def create_test_setups(self):
        # Create tool
        tool = GAMSModel('OLD MAGIC',
                         """A number of power stations are committed to meet demand
                         for a particular day. Three types of generators having
                         different operating characteristics are available. Generating
                         units can be shut down or operate between minimum and maximum
                         output levels. Units can be started up or closed down in
                         every demand block.""",
                         OLD_MAGIC_MODEL_PATH, 'magic.gms',
                         input_dir='input', output_dir='output')
        # Add input&output formats for tool
        tool.add_input_format(GDX_DATA_FMT)
        tool.add_input_format(GAMS_INC_FILE)
        tool.add_output_format(GDX_DATA_FMT)
        # Create data parameters
        g = Dimension('g', 'generators')
        param = Dimension('param', 'parameters')
        data = DataParameter('data', 'generation data', '?', [g, param])
        # Add input data parameter for tool
        tool.add_input(data)

        # TODO: Handle case where user tries to add a setup with a name that is already taken.

        # ----------------- Adding a Setup to data model -------------------:
        # Option 1: Create Setup with the wanted parent
        # Option 2: Create Setup with no parent and use insert_child() to associate Setup to model
        # Add Base Setup
        if not self.setup_model.insert_setup('BASE', 'The base setup', self._project, 0):
            logging.error("Adding Base to model failed")
            return
        # Add A
        base_index = self.setup_model.index(0, 0, QModelIndex())
        if not self.setup_model.insert_setup('A', 'Setup A', self._project, 0, base_index):
            logging.error("Adding A to model failed")
            return
        # Add B
        base_index = self.setup_model.index(0, 0, QModelIndex())
        if not self.setup_model.insert_setup('B', 'Setup B', self._project, 0, base_index):
            logging.error("Adding B to model failed")
            return
        # Add C
        a_index = self.setup_model.index(1, 0, base_index)  # A is on second row because B is now on first row
        if not self.setup_model.insert_setup('C', 'Setup C', self._project, 0, a_index):
            logging.error("Adding C to model failed")
            return
        # Add another Base
        if not self.setup_model.insert_setup('BASE 2', 'Another base setup', self._project, 0):
            logging.error("Adding Base to model failed")
            return
        # Add tool 'magic' to setup 'A'
        a_ind = self.setup_model.index(1, 0, base_index)
        a = self.setup_model.get_setup(a_ind)
        if not a.add_tool(tool, 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding 'magic' tool to 'A' failed\n")
            logging.error("Adding a model to Setup failed")
            return

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
            message (str): The error message to be written.
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
        setup_a_index = self.setup_model.index(0, 0, QModelIndex())
        retval = self.setup_model.insert_setup('setup D', 'test setup D', self._project, 0, setup_a_index)
        if not retval:
            logging.error("Adding Setup to model failed")
            return
        logging.debug("Setup added successfully")

    @pyqtSlot("QModelIndex")
    def update_tool_view(self, index):
        """Update tool name of selected Setup to tool QListView.

        Args:
            index (QModelIndex): Index of selected item.
        """
        if not index.isValid():
            return
        self.tool_proxy_model.emit_data_changed()

    def example_on_how_to_create_setuptree(self):
        """Create two Setups ('base' and 'setup a') and associate tool Magic with Setup A.

        NOTE: Obsolete!

         """
        # Create tool
        self._tools['magic'] = GAMSModel('OLD MAGIC',
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
        self.setup_list_model.add_data(self._setups['base'])
        self.setup_list_model.add_data(self._setups['setup A'])
        self.tool_list_model.add_data(self._tools['magic'])
        self.setuptree_model.add_data(self._setuptree)
        root_print = self._root.log()
        logging.debug("root print:\n%s" % root_print)

    def execute_all(self):
        """Run all SetupTrees in setuptree_list.

        NOTE: Obsolete!

        """
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
        """Clean up after a SetupTree has finished.

        NOTE: Obsolete!

        """
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

    def closeEvent(self, event=None):
        """Method for handling application exit.

        Args:
             event (QEvent): PyQt event
        """
        # Remove working files
        # TODO: Fix this
        # for _, setup in self._setups.items():
        #    setup.cleanup()
        logging.debug("Thank you for choosing Titan. Bye bye.")
        # noinspection PyArgumentList
        QApplication.quit()
