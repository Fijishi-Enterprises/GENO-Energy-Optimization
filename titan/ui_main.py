"""
Module for main application GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
import logging
import os
import sys
import json
import shutil
from PyQt5.QtCore import pyqtSignal, pyqtSlot, QModelIndex, Qt, QTimer
from PyQt5.QtWidgets import QMainWindow, QApplication, QMessageBox, QFileDialog, QCheckBox, QTextBrowser
from ui.main import Ui_MainWindow
from project import SceletonProject
from models import SetupModel, ToolModel
from setup import Setup
from helpers import find_work_dirs, remove_work_dirs
from GAMS import GAMSModel
from config import ERROR_COLOR, BLACK_COLOR, PROJECT_DIR, \
                   WORK_DIR, CONFIGURATION_FILE, GENERAL_OPTIONS
from configuration import ConfigurationParser
from widgets.setup_form_widget import SetupFormWidget
from widgets.project_form_widget import ProjectFormWidget
from widgets.context_menu_widget import ContextMenuWidget
from widgets.edit_tool_widget import EditToolWidget
from widgets.settings_widget import SettingsWidget
from widgets.input_data_widget import InputDataWidget
from widgets.input_explorer_widget import InputExplorerWidget
from modeltest.modeltest import ModelTest
from excel_handler import ExcelHandler


class TitanUI(QMainWindow):
    """Class for application main GUI functions."""

    # Custom PyQt signals
    add_msg_signal = pyqtSignal(str, int, name="add_msg_signal")
    add_err_msg_signal = pyqtSignal(str, name="add_err_msg_signal")
    add_proc_msg_signal = pyqtSignal(str, name="add_proc_msg_signal")
    add_proc_err_msg_signal = pyqtSignal(str, name="add_proc_err_msg_signal")
    add_link_signal = pyqtSignal(str, name="add_link_signal")

    def __init__(self):
        """ Initialize GUI."""
        super().__init__()
        # Set number formatting to use user's default settings
        locale.setlocale(locale.LC_NUMERIC, '')
        # Setup the user interface from Qt Creator files
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        self.ui.splitter.setStretchFactor(1, 1)  # Set UI horizontal splitter to the left
        # Class variables
        self._config = None
        self._project = None
        self._running_setup = None
        self._root = None  # Root node for SetupModel
        self.setup_model = None
        self.tool_model = None
        self.modeltest = None
        self.exec_mode = ''
        self.algorithm = True  # Tree-traversal algorithm (True=Breadth-first, False=Depth-first)
        # References for widgets
        self.setup_form = None
        self.project_form = None
        self.context_menu = None
        self.edit_tool_form = None
        self.settings_form = None
        self.input_data_form = None
        self.input_explorer = None
        self.tool_def_textbrowser = None  # QTextBrowser to show selected tool definition file
        self.timer = QTimer(parent=self)
        # Initialize general things
        self.init_conf()
        # Set logging level according to settings
        self.set_debug_level(level=self._config.get("settings", "debug_messages"))
        self.connect_signals()
        # Initialize ToolModel
        self.init_tool_model()
        # Initialize project
        self.init_project()

    # noinspection PyMethodMayBeStatic
    def set_debug_level(self, level):
        """Control application debug messages.

        Args:
            level (str): 0: not checked, 2: checked
        """
        if level == '2':
            logging.getLogger().setLevel(level=logging.DEBUG)
            logging.debug("Logging level: All messages")
        else:
            logging.debug("Logging level: Error messages only")
            logging.getLogger().setLevel(level=logging.ERROR)

    def connect_signals(self):
        """Connect PyQt signals."""
        # Custom signals (Needs to be connected before initializing project and model)
        self.add_msg_signal.connect(self.add_msg)
        self.add_err_msg_signal.connect(self.add_err_msg)
        self.add_proc_msg_signal.connect(self.add_proc_msg)
        self.add_proc_err_msg_signal.connect(self.add_proc_err_msg)
        self.add_link_signal.connect(self.add_link)
        # Menu actions
        self.ui.actionNew.triggered.connect(self.new_project)
        self.ui.actionSave.triggered.connect(self.save_project)
        self.ui.actionSave_As.triggered.connect(self.save_project_as)
        self.ui.actionLoad.triggered.connect(self.load_project)
        self.ui.actionSettings.triggered.connect(self.show_settings)
        self.ui.actionImportData.triggered.connect(self.import_data)
        self.ui.actionInspectData.triggered.connect(self.open_inspect_form)
        self.ui.actionExplore.triggered.connect(self.show_explorer_form)
        self.ui.actionHelp.triggered.connect(lambda: self.add_msg_signal.emit("Not implemented", 0))
        self.ui.actionAbout.triggered.connect(lambda: self.add_msg_signal.emit("Not implemented", 0))
        self.ui.actionUnpack.triggered.connect(lambda: self.add_msg_signal.emit("Not implemented", 0))
        self.ui.actionPack.triggered.connect(lambda: self.add_msg_signal.emit("Not implemented", 0))
        self.ui.actionQuit.triggered.connect(self.closeEvent)
        self.ui.actionAdd_Tool.triggered.connect(self.add_tool)
        self.ui.actionRefresh_Tools.triggered.connect(self.refresh_tools)
        self.ui.actionRemove_Tool.triggered.connect(self.remove_tool)
        self.ui.actionExecuteBranch.triggered.connect(self.execute_branch)
        self.ui.actionExecuteProject.triggered.connect(self.execute_all)
        self.ui.actionStop_Execution.triggered.connect(self.terminate_execution)
        # Widgets
        self.ui.pushButton_execute_all.clicked.connect(self.execute_all)
        self.ui.pushButton_execute_branch.clicked.connect(self.execute_branch)
        self.ui.pushButton_delete_setup.clicked.connect(self.delete_selected_setup)
        self.ui.pushButton_delete_all.clicked.connect(self.delete_all)
        self.ui.pushButton_clear_titan_output.clicked.connect(lambda: self.ui.textBrowser_main.clear())
        self.ui.pushButton_clear_gams_output.clicked.connect(lambda: self.ui.textBrowser_process_output.clear())
        self.ui.pushButton_clear_ready_selected.clicked.connect(self.clear_selected_ready_flag)
        self.ui.pushButton_clear_ready_all.clicked.connect(self.clear_all_ready_flags)
        self.ui.treeView_setups.customContextMenuRequested.connect(self.context_menu_configs)
        self.ui.toolButton_add_tool.clicked.connect(self.add_tool)
        self.ui.toolButton_refresh_tools.clicked.connect(self.refresh_tools)
        self.ui.toolButton_remove_tool.clicked.connect(self.remove_tool)
        self.ui.pushButton_import_data.clicked.connect(self.import_data)
        self.ui.pushButton_inspect_data.clicked.connect(self.open_inspect_form)
        self.ui.pushButton_show_explorer.clicked.connect(self.show_explorer_form)
        self.ui.textBrowser_main.anchorClicked.connect(self.open_anchor)
        self.ui.pushButton_terminate_execution.clicked.connect(self.terminate_execution)
        # noinspection PyUnresolvedReferences
        self.timer.timeout.connect(self.update_setup_model)

    def init_models(self):
        """Create data models for GUI views."""
        # Root for SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        # Create model for Setups
        self.setup_model = SetupModel(self._root)
        # Set SetupModel to QTreeView
        self.ui.treeView_setups.setModel(self.setup_model)
        self.ui.treeView_setups.setColumnWidth(0, 150)
        self.ui.treeView_setups.setColumnWidth(1, 125)
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
            logging.debug("{0} cmdline_args: {1}".format(tool.name, tool.cmdline_args))
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
        # Connect currentChanged and doubleClicked signals to Tool QListView
        # This method creates a new Tool model, so it's signals must be reconnected
        self.ui.listView_tools.selectionModel().currentChanged.connect(self.view_tool_def)
        self.ui.listView_tools.doubleClicked.connect(self.edit_tool_def)

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
            msg = 'Could not load previous project. Project file {0} not found.'.format(project_file_path)
            self.ui.statusbar.showMessage(msg, 10000)
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
        self.add_msg_signal.emit("Started project <b>{0}</b>".format(self._project.name), 0)
        # Create and save project file to disk
        self.save_project()

    def save_project_as(self):
        """Save Setups in project to disk. Ask file name from user."""
        # noinspection PyCallByClass, PyTypeChecker
        dir_path = QFileDialog.getSaveFileName(self, 'Save project', PROJECT_DIR, 'JSON (*.json);;EXCEL (*.xlsx)')
        file_path = dir_path[0]
        if file_path == '':  # Cancel button clicked
            self.add_msg_signal.emit("Saving project Canceled", 0)
            logging.debug("Saving canceled")
            return
        # Create new save file for a project
        file_name = os.path.split(file_path)[-1]
        if not file_name.lower().endswith('.json'):
            self.add_msg_signal.emit("Only *.json files supported. Saving to Excel file not implemented.", 0)
            return
        if not self._project:
            # Create new project
            self.new_project()
        else:
            # Update project file name
            self._project.change_filename(file_name)
            # Save open project into new file
            self.save_project()
        return

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
        # file_path = os.path.join(PROJECT_DIR, '{}.json'.format(self._project.short_name))
        file_path = os.path.join(PROJECT_DIR, '{}'.format(self._project.filename))
        self.add_msg_signal.emit("Saving project -> {0}".format(file_path), 0)
        self._project.save(file_path, self._root)
        msg = "Project '%s' saved to file'%s'" % (self._project.name, file_path)
        self.ui.statusbar.showMessage(msg, 7000)
        self.add_msg_signal.emit("Done", 1)

    def load_project(self, load_path=None):
        """Load project from a JSON (.json) or from an MS Excel (.xlsx) file.

        Args:
            load_path (str): If not None, this method is used to load the
            previously opened project at start-up
        """
        if not load_path:
            # noinspection PyCallByClass, PyTypeChecker
            answer = QFileDialog.getOpenFileName(self, 'Load project', PROJECT_DIR, 'Projects (*.json *.xlsx)')
            load_path = answer[0]
            if load_path == '':  # Cancel button clicked
                self.add_msg_signal.emit("Loading canceled", 0)
                return False
        if not os.path.isfile(load_path):
            self.add_msg_signal.emit("File not found '%s'" % load_path, 2)
            return False
        if load_path.lower().endswith('.json'):
            # Load project from JSON file
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
            self.add_msg_signal.emit("Loading project <b>{0}</b> from file: {1}"
                                     .format(self._project.name, load_path), 0)
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
        elif load_path.lower().endswith('.xlsx'):
            excel_fname = os.path.split(load_path)[1]
            # Load project from MS Excel file
            wb = ExcelHandler(load_path)
            try:
                wb.load_wb()
            except OSError:
                self.add_msg_signal.emit("OSError while loading project file: {0}".format(load_path), 2)
                return
            proj_details = wb.read_project_sheet()
            if not proj_details:
                # Not a valid project Excel
                self.add_msg_signal.emit("<br/>{0} is not a valid project file. 'Project' sheet not found"
                                         .format(excel_fname), 2)
                return False
            # Initialize UI
            self.clear_ui()
            if not proj_details[0]:
                self.add_msg_signal.emit("Project name not found in Excel file. "
                                         "Add it to cell B1 on 'Project' sheet and try again.", 2)
                return
            if not proj_details[1]:
                self.add_msg_signal.emit("Project description missing. "
                                         "You can add it to cell B2 on 'Project' sheet (optional).", 0)
                proj_details[1] = ''
            # Create project
            self._project = SceletonProject(proj_details[0], proj_details[1])
            # Setup models and views
            self.init_models()
            self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
            self.add_msg_signal.emit("Loading project <b>{0}</b>".format(self._project.name), 0)
            # Parse Setups from Excel and add them to the project
            self._project.parse_excel_setups(self.setup_model, self.tool_model, wb, self)
            msg = "Project '%s' loaded" % self._project.name
            self.ui.statusbar.showMessage(msg, 10000)
            self.add_msg_signal.emit("Done", 1)
            return True
        else:
            self.add_msg_signal.emit("Not a valid project file format. (.xlsx and .json supported)", 2)

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
        self.add_msg_signal.emit("Adding Tool from file: {0}".format(open_path), 0)
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
            # Add path to config file
            old_string = self._config.get('general', 'tools')
            new_string = old_string + '\n' + open_path
            self._config.set('general', 'tools', new_string)
            self._config.save()
            self.add_msg_signal.emit("Done", 1)
        else:
            # Tool already in model
            self.add_msg_signal.emit("Tool <b>{0}</b> already available".format(tool.name), 0)
            return

    def refresh_tools(self):
        """Refresh all Tools from available tool definition files."""
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
            return
        self.add_msg_signal.emit("Refreshing Tools", 0)
        self.init_tool_model()
        # Reattach all Tools to Setups because the tool model has changed.

        def traverse(setup):
            # Helper function to traverse tree
            if not setup.name == 'root':
                if setup.tool:
                    # Find the Tool with a same name from the tool model
                    old_tool_name = setup.tool.name
                    new_tool = self.tool_model.find_tool(old_tool_name)
                    if not new_tool:
                        self.add_msg_signal.emit("Refreshing Tool <b>{0}</b> failed for Setup <b>{1}</b>".format(
                            old_tool_name, setup.name), 2)
                        setup.tool = None
                    else:
                        setup.attach_tool(new_tool, setup.cmdline_args)
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
        self.add_msg_signal.emit("Done", 1)

    def remove_tool(self):
        """Removes a tool from the ToolModel. Also removes the JSON
        tool definition file path from the configuration file.
        """
        try:
            index = self.ui.listView_tools.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            logging.debug("No Tool selected")
            self.add_msg_signal.emit("No Tool selected", 0)
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
        msg = "Removing Tool '{0}'. Are you sure?".format(sel_tool.name)
        # noinspection PyCallByClass, PyTypeChecker
        answer = QMessageBox.question(self, 'Remove Tool', msg, QMessageBox.Yes, QMessageBox.No)
        if answer == QMessageBox.Yes:
            self.add_msg_signal.emit("Removing Tool <b>{0}</b><br/>Definition file path: {1}"
                                     .format(sel_tool.name, tool_def_path), 0)
            old_tool_paths = self._config.get('general', 'tools')
            if tool_def_path in old_tool_paths:
                if not self.tool_model.removeRow(index.row()):
                    self.add_msg_signal.emit("Error in removing Tool <b>{0}</b>".format(sel_tool.name), 2)
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
        else:
            return

    def edit_tool(self, setup, tool, cmdline_args):
        """Change the Tool associated with Setup.

        Args:
            setup (Setup): Setup whose Tool is edited
            tool (Tool): Tool that replaces current one
            cmdline_args (str): Additional Setup command line arguments

        Returns:
            Boolean value depending on operation success
        """
        # Add tool to Setup
        if tool is not None:
            self.add_msg_signal.emit("Changing Tool <b>{0}</b> for Setup <b>{1}</b>".format(tool.name, setup.name), 0)
            setup.detach_tool()
            setup.attach_tool(tool, cmdline_args=cmdline_args)
        else:
            self.add_msg_signal.emit("Removing Tool from Setup <b>{0}</b>" % setup.name, 0)
            setup.detach_tool()
        self.setup_model.emit_data_changed()
        return True

    def view_tool_def(self, current, previous):
        """Show selected Tool definition file in a QTextBrowser in main window.

        Args:
            current (QModelIndex): Index of the current item
            previous (QModelIndex): Index of the previous item
        """
        if not current.isValid():
            return
        if current.row() == 0:
            if self.tool_def_textbrowser:
                self.tool_def_textbrowser.hide()
                self.ui.label_5.setText("GAMS Output")
                self.ui.textBrowser_process_output.show()
            return
        current_tool = self.tool_model.tool(current.row())
        tool_def_file_path = current_tool.def_file_path
        json_data = ''
        with open(tool_def_file_path, 'r') as fp:
            try:
                json_data = json.load(fp)
            except ValueError:
                self.add_msg_signal.emit("Tool definition file not valid: '{0}'".format(tool_def_file_path), 2)
                logging.exception("Loading JSON data failed")
                return
        # Add QTextBrowser below GAMS output QTextBrowser
        if not self.tool_def_textbrowser:
            self.tool_def_textbrowser = QTextBrowser(self)
            self.ui.verticalLayout.addWidget(self.tool_def_textbrowser)
            self.tool_def_textbrowser.append(json.dumps(json_data, sort_keys=True, indent=4))
            # Edit label
            self.ui.label_5.setText("Tool Definition File")
            self.ui.textBrowser_process_output.hide()
        else:
            self.tool_def_textbrowser.clear()
            self.tool_def_textbrowser.append(json.dumps(json_data, sort_keys=True, indent=4))
            self.tool_def_textbrowser.show()
            self.ui.label_5.setText("Tool Definition File")
            self.ui.textBrowser_process_output.hide()

    def edit_tool_def(self):
        """Open the double-clicked Tools definition file in the default (.json) text-editor."""
        try:
            index = self.ui.listView_tools.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            return
        if not index.isValid():
            return
        if index.row() == 0:
            # Do not do anything if No Tool option is double-clicked
            return
        sel_tool = self.tool_model.tool(index.row())
        tool_def_path = sel_tool.def_file_path
        # Open the tool def file in editor (only windows supported)
        if not sys.platform == 'win32':
            logging.error("This feature is not supported by your OS: ({0})".format(sys.platform))
            self.add_msg_signal.emit("This feature is not supported by your OS [{0}]".format(sys.platform), 2)
            return
        os.system('start {0}'.format(tool_def_path))
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
        elif option == "Inspect Setup Data":
            self.open_input_data_form(ind)
            return
        else:
            # No option selected
            pass
        self.context_menu.deleteLater()
        self.context_menu = None

    @pyqtSlot("QModelIndex", name="open_setup_form")
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

    @pyqtSlot("QModelIndex", name="open_edit_tool_form")
    def open_edit_tool_form(self, index=QModelIndex()):
        """Show Edit Tool form.

        Args:
            index (QModelIndex): Index of the edited Setup
        """
        self.edit_tool_form = EditToolWidget(self, index)
        self.edit_tool_form.show()

    @pyqtSlot(name="open_inspect_form")
    def open_inspect_form(self):
        """PyqtSlot for QMenu and QPushButton Widgets."""
        self.open_input_data_form(QModelIndex())

    def open_input_data_form(self, index):
        """Show Input Data form.

        Args:
            index (QModelIndex): Selected Setup Index
        """
        if not self._project:
            self.add_msg_signal.emit("No project found. Load a project or create a new project to continue.", 0)
            return
        if self._root.child_count() == 0:
            self.add_msg_signal.emit("No Setups to inspect", 0)
            return
        if not index:
            self.input_data_form = InputDataWidget(self, index, self.setup_model)
            self.input_data_form.show()
        elif not index.isValid():
            index = False
        self.input_data_form = InputDataWidget(self, index, self.setup_model)
        self.input_data_form.show()

    @pyqtSlot(name="show_explorer_form")
    def show_explorer_form(self):
        """Open input data directory explorer."""
        if not self._project:
            self.add_msg_signal.emit("No project found. Load a project or create a new project to continue.", 0)
            return
        if self._root.child_count() == 0:
            self.add_msg_signal.emit("No Setups found", 0)
            return
        self.input_explorer = InputExplorerWidget(self, self.setup_model)
        self.input_explorer.show()

    @pyqtSlot(name="show_settings")
    def show_settings(self):
        """Show settings window."""
        self.settings_form = SettingsWidget(self, self._config)
        self.settings_form.show()

    def add_setup(self, name, description, tool, cmdline_args, parent=QModelIndex()):
        """Insert new Setup into SetupModel.

        Args:
            name (str): Setup name
            description (str): Setup description
            tool (Tool): Tool of Setup
            cmdline_args (str): Additional Setup Command line arguments
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
            self.add_msg_signal.emit("No Setup selected", 0)
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
            self.add_msg_signal.emit("Setup <b>{0}</b> deleted".format(name), 0)
            self.setup_model.remove_setup(row, parent)
            return
        else:
            logging.debug("Delete canceled")
            return

    def delete_all(self):
        """Delete all Setups from model. Ask user's permission first."""
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
            return
        root_index = QModelIndex()
        n_kids = self._root.child_count()
        msg = "You are about to delete all Setups in the project.\nAre you sure?"
        # noinspection PyCallByClass, PyTypeChecker
        answer = QMessageBox.question(self, 'Delete all Setups?', msg, QMessageBox.Yes, QMessageBox.No)
        if answer == QMessageBox.Yes:
            for i in range(n_kids):
                name = self._root.child(0).name
                self.add_msg_signal.emit("Setup <b>{}</b> deleted".format(name), 0)
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
        if self.ui.radioButton_breadth_first.isChecked():
            alg = 'breadth-first'
            self.algorithm = True
        elif self.ui.radioButton_depth_first.isChecked():
            alg = 'depth-first'
            self.algorithm = False
        else:
            self.add_msg_signal.emit("No tree traversal algorithm selected", 2)
            return
        if self.exec_mode == 'single':
            # Execute a single selected Setup
            selected_setup = self.get_selected_setup_index()
            # Check if no Setup selected
            if not selected_setup:
                self.add_msg_signal.emit("No Setup selected.<br/>", 0)
                return
            self.add_msg_signal.emit("<br/>Executing a single Setup", 0)
            self._running_setup = selected_setup.internalPointer()
        elif self.exec_mode == 'branch':
            # Set index of base Setup for the model
            base = self.get_selected_setup_base_index()
            # Check if no Setup selected
            if not base:
                self.add_msg_signal.emit("No Setup selected.<br/>", 0)
                return
            self.add_msg_signal.emit("<br/>Executing Branch. Algorithm: {0}".format(alg), 0)
            self.setup_model.set_base(base)
            # Set Base Setup as the first running Setup
            self._running_setup = self.setup_model.get_base().internalPointer()
        elif self.exec_mode == 'all':
            if not self._project:
                self.add_msg_signal.emit("Open a Project to execute Setups<br/>", 0)
                return
            if self._root.child_count() == 0:
                self.add_msg_signal.emit("No Setups to execute", 0)
                return
            self.add_msg_signal.emit("<br/>Executing Project <b>{0}</b>. Algorithm: {1}"
                                     .format(self._project.name, alg), 0)
            # Get the first base that is not ready. Set the next one in setup_done()
            base_name = ''
            for i in range(self._root.child_count()):
                if not self._root.child(i).is_ready:
                    base_name = self._root.child(i).name
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
        # Disable appropriate widgets during execution
        self.toggle_gui(False)
        # Connect setup_finished_signal to setup_done slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        logging.debug("Starting Setup '{0}'".format(self._running_setup.name))
        self.add_msg_signal.emit("<br/>Starting Setup <b>{0}</b>".format(self._running_setup.name), 0)
        self._running_setup.execute(self)

    @pyqtSlot(name="setup_done")
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
            self.add_msg_signal.emit("Setup <b>{0}</b> failed".format(self._running_setup.name), 2)
            self._running_setup = None
            self.toggle_gui(True)
            return
        if not self._running_setup.tool:  # No Tool
            self.add_msg_signal.emit("No Tool. No results.", 0)
        self.add_msg_signal.emit("Setup <b>{0}</b> ready".format(self._running_setup.name), 1)
        # Clear running Setup
        self._running_setup = None
        if self.exec_mode == 'single':
            self.add_msg_signal.emit("Done", 1)
            self.toggle_gui(True)
            return
        # Get next executed Setup
        next_setup = self.setup_model.get_next_setup(breadth_first=self.algorithm)
        if not next_setup:
            if self.exec_mode == 'branch':
                logging.debug("All Setups ready")
                self.add_msg_signal.emit("All Setups ready", 1)
                self.toggle_gui(True)
                return
            elif self.exec_mode == 'all':
                # Get the first base Setup that is not ready
                for i in range(self._root.child_count()):
                    if not self._root.child(i).is_ready:
                        new_base_name = self._root.child(i).name
                        new_base_index = self.setup_model.find_index(new_base_name)
                        self.setup_model.set_base(new_base_index)
                        next_setup = self.setup_model.get_base()
                        self.add_msg_signal.emit("Found base Setup <b>{0}</b>"
                                                 .format(next_setup.internalPointer().name), 0)
                        break
                if not next_setup:
                    self.add_msg_signal.emit("All Setups in Project ready", 1)
                    self.toggle_gui(True)
                    return
        self._running_setup = next_setup.internalPointer()
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        self.add_msg_signal.emit("<br/>Starting Setup <b>{0}</b>".format(self._running_setup.name), 0)
        # Connect setup_finished_signal to this same slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        self._running_setup.execute(self)

    @pyqtSlot(name='terminate_execution')
    def terminate_execution(self):
        """Stop current Setup execution by closing the Tool QProcess."""
        # TODO: Test if sending a SIGINT (Ctrl-c) signal makes the solver return the current point
        # and the appropriate model status, with a solution status of 8 (USER INTERRUPT), and
        # the GAMS run will continue.
        if not self._running_setup:
            self.add_msg_signal.emit("No running Setup", 0)
            return
        self._running_setup.terminate_setup()
        # Enable GUI after simulation has been stopped
        self.toggle_gui(True)
        return

    def update_setup_model(self):
        """Make all views connected to setup model update themselves."""
        self.setup_model.emit_data_changed()

    def toggle_gui(self, value):
        """Enable or disable selected GUI elements that should not work when execution is in progress.

        Args:
            value (boolean): False to disable GUI, True to enable GUI
        """
        self.ui.pushButton_execute_branch.setEnabled(value)
        self.ui.pushButton_execute_all.setEnabled(value)
        self.ui.pushButton_delete_setup.setEnabled(value)
        self.ui.pushButton_delete_all.setEnabled(value)
        self.ui.pushButton_clear_ready_selected.setEnabled(value)
        self.ui.pushButton_clear_ready_all.setEnabled(value)
        self.ui.actionExecuteSingle.setEnabled(value)
        self.ui.actionExecuteBranch.setEnabled(value)
        self.ui.actionExecuteProject.setEnabled(value)
        self.ui.actionStop_Execution.setEnabled(not value)
        self.ui.pushButton_terminate_execution.setEnabled(not value)
        if value:
            # Stop the animated icon QMovie
            self.setup_model.animated_icon.stop()
            # Stop timer when simulation stops
            self.timer.stop()
        else:
            # Start the animated icon QMovie
            self.setup_model.animated_icon.start()
            # Start timer when simulation starts. Updates the animated icon.
            self.timer.start(100)
        self.update_setup_model()

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
        self.add_msg_signal.emit("Ready flag for Setup <b>{0}</b> cleared".format(setup.name), 0)
        return

    def clear_all_ready_flags(self):
        """Clear ready flag for all Setups in the project."""
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
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
        self.add_msg_signal.emit("Finding next generation of Setup <b>{0}</b>".format(setup.name), 0)
        for ind in next_gen:
            self.add_msg_signal.emit("Setup <b>{0}</b> on next row".format(ind.internalPointer().name), 0)

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

    def import_data(self):
        """Open selected Excel file for creating text data files for Setups."""
        # noinspection PyCallByClass, PyTypeChecker
        answer = QFileDialog.getOpenFileName(self, 'Select Input Data File', PROJECT_DIR, 'MS Excel (*.xlsx)')
        load_path = answer[0]
        if load_path == '':  # Cancel button clicked
            return
        self.add_msg_signal.emit("<br/>Importing data from file: {0}".format(load_path), 0)
        if not os.path.isfile(load_path):
            self.add_msg_signal.emit("File not found '{0}'".format(load_path), 2)
            return
        # Load project from MS Excel file
        wb = ExcelHandler(load_path)
        try:
            wb.load_wb()
        except OSError:
            self.add_msg_signal.emit("OSError while loading file {0}".format(load_path), 2)
            return
        # Read data
        self._project.make_data_files(self.setup_model, wb, self)
        return True

    @pyqtSlot(str, int, name="add_msg")
    def add_msg(self, msg, code=0):
        """Writes given message to main textBrowser.

        Args:
            msg (str): String written to QTextBrowser
            code (int): Code for text color, 0: black, 1=green, 2=red
        """
        if code == 1:
            open_tag = "<span style='color:green'>"
        elif code == 2:
            open_tag = "<span style='color:red'>"
        else:
            open_tag = "<span style='color:black'>"
        message = open_tag + msg + "</span>"
        self.ui.textBrowser_main.append(message)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str, name="add_err_msg")
    def add_err_msg(self, message):
        """Writes given error message to main textBrowser with error text color.
        Note: Not in use at the moment.

        Args:
            message (str): The error message to be written.
        """
        self.ui.textBrowser_main.setTextColor(ERROR_COLOR)
        self.ui.textBrowser_main.append(message)
        self.ui.textBrowser_main.setTextColor(BLACK_COLOR)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str, name="add_proc_msg")
    def add_proc_msg(self, msg):
        """Writes given message to process output textBrowser.

        Args:
            msg (str): String written to QTextBrowser
        """
        self.ui.textBrowser_process_output.append(msg)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str, name="add_proc_err_msg")
    def add_proc_err_msg(self, msg):
        """Writes given message to process output textBrowser.

        Args:
            msg (str): Error message written to QTextBrowser
        """
        self.ui.textBrowser_process_output.setTextColor(ERROR_COLOR)
        self.ui.textBrowser_process_output.append(msg)
        self.ui.textBrowser_process_output.setTextColor(BLACK_COLOR)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot(str, name="add_link")
    def add_link(self, html_link):
        """Add link as an HTML <a> tag to textbrowser.

        Args:
            html_link (str): Link to the result folder embedded in a HTML <a> tag
        """
        self.ui.textBrowser_main.append(html_link)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot("QUrl", name="open_anchor")
    def open_anchor(self, qurl):
        """Starts Gamside or opens Windows Explorer in the given directory depending on the contents of qurl.

        Args:
            qurl (QUrl): gamside.exe command or a result directory embedded into an anchor.
        """
        cmd = qurl.toLocalFile()  # Either a path to result folder or a command to open gamside.exe
        if not os.path.isdir(cmd):
            # cmd is a command to open gamside.exe with the included project file
            # This all is just to remove '/' from the beginning of cmd
            split_cmd = cmd.split(' ')  # Split command into a list
            first_item = split_cmd.pop(0)  # Pop first part from list.
            if first_item[0] == '/':
                # first_item is '/gamside.exe'
                first_item = os.path.basename(first_item)  # Get rid of extra '/' in front of gamside.exe
            # Construct the cmd again
            cmd = first_item + ' ' + ' '.join(split_cmd)
        if not sys.platform == 'win32':
            logging.error("This feature is not supported by your OS: ({0})".format(sys.platform))
            self.add_msg_signal.emit("This feature is not supported by your OS [{0}]".format(sys.platform), 2)
            return
        logging.debug("start {}".format(cmd))
        os.system('start {}'.format(cmd))
        return

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

    def show_confirm_exit(self):
        """Shows confirm exit message box.

        Returns:
            True if user clicks Yes or False if exit is cancelled
        """
        ex = self._config.get('settings', 'confirm_exit')
        if ex != '0':
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
                # Flip check state for saving into conf file
                if chk == 0:
                    chk = '2'
                else:
                    chk = '0'
                self._config.set('settings', 'confirm_exit', chk)
                return True
            else:
                return False
        return True

    def show_save_project_prompt(self):
        """Shows the save project message box when exiting Sceleton."""
        save_at_exit = self._config.get('settings', 'save_at_exit')
        if save_at_exit == '0':
            # Don't save project and don't show message box
            logging.debug("Project changes not saved")
            return
        elif save_at_exit == '1':  # Default
            # Show message box
            msg = QMessageBox()
            msg.setIcon(QMessageBox.Question)
            msg.setWindowTitle("Save project")
            msg.setText("Save changes to project?")
            msg.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
            chkbox = QCheckBox()
            chkbox.setText("Do not ask me again")
            msg.setCheckBox(chkbox)
            answer = msg.exec_()
            chk = chkbox.checkState()
            if answer == QMessageBox.Yes:
                logging.debug("Saving project")
                self.save_project()
                if chk == 2:
                    # Save preference into config file
                    self._config.set('settings', 'save_at_exit', '2')
            else:
                logging.debug("Project changes not saved")
                if chk == 2:
                    # Save preference into config file
                    self._config.set('settings', 'save_at_exit', '0')
        elif save_at_exit == '2':
            # Save project and don't show message box
            logging.debug("Saving project")
            self.save_project()
        else:
            logging.debug("Unknown setting for save_at_exit. Writing default value")
            self._config.set('settings', 'save_at_exit', '1')
        return

    def show_delete_work_dirs_prompt(self):
        """Shows the delete work directories message box when exiting Sceleton."""
        # TODO: Show some kind of dialog that let's the user know when deleting is in progress
        del_dirs = self._config.get('settings', 'delete_work_dirs')
        if del_dirs == '0':
            # Don't delete work directories and don't show message box
            logging.debug("Work directories not deleted")
            return
        elif del_dirs == '1':  # Default
            # Find work directories
            dirs = find_work_dirs()
            dirs_str = '\n'.join(dirs)
            if len(dirs) == 0:
                # No work directories found, skip message box
                logging.debug("No work directories found in path {0}".format(WORK_DIR))
                return
            # Show message box
            msg = QMessageBox()
            msg.setIcon(QMessageBox.Question)
            msg.setWindowTitle("Emptying work directory")
            msg.setText("There are {0} work directories in path {1}. Would you like to delete them? "
                        "Click show details to see the paths.".format(len(dirs), WORK_DIR))
            msg.setDetailedText("These directories will be deleted:\n{0}".format(dirs_str))
            msg.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
            chkbox = QCheckBox()
            chkbox.setText("Do not ask me again")
            msg.setCheckBox(chkbox)
            answer = msg.exec_()
            chk = chkbox.checkState()
            if answer == QMessageBox.Yes:
                remove_work_dirs(dirs)
                logging.debug("Deleted {0} work directories".format(len(dirs)))
                if chk == 2:
                    # Save preference into config file
                    self._config.set('settings', 'delete_work_dirs', '2')
            else:
                logging.debug("Work directories not deleted")
                if chk == 2:
                    # Save preference into config file
                    self._config.set('settings', 'delete_work_dirs', '0')
        elif del_dirs == '2':
            # Delete work directories without prompt
            dirs = find_work_dirs()
            remove_work_dirs(dirs)
            logging.debug("Deleted {0} work directories".format(len(dirs)))
        else:
            logging.debug("Unknown setting for delete_work_dirs. Writing default value")
            self._config.set('settings', 'delete_work_dirs', '1')
        return

    def closeEvent(self, event):
        """Method for handling application exit.

        Args:
             event (QEvent): PyQt event
        """
        # Show confirm exit message box
        if not self.show_confirm_exit():
            # Exit cancelled
            logging.debug("Exit cancelled")
            if event:
                event.ignore()
            return
        # Show save project message box
        self.show_save_project_prompt()
        # Show delete work directories message box
        self.show_delete_work_dirs_prompt()
        logging.debug("See you later.")
        if self._project:
            self._config.set('general', 'project_path', self._project.path)
        self._config.save()
        # noinspection PyArgumentList
        QApplication.quit()
