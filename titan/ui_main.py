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
from PyQt5.QtWidgets import QMainWindow, QApplication, QMessageBox, QFileDialog, QCheckBox
from ui.main import Ui_MainWindow
from project import SceletonProject
from models import SetupModel, ToolModel
from tool import Setup
from tools import create_dir, copy_files, create_output_dir_timestamp
from GAMS import GAMSModel
from config import ERROR_COLOR, SUCCESS_COLOR, PROJECT_DIR, \
                   WORK_DIR, CONFIGURATION_FILE, GENERAL_OPTIONS
from configuration import ConfigurationParser
from widgets.setup_form_widget import SetupFormWidget
from widgets.project_form_widget import ProjectFormWidget
from widgets.context_menu_widget import ContextMenuWidget
from widgets.edit_tool_widget import EditToolWidget
from widgets.settings_widget import SettingsWidget
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
        self._config = None
        self._project = None
        self._running_setup = None
        self._root = None  # Root node for SetupModel
        self.setup_model = None
        self.tool_model = None
        self.modeltest = None
        self.exec_mode = ''
        self.output_dir_timestamp = ''
        # References for widgets
        self.setup_form = None
        self.project_form = None
        self.context_menu = None
        self.edit_tool_form = None
        self.settings_form = None
        # Initialize general things
        self.init_conf()
        self.connect_signals()
        # Initialize project
        self.init_project()
        # Initialize ToolModel
        self.init_tool_model()

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
        self.ui.actionSettings.triggered.connect(self.show_settings)
        self.ui.actionQuit.triggered.connect(self.closeEvent)
        # Widgets
        self.ui.pushButton_execute_all.clicked.connect(self.execute_all)
        self.ui.pushButton_execute_branch.clicked.connect(self.execute_branch)
        self.ui.pushButton_execute_single.clicked.connect(self.execute_single)
        self.ui.pushButton_delete_setup.clicked.connect(self.delete_selected_setup)
        self.ui.pushButton_delete_all.clicked.connect(self.delete_all)
        self.ui.pushButton_clear_titan_output.clicked.connect(lambda: self.ui.textBrowser_main.clear())
        self.ui.pushButton_clear_gams_output.clicked.connect(lambda: self.ui.textBrowser_process_output.clear())
        self.ui.pushButton_test.clicked.connect(self.traverse_model)
        self.ui.pushButton_clear_ready_selected.clicked.connect(self.clear_selected_ready_flag)
        self.ui.pushButton_clear_ready_all.clicked.connect(self.clear_all_ready_flags)
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)
        self.ui.treeView_setups.customContextMenuRequested.connect(self.context_menu_configs)
        self.ui.toolButton_add_tool.clicked.connect(self.add_tool)
        self.ui.toolButton_remove_tool.clicked.connect(self.remove_tool)

    def init_models(self):
        """Create data models for GUI views."""
        # Root for SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        # Create model for Setups
        self.setup_model = SetupModel(self._root)
        # Set SetupModel to QTreeView
        self.ui.treeView_setups.setModel(self.setup_model)
        # Initialize Tool model
        self.init_tool_model()
        # Start model test for SetupModel
        # self.modeltest = ModelTest(self.setup_model, self._root)

    def init_tool_model(self):
        """Create model for tools"""
        self.tool_model = ToolModel()
        tool_defs = self._config.get('general', 'tools').split('\n')
        for tool_def in tool_defs:
            if tool_def == '':
                continue
            # Load tool definition
            tool = GAMSModel.load(tool_def, self)
            if not tool:
                logging.error("Failed to load Tool from path '{0}'".format(tool_def))
                self.add_msg_signal.emit("Failed to load Tool from path '{0}'".format(tool_def), 2)
                continue
            # Add tool definition file path to tool instance variable
            tool.set_def_path(tool_def)
            # Insert tool into model
            self.tool_model.insertRow(tool)
        # Set ToolModel to available Tools view
        self.ui.listView_tools.setModel(self.tool_model)

    def init_conf(self):
        """Initialize configuration file."""
        self._config = ConfigurationParser(CONFIGURATION_FILE, defaults=GENERAL_OPTIONS)
        self._config.load()

    def init_project(self):
        """Initializes project at Sceleton start-up. Loads the last project that was open
        when Sceleton was closed or if Sceleton is started for the first time, then start
        without a project.
        """
        # Get the path of the project file from the configuration file
        project_file_path = self._config.get('general', 'project_path')
        if not os.path.isfile(project_file_path):
            # logging.debug("Previous project not found")
            return
        if not self.load_project(project_file_path):
            logging.error("Loading project failed. File: %s" % project_file_path)
        return

    def clear_ui(self):
        """Clear UI when starting a new project or loading a project."""
        # Clear Setup Model
        if self._root:
            self.delete_all_no_confirmation()
        self._root = None
        self.setup_model = None
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
        self.init_models()
        self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
        self.add_msg_signal.emit("Started project '{0}'".format(self._project.name), 0)
        # Create and save project file to disk
        self.save_project()

    def save_project_as(self):
        """Save Setups in project to disk. Ask file name from user."""
        # noinspection PyCallByClass, PyTypeChecker
        dir_path = QFileDialog.getSaveFileName(self, 'Save project', PROJECT_DIR, 'JSON (*.json)')
        file_path = dir_path[0]
        if file_path == '':  # Cancel button clicked
            self.add_msg_signal.emit("Saving project Canceled", 0)
            logging.debug("Saving canceled")
            return
        # Create new project
        file_name = os.path.split(file_path)[-1]
        proj_name = os.path.splitext(file_name)[0]
        proj_desc = ''
        self.create_project(proj_name, proj_desc)

    def save_project(self):
        """Save Setups in project to disk. Use project name as file name."""
        if not self._project:
            # If project is not found, create a new one before continuing
            msg = 'No project open. Create a new one?'
            # noinspection PyCallByClass, PyTypeChecker
            answer = QMessageBox.question(self, 'No Project', msg, QMessageBox.Yes, QMessageBox.No)
            if answer == QMessageBox.Yes:
                logging.debug("Creating a new project")
                self.new_project()
                return
            else:
                return
        # Use project name as file name
        file_path = os.path.join(PROJECT_DIR, '{}.json'.format(self._project.short_name))
        self.add_msg_signal.emit("Saving project -> {0}".format(file_path), 0)
        self._project.save(file_path, self._root)
        msg = "Project '%s' saved to file'%s'" % (self._project.name, file_path)
        self.ui.statusbar.showMessage(msg, 7000)
        self.add_msg_signal.emit("Done", 1)

    def load_project(self, load_path=None):
        """Load project from file in JSON format.

        Args:
            load_path (str): If not None, this method is used to load the
            previously opened project at start-up
        """
        if not load_path:
            # noinspection PyCallByClass, PyTypeChecker
            answer = QFileDialog.getOpenFileName(self, 'Load project', PROJECT_DIR, 'JSON (*.json)')
            load_path = answer[0]
            if load_path == '':  # Cancel button clicked
                self.add_msg_signal.emit("Loading canceled", 0)
                return False
        self.add_msg_signal.emit("Loading project from file: <{0}>".format(load_path), 0)
        if not os.path.isfile(load_path):
            self.add_msg_signal.emit("File not found '%s'" % load_path, 2)
            return False
        try:
            with open(load_path, 'r') as fh:
                dicts = json.load(fh)
        except OSError:
            self.add_msg_signal.emit("OSError: Could not load file '{}'".format(load_path), 2)
            return False
        # Initialize UI
        self.clear_ui()
        # Parse project info
        project_dict = dicts['project']
        proj_name = project_dict['name']
        proj_desc = project_dict['desc']
        # Create project
        self._project = SceletonProject(proj_name, proj_desc)
        # Setup models and views
        self.init_models()
        self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
        self.add_msg_signal.emit("Loading project '{0}'".format(self._project.name), 0)
        # Parse Setups
        setup_dict = dicts['setups']
        if len(setup_dict) == 0:
            self.add_msg_signal.emit("No Setups found in project file '{}'".format(load_path), 0)
            return True
        self._project.parse_setups(setup_dict, self.setup_model, self.tool_model, self)
        msg = "Project '%s' loaded" % self._project.name
        self.ui.statusbar.showMessage(msg, 10000)
        self.add_msg_signal.emit("Done", 1)
        return True

    def add_tool(self):
        """Method to add a new tool from a JSON tool definition file to the
        ToolModel instance (available tools). Opens a load dialog
        where user can select the wanted tool definition file. The path of the
        definition file will be saved to titan.conf, so that it is found on
        the next startup.
        """
        # noinspection PyCallByClass, PyTypeChecker
        answer = QFileDialog.getOpenFileName(self, 'Select tool definition file',
                                             os.path.join(PROJECT_DIR, os.path.pardir),
                                             'JSON (*.json)')
        if answer[0] == '':  # Cancel button clicked
            return
        open_path = os.path.abspath(answer[0])
        if not os.path.isfile(open_path):
            self.add_msg_signal.emit("Tool definition file path not valid '%s'" % open_path, 2)
            return
        self.add_msg_signal.emit("Adding Tool from file: <{0}>".format(open_path), 0)
        # Load tool definition
        tool = GAMSModel.load(open_path, self)
        if not tool:
            self.add_msg_signal.emit("Adding Tool failed".format(open_path), 2)
            return
        if not self.tool_model.find_tool(tool.name):
            # Add definition file path into tool
            tool.set_def_path(open_path)
            # Insert tool into model
            self.tool_model.insertRow(tool)
            # self.tool_model.emit_data_changed()
            # Add path to config file
            old_string = self._config.get('general', 'tools')
            new_string = old_string + '\n' + open_path
            self._config.set('general', 'tools', new_string)
            self._config.save()
            self.add_msg_signal.emit("Done", 1)
        else:
            # Tool already in model
            self.add_msg_signal.emit("Tool '{0}' already available".format(tool.name), 0)
            return

    def remove_tool(self):
        """Removes a tool from the ToolModel. Also removes the JSON
        tool definition file path from the configuration file.
        """
        try:
            index = self.ui.listView_tools.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            logging.debug("No Tool selected")
            return
        if not index.isValid():
            logging.debug("Index not valid")
            return
        if index.row() == 0:
            # Do not remove No Tool option
            self.add_msg_signal.emit("'No Tool' cannot be removed", 0)
            return
        sel_tool = self.tool_model.tool(index.row())
        tool_def_path = sel_tool.def_file_path
        self.add_msg_signal.emit("Removing tool: {0}\nDefinition file path: {1}"
                                 .format(sel_tool.name, tool_def_path), 0)
        old_tool_paths = self._config.get('general', 'tools')
        if tool_def_path in old_tool_paths:
            if not self.tool_model.removeRow(index.row()):
                self.add_msg_signal("Error in removing Tool {0}".format(sel_tool.name), 2)
                return
            new_tool_paths = old_tool_paths.replace('\n' + tool_def_path, '')
            # self.add_msg_signal.emit("Old tools string:{0}".format(old_tool_paths), 0)
            # self.add_msg_signal.emit("New tools string:{0}".format(new_tool_paths), 0)
            self._config.set('general', 'tools', new_tool_paths)
            self._config.save()
            self.add_msg_signal.emit("Done", 1)
        else:
            self.add_msg_signal.emit("Path ({0}) not found in configuration file."
                                     " Remove the path manually and restart Sceleton".format(tool_def_path), 0)
            return

    def context_menu_configs(self, pos):
        """Context menu for Setup QTreeView.

        Args:
            pos (int): Received from the customContextMenuRequested
            signal. Contains mouse position.
        """
        ind = self.ui.treeView_setups.indexAt(pos)
        global_pos = self.ui.treeView_setups.mapToGlobal(pos)
        self.context_menu = ContextMenuWidget(self, global_pos, ind)
        option = self.context_menu.get_action()
        if option == "Add Child":
            self.open_setup_form(ind)
            return
        elif option == "Add New Base":
            self.open_setup_form()
            return
        elif option == "Show Input":
            selected_setup = ind.internalPointer()
            setup_name = selected_setup.name
            tool = selected_setup.tool
            if tool:
                input_files = selected_setup.get_input_files()
                self.add_msg_signal.emit("Showing input files for Setup '%s'\nInput folder: %s"
                                         % (setup_name, selected_setup.input_dir), 0)
                self.add_msg_signal.emit("Input files:\n{0}".format(input_files), 0)
            else:
                self.add_msg_signal.emit("No tool found", 0)
            return
        elif option == "Edit Tool":
            self.open_edit_tool_form(ind)
            return
        elif option == "Execute":
            self.execute_single()
            return
        elif option == "Execute Branch":
            self.execute_branch()
            return
        elif option == "Execute Project":
            self.execute_all()
            return
        elif option == "Clear Ready Flag":
            self.clear_selected_ready_flag()
            return
        else:
            # No option selected
            pass
        self.context_menu.deleteLater()
        self.context_menu = None

    @pyqtSlot("QModelIndex")
    def open_setup_form(self, index=QModelIndex()):
        """Show Setup creation form.

        Args:
            index (QModelIndex): Parent index of the new Setup
        """
        if not self._project:
            # If project is not found, create a new one or load before continuing
            msg = 'Adding Setups requires a project.\nLoad an existing project (Yes)\nor create a new one (No)?'
            # noinspection PyCallByClass, PyTypeChecker
            answer = QMessageBox.question(self, 'Project Needed', msg, QMessageBox.Yes, QMessageBox.No)
            if answer == QMessageBox.Yes:
                logging.debug("Loading a project")
                self.load_project()
                return
            elif answer == QMessageBox.No:
                logging.debug("Creating a new project")
                self.new_project()
                return
            else:
                logging.debug("Project creation canceled")
                return
        if index is False:  # Happens when 'Add Base' button is pressed
            index = QModelIndex()
        self.setup_form = SetupFormWidget(self, index)
        self.setup_form.show()

    @pyqtSlot("QModelIndex")
    def open_edit_tool_form(self, index=QModelIndex()):
        """Show Edit Tool form.

        Args:
            index (QModelIndex): Index of the edited Setup
        """
        self.edit_tool_form = EditToolWidget(self, index)
        self.edit_tool_form.show()

    @pyqtSlot()
    def show_settings(self):
        """Show settings window."""
        self.settings_form = SettingsWidget(self, self._config)
        self.settings_form.show()

    def edit_tool(self, setup, tool, cmdline_args):
        """Change the Tool associated with Setup.

        Args:
            setup (Setup): Setup whose Tool is edited
            tool (Tool): Tool that replaces current one
            cmdline_args (str): Command line arguments for the tool

        Returns:
            Boolean value depending on operation success
        """
        # Add tool to Setup
        if tool is not None:
            # setup_index = self.setup_model.find_index(name)
            # setup = self.setup_model.get_setup(setup_index)
            self.add_msg_signal.emit("Changing Tool '%s' for Setup '%s'" % (tool.name, setup.name), 0)
            setup.detach_tool()
            setup.attach_tool(tool, cmdline_args=cmdline_args)
        else:
            self.add_msg_signal.emit("Removing Tool from Setup '%s'" % setup.name, 0)
            setup.detach_tool()
        self.setup_model.emit_data_changed()
        return True

    def add_setup(self, name, description, tool, cmdline_args, parent=QModelIndex()):
        """Insert new Setup into SetupModel.

        Args:
            name (str): Setup name
            description (str): Setup description
            tool (Tool): Tool of Setup
            cmdline_args (str): Command line arguments used with tool
            parent (QModelIndex): Parent Setup index
        """
        if name == '':
            self.add_msg_signal.emit("No name given. Try again.", 0)
            return
        if not parent.isValid():
            logging.debug("Inserting Base")
            if not self.setup_model.insert_setup(name, description, self._project, 0):
                logging.error("Adding base Setup failed")
                return
        else:
            logging.debug("Inserting Child")
            if not self.setup_model.insert_setup(name, description, self._project, 0, parent):
                logging.error("Adding child Setup failed")
                return
        # Add tool to Setup
        if tool is not None:
            setup_index = self.setup_model.find_index(name)
            setup = self.setup_model.get_setup(setup_index)
            setup.attach_tool(tool, cmdline_args=cmdline_args)
        return

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

    def execute_single(self):
        """Execute selected Setup."""
        self.exec_mode = 'single'
        self.execute_setup()

    def execute_branch(self):
        """Starts executing a Setup branch."""
        self.exec_mode = 'branch'
        self.execute_setup()

    def execute_all(self):
        """Starts executing all Setups in the project."""
        self.exec_mode = 'all'
        self.execute_setup()

    def execute_setup(self):
        """Start executing Setups according to the selected execution mode."""
        if self.ui.radioButton_depth_first.isChecked():
            self.add_msg_signal.emit("Depth-first algorithm not implemented yet.", 0)
            return
        # Create a new timestamp for this execution run
        self.output_dir_timestamp = create_output_dir_timestamp()
        if self.exec_mode == 'single':
            # Execute a single selected Setup
            selected_setup = self.get_selected_setup_index()
            # Check if no Setup selected
            if not selected_setup:
                self.add_msg_signal.emit("No Setup selected.\n", 0)
                return
            self._running_setup = selected_setup.internalPointer()
        elif self.exec_mode == 'branch':
            # Set index of base Setup for the model
            base = self.get_selected_setup_base_index()
            # Check if no Setup selected
            if not base:
                self.add_msg_signal.emit("No Setup selected.\n", 0)
                return
            self.setup_model.set_base(base)
            # Set Base Setup as the first running Setup
            self._running_setup = self.setup_model.get_base().internalPointer()
        elif self.exec_mode == 'all':
            if not self._project:
                self.add_msg_signal.emit("Open a Project to execute Setups\n", 0)
                return
            if self._root.child_count() == 0:
                self.add_msg_signal("No Setups to execute", 0)
                return
            self.add_msg_signal.emit("Executing all Setups in Project '{0}'\n".format(self._project.name), 0)
            # Get the first base that is not ready. Set the next one in setup_done()
            base_name = ''
            for i in range(self._root.child_count()):
                if not self._root.child(i).is_ready:
                    base_name = self._root.child(0).name
                    break
            if base_name == '':
                self.add_msg_signal.emit("All base Setups ready. Clear ready flags"
                                         " or try executing individual Setups", 0)
                return
            base_index = self.setup_model.find_index(base_name)
            self.setup_model.set_base(base_index)
            self._running_setup = self.setup_model.get_base().internalPointer()
            # logging.debug("running_setup name: %s" % self._running_setup.name)
        else:
            self.add_msg_signal.emit("Execution mode not recognized", 2)
            return
        # Connect setup_finished_signal to setup_done slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("\nStarting Setup '%s'" % self._running_setup.name, 0)
        self._running_setup.execute(self)

    @pyqtSlot()
    def setup_done(self):
        """Start executing next Setup or end run if all Setups are done."""
        logging.debug("Setup <{0}> finished".format(self._running_setup.name))
        # Emit dataChanged signal to QtreeView because is_ready has been updated
        self.setup_model.emit_data_changed()
        # Disconnect signal to make sure it is not connected to multiple Setups
        try:
            self._running_setup.setup_finished_signal.disconnect()
        except TypeError:  # Just in case
            # logging.warning("setup_finished_signal not connected")
            pass
        if not self._running_setup.is_ready:
            self.add_msg_signal.emit("Setup '{0}' failed".format(self._running_setup.name), 2)
            return
        self.add_msg_signal.emit("Setup '%s' ready" % self._running_setup.name, 1)
        self.add_msg_signal.emit("Output folder: {0}".format(self._running_setup.output_dir), 0)
        # Collect output files into permanent result directories
        self.collect_results()
        # Clear running Setup
        self._running_setup = None
        if self.exec_mode == 'single':
            self.add_msg_signal.emit("Done", 1)
            return
        # Get next executed Setup
        next_setup = self.setup_model.get_next_setup(breadth_first=True)
        if not next_setup:
            if self.exec_mode == 'branch':
                logging.debug("All Setups ready")
                self.add_msg_signal.emit("All Setups ready", 1)
                return
            elif self.exec_mode == 'all':
                self.add_msg_signal.emit("Looking for a new base Setup", 0)
                # Get the first base Setup that is not ready
                for i in range(self._root.child_count()):
                    if not self._root.child(i).is_ready:
                        new_base_name = self._root.child(i).name
                        new_base_index = self.setup_model.find_index(new_base_name)
                        self.setup_model.set_base(new_base_index)
                        next_setup = self.setup_model.get_base()
                        self.add_msg_signal.emit("Found base Setup '{0}'".format(next_setup.internalPointer().name), 0)
                        break
                if not next_setup:
                    self.add_msg_signal.emit("All Setups in Project ready", 1)
                    return
        self._running_setup = next_setup.internalPointer()
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("Starting Setup '%s'" % self._running_setup.name, 0)
        # Connect setup_finished_signal to this same slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        self._running_setup.execute(self)

    def collect_results(self):
        """Collect output files into result directories
        that are unique for each run."""
        if not self._running_setup.tool:
            # No Tool
            self.add_msg_signal.emit("No Tool. No results to collect", 0)
            return
        result_path = create_dir(os.path.abspath(os.path.join(
            self._running_setup.output_dir, self._running_setup.short_name + self.output_dir_timestamp)))
        self.add_msg_signal.emit("Collecting results to folder {0}".format(result_path), 0)
        if result_path:
            copy_files(self._running_setup.output_dir, result_path)
        else:
            self.add_msg_signal("Error collecting results to folder {0}".format(result_path), 2)
        return

    def clear_selected_ready_flag(self):
        """Clears ready flag for the selected Setup."""
        index = self.get_selected_setup_index()
        if not index:
            self.add_msg_signal.emit("No Setup selected", 0)
            return
        setup = index.internalPointer()
        if not setup.is_ready:
            self.add_msg_signal.emit("Selected Setup not ready", 0)
            return
        setup.is_ready = False
        self.setup_model.emit_data_changed()
        self.add_msg_signal.emit("Ready flag for Setup '{0}' cleared".format(setup.name), 0)
        return

    def clear_all_ready_flags(self):
        """Clear ready flag for all Setups in the project."""
        if not self._project:
            self.add_msg_signal("No project open", 0)
            return

        def traverse(setup):
            # Helper function to traverse tree
            if not setup.name == 'root':
                if setup.is_ready:
                    setup.is_ready = False
            for kid in setup.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from root
        if not self._root:
            self.add_msg_signal.emit("No Setups in project", 0)
        else:
            traverse(self._root)
        self.setup_model.emit_data_changed()
        self.add_msg_signal.emit("All ready flags cleared", 0)
        return

    def get_selected_setup_index(self):
        """Returns the index of the selected Setup or None if
         nothing is selected or index is not valid."""
        try:
            index = self.ui.treeView_setups.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return None
        if not index.isValid():
            return None
        return index

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
            # base == setup
            base_index = index
        else:
            # base == setup.parent()
            base_index = index.parent()
            while base_index.internalPointer().parent().name is not 'root':
                # base == base.parent()
                base_index = base_index.parent()
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
        if not self._root:
            logging.debug("No Setups in SetupModel")
            return
        traverse(self._root)

    def test_msgbox(self):
        msg = QMessageBox()
        msg.setIcon(QMessageBox.Question)
        msg.setWindowTitle("Quitting Sceleton")
        msg.setText("Exit Sceleton?")
        msg.setInformativeText("This is additional information")
        msg.setDetailedText("The details are as follows:")
        msg.setStandardButtons(QMessageBox.Ok | QMessageBox.Cancel)
        chkbox = QCheckBox()
        chkbox.setText("Do not ask me again")
        msg.setCheckBox(chkbox)
        retval = msg.exec_()
        chk = chkbox.checkState()
        if retval == QMessageBox.Ok:
            logging.debug("Ok selected. Checkbox state:{0}".format(chk))
        else:
            logging.debug("Cancel selected")

    def closeEvent(self, event):
        """Method for handling application exit.

        Args:
             event (QEvent): PyQt event
        """
        # Remove working files
        # TODO: Fix this
        # for _, setup in self._setups.items():
        #    setup.cleanup()
        # for dirpath, dirnames, filenames in os.walk(WORK_DIR):
        #     logging.debug("dirpath:\n{0}\ndirnames:\n{1}\nfilenames:\n{2}".format(dirpath, dirnames, filenames))

        if self._config.get('settings', 'confirm_exit') != '0':
            msg = QMessageBox()
            msg.setIcon(QMessageBox.Question)
            msg.setWindowTitle("Confirm exit")
            msg.setText("Are you sure you want to exit Sceleton?")
            msg.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
            chkbox = QCheckBox()
            chkbox.setText("Do not ask me again")
            msg.setCheckBox(chkbox)
            answer = msg.exec_()  # Show message box
            chk = chkbox.checkState()
            if answer == QMessageBox.Yes:
                logging.debug("See you later. Checkbox state:{0}".format(chk))
                # Flip check state for config file
                if chk == 0:
                    chk = '2'
                else:
                    chk = '0'
                self._config.set('settings', 'confirm_exit', chk)
                if self._project:
                    self._config.set('general', 'project_path', self._project.path)
                self._config.save()
                # noinspection PyArgumentList
                QApplication.quit()
            else:
                logging.debug("Exit cancelled")
                if event:
                    event.ignore()
                return
        else:
            logging.debug("See you later.")
            if self._project:
                self._config.set('general', 'project_path', self._project.path)
            self._config.save()
            # noinspection PyArgumentList
            QApplication.quit()
