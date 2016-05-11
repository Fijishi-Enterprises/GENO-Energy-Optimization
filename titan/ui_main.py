"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
import os
import json
from PyQt5.QtCore import pyqtSignal, pyqtSlot, QModelIndex, Qt
from PyQt5.QtWidgets import QMainWindow, QApplication, QMessageBox, QFileDialog
from ui.main import Ui_MainWindow
from project import SceletonProject
from models import SetupModel, ToolProxyModel
from tool import Dimension, DataParameter, Setup
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE
from config import MAGIC_MODEL_PATH, OLD_MAGIC_MODEL_PATH,\
                   MAGIC_INVESTMENTS_JSON, MAGIC_OPERATION_JSON,\
                   ERROR_COLOR, SUCCESS_COLOR, PROJECT_DIR
from widgets.setup_popup_widget import SetupPopupWidget
from widgets.project_form_widget import ProjectFormWidget
from widgets.context_menu_widget import ContextMenuWidget
from modeltest.modeltest import ModelTest


class TitanUI(QMainWindow):
    """Class for application main GUI functions."""

    # Custom PyQt signals
    add_msg_signal = pyqtSignal(str, int)
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
        # Class variables
        self._running_setup = None
        self._root = None  # Root node for SetupModel
        self.setup_model = None
        self.modeltest = None
        self.tool_proxy_model = None
        self.setup_dict = dict()
        # References for widgets
        self.setup_popup = None
        self.project_form = None
        self.context_menu = None
        # Load project
        self._project = self.init_project('project_1')
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
        self.ui.actionNew.triggered.connect(self.new_project)
        self.ui.actionSave.triggered.connect(self.save_project)
        self.ui.actionSave_As.triggered.connect(self.save_project_as)
        self.ui.actionLoad.triggered.connect(self.load_project)
        self.ui.actionQuit.triggered.connect(self.closeEvent)
        # Widgets
        self.ui.pushButton_create_setups_1.clicked.connect(self.create_setups_1)
        self.ui.pushButton_create_setups_2.clicked.connect(self.create_setups_2)
        self.ui.pushButton_create_setups_3.clicked.connect(self.create_setups_3)
        self.ui.pushButton_create_test_setups.clicked.connect(self.create_test_setups)
        self.ui.pushButton_execute.clicked.connect(self.execute_setup)
        self.ui.pushButton_test.clicked.connect(self.traverse_model)
        self.ui.pushButton_delete_setup.clicked.connect(self.delete_selected_setup)
        self.ui.pushButton_add_base.clicked.connect(self.open_setup_popup)
        self.ui.pushButton_delete_all.clicked.connect(self.delete_all)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)
        self.ui.treeView_setups.pressed.connect(self.update_tool_view)
        self.ui.treeView_setups.customContextMenuRequested.connect(self.context_menu_configs)

    def init_views(self):
        """Create data models for GUI views."""
        # Root for SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        self.setup_model = SetupModel(self._root)
        # Set model test in action
        # self.modeltest = ModelTest(self.setup_model, self._root)
        # Set model into QTreeView
        self.ui.treeView_setups.setModel(self.setup_model)
        # Make a ProxyModel to show the tool associated with the selected Setup
        self.tool_proxy_model = ToolProxyModel(self.ui)
        self.tool_proxy_model.setSourceModel(self.setup_model)
        self.ui.listView_tools.setModel(self.tool_proxy_model)
        # TODO: Show input files of Setup directory

    def init_project(self, project_name):
        """Initialize project when Sceleton is started.

        Args:
            project_name (str): Project name
        """
        # TODO: This method is not needed when loading works
        project_desc = 'a test project'
        project = SceletonProject(project_name, project_desc)
        self.setWindowTitle("Sceleton Titan    -- {} --".format(project.name))
        return project

    def clear_ui(self):
        """Clear UI when starting a new project or loading a project."""
        # Clear Setup Model
        self.delete_all_no_confirmation()
        self._root = None
        self.setup_model = None
        self.tool_proxy_model = None
        # Set project to None
        self._project = None
        # Clear text browsers
        self.ui.textBrowser_main.clear()
        self.ui.textBrowser_process_output.clear()

    def new_project(self):
        """Show 'New Project' form to user to query project details."""
        self.project_form = ProjectFormWidget(self)
        self.project_form.show()

    def create_project(self, name, description):
        """Create new project and set it active.

        Args:
            name (str): Project name
            description (str): Project description
        """
        self.clear_ui()
        self._project = SceletonProject(name, description)
        self.init_views()
        self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
        self.add_msg_signal.emit("Started project '{0}'".format(self._project.name), 0)
        # Create and save project file to disk
        self.save_project()

    def save_project_as(self):
        """Save Setups in project to disk. Ask file name from user."""
        if self._root.child_count() == 0:
            self.ui.statusbar.showMessage("No Setups to Save", 5000)
            return
        # Open file dialog to query save file name
        # noinspection PyCallByClass, PyTypeChecker
        dir_path = QFileDialog.getSaveFileName(self, 'Save project',
                                                     PROJECT_DIR,
                                                     'JSON (*.json)')
        file_path = dir_path[0]
        if file_path == '':  # Cancel button clicked
            self.add_msg_signal.emit("Saving project Canceled", 0)
            logging.debug("Saving canceled")
            return
        # Create new project
        file_name = os.path.split(file_path)[-1]
        proj_name = os.path.splitext(file_name)[0]
        proj_desc = ''
        self._project = SceletonProject(proj_name, proj_desc)
        self.add_msg_signal.emit("Saving project '{0}' to file: <{1}>".format(self._project.name, file_name), 0)
        self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
        self.save(file_path)

    def save_project(self):
        """Save Setups in project to disk. Use project name as file name."""
        # if self._root.child_count() == 0:
        #     self.ui.statusbar.showMessage("No Setups to Save", 5000)
        #     return
        # Use project name as file name
        file_name = os.path.join(PROJECT_DIR, '{}.json'.format(self._project.short_name))
        self.add_msg_signal.emit("Saving project -> {0}".format(file_name), 0)
        self.save(file_name)

    def save(self, fname):
        """Project information and Setups are collected to their own dictionaries.
        These dictionaries are then saved into another dictionary, which is saved to a
        JSON file.

        Args:
            fname (str): Path to the save file.
        """
        # TODO: Plan (for now) is to save all project stuff into one JSON file.
        # Clear Setup dictionary
        self.setup_dict.clear()
        project_dict = dict()  # This is written to JSON file
        dic = dict()  # This is an intermediate dictionary to hold project info
        dic['name'] = self._project.name
        dic['desc'] = self._project.description
        # Save project stuff
        project_dict['project'] = dic
        # TODO: Add children into the dictionary of the parent in JSON (If Setups are easier to load that way)

        def traverse(item):
            logging.debug("\t" * traverse.level + item.name)
            if not item.name == 'root':
                self.update_json_dict(item)
            for kid in item.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from root
        traverse(self._root)

        # Save Setups into dictionary
        project_dict['setups'] = self.setup_dict
        # Write into JSON file
        with open(fname, 'w') as fp:
            json.dump(project_dict, fp, indent=4)
        msg = "Project '%s' saved to file'%s'" % (self._project.name, fname)
        self.ui.statusbar.showMessage(msg, 5000)
        self.add_msg_signal.emit("Done", 1)

    def update_json_dict(self, setup):
        """Update tree dictionary with Setup dictionary.

        Args:
            setup (Setup): Setup object to save
        """
        # TODO: Add all necessary attributes from Setup object to here (e.g. cmdline_args)
        the_dict = dict()
        the_dict['name'] = setup.name
        if setup.parent() is not None:
            the_dict['parent'] = setup.parent().short_name
        else:
            the_dict['parent'] = None
        if setup.tool:
            the_dict['tool'] = setup.tool.short_name
        else:
            the_dict['tool'] = None
        the_dict['is_ready'] = setup.is_ready
        the_dict['n_child'] = setup.child_count()
        # if setup.child_count() > 0:
        #     the_dict['children'] = self.update_json_dict()
        name = setup.short_name
        self.setup_dict[name] = the_dict

    def load_project(self):
        """Load project from file."""
        # noinspection PyCallByClass, PyTypeChecker
        answer = QFileDialog.getOpenFileName(self, 'Load project', PROJECT_DIR, 'JSON (*.json)')
        load_path = answer[0]
        if load_path == '':  # Cancel button clicked
            self.add_msg_signal.emit("Loading canceled", 0)
            return
        self.add_msg_signal.emit("Loading project from file: <{0}>".format(load_path), 0)
        if not os.path.isfile(load_path):
            self.add_msg_signal.emit("File not found '%s'" % load_path, 2)
            return
        dicts = dict()
        try:
            with open(load_path, 'r') as fh:
                dicts = json.load(fh)
        except OSError:
            self.add_msg_signal.emit("OSError: Could not load file '{}'".format(load_path), 2)
            return
        # Initialize UI
        self.clear_ui()
        # Parse project info
        project_dict = dicts['project']
        proj_name = project_dict['name']
        proj_desc = project_dict['desc']
        # Create project
        self._project = SceletonProject(proj_name, proj_desc)
        # Setup views
        self.init_views()
        self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))

        # Parse Setups
        setup_dict = dicts['setups']
        if len(setup_dict) == 0:
            self.add_msg_signal.emit("No Setups found in project file '{}'".format(load_path), 0)
            return
        self.add_msg_signal.emit("Loading %d Setups" % len(setup_dict), 0)
        self.add_msg_signal.emit("Current project is now '{0}'".format(self._project.name), 0)
        for dic in setup_dict:
            logging.debug("Setup short name: %s" % dic)
            # logging.debug("values: %s" % dicts[dic])
            # Add base Setups first
            if setup_dict[dic]['parent'] == 'root':
                name = setup_dict[dic]['name']
                desc = ''
                index = QModelIndex()
                self.add_setup(name, desc, index)
                # TODO: Parse other attributes too
                # Check if this base setup has children
                if setup_dict[dic]['n_child'] > 0:
                    # Find all children of this base Setup and add them to model
                    for dictio in setup_dict:
                        if setup_dict[dictio]['parent'] == name:
                            kid_name = setup_dict[dictio]['name']
                            kid_desc = ''
                            # TODO: This index might not work in all cases
                            parent_index = self.setup_model.index(0, 0, QModelIndex())  # Get the index of parent
                            self.add_setup(kid_name, kid_desc, parent_index)
                            # TODO: Parse other attributes too
                            # TODO: Check if this kid has children and add them (recursively)
            for key in setup_dict[dic]:
                logging.debug("%s: %s" % (key, setup_dict[dic][key]))
        msg = "Project '%s' loaded" % self._project.name
        self.ui.statusbar.showMessage(msg, 5000)

    def context_menu_configs(self, pos):
        """Context menu for the configuration tree.

        Args:
            pos (int): Received from the customContextMenuRequested
            signal, contains mouse position.
        """
        ind = self.ui.treeView_setups.indexAt(pos)
        global_pos = self.ui.treeView_setups.mapToGlobal(pos)
        self.context_menu = ContextMenuWidget(self, global_pos, ind)
        option = self.context_menu.get_action()
        # option = ContextMenuWidget(self, global_pos, ind).get_action()
        if option == "Add Child":
            logging.debug("adding child")
            self.open_setup_popup(ind)
            return
        elif option == "Add New Base":
            self.open_setup_popup()
            return
        elif option == "Edit":
            logging.debug("Edit selected")
            return
        elif option == "Execute":
            logging.debug("Selected setup:%s" % ind.internalPointer().name)
            self.execute_setup()
            return
        else:
            # No option selected
            pass
        self.context_menu.deleteLater()
        self.context_menu = None

    @pyqtSlot("QModelIndex")
    def open_setup_popup(self, index=QModelIndex()):
        """Show Setup creation popup.

        Args:
            index (QModelIndex): Parent index of the new Setup
        """
        if index is False:  # Happens when 'Add Base' button is pressed
            index = QModelIndex()
        self.setup_popup = SetupPopupWidget(self, index)
        self.setup_popup.show()

    def add_setup(self, name, description, parent=QModelIndex()):
        """Insert new Setup into SetupModel.

        Args:
            name (str): Setup name
            description (str): Setup description
            parent (QModelIndex): Parent Setup index
        """
        if name == '':
            self.add_msg_signal.emit("No name given. Try again.", 0)
            return
        if not parent.isValid():
            logging.debug("Inserting Base")
            if not self.setup_model.insert_setup(name, description, self._project, 0):
                logging.error("Adding base Setup failed")
        else:
            logging.debug("Inserting Child")
            if not self.setup_model.insert_setup(name, description, self._project, 0, parent):
                logging.error("Adding child Setup failed")
        return

    def delete_all(self):
        """Delete all Setups from model. Ask user's permission first."""
        root_index = QModelIndex()
        n_kids = self._root.child_count()
        msg = "You are about to delete all Setups in the project.\nAre you sure?"
        # noinspection PyCallByClass, PyTypeChecker
        answer = QMessageBox.question(self, 'Delete all Setups?', msg, QMessageBox.Yes, QMessageBox.No)
        if answer == QMessageBox.Yes:
            for i in range(n_kids):
                name = self._root.child(0).name
                self.add_msg_signal.emit("Setup '{}' deleted".format(name), 0)
                self.setup_model.remove_setup(0, root_index)
            return
        else:
            logging.debug("Delete canceled")
            return

    def delete_all_no_confirmation(self):
        """Delete all Setups from model."""
        root_index = QModelIndex()
        n_kids = self._root.child_count()
        for i in range(n_kids):
            self.setup_model.remove_setup(0, root_index)
        return

    def execute_setup(self):
        """Start executing selected Setup and all it's parents."""
        # Set index of base Setup for the model
        base = self.get_selected_setup_base_index()
        # Check if no Setup selected
        if not base:
            self.add_msg_signal.emit("No Setup selected.\n", 0)
            return
        self.setup_model.set_base(base)
        # Set Base Setup as the first running Setup
        self._running_setup = self.setup_model.get_base().internalPointer()
        # Connect setup_finished_signal to setup_done slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("\nStarting Setup '%s'" % self._running_setup.name, 0)
        self._running_setup.execute(self)

    @pyqtSlot()
    def setup_done(self):
        """Start executing finished Setup's parent or end run if all Setups are ready."""
        logging.debug("Setup <{0}> ready".format(self._running_setup.name))
        self.add_msg_signal.emit("Setup '%s' ready" % self._running_setup.name, 1)
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
            self.add_msg_signal.emit("All Setups ready", 1)
            return
        self._running_setup = next_setup.internalPointer()
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("Starting Setup '%s'" % self._running_setup.name, 0)
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
        # self.add_msg_signal.emit("Base Setup '{}'".format(base.name), 0)
        # self.add_msg_signal.emit("Base Setup from Index: '{}'".format(base_index.internalPointer().name), 0)
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
            self.add_msg_signal.emit("Next generation not found", 0)
            return None
        self.add_msg_signal.emit("Finding next generation of Setup '%s'" % setup.name, 0)
        for ind in next_gen:
            self.add_msg_signal.emit("Setup '%s' on next row" % ind.internalPointer().name, 0)

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
        self.add_msg_signal.emit("Pressed item row:%s column:%s setup name:%s" % (row, column, setup.name), 0)
        siblings = self.setup_model.get_siblings(index)
        if not siblings:
            self.add_msg_signal.emit("No siblings found", 0)
            return None
        for ind in siblings:
            self.add_msg_signal.emit("Setups on current row:%s" % ind.internalPointer().name, 0)

    def delete_selected_setup(self):
        """Removes selected Setup (and all of it's children) from SetupModel."""
        try:
            index = self.ui.treeView_setups.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return
        if not index.isValid():
            return
        row = index.row()
        parent = self.setup_model.parent(index)
        name = index.internalPointer().name
        msg = "You are about to delete Setup '%s' and all of its children.\nAre you sure?" % name
        # noinspection PyCallByClass, PyTypeChecker
        answer = QMessageBox.question(self, 'Deleting Setup', msg, QMessageBox.Yes, QMessageBox.No)
        if answer == QMessageBox.Yes:
            self.add_msg_signal.emit("Setup '%s' deleted" % name, 0)
            self.setup_model.remove_setup(row, parent)
            return
        else:
            logging.debug("Delete canceled")
            return

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
            logging.error("Adding 'base' Setup to model failed")
            return
        # Add A
        base_index = self.setup_model.index(0, 0, QModelIndex())
        if not self.setup_model.insert_setup('setup A', 'test setup A', self._project, 0, base_index):
            logging.error("Adding 'setup A' Setup to model failed")
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
        # ----------------- Adding a Setup to data model -------------------:
        # Option 1: Create Setup with the wanted parent
        # Option 2: Create Setup with no parent and use insert_child() to associate Setup to model
        # Add Base Setup
        if not self.setup_model.insert_setup('A', 'Base setup', self._project, 0):
            logging.error("Adding Base Setup 'A' failed")
            return
        # Add C as child of A
        a_index = self.setup_model.index(0, 0, QModelIndex())
        # b_index = self.setup_model.index(0, 0, QModelIndex())
        if not self.setup_model.insert_setup('C', 'Setup C', self._project, 0, a_index):
            logging.error("Adding C to model failed")
            return
        # Add B as child of A
        if not self.setup_model.insert_setup('B', 'Setup B', self._project, 0, a_index):
            logging.error("Adding B to model failed")
            return
        # Add D as child of C
        c_index = self.setup_model.index(1, 0, a_index)  # C is on second row now
        if not self.setup_model.insert_setup('D', 'Setup D', self._project, 0, c_index):
            logging.error("Adding D to model failed")
            return
        # Add another Base
        if not self.setup_model.insert_setup('E', 'Another base setup', self._project, 0):
            logging.error("Adding Base Setup 'E' failed")
            return
        # Add tool 'magic' to setup 'C'
        # c_index = self.setup_model.index(1, 0, a_index)
        # c = self.setup_model.get_setup(c_index)
        # if not c.add_tool(tool, 'MIP=CPLEX'):
        #     self.add_err_msg_signal.emit("Adding 'magic' tool to 'C' failed\n")
        #     logging.error("Adding a model to Setup failed")
        #     return

    @pyqtSlot(str, int)
    def add_msg(self, msg, code=0):
        """Writes given message to main textBrowser.

        Args:
            msg (str): String written to TextBrowser
            code (int): Code for text color, 0: regular, 1=green, 2=red
        """
        old_color = self.ui.textBrowser_main.textColor()
        if code == 1:
            self.ui.textBrowser_main.setTextColor(SUCCESS_COLOR)
        elif code == 2:
            self.ui.textBrowser_main.setTextColor(ERROR_COLOR)
        self.ui.textBrowser_main.append(msg)
        self.ui.textBrowser_main.setTextColor(old_color)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str)
    def add_err_msg(self, message):
        """Writes given error message to main textBrowser with error text color.

        Args:
            message (str): The error message to be written.
        """
        old_color = self.ui.textBrowser_main.textColor()
        self.ui.textBrowser_main.setTextColor(ERROR_COLOR)
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

    def test_match(self):
        """Test method for finding an item based on a string."""
        value = 'base'
        start_index = self.setup_model.index(0, 0, QModelIndex())
        if not start_index.isValid():
            self.add_msg_signal.emit("No items in QTreeView", 0)
            return
        ret_index_list = self.setup_model.match(
            start_index, Qt.DisplayRole, value, 1, Qt.MatchFixedString | Qt.MatchRecursive)
        if len(ret_index_list) > 0:
            for ind in ret_index_list:
                self.add_msg_signal.emit("Found '%s' in %s" % (value, ind.internalPointer().name), 0)
        else:
            self.add_msg_signal.emit("'%s' not found" % value, 0)

    def print_tree(self):
        """Print Setup tree model."""
        root_print = self.setup_model.get_root().log()
        logging.debug("Setup tree:\n%s" % root_print)

    def traverse_model(self):
        """Print Setup tree model."""
        def traverse(item):
            logging.debug("\t" * traverse.level + item.name)
            for kid in item.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from root
        traverse(self._root)

    @pyqtSlot("QModelIndex")
    def update_tool_view(self, index):
        """Update tool name of selected Setup to tool QListView.

        Args:
            index (QModelIndex): Index of selected item.
        """
        if not index.isValid():
            return
        self.tool_proxy_model.emit_data_changed()

    def closeEvent(self, event):
        """Method for handling application exit.

        Args:
             event (QEvent): PyQt event
        """
        # Remove working files
        # TODO: Fix this
        # for _, setup in self._setups.items():
        #    setup.cleanup()
        logging.debug("See you later.")
        # if self.setup_popup:
        #     self.setup_popup = None
        # noinspection PyArgumentList
        QApplication.quit()
