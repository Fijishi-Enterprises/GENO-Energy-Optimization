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
import subprocess
from PyQt5.QtCore import pyqtSignal, pyqtSlot, QModelIndex, Qt, QTimer, QSettings
from PyQt5.QtWidgets import QMainWindow, QApplication, QMessageBox, \
                            QFileDialog, QCheckBox, QComboBox, QAction
from PyQt5.Qt import QDesktopServices, QUrl
from ui.main import Ui_MainWindow
from project import SceletonProject
from models import SetupModel, ToolModel
from setup import Setup
from helpers import find_work_dirs, erase_dir, \
                    busy_effect, project_dir
from config import ERROR_COLOR, BLACK_COLOR, \
                   DEFAULT_WORK_DIR, CONFIGURATION_FILE,\
                   GENERAL_OPTIONS, GAMSIDE_EXECUTABLE, \
                   SCELETON_VERSION, STATUSBAR_STYLESHEET
from configuration import ConfigurationParser
from delegates import SetupStyledItemDelegate
from widgets.setup_form_widget import SetupFormWidget
from widgets.project_form_widget import ProjectFormWidget
from widgets.setup_context_menu_widget import SetupContextMenuWidget
from widgets.edit_tool_widget import EditToolWidget
from widgets.settings_widget import SettingsWidget
from widgets.input_verifier_widget import InputVerifierWidget
from widgets.input_explorer_widget import InputExplorerWidget
from widgets.output_explorer_widget import OutputExplorerWidget
from widgets.about_widget import AboutWidget
from widgets.tool_context_menu_widget import ToolContextMenuWidget
from widgets.progressbar_dialog_widget import ProgressBarDialog
from modeltest.modeltest import ModelTest
from excel_handler import ExcelHandler
import widgets.toolbars


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
        super().__init__(flags=Qt.Window)
        # Set number formatting to use user's default settings
        locale.setlocale(locale.LC_NUMERIC, '')
        # Setup the user interface from Qt Designer files
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
        self.qsettings = QSettings("VTT", "Sceleton Titan")
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
        self.setup_delegate = None
        # References for widgets
        self.setup_form = None
        self.project_form = None
        self.setup_context_menu = None
        self.tool_context_menu = None
        self.edit_tool_form = None
        self.settings_form = None
        self.input_verifier_form = None
        self.input_explorer = None
        self.results_form = None
        self.about_form = None
        self.delete_progressbar = None
        # Initialize QStatusBar
        self.ui.statusbar.setStyleSheet(STATUSBAR_STYLESHEET)
        self.ui.statusbar.setFixedHeight(20)
        # Make and initialize QToolBars
        self.view_toolbar = widgets.toolbars.make_view_toolbar(self)
        self.addToolBar(Qt.RightToolBarArea, self.view_toolbar)
        self.execute_toolbar = widgets.toolbars.make_execute_toolbar(self)
        self.addToolBar(Qt.TopToolBarArea, self.execute_toolbar)
        self.tool_toolbar = widgets.toolbars.make_tool_toolbar(self)
        self.addToolBar(Qt.TopToolBarArea, self.tool_toolbar)
        self.delete_toolbar = widgets.toolbars.make_delete_toolbar(self)
        self.addToolBar(Qt.TopToolBarArea, self.delete_toolbar)
        self.clear_toolbar = widgets.toolbars.make_clear_toolbar(self)
        self.addToolBar(Qt.TopToolBarArea, self.clear_toolbar)
        self.data_toolbar = widgets.toolbars.make_data_toolbar(self)
        self.addToolBar(Qt.TopToolBarArea, self.data_toolbar)
        # Make QActions for keyboard shortcuts
        self.action_clone = QAction(self)
        self.action_clone.setShortcut("C")
        self.addAction(self.action_clone)
        # Initialize others
        self.timer = QTimer(parent=self)  # Timer for animating item decorations
        self.init_conf()  # Init conf file
        # Set logging level according to settings
        self.set_debug_level(level=self._config.get("settings", "debug_messages"))
        self.connect_signals()
        self.init_project()
        self.restore_ui()

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

    def init_conf(self):
        """Initialize configuration file."""
        self._config = ConfigurationParser(CONFIGURATION_FILE, defaults=GENERAL_OPTIONS)
        self._config.load()

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
        self.ui.actionVerifyData.triggered.connect(self.open_verifier_form)
        self.ui.actionExplore.triggered.connect(self.show_explorer_form)
        self.ui.actionResults.triggered.connect(self.show_results_form)
        self.ui.actionHelp.triggered.connect(lambda: self.add_msg_signal.emit("Not implemented", 0))
        self.ui.actionAbout.triggered.connect(self.show_about)
        self.ui.actionUnpack.triggered.connect(lambda: self.add_msg_signal.emit("Not implemented", 0))
        self.ui.actionPack.triggered.connect(lambda: self.add_msg_signal.emit("Not implemented", 0))
        self.ui.actionQuit.triggered.connect(self.closeEvent)
        self.ui.actionAdd_Tool.triggered.connect(self.add_tool)
        self.ui.actionRefresh_Tools.triggered.connect(self.refresh_tools)
        self.ui.actionRemove_Tool.triggered.connect(self.remove_tool)
        self.ui.actionExecuteSelected.triggered.connect(self.execute_selected)
        self.ui.actionExecuteProject.triggered.connect(self.execute_project)
        self.ui.actionStop_Execution.triggered.connect(self.terminate_execution)
        # Connect keyboard shortcut QActions
        self.action_clone.triggered.connect(self.clone)
        # Toolbars (Toolbar QAction signals are connected in toolbars.py)
        self.ui.actionShowResizeViewsToolbar.triggered.connect(self.set_toolbar_visibility)
        self.ui.actionShowToolToolbar.triggered.connect(self.set_toolbar_visibility)
        self.ui.actionShowExecuteToolbar.triggered.connect(self.set_toolbar_visibility)
        self.ui.actionShowDeleteToolbar.triggered.connect(self.set_toolbar_visibility)
        self.ui.actionShowClearToolbar.triggered.connect(self.set_toolbar_visibility)
        self.ui.actionShowDataToolbar.triggered.connect(self.set_toolbar_visibility)
        self.view_toolbar.visibilityChanged.connect(self.set_toolbar_menu_checkbox_states)
        self.execute_toolbar.visibilityChanged.connect(self.set_toolbar_menu_checkbox_states)
        self.tool_toolbar.visibilityChanged.connect(self.set_toolbar_menu_checkbox_states)
        self.delete_toolbar.visibilityChanged.connect(self.set_toolbar_menu_checkbox_states)
        self.clear_toolbar.visibilityChanged.connect(self.set_toolbar_menu_checkbox_states)
        self.data_toolbar.visibilityChanged.connect(self.set_toolbar_menu_checkbox_states)
        # Widgets
        self.ui.treeView_setups.customContextMenuRequested.connect(self.show_setup_context_menu)
        self.ui.listView_tools.customContextMenuRequested.connect(self.show_tool_context_menu)
        self.ui.textBrowser_main.anchorClicked.connect(self.open_anchor)
        # noinspection PyUnresolvedReferences
        self.timer.timeout.connect(self.update_setup_model)
        self.ui.tabWidget_tools.tabBar().currentChanged.connect(self.current_tab_changed)

    def restore_ui(self):
        """Restore UI state from previous session."""
        window_size = self.qsettings.value("window_size", type="QSize")
        window_pos = self.qsettings.value("window_pos", type="QPoint")
        window_state = self.qsettings.value("window_state", type="QByteArray")
        hor_splitter_state = self.qsettings.value("horizontal_splitter_state", type="QByteArray")
        left_vert_splitter_state = self.qsettings.value("left_vertical_splitter_state", type="QByteArray")
        right_vert_splitter_state = self.qsettings.value("right_vertical_splitter_state", type="QByteArray")
        # Restore UI
        if window_size:
            self.resize(window_size)
        if window_pos:
            self.move(window_pos)
        if window_state:
            self.restoreState(window_state, version=1)
        if hor_splitter_state:
            self.ui.splitter_horizontal.restoreState(hor_splitter_state)
        if left_vert_splitter_state:
            self.ui.splitter_vertical_left.restoreState(left_vert_splitter_state)
        if right_vert_splitter_state:
            self.ui.splitter_vertical_right.restoreState(right_vert_splitter_state)
        # Set check box states in the View->Toolbars menu
        if not self.view_toolbar.isVisible():
            self.ui.actionShowResizeViewsToolbar.setChecked(False)
        else:
            self.ui.actionShowResizeViewsToolbar.setChecked(True)
        if not self.execute_toolbar.isVisible():
            self.ui.actionShowExecuteToolbar.setChecked(False)
        else:
            self.ui.actionShowExecuteToolbar.setChecked(True)
        if not self.tool_toolbar.isVisible():
            self.ui.actionShowToolToolbar.setChecked(False)
        else:
            self.ui.actionShowToolToolbar.setChecked(True)
        if not self.delete_toolbar.isVisible():
            self.ui.actionShowDeleteToolbar.setChecked(False)
        else:
            self.ui.actionShowDeleteToolbar.setChecked(True)
        if not self.data_toolbar.isVisible():
            self.ui.actionShowDataToolbar.setChecked(False)
        else:
            self.ui.actionShowDataToolbar.setChecked(True)
        if not self.clear_toolbar.isVisible():
            self.ui.actionShowClearToolbar.setChecked(False)
        else:
            self.ui.actionShowClearToolbar.setChecked(True)

    @pyqtSlot(name="set_toolbar_visibility")
    def set_toolbar_visibility(self):
        """Show or hide QToolBars."""
        if self.sender().objectName() == "actionShowResizeViewsToolbar":
            if self.sender().isChecked():
                self.view_toolbar.show()
            else:
                self.view_toolbar.hide()
        elif self.sender().objectName() == "actionShowExecuteToolbar":
            if self.sender().isChecked():
                self.execute_toolbar.show()
            else:
                self.execute_toolbar.hide()
        elif self.sender().objectName() == "actionShowToolToolbar":
            if self.sender().isChecked():
                self.tool_toolbar.show()
            else:
                self.tool_toolbar.hide()
        elif self.sender().objectName() == "actionShowDeleteToolbar":
            if self.sender().isChecked():
                self.delete_toolbar.show()
            else:
                self.delete_toolbar.hide()
        elif self.sender().objectName() == "actionShowDataToolbar":
            if self.sender().isChecked():
                self.data_toolbar.show()
            else:
                self.data_toolbar.hide()
        elif self.sender().objectName() == "actionShowClearToolbar":
            if self.sender().isChecked():
                self.clear_toolbar.show()
            else:
                self.clear_toolbar.hide()
        else:
            logging.error("Unknown sender: '{0}'".format(self.sender()))

    @pyqtSlot(name="set_toolbar_menu_checkbox_states")
    def set_toolbar_menu_checkbox_states(self):
        """Set menu check box state according to toolbar visibility."""
        if self.sender().objectName() == "viewToolbar":
            if not self.view_toolbar.isVisible():
                self.ui.actionShowResizeViewsToolbar.setChecked(False)
            else:
                self.ui.actionShowResizeViewsToolbar.setChecked(True)
        elif self.sender().objectName() == "executeToolbar":
            if not self.execute_toolbar.isVisible():
                self.ui.actionShowExecuteToolbar.setChecked(False)
            else:
                self.ui.actionShowExecuteToolbar.setChecked(True)
        elif self.sender().objectName() == "toolToolbar":
            if not self.tool_toolbar.isVisible():
                self.ui.actionShowToolToolbar.setChecked(False)
            else:
                self.ui.actionShowToolToolbar.setChecked(True)
        elif self.sender().objectName() == "deleteToolbar":
            if not self.delete_toolbar.isVisible():
                self.ui.actionShowDeleteToolbar.setChecked(False)
            else:
                self.ui.actionShowDeleteToolbar.setChecked(True)
        elif self.sender().objectName() == "dataToolbar":
            if not self.data_toolbar.isVisible():
                self.ui.actionShowDataToolbar.setChecked(False)
            else:
                self.ui.actionShowDataToolbar.setChecked(True)
        elif self.sender().objectName() == "clearToolbar":
            if not self.clear_toolbar.isVisible():
                self.ui.actionShowClearToolbar.setChecked(False)
            else:
                self.ui.actionShowClearToolbar.setChecked(True)
        else:
            logging.error("Unknown sender in visibilityChanged: '{0}'".format(self.sender()))

    @pyqtSlot(name="handle_view_toolbar_actions")
    def handle_view_toolbar_actions(self):
        """Handles QActions in the Resize Views Toolbar."""
        if self.sender().objectName() == "maximize_action":
            self.ui.splitter_vertical_right.setSizes([100000, 0])  # Maximize command output tab height
        elif self.sender().objectName() == "minimize_action":
            self.ui.splitter_vertical_right.setSizes([0, 100000])  # Maximize tool output tab height
        elif self.sender().objectName() == "split_action":
            sizes = self.ui.splitter_vertical_right.sizes()  # Height of tabWidgets
            s = sum(sizes)/2
            self.ui.splitter_vertical_right.setSizes([s, s])  # Split cmd and tool output tabs evenly
        else:
            logging.error("Unknown sender: '{0}'".format(self.sender()))

    def init_models(self, tools):
        """Create data models for GUI views.

        Args:
            tools (list): List of tool definition file paths
        """
        # Root for SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        # Create model for Setups
        self.setup_model = SetupModel(self._root, self)
        # Set custom item delegate for QTreeView
        self.setup_delegate = SetupStyledItemDelegate(self)
        self.ui.treeView_setups.setItemDelegateForColumn(0, self.setup_delegate)
        # Set SetupModel to QTreeView
        self.ui.treeView_setups.setModel(self.setup_model)
        self.ui.treeView_setups.setColumnWidth(0, 160)
        self.ui.treeView_setups.setColumnWidth(1, 115)
        self.ui.treeView_setups.setColumnWidth(2, 115)
        # Initialize Tool model
        self.init_tool_model(tools)
        # Start model test for SetupModel
        # self.modeltest = ModelTest(self.setup_model, self._root)

    def init_tool_model(self, tool_def_list):
        """Initialize Tool model.

        Args:
            tool_def_list (list): List of tool definition file paths used in this project
        """
        self.tool_model = ToolModel()
        n_tools = 0
        logging.debug("Initializing Tool model")
        self.add_msg_signal.emit("Loading Tools...", 0)
        for tool_def in tool_def_list:
            if tool_def == '' or not tool_def:
                continue
            # Load tool definition
            tool = SceletonProject.load_tool(tool_def, self)
            n_tools += 1
            if not tool:
                logging.error("Failed to load Tool from path '{0}'".format(tool_def))
                continue
            # Add tool definition file path to tool instance variable
            tool.set_def_path(tool_def)
            # Insert tool into model
            self.tool_model.insertRow(tool)
            self.add_msg_signal.emit("Tool <b>{0}</b> ready".format(tool.name), 0)
        # Set ToolModel to available Tools view
        self.ui.listView_tools.setModel(self.tool_model)
        # Connect currentChanged and doubleClicked signals to Tool QListView
        # This method creates a new Tool model, so it's signals must be reconnected
        # Qt.UniqueConnection makes sure that the signal is connected only once
        try:
            self.ui.listView_tools.selectionModel().currentChanged.connect(self.view_tool_def, Qt.UniqueConnection)
        except TypeError:
            pass
        try:
            self.ui.listView_tools.doubleClicked.connect(self.edit_tool_def, Qt.UniqueConnection)
        except TypeError:
            pass
        if n_tools == 0:
            self.add_msg_signal.emit("Project has no Tools", 3)
        self.add_msg_signal.emit("Done", 1)

    def init_project(self):
        """Initializes project at Sceleton start-up. Loads the last project that was open
        when Sceleton was closed or if Sceleton is started for the first time, then start
        without a project.
        """
        # Get the path of the project file from the configuration file
        project_file_path = self._config.get('general', 'previous_project')
        if not os.path.isfile(project_file_path):
            msg = 'Could not load previous project. Project file {0} not found.'.format(project_file_path)
            self.ui.statusbar.showMessage(msg, 10000)
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

    def current_project(self):
        """Returns current project."""
        return self._project

    def new_project(self):
        """Show 'New Project' form to user to query project details."""
        self.project_form = ProjectFormWidget(self, self._config)
        self.project_form.show()

    def create_project(self, name, description):
        """Create new project and set it active.

        Args:
            name (str): Project name
            description (str): Project description
        """
        self.clear_ui()
        self._project = SceletonProject(name, description, self._config)
        tools = list()  # Start project with no Tools
        self.init_models(tools)
        self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
        self.add_msg_signal.emit("Started project <b>{0}</b>".format(self._project.name), 0)
        # Create and save project file to disk
        self.save_project()

    def save_project_as(self):
        """Save Setups in project to disk. Ask file name from user."""
        # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
        dir_path = QFileDialog.getSaveFileName(self, 'Save project', project_dir(self._config),
                                               'JSON (*.json);;EXCEL (*.xlsx)')
        file_path = dir_path[0]
        if file_path == '':  # Cancel button clicked
            self.add_msg_signal.emit("Saving project Canceled", 0)
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
                self.new_project()
                return
            else:
                return
        # Put tool definition files of all Tools used in this project into a list
        tool_list = list()
        for i in range(self.tool_model.rowCount()):
            if i > 0:
                tool_list.append(self.tool_model.tool(i).get_def_path())
        # Use project name as file name
        file_path = os.path.join(project_dir(self._config), '{}'.format(self._project.filename))
        self.add_msg_signal.emit("Saving project -> <b>{0}</b>".format(file_path), 0)
        logging.debug("Saving project -> {0}".format(file_path))
        self._project.save(file_path, self._root, tool_list)
        msg = "Project {0} saved -> {1}".format(self._project.name, file_path)
        self.ui.statusbar.showMessage(msg, 7000)
        self.add_msg_signal.emit("Done", 1)
        return

    def load_project(self, load_path=None):
        """Load project from a JSON (.json) or from an MS Excel (.xlsx) file.

        Args:
            load_path (str): If not None, this method is used to load the
            previously opened project at start-up
        """
        tools = list()  # For Tool definition file paths
        if not load_path:
            # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
            answer = QFileDialog.getOpenFileName(self, 'Load project', project_dir(self._config),
                                                 'Projects (*.json *.xlsx)')
            load_path = answer[0]
            if load_path == '':  # Cancel button clicked
                return False
        if not os.path.isfile(load_path):
            self.add_msg_signal.emit("File not found: <b>{0}</b>".format(load_path), 2)
            return False
        if load_path.lower().endswith('.json'):
            # Load project from JSON file
            try:
                with open(load_path, 'r') as fh:
                    dicts = json.load(fh)
            except OSError:
                self.add_msg_signal.emit("OSError: Could not load file <b>{0}</b>".format(load_path), 2)
                return False
            # Initialize UI
            self.clear_ui()
            # Parse project info
            project_dict = dicts['project']
            proj_name = project_dict['name']
            proj_desc = project_dict['desc']
            try:
                proj_work_dir = project_dict['work_dir']
            except KeyError:
                logging.debug("Work dir not found in project file. Using default work directory")
                proj_work_dir = DEFAULT_WORK_DIR
            try:
                tools = project_dict['tools']
            except KeyError:
                logging.debug("tools keyword not found in project file")
            # Create project
            self._project = SceletonProject(proj_name, proj_desc, self._config)
            self._project.change_work_dir(proj_work_dir)
            # Setup models and views
            self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
            self.add_msg_signal.emit("Loading project <b>{0}</b>".format(self._project.name), 0)
            self.init_models(tools)
            # Parse Setups
            self.add_msg_signal.emit("Loading Setups...", 0)
            setup_dict = dicts['setups']
            if len(setup_dict) == 0:
                self.add_msg_signal.emit("Project has no Setups", 3)
                self.add_msg_signal.emit("Done", 1)
                return True
            self._project.parse_setups(setup_dict, self.setup_model, self.tool_model, self)
            msg = "Project {0} loaded".format(self._project.name)
            self.ui.statusbar.showMessage(msg, 10000)
            self.add_msg_signal.emit("Done", 1)
            self.check_clear_flags()
            self.ui.treeView_setups.expandAll()
            self.ui.treeView_setups.resizeColumnToContents(0)
            # Add 25 to Setup column width to accommodate for decoration
            self.ui.treeView_setups.setColumnWidth(0, self.ui.treeView_setups.columnWidth(0) + 25)
            return True
        elif load_path.lower().endswith('.xlsx'):
            excel_fname = os.path.split(load_path)[1]
            # Load project from MS Excel file
            wb = ExcelHandler(load_path)
            try:
                wb.load_wb()
            except OSError:
                self.add_msg_signal.emit("OSError while loading project file: <b>{0}</b>".format(load_path), 2)
                return False
            proj_details = wb.read_project_sheet()
            if not proj_details:
                # Not a valid project Excel
                self.add_msg_signal.emit("<br/><b>{0}</b> is not a valid project file. <b>Project</b> sheet not found"
                                         .format(excel_fname), 2)
                return False
            # Initialize UI
            self.clear_ui()
            if not proj_details[0]:
                self.add_msg_signal.emit("Project name not found in Excel file. "
                                         "Add it to cell B1 on <b>Project</b> sheet and try again.", 2)
                return False
            if not proj_details[1]:
                self.add_msg_signal.emit("Project description missing. "
                                         "You can add it to cell B2 on <b>Project</b> sheet (optional).", 3)
                proj_details[1] = ''
            if not proj_details[2]:
                self.add_msg_signal.emit("Project work directory missing. "
                                         "You can add it to cell B3 on <b>Project</b> sheet. (optional).", 3)
                proj_details[2] = DEFAULT_WORK_DIR
            if not proj_details[3]:
                self.add_msg_signal.emit("Project Tool definition file paths missing. "
                                         "You can add them to row 4 (starting from column B) on "
                                         "<b>Project</b> sheet.", 3)
                proj_details[3] = tools
            # Create project
            self._project = SceletonProject(proj_details[0], proj_details[1], self._config)
            self._project.change_work_dir(proj_details[2])
            # Setup models and views
            self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
            self.add_msg_signal.emit("Loading project <b>{0}</b>".format(self._project.name), 0)
            self.init_models(proj_details[3])
            # Parse Setups from Excel and add them to the project
            self.add_msg_signal.emit("Loading Setups...", 0)
            self._project.parse_excel_setups(self.setup_model, self.tool_model, wb, self)
            msg = "Project {0} loaded".format(self._project.name)
            self.ui.statusbar.showMessage(msg, 10000)
            self.add_msg_signal.emit("Done", 1)
            self.check_clear_flags()
            self.ui.treeView_setups.expandAll()
            self.ui.treeView_setups.resizeColumnToContents(0)
            # Add 25 to Setup column width to accommodate for decoration
            self.ui.treeView_setups.setColumnWidth(0, self.ui.treeView_setups.columnWidth(0) + 25)
            return True
        else:
            self.add_msg_signal.emit("Invalid project file format. Only <b>.xlsx</b> and <b>.json</b> supported)", 2)

    def add_tool(self):
        """Method to add a new tool from a JSON tool definition file to the
        ToolModel instance (available tools). Opens a load dialog
        where user can select the wanted tool definition file. The path of the
        definition file is saved to project settings.
        """
        if not self._project:
            self.add_msg_signal.emit("Make a new project or load a project to add tools", 0)
            return
        # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
        answer = QFileDialog.getOpenFileName(self, 'Select tool definition file',
                                             os.path.join(project_dir(self._config), os.path.pardir),
                                             'JSON (*.json)')
        if answer[0] == '':  # Cancel button clicked
            return
        def_file = os.path.abspath(answer[0])
        if not os.path.isfile(def_file):
            self.add_msg_signal.emit("Tool definition file path not valid <b>{0}</b>".format(def_file), 2)
            return
        self.add_msg_signal.emit("Adding Tool -> <b>{0}</b>".format(def_file), 0)
        # Load tool definition
        tool = SceletonProject.load_tool(def_file, self)
        if not tool:
            self.add_msg_signal.emit("Adding Tool failed".format(def_file), 2)
            return
        if not self.tool_model.find_tool(tool.name):
            # Add definition file path into tool
            tool.set_def_path(def_file)
            # Insert tool into model
            self.tool_model.insertRow(tool)
            # Save Tool def file path to project file
            project_file = self._project.path  # Path to project file
            if project_file.lower().endswith('.json'):
                # Load project from JSON file
                try:
                    with open(project_file, 'r') as fh:
                        dicts = json.load(fh)
                except OSError:
                    self.add_msg_signal.emit("OSError: Could not load file <b>{0}</b>".format(project_file), 2)
                    return
                # Get project settings
                project_dict = dicts['project']
                setup_dict = dicts['setups']
                try:
                    tools = project_dict['tools']
                    if def_file not in tools:
                        tools.append(def_file)
                    project_dict['tools'] = tools
                except KeyError:
                    logging.debug("tools keyword not found in project file")
                    project_dict['tools'] = [def_file]
                # Save dictionaries back to JSON file
                dicts['project'] = project_dict
                dicts['setups'] = setup_dict
                with open(project_file, 'w') as fp:
                    json.dump(dicts, fp, indent=4)
                self.add_msg_signal.emit("Tool <b>{0}</b> added. Reload project to refresh Setups".format(tool.name), 3)
                self.add_msg_signal.emit("Done", 1)
            else:
                self.add_msg_signal.emit("This feature is not supported with Excel project files. "
                                         "Save project into JSON file and try again", 0)
                return
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
        project_file = self._project.path  # Path to project file
        if project_file.lower().endswith('.json'):
            # Load project from JSON file
            try:
                with open(project_file, 'r') as fh:
                    dicts = json.load(fh)
            except OSError:
                self.add_msg_signal.emit("OSError: Could not load file <b>{0}</b>".format(project_file), 2)
                return
            # Get project settings
            project_dict = dicts['project']
            try:
                tools = project_dict['tools']
            except KeyError:
                logging.debug("tools keyword not found in project file")
                self.add_msg_signal.emit("No Tools in project", 0)
                return
            self.init_tool_model(tools)

            # Reattach all Tools to Setups because the tool model may have changed.
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
                pass
                # self.add_msg_signal.emit("No Setups in project", 0)
            else:
                traverse(self._root)
            self.setup_model.emit_data_changed()
        else:
            self.add_msg_signal.emit("This feature is not supported with Excel project files. "
                                     "Save project into JSON file and try again", 0)
            return

    def remove_tool(self):
        """Removes a tool from the ToolModel and the tool
        definition file path from the project file.
        """
        try:
            index = self.ui.listView_tools.selectedIndexes()[0]
        except IndexError:
            # Nothing selected
            self.add_msg_signal.emit("Select a Tool to remove", 0)
            return
        if not index.isValid():
            return
        if index.row() == 0:
            # Do not remove No Tool option
            self.add_msg_signal.emit("<b>No Tool</b> cannot be removed", 0)
            return
        sel_tool = self.tool_model.tool(index.row())
        tool_def_path = sel_tool.def_file_path
        msg = "Removing Tool <b>{0}</b>. Are you sure?".format(sel_tool.name)
        # noinspection PyCallByClass, PyTypeChecker
        answer = QMessageBox.question(self, 'Remove Tool', msg, QMessageBox.Yes, QMessageBox.No)
        if answer == QMessageBox.Yes:
            self.add_msg_signal.emit("Removing Tool <b>{0}</b> -> <b>{1}</b>".format(sel_tool.name, tool_def_path), 0)
            # Remove tool def file path from the project file (only JSON supported)
            project_file = self._project.path  # Path to project file
            if not project_file.lower().endswith('.json'):
                self.add_msg_signal.emit("This feature is not supported with Excel project files. "
                                         "Save project into JSON file and try again", 0)
                return
            # Read project data from JSON file
            try:
                with open(project_file, 'r') as fh:
                    dicts = json.load(fh)
            except OSError:
                self.add_msg_signal.emit("OSError: Could not load file <b>{0}</b>".format(project_file), 2)
                return
            # Get project settings
            project_dict = dicts['project']
            setup_dict = dicts['setups']
            if not self.tool_model.removeRow(index.row()):
                self.add_msg_signal.emit("Error in removing Tool <b>{0}</b>".format(sel_tool.name), 2)
                return
            try:
                tools = project_dict['tools']
                tools.remove(tool_def_path)
                # logging.debug("tools list after removal:{}".format(tools))
                project_dict['tools'] = tools
            except KeyError:
                self.add_msg_signal.emit("This is odd. Tools dictionary not found in project file <b>{0}</b>"
                                         .format(project_file), 2)
                return
            except ValueError:
                self.add_msg_signal.emit("This is odd. Tool definition file path <b>{0}</b> not found "
                                         "in project file <b>{1}</b>".format(tool_def_path, project_file), 2)
                return
            # Save dictionaries back to JSON file
            dicts['project'] = project_dict
            dicts['setups'] = setup_dict
            with open(project_file, 'w') as fp:
                json.dump(dicts, fp, indent=4)

            # Go through all Setups and remove Tool if not found
            def traverse(setup):
                # Helper function to traverse tree
                if not setup.name == 'root':
                    if setup.tool:
                        # Check if Setup's Tool still exists
                        tool_instance = self.tool_model.find_tool(setup.tool.name)
                        if not tool_instance:
                            self.add_msg_signal.emit("Removing Tool from Setup <b>{0}</b>".format(setup.name), 3)
                            setup.tool = None
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
            self.add_msg_signal.emit("Removing Tool from Setup <b>{0}</b>".format(setup.name), 0)
            setup.detach_tool()
        self.setup_model.emit_data_changed()
        return True

    # noinspection PyUnusedLocal
    def view_tool_def(self, current, previous):
        """Show selected Tool definition file in a QTextBrowser.

        Args:
            current (QModelIndex): Index of the current item
            previous (QModelIndex): Index of the previous item
        """
        if not current.isValid():
            return
        if current.row() == 0:
            self.ui.textBrowser_tool_def.clear()
            self.ui.label_tool_name.setText("")
            self.ui.tabWidget_tools.tabBar().setCurrentIndex(0)
            return
        current_tool = self.tool_model.tool(current.row())
        tool_def_file_path = current_tool.def_file_path
        with open(tool_def_file_path, 'r') as fp:
            try:
                json_data = json.load(fp)
            except ValueError:
                self.add_msg_signal.emit("Tool definition file not valid: '{0}'".format(tool_def_file_path), 2)
                logging.exception("Loading JSON data failed")
                return
        self.ui.textBrowser_tool_def.clear()
        self.ui.tabWidget_tools.tabBar().setCurrentIndex(1)
        self.ui.label_tool_name.setText("{0}".format(current_tool.name))
        self.ui.textBrowser_tool_def.append(json.dumps(json_data, sort_keys=True, indent=4))

    @busy_effect
    @pyqtSlot("QModelIndex", name='edit_tool_def')
    def edit_tool_def(self, clicked_index):
        """Open the double-clicked Tools definition file in the default (.json) text-editor.

        Args:
            clicked_index (QModelIndex): Index of the double clicked item
        """
        if clicked_index.row() == 0:
            return  # Don't do anything if No Tool option is double-clicked
        sel_tool = self.tool_model.tool(clicked_index.row())
        tool_def_url = "file:///" + sel_tool.def_file_path
        # Open Tool definition file in editor
        # noinspection PyTypeChecker, PyCallByClass, PyArgumentList
        res = QDesktopServices.openUrl(QUrl(tool_def_url, QUrl.TolerantMode))
        if not res:
            logging.error("Failed to open editor for {0}".format(tool_def_url))
            self.add_msg_signal.emit("Unable to open Tool definition file in an editor. Make sure that <b>.json</b> "
                                     "files are associated with a text editor.", 2)
        return

    @pyqtSlot(int, name='current_tab_changed')
    def current_tab_changed(self, i):
        """Slot for Tool QTabWidget currentChanged signal.

         Args:
             i (int): Index of the current tab
        """
        if i == 0:
            self.ui.label_tool_name.setText("")
        elif i == 1:
            try:
                selected_index = self.ui.listView_tools.selectedIndexes()[0]
            except IndexError:
                self.ui.textBrowser_tool_def.append("Select a Tool to display it's definition file contents here")
                self.ui.label_tool_name.setText("")
                return
            if not selected_index.isValid() or not selected_index:
                self.ui.label_tool_name.setText("")
                return
            if selected_index.row() == 0:
                self.ui.textBrowser_tool_def.append("Select a Tool to display it's definition file contents here")
                self.ui.label_tool_name.setText("")
                return
            else:
                tool_name = self.tool_model.tool(selected_index.row()).name
                self.ui.label_tool_name.setText(tool_name)
                return
        else:
            return

    @pyqtSlot("QPoint", name="show_tool_context_menu")
    def show_tool_context_menu(self, pos):
        """Context menu for Tool QTreeView.

        Args:
            pos (int): Received from the customContextMenuRequested
            signal. Contains mouse position.
        """
        global_pos = self.ui.listView_tools.viewport().mapToGlobal(pos)
        self.tool_context_menu = ToolContextMenuWidget(self, global_pos)
        option = self.tool_context_menu.get_action()
        if option == "Add Tool":
            self.add_tool()
            return
        elif option == "Refresh Tools":
            self.refresh_tools()
            return
        elif option == "Remove Tool":
            self.remove_tool()
        else:
            # No option selected
            pass
        self.tool_context_menu.deleteLater()
        self.tool_context_menu = None

    @pyqtSlot("QPoint", name="show_setup_context_menu")
    def show_setup_context_menu(self, pos):
        """Context menu for Setup QTreeView.

        Args:
            pos (QPoint): Received from the customContextMenuRequested
            signal. Contains mouse position.
        """
        ind = self.ui.treeView_setups.indexAt(pos)
        global_pos = self.ui.treeView_setups.viewport().mapToGlobal(pos)
        self.setup_context_menu = SetupContextMenuWidget(self, global_pos, ind)
        option = self.setup_context_menu.get_action()
        if option == "Add Child Setup":
            self.open_setup_form(ind)
            return
        elif option == "Add Setup":
            self.open_setup_form()
            return
        elif option == "Edit Tool":
            self.open_edit_tool_form(ind)
            return
        elif option == "Execute Single":
            self.execute_single()
            return
        elif option == "Execute Selected":
            self.execute_selected()
            return
        elif option == "Execute Project":
            self.execute_project()
            return
        elif option == "Clear Flags":
            self.clear_setup_flags()
            return
        elif option == "Clear All Flags":
            self.clear_flags()
            return
        elif option == "Verify Input Data":
            self.open_verify_data_form()
            return
        elif option == "Explore Input Data":
            self.show_explorer_form()
            return
        elif option == "Clone":
            self.clone_setup(ind)
        else:
            # No option selected
            pass
        self.setup_context_menu.deleteLater()
        self.setup_context_menu = None

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
                self.load_project()
                return
            elif answer == QMessageBox.No:
                self.new_project()
                return
            else:
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

    @pyqtSlot(name="open_verifier_form")
    def open_verifier_form(self):
        """PyqtSlot for QMenu and QPushButton Widgets."""
        self.open_verify_data_form()

    def open_verify_data_form(self):
        """Show verify data form."""
        if not self._project:
            self.add_msg_signal.emit("No project found. Load or create a project to use this tool", 0)
            return
        if self._root.child_count() == 0:
            self.add_msg_signal.emit("No Setups in project", 0)
            return
        self.input_verifier_form = InputVerifierWidget(self, self.setup_model, self._project.project_dir)
        self.input_verifier_form.show()

    @pyqtSlot(name="show_explorer_form")
    def show_explorer_form(self):
        """Open input data directory explorer."""
        if not self._project:
            self.add_msg_signal.emit("No project found. Load or create a project to explore Setup input data.", 0)
            return
        if self._root.child_count() == 0:
            self.add_msg_signal.emit("No Setups in project", 0)
            return
        self.input_explorer = InputExplorerWidget(self, self.setup_model)
        self.input_explorer.show()

    @pyqtSlot(name="show_results_form")
    def show_results_form(self):
        """Open output data (results) explorer."""
        if not self._project:
            self.add_msg_signal.emit("No project found. Load or create a project to open this tool.", 0)
            return
        if self._root.child_count() == 0:
            self.add_msg_signal.emit("No Setups in project", 0)
            return
        self.results_form = OutputExplorerWidget(self, self.setup_model, self._project.project_dir)
        self.results_form.show()

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
            if not self.setup_model.insert_setup(name, description, self._project, 0):
                logging.error("Adding base Setup failed")
                return
        else:
            if not self.setup_model.insert_setup(name, description, self._project, 0, parent):
                logging.error("Adding child Setup failed")
                return
        # Add tool to Setup
        if tool is not None:
            setup_index = self.setup_model.find_index(name)
            setup = self.setup_model.get_setup(setup_index)
            setup.attach_tool(tool, cmdline_args=cmdline_args)
        return

    def clone(self):
        """Clone keyboard shortcut triggered handler.
        Get selected Setup and call clone_setup() method."""
        index = self.ui.treeView_setups.selectionModel().selectedRows()
        if not index:
            logging.debug("No Setup to clone Selected")
            return
        index = index[0]
        if not index.isValid():
            logging.debug("Index not valid for cloning")
            return
        self.clone_setup(index)

    def clone_setup(self, ind):
        """Clone selected Setup.

        Args:
            ind (QModelIndex): Selected Setup
        """
        s = ind.internalPointer()
        start_index = self.setup_model.index(0, 0, QModelIndex())
        all_setups = self.setup_model.match(start_index, Qt.DisplayRole, '.*', -1, Qt.MatchRegExp | Qt.MatchRecursive)
        short_names = [setup.internalPointer().short_name for setup in all_setups]
        name_ok = False
        i = 0
        clone_name = "dummy123"
        while not name_ok:
            clone_name = s.name + '_' + str(i)
            clone_short_name = clone_name.lower().replace(' ', '_')
            # Check if Setup with the same name already exists
            if start_index.isValid():
                matching_index = self.setup_model.match(
                    start_index, Qt.DisplayRole, clone_name, 1, Qt.MatchFixedString | Qt.MatchRecursive)
                if len(matching_index) > 0:  # Match found
                    # logging.debug("Setup '{0}' already exists".format(clone_name))
                    i += 1
                    continue
                # Check that no existing Setup short name matches the new Setup's short name.
                if clone_short_name in short_names:
                    logging.debug("Setup using folder name '{0}' already exists".format(clone_short_name))
                    i += 1
                    continue
            name_ok = True
        self.add_setup(clone_name, s.description, s.tool, s.cmdline_args, parent=QModelIndex())
        self.add_msg_signal.emit("Setup <b>{0}</b> cloned -> <b>{1}</b>".format(s.name, clone_name), 0)

    @pyqtSlot(name='delete_selected_setup')
    def delete_selected_setup(self):
        """Removes selected Setup(s) and all of it's children from the SetupModel."""
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
            return
        show_question_box = True
        del_input_dirs = self._config.getboolean('settings', 'delete_input_dirs')
        indexes = self.get_selected_setup_indexes()
        if not indexes:
            self.add_msg_signal.emit("No Setup selected<br/>", 0)
            return
        # Get names of deleted Setups
        setups = [ind.internalPointer().name for ind in indexes]
        for setup in setups:
            # Find index of setup
            index = self.setup_model.find_index(setup)
            try:
                row = index.row()
            except AttributeError:
                # This happens when user tries to delete a child Setup whose Parent has already been deleted
                continue
            parent = self.setup_model.parent(index)
            selected_setup = index.internalPointer()
            name = selected_setup.name
            if not del_input_dirs:
                title = "Delete Setup?"
                msg = "You are about to delete Setup <b>{0}</b> and all of its children.\nAre you sure?".format(name)
            else:
                title = "Delete Setup and input directory?"
                msg = "You are about to delete Setup <b>{0}</b> and all of its children." \
                      "\nInput directories will be deleted as well.\nAre you sure?".format(name)
            # If 'Yes To All' was selected, do not show question box anymore
            if not show_question_box:
                # Delete Setup
                self.delete_setup(selected_setup, row, parent, del_input_dirs)
            else:
                # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
                answer = QMessageBox.question(self, title, msg, QMessageBox.YesToAll | QMessageBox.Yes |
                                              QMessageBox.No | QMessageBox.Cancel)
                if answer == QMessageBox.Yes:
                    # Delete Setup
                    self.delete_setup(selected_setup, row, parent, del_input_dirs)
                elif answer == QMessageBox.YesToAll:
                    show_question_box = False
                    # Delete Setup
                    self.delete_setup(selected_setup, row, parent, del_input_dirs)
                elif answer == QMessageBox.No:
                    pass
                else:  # Cancel, 'X', or Escape key pressed
                    break
        return

    @pyqtSlot(name='delete_all')
    def delete_all(self):
        """Delete all Setups from model. Ask user's permission first."""
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
            return
        root_index = QModelIndex()
        n_kids = self._root.child_count()

        del_input_dirs = self._config.getboolean('settings', 'delete_input_dirs')
        if not del_input_dirs:
            title = "Delete all Setups?"
            msg = "You are about to delete all Setups in the project.\nAre you sure?"
        else:
            title = "Delete all Setups and input directories?"
            msg = "You are about to delete all Setups and their input directories in the project.\nAre you sure?"
        # noinspection PyCallByClass, PyTypeChecker
        answer = QMessageBox.question(self, title, msg, QMessageBox.Yes, QMessageBox.No)
        # Get deleted Setup's names and input dirs
        [names, input_dirs] = self.get_deleted_setup_lists(self.setup_model.get_root())
        if answer == QMessageBox.Yes:
            # This removes the Setups
            for i in range(n_kids):
                self.setup_model.remove_setup(0, root_index)
            # This is just for printing
            for n in names:
                self.add_msg_signal.emit("Setup <b>{}</b> deleted".format(n), 0)
            # Delete input directories if selected
            if del_input_dirs:
                for path in input_dirs:
                    try:
                        if not erase_dir(path):
                            self.add_msg_signal.emit("Removing path <b>{0}</b> failed".format(path), 2)
                            continue
                    except OSError:
                        logging.exception("OSError while removing directory {}. Check permissions.".format(path))
                        continue
                    else:
                        self.add_msg_signal.emit("Directory <b>{0}</b> removed".format(path), 0)
        return

    # noinspection PyMethodMayBeStatic
    def get_deleted_setup_lists(self, start_setup):
        """Returns two lists with deleted Setup names and input directories.
        Find Setup's to be deleted starting from the given Setup.

        Args:
            start_setup (Setup): Traverse tree from this Setup. Give root to traverse the whole tree.

        Returns:
            List that contains two lists: Setup names to be deleted and their input directories
        """
        names = list()
        input_dirs = list()

        def traverse(setup):
            # Helper function to traverse tree
            if not setup.name == 'root':
                names.append(setup.name)
                input_dirs.append(setup.input_dir)
            for kid in setup.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from selected Setup
        traverse(start_setup)
        return [names, input_dirs]

    def delete_all_no_confirmation(self):
        """Delete all Setups from model."""
        root_index = QModelIndex()
        n_kids = self._root.child_count()
        for i in range(n_kids):
            self.setup_model.remove_setup(0, root_index)
        return

    def delete_setup(self, setup, row, parent, del_input_dirs):
        """Delete Setup and it's Input directory if selected.
        Used by delete_selected_setup() method.

        Args:
            setup (Setup): Setup to delete
            row (int): Row of Setup
            parent (QModelIndex): Index of deleted Setup's parent
            del_input_dirs (bool): User setting whether to delete input directory as well as the Setup
        """
        [names, input_dirs] = self.get_deleted_setup_lists(setup)
        self.setup_model.remove_setup(row, parent)
        for n in names:
            self.add_msg_signal.emit("Setup <b>{}</b> deleted".format(n), 0)
        # Delete input directories if selected
        if del_input_dirs:
            for path in input_dirs:
                try:
                    if not erase_dir(path):
                        self.add_msg_signal.emit("Removing path <b>{0}</b> failed".format(path), 2)
                        continue
                except OSError:
                    logging.exception("OSError while removing directory {}".format(path))
                    continue
                else:
                    self.add_msg_signal.emit("Directory <b>{0}</b> removed".format(path), 0)
        return

    def execute_single(self):
        """Execute selected Setup."""
        self.exec_mode = 'single'
        self.execute_setup()

    def execute_selected(self):
        """Starts executing a Setup branch."""
        self.exec_mode = 'selected'
        self.execute_setup()

    def execute_project(self):
        """Starts executing all Setups in the project."""
        self.exec_mode = 'project'
        self.execute_setup()

    def execute_setup(self):
        """Start executing Setups according to the selected execution mode."""
        alg = ''
        # Find current text in the algorithm combobox
        for act in self.execute_toolbar.actions():
            cand = self.execute_toolbar.widgetForAction(act)
            if isinstance(cand, QComboBox):
                alg = cand.currentText()
                # logging.debug("Found QComboBox: {0}".format(cand.currentText()))
        if alg == "Breadth-first":
            self.algorithm = True
        elif alg == "Depth-first":
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
        elif self.exec_mode == 'selected':
            # Set index of base Setup for the model
            base = self.get_selected_setup_base_index()
            # Check if no Setup selected
            if not base:
                self.add_msg_signal.emit("No Setup selected.<br/>", 0)
                return
            self.add_msg_signal.emit("<br/>Executing selected Setup. Algorithm: {0}".format(alg), 0)
            self.setup_model.set_base(base)
            # Set Base Setup as the first running Setup
            self._running_setup = self.setup_model.get_base().internalPointer()
        elif self.exec_mode == 'project':
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
        self.ui.label_tool_name.setText("")
        self.ui.tabWidget_tools.tabBar().setCurrentIndex(0)
        # Connect setup_finished_signal to setup_done slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        start_msg = "*** Starting Setup <b>{0}</b> ***".format(self._running_setup.name)
        star_line = "\t\t" + "*" * (len(start_msg) - 10)  # Deduct <b> tag space
        self.add_msg_signal.emit("<br/>" + star_line, 0)
        self.add_msg_signal.emit("\t\t" + start_msg, 0)
        self.add_msg_signal.emit(star_line + "<br/>", 0)
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
        if self._running_setup.failed:
            self.add_msg_signal.emit("Setup <b>{0}</b> failed".format(self._running_setup.name), 2)
            self._running_setup = None
            self.toggle_gui(True)
            return
        if not self._running_setup.tool:  # No Tool
            self.add_msg_signal.emit("No Tool. No results.", 0)
        self.add_msg_signal.emit("Setup <b>{0}</b> Done".format(self._running_setup.name), 1)
        # Clear running Setup
        self._running_setup = None
        if self.exec_mode == 'single':
            self.add_msg_signal.emit("Done", 1)
            self.toggle_gui(True)
            return
        if self.exec_mode == 'selected':
            # Get next executed Setup
            next_setup = self.setup_model.get_next_setup_selected(self.get_selected_setup_index())
            if not next_setup:
                logging.debug("Selected Setups Completed")
                self.add_msg_signal.emit("Selected Setups Completed", 1)
                self.toggle_gui(True)
                return
            self._running_setup = next_setup.internalPointer()
        elif self.exec_mode == 'project':
            # Get next executed Setup in the current branch
            next_setup = self.setup_model.get_next_setup(breadth_first=self.algorithm)
            # Find a new base Setup if no more Setups left descending from the current base Setup
            if not next_setup:
                for i in range(self._root.child_count()):
                    if not self._root.child(i).is_ready:
                        new_base_name = self._root.child(i).name
                        new_base_index = self.setup_model.find_index(new_base_name)
                        self.setup_model.set_base(new_base_index)
                        next_setup = self.setup_model.get_base()
                        break
            # End execution if no more base Setups left
            if not next_setup:
                self.add_msg_signal.emit("All Setups Completed", 1)
                self.toggle_gui(True)
                return
            self._running_setup = next_setup.internalPointer()
        logging.debug("Starting Setup <{0}>".format(self._running_setup.name))
        start_msg = "*** Starting Setup <b>{0}</b> ***".format(self._running_setup.name)
        star_line = "\t\t" + "*" * (len(start_msg) - 10)  # Deduct <b> tag space
        self.add_msg_signal.emit("<br/>" + star_line, 0)
        self.add_msg_signal.emit("\t\t" + start_msg, 0)
        self.add_msg_signal.emit(star_line + "<br/>", 0)
        # Connect setup_finished_signal to this slot
        self._running_setup.setup_finished_signal.connect(self.setup_done)
        self._running_setup.execute(self)

    @pyqtSlot(name='terminate_execution')
    def terminate_execution(self):
        """Stop current Setup execution by closing the Tool QProcess."""
        # TODO: Test this with other than GAMS Tools
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

    @pyqtSlot(name='update_setup_model')
    def update_setup_model(self):
        """Make all views connected to the setup model update themselves."""
        self.setup_model.emit_data_changed()

    def toggle_gui(self, value):
        """Enable or disable selected GUI elements that should not work when execution is in progress.

        Args:
            value (boolean): False to disable GUI, True to enable GUI
        """
        # Disable / Enable menu actions
        self.ui.actionAdd_Tool.setEnabled(value)
        self.ui.actionRefresh_Tools.setEnabled(value)
        self.ui.actionRemove_Tool.setEnabled(value)
        self.ui.actionExecuteSelected.setEnabled(value)
        self.ui.actionExecuteProject.setEnabled(value)
        self.ui.actionStop_Execution.setEnabled(not value)
        self.ui.actionImportData.setEnabled(value)
        # Disable / Enable toolbar actions
        for act in self.execute_toolbar.actions():  # Execute toolbar
            if act.text() == "Selected":
                act.setEnabled(value)
            elif act.text() == "Project":
                act.setEnabled(value)
            elif act.text() == "Cancel":
                act.setEnabled(not value)
        for act in self.tool_toolbar.actions():  # Tool toolbar
            if act.text() == "Add":
                act.setEnabled(value)
            elif act.text() == "Refresh":
                act.setEnabled(value)
            elif act.text() == "Remove":
                act.setEnabled(value)
        for act in self.delete_toolbar.actions():  # Delete toolbar
            if act.text() == "Single":
                act.setEnabled(value)
            elif act.text() == "All":
                act.setEnabled(value)
        for act in self.data_toolbar.actions():  # Data toolbar
            if act.text() == "Import":
                act.setEnabled(value)
        for act in self.clear_toolbar.actions():  # Clear Flags toolbar
            if act.text() == "Failed":
                act.setEnabled(value)
            elif act.text() == "Ready":
                act.setEnabled(value)
            elif act.text() == "All":
                act.setEnabled(value)
        # Start / stop animated icon QMovie
        if value:
            self.setup_model.animated_icon.stop()  # Stop animation
            # Stop timer when simulation stops
            self.timer.stop()
        else:
            self.setup_model.animated_icon.start()  # Start animation
            # Start timer when simulation starts. Updates the animated icon.
            self.timer.start(50)
        self.update_setup_model()

    def check_clear_flags(self):
        """Clear flags from Setups if user has set this option in settings.
        Used at Sceleton startup and when a project has been loaded.
        """
        clear_flags_setting = self._config.getboolean('settings', 'clear_flags')
        if not clear_flags_setting:
            return
        self.clear_given_flags(clear_ready=True, clear_failed=True)

    @pyqtSlot(name='clear_ready_flags')
    def clear_ready_flags(self):
        """Clear ready flags for all Setups."""
        self.clear_given_flags(clear_ready=True, clear_failed=False)

    @pyqtSlot(name='clear_failed_flags')
    def clear_failed_flags(self):
        """Clear failed flags for all Setups."""
        self.clear_given_flags(clear_ready=False, clear_failed=True)

    @pyqtSlot(name='clear_flags')
    def clear_flags(self):
        """Clear flags for all Setups."""
        self.clear_given_flags(clear_ready=True, clear_failed=True)

    def clear_given_flags(self, clear_ready=True, clear_failed=True):
        """Helper function to clear selected flags from all Setups in project.

        Args:
            clear_ready (bool): Clears Setup ready flags if True
            clear_failed (bool): Clears Setup failed flags if True
        """
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
            return

        def traverse(setup):
            # Helper function to traverse tree
            if not setup.name == 'root':
                if clear_ready:
                    setup.is_ready = False
                if clear_failed:
                    setup.failed = False
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
        return

    def clear_given_flags_branch(self, clear_ready=True, clear_failed=True):
        """Helper function to clear selected flags from the selected Setup and its children.

        Args:
            clear_ready (bool): Clears Setup ready flags if True
            clear_failed (bool): Clears Setup failed flags if True
        """
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
            return
        index = self.get_selected_setup_index()
        if not index:
            self.add_msg_signal.emit("No Setup selected", 0)
            return

        def traverse(setup):
            # Helper function to traverse tree
            if not setup.name == 'root':
                # logging.debug("Clearing flags of Setup: {}".format(setup.name))
                if clear_ready:
                    setup.is_ready = False
                if clear_failed:
                    setup.failed = False
            for kid in setup.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from selected Setup
        traverse(index.internalPointer())
        self.setup_model.emit_data_changed()

    def clear_setup_flags(self):
        """Clears ready and failed flag for the selected Setup.
        Used when context-menu command Clear Flags is selected.
        """
        index = self.get_selected_setup_index()
        if not index:
            self.add_msg_signal.emit("No Setup selected", 0)
            return
        setup = index.internalPointer()
        # noinspection PyTypeChecker, PyArgumentList, PyCallByClass
        answer = QMessageBox.question(self, "Clear flags", "Clear children's flags as well?",
                                      QMessageBox.Yes | QMessageBox.No | QMessageBox.Cancel)
        if answer == QMessageBox.Yes:
            self.clear_given_flags_branch(clear_ready=True, clear_failed=True)
        elif answer == QMessageBox.No:
            setup.is_ready = False
            setup.failed = False
            self.setup_model.emit_data_changed()
        else:
            pass
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

    def get_selected_setup_indexes(self):
        """Returns the indexes of the selected rows or None if
         nothing is selected or index is not valid."""
        try:
            indexes = self.ui.treeView_setups.selectionModel().selectedRows()
        except IndexError:
            # Nothing selected
            return None
        for index in indexes:
            if not index.isValid():
                return None
        return indexes

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

    def import_data(self):
        """Open selected Excel file for creating text data files for Setups."""
        if not self._project:
            self.add_msg_signal.emit("No project open", 0)
            return
        # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
        answer = QFileDialog.getOpenFileName(self, 'Import Data', project_dir(self._config),
                                             'MS Excel (*.xlsx)')
        load_path = answer[0]
        if load_path == '':  # Cancel button clicked
            return
        self.add_msg_signal.emit("<br/>Importing data from file: <b>{0}</b>".format(load_path), 0)
        if not os.path.isfile(load_path):
            self.add_msg_signal.emit("File not found: <b>{0}</b>".format(load_path), 2)
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
        if code == 1:  # SUCCESS
            open_tag = "<span style='color:green;white-space: pre-wrap;'>"
        elif code == 2:  # ERROR
            open_tag = "<span style='color:red;white-space: pre-wrap;'>"
        elif code == 3:  # WARNING
            open_tag = "<span style='color:goldenrod;white-space: pre-wrap;'>"
        else:
            open_tag = "<span style='color:black;white-space: pre-wrap;'>"
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
            html_link (str): Link to a file or folder embedded in a HTML <a> tag
        """
        self.ui.textBrowser_main.insertHtml(html_link)
        # noinspection PyArgumentList
        QApplication.processEvents()

    @pyqtSlot("QUrl", name="open_anchor")
    def open_anchor(self, qurl):
        """Starts gamside.exe or opens file explorer in the given directory depending on the contents of qurl.

        Args:
            qurl (QUrl): Directory path or a file to open
        """
        path = qurl.toLocalFile()  # Either a path to result folder or a command to open gamside.exe
        file_ext = path[-4:]
        if file_ext == '.gpr':  # Path points to a GAMSIDE project file
            # Do not run GAMSIDE unless using Windows
            if not sys.platform == 'win32':
                logging.error("This feature is not supported by your OS: ({0})".format(sys.platform))
                self.add_msg_signal.emit("This feature is not supported by your OS [{0}]".format(sys.platform), 2)
                return
            # Get selected GAMS version from settings
            gams_path = self._config.get('general', 'gams_path')
            # Make path to gamside.exe according to the selected GAMS directory in settings
            gamside_exe_path = GAMSIDE_EXECUTABLE
            if not gams_path == '':
                gamside_exe_path = os.path.join(gams_path, GAMSIDE_EXECUTABLE)
            # Set selected gamside.exe version to handle the file
            cmd = [gamside_exe_path, path]
            logging.debug("cmd: {}".format(cmd))
            # Get all running processes
            running_tasks = subprocess.check_output('tasklist')  # Returns bytes
            # check if gamside.exe is running
            if b'gamside.exe' in running_tasks:
                logging.debug("gamside.exe is already running")
                msg = "Close GAMSIDE.EXE and try again."
                # noinspection PyTypeChecker, PyArgumentList, PyCallByClass
                QMessageBox.information(self, "Application already running", msg)
                return
            else:
                # Use PoPen() because call() and run() wait for the subprocess to return
                subprocess.Popen(cmd)
                return
        # Open path in Explorer
        # noinspection PyTypeChecker, PyCallByClass, PyArgumentList
        res = QDesktopServices.openUrl(qurl)
        if not res:
            self.add_msg_signal.emit("Failed to open path {}".format(path), 2)
            logging.error("Failed to open editor for QUrl {0}".format(qurl))

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
        """Shows the delete work directories message box when exiting Sceleton.
        If progress bar dialog is shown, it emits a signal to quit_application()
        method when finished.

        Returns:
            True if progress bar dialog is shown,
            False otherwise.
        """
        del_dirs = self._config.get('settings', 'delete_work_dirs')
        if del_dirs == '0':
            # Don't delete work directories and don't show message box
            logging.debug("Work directories not deleted")
            return False
        elif del_dirs == '1':  # Default
            # Find work directories
            all_dirs = find_work_dirs(self._project)  # All directories in work directory
            dirs = list()  # Directory paths to remove
            # Get all directories that contain '__sceleton' suffix
            for entry in all_dirs:
                d = os.path.split(entry)[1]
                if '__sceleton' in d:
                    dirs.append(entry)
            dirs_str = '\n'.join(dirs)
            if len(dirs) == 0:
                # No work directories found, skip message box
                logging.debug("No work directories found in path {0}".format(self._project.work_dir))
                return False
            # Show message box
            msg = QMessageBox()
            msg.setIcon(QMessageBox.Question)
            msg.setWindowTitle("Emptying work directory")
            msg.setText("There are {0} work directories in path {1}. Would you like to delete them? "
                        "Click show details to see the paths.".format(len(dirs), self._project.work_dir))
            msg.setDetailedText("These directories will be deleted:\n{0}".format(dirs_str))
            msg.setStandardButtons(QMessageBox.Yes | QMessageBox.No)
            chkbox = QCheckBox()
            chkbox.setText("Do not ask me again")
            msg.setCheckBox(chkbox)
            answer = msg.exec_()
            chk = chkbox.checkState()
            if answer == QMessageBox.Yes:
                if chk == 2:
                    # Save preference into config file
                    self._config.set('settings', 'delete_work_dirs', '2')
                logging.debug("Deleting {0} directories".format(len(dirs)))
                self.show_delete_dialog(dirs)
                return True
            else:
                logging.debug("Work directories not deleted")
                if chk == 2:
                    # Save preference into config file
                    self._config.set('settings', 'delete_work_dirs', '0')
                return False
        elif del_dirs == '2':
            # Delete work directories without prompt
            all_dirs = find_work_dirs(self._project)  # All directories in work directory
            dirs = list()  # Directory paths to remove
            # Get all directories that contain '__sceleton' suffix
            for entry in all_dirs:
                d = os.path.split(entry)[1]
                if '__sceleton' in d:
                    dirs.append(entry)
            logging.debug("Deleting {0} directories".format(len(dirs)))
            self.show_delete_dialog(dirs)
            return True
        else:
            logging.debug("Unknown setting for delete_work_dirs. Writing default value")
            self._config.set('settings', 'delete_work_dirs', '1')
        return False

    def show_delete_dialog(self, dirs):
        """Show delete dialog with progressbar. Continues
        to quit_application() when finished.

        Args:
            dirs (list): List of directory paths to delete
        """
        self.delete_progressbar = ProgressBarDialog(self, dirs)
        self.delete_progressbar.show()
        self.delete_progressbar.remove_work_dirs()

    def show_about(self):
        """Show About Sceleton form."""
        self.about_form = AboutWidget(self, SCELETON_VERSION)
        self.about_form.show()

    def closeEvent(self, event):
        """Method for handling application exit.

        Args:
             event (QEvent): PyQt event
        """
        # Show confirm exit message box
        if not self.show_confirm_exit():
            # Exit cancelled
            if event:
                event.ignore()
            return
        if self._project:
            self._config.set('general', 'previous_project', self._project.path)
            # Show save project message box
            self.show_save_project_prompt()
            # Show delete work directories message box
            if self.show_delete_work_dirs_prompt():  # Returns True if delete work directories progress bar is shown
                return
        self.quit_application()

    def quit_application(self):
        """This is needed in order to make delete work directories dialog work during exit."""
        logging.debug("See you later.")
        # Save application states and geometries
        self.qsettings.setValue("horizontal_splitter_state", self.ui.splitter_horizontal.saveState())
        self.qsettings.setValue("left_vertical_splitter_state", self.ui.splitter_vertical_left.saveState())
        self.qsettings.setValue("right_vertical_splitter_state", self.ui.splitter_vertical_right.saveState())
        self.qsettings.setValue("window_size", self.size())
        self.qsettings.setValue("window_pos", self.pos())
        self.qsettings.setValue("window_state", self.saveState(version=1))
        self._config.save()
        # noinspection PyArgumentList
        QApplication.quit()  # same as QApplication.exit(0)
