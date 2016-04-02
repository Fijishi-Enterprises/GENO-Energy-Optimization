"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
from PyQt5.QtCore import pyqtSignal, pyqtSlot, Qt, QVariant, \
    QAbstractItemModel, QAbstractListModel, QModelIndex
from PyQt5.QtWidgets import QMainWindow, QApplication
from PyQt5.QtGui import QStandardItemModel, QStandardItem
from ui.main import Ui_MainWindow
from project import SceletonProject
from tool import Dimension, DataParameter, Setup, SetupTree
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE
from config import ERROR_TEXT_COLOR, MAGIC_MODEL_PATH, OLD_MAGIC_MODEL_PATH


class SetupTreeListModel(QAbstractListModel):
    """Class to store SetupTree instances."""
    def __init__(self, parent=None):
        super().__init__()
        self._data = list()
        self._parent = parent

    def rowCount(self, parent=None, *args, **kwargs):
        """Reimplemented from QAbstractItemModel.

        Args:
            parent (QModelIndex): Parent index
            *args:
            **kwargs:

        Returns:
            The number of rows under the given parent.
        """
        return len(self._data)

    def data(self, index, role=None):
        """Reimplemented method from QAbstractItemModel.

        Args:
            index (QModelIndex): Index of data
            role (int): Role of data asked from the model by view

        Returns:
            Data stored under the given role for the item referred to by the index.
        """
        if not index.isValid() or self.rowCount() == 0:
            return QVariant()

        if role == Qt.DisplayRole:
            row = index.row()
            name = self._data[row].name
            return name

    def flags(self, index):
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable

    def add_data(self, d):
        """Append new object to the end of the data list.

        Args:
            d (QObject): New SetupTree, Setup or Tool to add

        Returns:
            True if successful, False otherwise
        """
        self.beginInsertRows(QModelIndex(), len(self._data), len(self._data))
        self._data.append(d)
        self.endInsertRows()

    # def insertRow(self, position, parent=QModelIndex(), *args, **kwargs):
    #
    #     self.beginInsertRows(parent, position, position)  # (index, first, last)
    #     self._setuptrees.insert(position, setuptree)
    #     self.endInsertRows()
    #     return True

    # def removeRow(self, position, parent=None, *args, **kwargs):
    #     self.beginRemoveRows()
    #     self.endRemoveRows()


