"""
Widget to show Setup input data.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   30.9.2016
"""

import os
import logging
import json
from PyQt5.QtWidgets import QWidget, QTreeView
from PyQt5.QtCore import pyqtSlot, Qt, QModelIndex, QFileInfo
from PyQt5.Qt import QStandardItem, QStandardItemModel, QFileIconProvider, QBrush, QColor
import ui.input_data_form
from helpers import busy_effect


class InputDataWidget(QWidget):
    """ A widget to show the input of a Setup.

    Attributes:
        parent: PyQt parent widget.
    """
    def __init__(self, parent, index, setup_model):
        """ Initialize class. """
        super().__init__()
        self._parent = parent  # QWidget parent
        #  Set up the user interface from Designer.
        self.ui = ui.input_data_form.Ui_Form()
        self.ui.setupUi(self)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        # Instance attributes
        self.index = index
        self.setup_model = setup_model
        self.file_item_model = QStandardItemModel()
        # Set model for QListView
        self.ui.listView_input_files.setModel(self.file_item_model)
        # Make a new QTreeView
        self.combo_tree_view = QTreeView(self)
        # Set QComboBox view as the new QTreeView
        self.ui.comboBox_setup.setView(self.combo_tree_view)
        # Set SetupModel as the QComboBox model
        self.ui.comboBox_setup.setModel(self.setup_model)
        self.ui.comboBox_setup.view().expandAll()
        # Hide cmdline args column
        self.ui.comboBox_setup.view().hideColumn(2)
        self.ui.comboBox_setup.view().setColumnWidth(0, 150)
        if not index:  # Show files of the first Setup if no Setup selected
            index = self.setup_model.index(0, 0, QModelIndex())
            if not index.isValid():  # If Setup model empty
                return
        # Set the root of the combobox to the PARENT of the wanted Setup
        self.ui.comboBox_setup.setRootModelIndex(index.parent())
        # Now setCurrentIndex works. This selects the wanted item.
        self.ui.comboBox_setup.setCurrentIndex(index.row())
        # Set the root of the combobox back to original so that the whole is visible.
        self.ui.comboBox_setup.setRootModelIndex(QModelIndex())
        # Get selected Setup from model
        s = index.internalPointer()
        files = s.find_input_files('*.*')
        self.populate_file_item_model(files, s)
        # Connect signals
        self.connect_signals()

    def connect_signals(self):
        """ Connect PyQt signals. """
        self.ui.pushButton_close.clicked.connect(self.close)
        self.ui.comboBox_setup.currentIndexChanged.connect(self.selection_changed)

    @busy_effect
    def populate_file_item_model(self, files, setup):
        """Show found files and match them with Tool requirements.

        Args:
            files (list): List of abs. paths to found files
            setup (Setup): Selected Setup
        """
        self.file_item_model.clear()
        tool = setup.tool
        if not files and not tool:  # Show required files if Setup has a Tool
            self.file_item_model.appendRow(QStandardItem("No files found"))
            return
        top_item_brush = QBrush(QColor("LightGray"))
        section_brush = QBrush(QColor("Pink"))
        summary_brush = QBrush(QColor("Wheat"))
        input_brush = QBrush(QColor("Khaki"))
        missing_item_brush = QBrush(QColor("OrangeRed"))
        ready_item_brush = QBrush(QColor("LightGreen"))
        summary_item = QStandardItem("Summary:")
        summary_item.setBackground(summary_brush)
        missing_item = QStandardItem("Missing required files:")
        missing_item.setBackground(missing_item_brush)
        ready_item = QStandardItem("All required files found. Setup ready to be executed.")
        ready_item.setBackground(ready_item_brush)
        req_files = list()
        found_from_input = dict()
        if not tool:
            item = QStandardItem("No tool. No required files.")
            item.setBackground(top_item_brush)
            self.file_item_model.appendRow(item)
        else:
            tool_def_file_path = tool.get_def_path()
            req_files = self.get_required_files(tool_def_file_path)
            if not req_files:
                item = QStandardItem("Tool {0}. No required files found".format(tool.name))
                item.setBackground(top_item_brush)
                self.file_item_model.appendRow(item)
            else:
                item = QStandardItem("Required files for Tool '{0}'".format(tool.name))
                item.setBackground(top_item_brush)
                self.file_item_model.appendRow(item)
                [self.file_item_model.appendRow(QStandardItem("{0}".format(file))) for file in req_files]
        if files:  # Files is empty if Project contains no files
            # Add 'Input Files' after required files
            input_section = QStandardItem("Input files:")
            input_section.setBackground(input_brush)
            self.file_item_model.appendRow(input_section)
            sections = list()
            # Add current Setup section
            header_section = QStandardItem("{0}".format(setup.short_name))
            header_section.setBackground(section_brush)
            self.file_item_model.appendRow(header_section)
            sections.append(setup.short_name)
            # Check the first found file and if it is not in setup.short_name directory, add 'no files found' item
            head, tail = os.path.split(files[0])
            first_section = os.path.basename(head)  # Get file Setup (short) name
            if not first_section == setup.short_name:
                self.file_item_model.appendRow(QStandardItem("Input directory empty"))
        for file in files:
            head, filename = os.path.split(file)  # filename is the name of found file
            head2, section = os.path.split(head)  # section is the Setup short name
            head3, tail = os.path.split(head2)
            is_output = os.path.basename(head3)  # This is 'output' if found file is in output folder
            # Check if file was found in output directory.
            if is_output == 'output':
                # Do not show files in the most recent output folder
                # because these are not used by the next Setup that is executed.
                continue
            # Check if filename in required files
            if req_files:
                if filename in req_files:
                    # logging.debug("Found required file:{0}".format(filename))
                    found_from_input[section] = filename
                    req_files.remove(filename)
            if section in sections:
                # Add file under the current section
                item = QStandardItem(file)
                # Get the icon that is used by explorer and show that with the file
                file_info = QFileInfo(file)
                icon_provider = QFileIconProvider()
                icon = icon_provider.icon(file_info)
                item.setData(icon, Qt.DecorationRole)
                self.file_item_model.appendRow(item)
            else:
                # Add a new section and add new file under that
                section_item = QStandardItem(section)
                section_item.setBackground(section_brush)
                self.file_item_model.appendRow(section_item)
                sections.append(section)
                # Add current path under this section
                item = QStandardItem(file)
                # Get the icon that is used by explorer and show that with the file
                file_info = QFileInfo(file)
                icon_provider = QFileIconProvider()
                icon = icon_provider.icon(file_info)
                item.setData(icon, Qt.DecorationRole)
                self.file_item_model.appendRow(item)
        # Add Summary item
        self.file_item_model.appendRow(summary_item)
        if found_from_input:
            for key, value in found_from_input.items():
                self.file_item_model.appendRow(QStandardItem("Required file '{0}' found in Setup '{1}' input files"
                                                             .format(value, key)))
        if req_files:
            # If required files are still missing check all parents tool's output files
            found_files = dict()
            found_files = self.check_tool_output_files(req_files, setup.parent(), found_files)
            # logging.debug("found:{0} req_files:{1}".format(found_files, req_files))
            if not found_files:
                self.file_item_model.appendRow(missing_item)
                [self.file_item_model.appendRow(QStandardItem("{0}".format(file))) for file in req_files]
                return
            for key, value in found_files.items():
                self.file_item_model.appendRow(QStandardItem("Required file '{0}' is provided by Setup '{1}'"
                                                             .format(value, key)))
            if req_files:
                self.file_item_model.appendRow(missing_item)
                [self.file_item_model.appendRow(QStandardItem("{0}".format(file))) for file in req_files]
                return
        self.file_item_model.appendRow(ready_item)

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

    @pyqtSlot(int)
    def selection_changed(self, ind):
        """Update shown input files when selected Setup changes.

        Args:
            ind (int): Combobox selected index
        """
        setup_name = self.ui.comboBox_setup.currentText()
        s = self.setup_model.find_index(setup_name)
        files = s.internalPointer().find_input_files('*.*')
        self.populate_file_item_model(files, s.internalPointer())

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
                return None
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
                return None
        infiles = json_data['infiles']
        str_files = list()
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
