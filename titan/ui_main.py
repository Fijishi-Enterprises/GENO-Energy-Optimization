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
from models import SetupModel, ToolProxyModel, ToolModel
from tool import Setup
from GAMS import GAMSModel, GDX_DATA_FMT, GAMS_INC_FILE
from config import ERROR_COLOR, SUCCESS_COLOR, PROJECT_DIR, \
                   CONFIGURATION_FILE, GENERAL_OPTIONS
from configuration import ConfigurationParser
from widgets.setup_form_widget import SetupFormWidget
from widgets.project_form_widget import ProjectFormWidget
from widgets.context_menu_widget import ContextMenuWidget
from widgets.edit_tool_widget import EditToolWidget
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
        self.tool_proxy_model = None
        self.setup_dict = dict()
        self.exec_mode = ''
        # References for widgets
        self.setup_form = None
        self.project_form = None
        self.context_menu = None
        self.edit_tool_form = None
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
        self.ui.checkBox_debug.clicked.connect(self.set_debug_level)
        self.ui.treeView_setups.pressed.connect(self.update_tool_view)
        self.ui.treeView_setups.customContextMenuRequested.connect(self.context_menu_configs)
        self.ui.toolButton_add_tool.clicked.connect(self.add_tool)
        self.ui.toolButton_remove_tool.clicked.connect(self.remove_tool)

    def init_models(self):
        """Create data models for GUI views."""
        # Root for SetupModel
        self._root = Setup('root', 'root node for Setups,', self._project)
        # Create model for Setups
        self.setup_model = SetupModel(self._root)
        # Start model test for SetupModel
        # self.modeltest = ModelTest(self.setup_model, self._root)
        self.init_tool_model()
        # Set SetupModel to QTreeView
        self.ui.treeView_setups.setModel(self.setup_model)
        # Make a ProxyModel to show the tool associated with the selected Setup
        self.tool_proxy_model = ToolProxyModel(self.ui)
        self.tool_proxy_model.setSourceModel(self.setup_model)
        self.ui.listView_tool.setModel(self.tool_proxy_model)
        # Set ToolModel to available Tools view
        # self.ui.listView_tools.setModel(self.tool_model)

    def init_tool_model(self):
        """Create model for tools"""
        self.tool_model = ToolModel()
        tool_defs = self._config.get('general', 'tools').split('\n')
        for tool_def in tool_defs:
            if tool_def == '':
                continue
            # Load tool definition
            tool = GAMSModel.load(tool_def)
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
            logging.error("Error loading project from file: %s" % project_file_path)
            return

    def clear_ui(self):
        """Clear UI when starting a new project or loading a project."""
        # Clear Setup Model
        if self._root:
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
        self.init_models()
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
        self._project = SceletonProject(proj_name, proj_desc)
        self.add_msg_signal.emit("Saving project '{0}' to file: <{1}>".format(self._project.name, file_name), 0)
        self.setWindowTitle("Sceleton Titan    -- {} --".format(self._project.name))
        self.save(file_path)

    def save_project(self):
        """Save Setups in project to disk. Use project name as file name."""
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
        # Clear Setup dictionary
        self.setup_dict.clear()
        project_dict = dict()  # This is written to JSON file
        dic = dict()  # This is an intermediate dictionary to hold project info
        dic['name'] = self._project.name
        dic['desc'] = self._project.description
        # Save project stuff
        project_dict['project'] = dic

        def traverse(item):
            # Helper function to traverse tree
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
        """Update tree dictionary with Setup dictionary. Setups will be written as a nested dictionary.
        I.e. child dictionaries are inserted into the parent Setups dictionary with key '.kids'.
        '.kids' was chosen because this is not allowed as a Setup name.

        Args:
            setup (Setup): Setup object to save
        """
        # TODO: Add all necessary attributes from Setup object to here
        setup_name = setup.name
        setup_short_name = setup.short_name
        parent_name = setup.parent().name
        parent_short_name = setup.parent().short_name
        the_dict = dict()
        the_dict['name'] = setup_name
        the_dict['desc'] = setup.description
        if setup.tool:
            the_dict['tool'] = setup.tool.name
            the_dict['cmdline_args'] = setup.cmdline_args
        else:
            the_dict['tool'] = None
            the_dict['cmdline_args'] = ""
        the_dict['is_ready'] = setup.is_ready
        the_dict['n_child'] = setup.child_count()
        if setup.parent() is not None:
            the_dict['parent'] = parent_name
        else:
            logging.debug("Setup '%s' parent is None" % setup_name)
            the_dict['parent'] = None
        the_dict['.kids'] = dict()  # Note: '.' is because it is not allowed as a Setup name
        # Add this Setup under the appropriate Setups children
        if parent_name == 'root':
            self.setup_dict[setup_short_name] = the_dict
        else:
            # Find the parent dictionary where this setup should be inserted
            diction = self._finditem(self.setup_dict, parent_short_name)
            try:
                diction['.kids'][setup_short_name] = the_dict
            except KeyError:
                logging.error("_finditem() error while saving. Parent setup dictionary not found")
        return

    def _finditem(self, obj, key):
        """Finds a key recursively from a nested dictionary.

        Args:
            obj: Dictionary to search
            key: Key to find

        Returns:
            Dictionary with the given key.
        """
        if key in obj:
            return obj[key]
        for k, v in obj.items():
            if isinstance(v, dict):
                item = self._finditem(v, key)
                if item is not None:
                    return item

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
        # dicts = dict()
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
        # Parse Setups
        setup_dict = dicts['setups']
        if len(setup_dict) == 0:
            self.add_msg_signal.emit("No Setups found in project file '{}'".format(load_path), 0)
            return False
        self.add_msg_signal.emit("Loading project '{0}'".format(self._project.name), 0)
        self.parse_setups(setup_dict)
        msg = "Project '%s' loaded" % self._project.name
        self.ui.statusbar.showMessage(msg, 5000)
        self.add_msg_signal.emit("Done", 1)
        return True

    def parse_setups(self, setup_dict):
        """Parse all found Setups recursively from Setup dictionary loaded from JSON file
        and add them to the SetupModel.

        Args:
            setup_dict (dict): Dictionary of Setups in JSON format
        """
        for k, v in setup_dict.items():
            if isinstance(v, dict):
                if not k == '.kids':
                    # Add Setup
                    name = v['name']  # Setup name
                    desc = v['desc']
                    parent_name = v['parent']
                    tool_name = v['tool']
                    cmdline_args = v['cmdline_args']
                    logging.info("Loading Setup '%s'" % name)
                    self.add_msg_signal.emit("Loading Setup '{0}'".format(name), 0)
                    if parent_name == 'root':
                        if not self.setup_model.insert_setup(name, desc, self._project, 0):
                            logging.error("Inserting base Setup %s failed" % name)
                            self.add_msg_signal.emit("Loading Setup '%s' failed. Parent Setup: '%s'"
                                                     % (name, parent_name), 2)
                    else:
                        parent_index = self.setup_model.find_index(parent_name)
                        parent_row = parent_index.row()
                        if not self.setup_model.insert_setup(name, desc, self._project, parent_row, parent_index):
                            logging.error("Inserting child Setup %s failed" % name)
                            self.add_msg_signal.emit("Loading Setup '%s' failed. Parent Setup: '%s'"
                                                     % (name, parent_name), 2)
                    if tool_name is not None:
                        # Get tool from ToolModel
                        tool = self.tool_model.find_tool(tool_name)
                        if not tool:
                            logging.error("Could not add Tool to Setup. Tool '%s' not found" % tool_name)
                            self.add_msg_signal.emit("Could not find Tool '%s' for Setup '%s'."
                                                     " Add Tool and reload project."
                                                     % (tool_name, name), 2)
                        else:
                            # Add tool to Setup
                            setup_index = self.setup_model.find_index(name)
                            setup = self.setup_model.get_setup(setup_index)
                            setup.add_input(tool)
                            setup.attach_tool(tool, cmdline_args=cmdline_args)
                self.parse_setups(v)

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
        self.add_msg_signal.emit("Adding tool from file: <{0}>".format(open_path), 0)
        # Load tool definition
        tool = GAMSModel.load(open_path)
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
            logging.debug("index:%s" % index)
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
                gdx_input_files = selected_setup.get_input_files(tool=tool, file_fmt=GDX_DATA_FMT)
                inc_input_files = selected_setup.get_input_files(tool=tool, file_fmt=GAMS_INC_FILE)
                self.add_msg_signal.emit("Showing input files for Setup '%s'\nInput folder: %s"
                                         % (setup_name, selected_setup.input_dir), 0)
                self.add_msg_signal.emit("GDX Input files:\n{0}".format(gdx_input_files), 0)
                self.add_msg_signal.emit("GAMS INC Input files:\n{0}".format(inc_input_files), 0)
            else:
                self.add_msg_signal.emit("No tool found", 0)
            return
        elif option == "Edit Tool":
            logging.debug("Opening edit tool form")
            self.open_edit_tool_form(ind)
            return
        elif option == "Execute":
            # logging.debug("Selected setup:%s" % ind.internalPointer().name)
            self.execute_single()
            return
        elif option == "Execute Branch":
            logging.debug("Selected setup:%s" % ind.internalPointer().name)
            self.execute_branch()
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

    def edit_tool(self, setup, tool, cmdline_args):
        """Change the Tool associated with Setup.

        Args:
            setup (Setup): Setup whose Tool is edited
            tool (Tool): Tool that replaces current one
            cmdline_args (str): Command line arguments for the tool

        Returns:
            Boolean value depending on operation success
        """
        # TODO: Tool view is not updated when going from 'No Tool' to some Tool
        # Add tool to Setup
        if tool is not None:
            # setup_index = self.setup_model.find_index(name)
            # setup = self.setup_model.get_setup(setup_index)
            self.add_msg_signal.emit("Changing Tool '%s' for Setup '%s'" % (tool.name, setup.name), 0)
            setup.detach_tool()
            setup.add_input(tool)
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
            setup.add_input(tool)
            setup.attach_tool(tool, cmdline_args=cmdline_args)
        return

    def execute_all(self):
        """Starts executing all Setups in the project."""
        self.exec_mode = 'all'
        self.add_msg_signal.emit("Not implemented", 0)
        # self.execute_setup()

    def execute_branch(self):
        """Starts executing a Setup branch."""
        self.exec_mode = 'branch'
        self.execute_setup()

    def execute_single(self):
        """Execute selected Setup."""
        self.exec_mode = 'single'
        self.execute_setup()

    def execute_setup(self):
        """Start executing Setups according to the selected execution mode."""
        if self.exec_mode == 'branch':
            # Set index of base Setup for the model
            base = self.get_selected_setup_base_index()
            # Check if no Setup selected
            if not base:
                self.add_msg_signal.emit("No Setup selected.\n", 0)
                return
            self.setup_model.set_base(base)
            # Set Base Setup as the first running Setup
            self._running_setup = self.setup_model.get_base().internalPointer()
        elif self.exec_mode == 'single':
            # Execute a single selected Setup
            selected_setup = self.get_selected_setup_index()
            # Check if no Setup selected
            if not selected_setup:
                self.add_msg_signal.emit("No Setup selected.\n", 0)
                return
            self._running_setup = selected_setup.internalPointer()
        elif self.exec_mode == 'all':
            if not self._project:
                self.add_msg_signal.emit("Open a Project to execute Setups\n", 0)
                return
            self.add_msg_signal.emit("Executing all Setups in Project '{0}'\n".format(self._project.name), 0)
            # TODO: Return if no Setups in project
            self.setup_model.set_base(QModelIndex())
            #self._running_setup = self.setup_model.get_base().internalPointer()
            self._running_setup = self.setup_model.get_root()
            logging.debug("running_setup name: %s" % self._running_setup.name)
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
        self.add_msg_signal.emit("Results saved to: {0}".format(self._running_setup.output_dir), 0)
        if self.exec_mode == 'single':
            self.add_msg_signal.emit("Done", 1)
            return
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
        if self._project:
            self._config.set('general', 'project_path', self._project.path)
        self._config.save()
        # noinspection PyArgumentList
        QApplication.quit()