class SetupGraphModel(QAbstractItemModel):
    """INPUTS: Node, QObject"""
    def __init__(self, root, parent=None):
        super().__init__(parent)
        self._root_setup = root

    def rowCount(self, parent=None, *args, **kwargs):
        """Returns row count for the view."""
        if not parent.isValid():
            parent_setup = self._root_setup
        else:
            parent_setup = parent.internalPointer()

        return parent_setup.child_count()

    def columnCount(self, parent=None, *args, **kwargs):
        """Returns column count for the view."""
        return 1

    def data(self, index, role=None):

        if not index.isValid():
            return None

        setup = index.internalPointer()

        if role == Qt.DisplayRole:
            if index.column() == 0:
                if setup.is_ready:
                    return setup.name + " (Ready)"
                return setup.name

    def headerData(self, section, orientation, role=None):
        if role == Qt.DisplayRole:
            if section == 0:
                return "Setups"
            else:
                return "FixMe"

    def parent(self, index=None):
        """Gives parent of the setup with the given QModelIndex.

        Args:
            index (QModelIndex): Given index

        Returns:
            Parent of the setup with the given QModelIndex
        """
        setup = self.get_setup(index)
        parent_setup = setup.parent()

        if parent_setup == self._root_setup:
            return QModelIndex()

        return self.createIndex(parent_setup.row(), 0, parent_setup)

    def index(self, row, column, parent=None, *args, **kwargs):
        """Gives a QModelIndex that corresponds to the given row, column and parent setup.

        Args:
            row (int): Row number
            column (int): Column number
            parent (QModelIndex): Parent setup QModelIndex

        Returns:
            QModelIndex that corresponds to the given row, column and parent setup
        """
        parent_setup = self.get_setup(parent)
        child_setup = parent_setup.child(row)

        if child_setup:
            return self.createIndex(row, column, child_setup)
        else:
            return QModelIndex()

    def get_setup(self, index):
        """Get setup with the given index.

        Args:
            index (QModelIndex): index of the setup

        Returns:
            Setup at given index
        """
        if index.isValid():
            setup = index.internalPointer()
            if setup:
                return setup
        return self._root_setup

    # def insertRows(self, position, rows, parent=QModelIndex(), *args, **kwargs):
    #
    #     parent_setup = self.get_setup(parent)
    #
    #     self.beginInsertRows(parent, position, position + rows - 1)
    #
    #     for row in range(rows):
    #
    #         child_count = parent_setup.child_count()
    #         childNode = Node("untitled" + str(childCount))
    #         success = parentNode.insertChild(position, childNode)
    #
    #     self.endInsertRows()
    #
    #     return success

    def add_data(self, row, d, parent=QModelIndex()):
        """Append new object as the root setup.

        Args:
            row (int): Row where to insert new setup
            d (Setup): New Setup object
            parent (QModelIndex): Index of parent. Will be invalid if parent is root.

        Returns:
            True if successful, False otherwise
        """
        parent_setup = self.get_setup(parent)

        # self.beginInsertRows(QModelIndex(), len(self._root_setup), len(self._root_setup))
        self.beginInsertRows(parent, row, row)
        retval = parent_setup.add_child(d)
        # self._root_setup = d
        self.endInsertRows()
        return retval

    def insert_setup(self, name, description, project, row, parent=QModelIndex()):
        """Add new Setup to model.

        Args:
            row (int): Row where to insert new setup
            parent (QModelIndex): Index of parent. Will be invalid if parent is root.

        Returns:
            True if successful, False otherwise
        """
        parent_setup = self.get_setup(parent)
        self.beginInsertRows(parent, row, row)
        # new_setup = Setup(name, description, project, parent_setup)
        new_setup = Setup(name, description, project)
        retval = parent_setup.insert_child(position=row, child=new_setup)
        self.endInsertRows()
        return retval

    def emit_data_changed(self):
        self.dataChanged.emit(QModelIndex(), QModelIndex())


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
        self.setupgraphmodel = None
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
        self.ui.pushButton_clear_listview.clicked.connect(self.clear_listview)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)
        self.ui.listView_setuptrees.pressed.connect(self.dummy1_button)
        self.ui.treeView_setups.pressed.connect(self.get_clicked_setup)

    def init_views(self):
        """Create a model for QListView's data."""
        self.setuptree_model = SetupTreeListModel()
        self.setup_model = SetupTreeListModel()
        self.tool_model = SetupTreeListModel()
        # Make root for Setup model
        self._root = Setup('root', 'root node for Setups,', self._project)
        self.setupgraphmodel = SetupGraphModel(self._root)
        # Set model into treeView
        self.ui.treeView_setups.setModel(self.setupgraphmodel)
        self.ui.listView_setuptrees.setModel(self.setuptree_model)
        self.ui.listView_setups.setModel(self.setup_model)
        self.ui.listView_tools.setModel(self.tool_model)
        # self.ui.treeView_setups.setModel(self.setupgraphmodel)
        # self.model_listview = QStandardItemModel(self.ui.listView_setuptreelist)

    def clear_listview(self):
        self.add_msg_signal.emit("Clearing QListView")
        # TODO: Remove data from private setuptrees list
        # self.setuptree_model.clear()

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
        # Add data into treeView
        # self.setupgraphmodel = SetupGraphModel(self._setups['base'])
        # self.ui.treeView_setups.setModel(self.setupgraphmodel)
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
        if not self.setupgraphmodel.insert_setup('BASE', 'The base setup', self._project, 0):
            logging.error("Adding Base to model failed")
            return
        # Add A
        base_index = self.setupgraphmodel.index(0, 0, QModelIndex())
        if not self.setupgraphmodel.insert_setup('A', 'Setup A', self._project, 0, base_index):
            logging.error("Adding A to model failed")
            return
        # Add B
        base_index = self.setupgraphmodel.index(0, 0, QModelIndex())
        if not self.setupgraphmodel.insert_setup('B', 'Setup B', self._project, 0, base_index):
            logging.error("Adding B to model failed")
            return
        # Add C
        a_index = self.setupgraphmodel.index(1, 0, base_index)  # A is on second row because B is now on first row
        if not self.setupgraphmodel.insert_setup('C', 'Setup C', self._project, 0, a_index):
            logging.error("Adding C to model failed")
            return
        # Add another Base
        if not self.setupgraphmodel.insert_setup('BASE 2', 'Another base setup', self._project, 0):
            logging.error("Adding Base to model failed")
            return
        # Add tool 'magic' to setup 'A'
        a_ind = self.setupgraphmodel.index(1, 0, base_index)
        a = self.setupgraphmodel.get_setup(a_ind)
        if not a.add_tool(self._tools['magic'], 'MIP=CPLEX'):
            self.add_err_msg_signal.emit("Adding 'magic' tool to 'A' failed\n")
            logging.error("Adding a model to Setup failed")
            return

    def run_selected_setup(self):
        """Start executing selected Setup and all it's parents."""
        # Get selected index QtreeView
        try:
            index = self.ui.treeView_setups.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return
        if not index.isValid():
            return
        row = index.row()
        column = index.column()
        # Get Setup to where the index is pointing
        self._running_setup = index.internalPointer()
        self.add_msg_signal.emit("Selected item at row:%s column:%s setup name:%s"
                                 % (row, column, self._running_setup.name))

        # base_ind = self.setupgraphmodel.index(1, 0, QModelIndex())
        # a_ind = self.setupgraphmodel.index(1, 0, base_ind)
        # self._running_setup = self.setupgraphmodel.get_setup(a_ind)

        # Connect setup_finished_signal to some slot in this class
        self._running_setup.setup_finished_signal.connect(self.setup_finished)
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("\nStarting Setup '%s'" % self._running_setup.name)
        self._running_setup.execute()

    @pyqtSlot("QModelIndex")
    def get_clicked_setup(self, index):
        if not index.isValid():
            return
        row = index.row()
        column = index.column()
        setup = index.internalPointer()
        # self.add_msg_signal.emit("Pressed item row:%s column:%s setup name:%s" % (row, column, setup.name))
        logging.debug("Pressed item row:%s column:%s setup name:%s" % (row, column, setup.name))

    @pyqtSlot()
    def get_selected_setup(self):
        try:
            index = self.ui.treeView_setups.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return
        if not index.isValid():
            return
        row = index.row()
        column = index.column()
        setup = index.internalPointer()
        self.add_msg_signal.emit("Pressed item row:%s column:%s setup name:%s" % (row, column, setup.name))

    @pyqtSlot()
    def setup_finished(self):
        # Get parent of current Setup and execute it unless it is 'root' Setup
        logging.debug("Setup <{0}> ready".format(self._running_setup.name))
        self.add_msg_signal.emit("Setup '%s' ready" % self._running_setup.name)
        # Emit dataChanged signal to QtreeView because is_ready is now updated.
        self.setupgraphmodel.emit_data_changed()
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
            # self._running_setup = None
            return
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("Starting Setup '%s'" % self._running_setup.name)
        # Connect setup_finished_signal to this same slot
        self._running_setup.setup_finished_signal.connect(self.setup_finished)
        self._running_setup.execute()

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
        setup_a_index = self.setupgraphmodel.index(0, 0, QModelIndex())
        retval = self.setupgraphmodel.insert_setup('setup D', 'test setup D', self._project, 0, setup_a_index)
        if not retval:
            logging.error("Adding Setup to model failed")
            return
        logging.debug("Setup added successfully")

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
