"""
Widget to show Setup Tool requirements and check if it is ready to be run.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   30.9.2016
"""

import os
import logging
import json
from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import pyqtSlot, Qt, QModelIndex
from PyQt5.Qt import QStandardItem, QStandardItemModel
import ui.input_verifier_form
from helpers import busy_effect
from models import SetupAndToolProxyModel


class InputVerifierWidget(QWidget):
    """ A widget to show the input of a Setup.

    Attributes:
        parent: PyQt parent widget.
    """
    def __init__(self, parent, setup_model, project_dir):
        """ Initialize class. """
        super().__init__(flags=Qt.Window)
        self._parent = parent  # QWidget parent
        #  Set up the user interface from Designer.
        self.ui = ui.input_verifier_form.Ui_Form()
        self.ui.setupUi(self)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        # Instance attributes
        self.setup_model = setup_model
        # Models for listViews
        self.req_files_model = QStandardItemModel()
        self.found_files_model = QStandardItemModel()
        # Proxy Setup model for treeView
        self.proxy_setup_model = SetupAndToolProxyModel()
        self.proxy_setup_model.setSourceModel(self.setup_model)
        # Set models for views
        self.ui.listView_required_files.setModel(self.req_files_model)
        self.ui.treeView_setuptree.setModel(self.proxy_setup_model)
        self.ui.treeView_setuptree.setColumnWidth(0, 264)
        self.ui.treeView_setuptree.expandAll()
        self.ui.label_project_dir.setText("Project directory: <b>{0}</b>".format(project_dir))

        # Reset all ready_to_run attributes and check all Setups
        def traverse(setup):
            # Helper function to traverse tree
            if not setup.name == 'root':
                setup.ready_to_run = None
                self.check_setup(setup)
            for kid in setup.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from proxy model root
        proxy_root = self.proxy_setup_model.sourceModel().get_root()
        if not proxy_root:
            logging.error("Proxy model root Setup not found")
            self.connect_signals()
            return
        traverse(proxy_root)
        self.proxy_setup_model.emit_data_changed()
        # Connect signals
        self.connect_signals()

    def connect_signals(self):
        """ Connect PyQt signals. """
        self.ui.pushButton_close.clicked.connect(self.close)
        self.ui.treeView_setuptree.selectionModel().currentChanged.connect(self.selection_changed)

    @pyqtSlot(QModelIndex, QModelIndex, name='selection_changed')
    def selection_changed(self, current, previous):
        """Update views when selected Setup changes.

        Args:
            current (QModelIndex): Current selected index
            previous (QModelIndex): Previous selected index
        """
        ind = self.proxy_setup_model.mapToSource(current)
        self.check_setup(ind.internalPointer())

    @busy_effect
    def check_setup(self, setup):
        """Check if Setup is ready to be run by checking if the
        required input files of it's Tool are either provided
        by its own input files, some parent or some parent's Tool.
        I.e. show required files and their whereabouts.

        Args:
            setup (Setup): Setup to check
        """
        self.req_files_model.clear()
        self.ui.textBrowser_output.clear()
        tool = setup.tool
        if not tool:
            item = QStandardItem("...")
            item.setFlags(Qt.ItemIsEnabled)
            self.req_files_model.appendRow(item)
            self.ui.textBrowser_output.append("Setup <b>{}</b> ready".format(setup.name))
            setup.ready_to_run = 1
            return
        tool_def_file_path = tool.get_def_path()
        req_files = self.get_required_files(tool_def_file_path)
        if not req_files:
            item = QStandardItem("Tool {0} does not require any files".format(tool.name))
            item.setFlags(Qt.ItemIsEnabled)
            self.req_files_model.appendRow(item)
            self.ui.textBrowser_output.append("<br/>Setup <b>{}</b> ready".format(setup.name))
            setup.ready_to_run = 1
            return
        # Print required files
        for file in req_files:
            item = QStandardItem("{0}".format(file))
            item.setFlags(Qt.ItemIsEnabled)
            self.req_files_model.appendRow(item)
        # Check if required files are in Setup input files
        for req_file in req_files:
            found_file = setup.find_input_file(req_file)
            if found_file:
                self.ui.textBrowser_output.append("<b>{0}</b> found in <b>{1}</b>".format(req_file, found_file))
                req_files.remove(req_file)
        # Find remaining required files from parent Setup's Tool output files
        if len(req_files) > 0:
            found_files = dict()
            found_files = self.check_tool_output_files(req_files, setup.parent(), found_files)
            for key, value in found_files.items():
                self.ui.textBrowser_output.append("<b>{0}</b> is an output file of Setup <b>{1}</b>".format(value, key))
            if req_files:
                for m_file in req_files:
                    self.ui.textBrowser_output.append("<b>{0}</b> not found".format(m_file))
                self.ui.textBrowser_output.append("<br/>Setup <b>{}</b> not ready".format(setup.name))
                setup.ready_to_run = 2
            else:
                self.ui.textBrowser_output.append("<br/>Setup <b>{}</b> ready".format(setup.name))
                setup.ready_to_run = 1
        else:
            self.ui.textBrowser_output.append("<br/>Setup <b>{}</b> ready".format(setup.name))
            setup.ready_to_run = 1

    def check_tool_output_files(self, req_files, setup, found_files):
        """Check the output files of Tools for required input files.

        Args:
            req_files (list): List of required file names
            setup (Setup): Current Setup
            found_files (dict): Contains the Setup and Tool as key and the found file as value

        Returns:
            Dictionary containing found files and Setups and Tools.
        """
        if setup.is_root:
            return found_files
        tool = setup.tool
        # Check the parents tool (setup is already the parent)
        if not tool:
            return self.check_tool_output_files(req_files, setup.parent(), found_files)
        # Get Tool output files
        tool_def_file_path = tool.get_def_path()
        output_files = self.get_output_files(tool_def_file_path)
        for file in output_files:
            if '*' in file or '?' in file:
                logging.debug("Skipping wild card output file names: {0}".format(file))
                continue
            if file in req_files:
                # logging.debug("Found {0} in Setup {1} Tool {2} output files".format(file, setup.name, tool.name))
                req_files.remove(file)
                key = setup.name + " (" + tool.name + ")"
                found_files[key] = file
        if req_files:
            return self.check_tool_output_files(req_files, setup.parent(), found_files)
        return found_files

    # noinspection PyMethodMayBeStatic
    def get_output_files(self, json_file_path):
        """Returns a list of output files of Tool defined in the given path.

        Args:
            json_file_path (str): Absolute path to the Tool definition file

        Returns:
            List of output files given by Tool or empty list if no output files defined.
        """
        with open(json_file_path, 'r') as fp:
            try:
                json_data = json.load(fp)
            except ValueError:
                logging.exception("Loading JSON data failed")
                return []
        outfiles = json_data['outfiles']
        str_files = list()
        for file in outfiles:
            # Just return the file names in a list
            head, tail = os.path.split(file)
            str_files.append(tail)
        return str_files

    # noinspection PyMethodMayBeStatic
    def get_required_files(self, json_file_path):
        """Returns a list of required input files of Tool defined in the given path.

        Args:
            json_file_path (str): Absolute path to the Tool definition file

        Returns:
            List of Tool's required input files or empty list if none found.
        """
        with open(json_file_path, 'r') as fp:
            try:
                json_data = json.load(fp)
            except ValueError:
                logging.exception("Loading JSON data failed")
                return []
        infiles = json_data['infiles']
        str_files = list()
        # TODO: What if required file is in a sub-folder?
        for file in infiles:
            # Just return the file names in a list
            head, tail = os.path.split(file)
            str_files.append(tail)
        return str_files

    def keyPressEvent(self, e):
        """Close form when escape key is pressed.

        Args:
            e (QKeyEvent): Received key press event.
        """
        if e.key() == Qt.Key_Escape:
            self.close()

    def closeEvent(self, event=None):
        """Handle close window.

        Args:
            event (QEvent): Closing event if 'X' is clicked.
        """
        if event:
            event.accept()
