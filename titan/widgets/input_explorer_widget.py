"""
Widget to show Setup input directory explorer

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   20.1.2017
"""

import os
import logging
from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import pyqtSlot, Qt, QModelIndex, QFileInfo, QItemSelectionModel
from PyQt5.Qt import QStandardItem, QStandardItemModel, QFileIconProvider, QDesktopServices, QUrl, QTextCursor
import ui.input_explorer_form
from helpers import busy_effect
from models import SetupProxyModel


class InputExplorerWidget(QWidget):
    """Class constructor.

    Attributes:
        parent (QWidget): PyQt parent widget.
        setup_model (QAbstractItemModel): Setup model
    """
    def __init__(self, parent, setup_model):
        """ Initialize class. """
        super().__init__(flags=Qt.Window)
        self._parent = parent  # QWidget parent
        #  Set up the user interface from Designer.
        self.ui = ui.input_explorer_form.Ui_Form()
        self.ui.setupUi(self)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        # Data models
        self.setup_model = setup_model
        self.file_item_model = QStandardItemModel(self)
        # Make proxy model for filtering out the Tool and cmdline_args columns
        self.proxy_setup_model = SetupProxyModel()
        self.proxy_setup_model.setSourceModel(self.setup_model)
        # Set models to views
        self.ui.tableView_file_explorer.setModel(self.file_item_model)
        self.ui.treeView_setups.setModel(self.proxy_setup_model)
        # Set the first Setup selected
        index = self.setup_model.index(0, 0, QModelIndex())
        if not index.isValid():  # If Setup model empty. Should not happen
            return
        self.ui.treeView_setups.expandAll()
        self.ui.treeView_setups.selectionModel().select(index, QItemSelectionModel.SelectCurrent)
        # Get selected Setup from model (No mapping needed because index is in source model)
        s = index.internalPointer()
        files = self.input_files(index)
        # Show files of the first Setup
        self.populate_file_item_model(files, s)
        # Connect signals
        self.connect_signals()

    def connect_signals(self):
        """ Connect PyQt signals. """
        self.ui.pushButton_close.clicked.connect(self.close)
        self.ui.treeView_setups.selectionModel().currentChanged.connect(self.current_changed)
        self.ui.tableView_file_explorer.selectionModel().currentChanged.connect(self.show_preview)
        self.ui.tableView_file_explorer.doubleClicked.connect(self.open_file)

    @busy_effect
    @pyqtSlot(QModelIndex, QModelIndex, name="show_preview")
    def show_preview(self, current, previous):
        """Show contents of selected file if it is known to be a text file.

        Args:
            previous (QModelIndex): Previously selected item
            current (QModelIndex): Current selected item
        """
        self.ui.textBrowser_preview.clear()
        item = self.file_item_model.itemFromIndex(current)
        item_data = item.data(Qt.UserRole)  # Contains path to folder or file
        if not item_data:
            return
        ext = item_data[-4:]
        supported_extensions = ['.inc', '.txt', '.bat', '.csv', '.gms', '.gpr', '.lst']
        if ext in supported_extensions:
            too_big = 50*1024  # 50kB
            try:
                file_size = os.path.getsize(item_data)
            except OSError:
                logging.error("Could not determine file size: {}".format(item_data))
                return
            if file_size < too_big:
                with open(item_data, 'r') as f:
                    contents = f.read().splitlines()
                    for line in contents:
                        self.ui.textBrowser_preview.append(line)
                # Rewind cursor to the beginning of the file
                self.ui.textBrowser_preview.moveCursor(QTextCursor.Start)
            else:
                file_size_kb = int(file_size/1024 + 0.5)
                self.ui.textBrowser_preview.append("File too big for preview (>50kB)".format(file_size_kb))
        return

    @pyqtSlot(QModelIndex, QModelIndex, name="current_changed")
    def current_changed(self, current, previous):
        """Update shown input files when selected Setup changes.

        Args:
            current (QModelIndex): Current selected item
            previous (QModelIndex): Previously selected item
        """
        if not current:
            logging.debug("Nothing selected")
            return
        # Map proxy model index to source model index
        mapped_index = self.proxy_setup_model.mapToSource(current)
        files = self.input_files(mapped_index)
        self.populate_file_item_model(files, mapped_index.internalPointer())

    @busy_effect
    @pyqtSlot(QModelIndex, name="open_file")
    def open_file(self, ind):
        """Open file or directory pointed by the index.

        Args:
            ind (QModelIndex): Index of the double-clicked QStandardItem
        """
        item = self.file_item_model.itemFromIndex(ind)
        item_data = item.data(Qt.UserRole)  # Contains path to folder or file
        if not item_data:
            logging.debug("No files in directory.")
            return
        url = "file:///" + item_data
        file_ext = url[-4:]
        if file_ext == '.bat' or file_ext == '.exe':
            logging.debug("Executable file double-clicked")
            return
        logging.debug("Opening url: {}".format(url))
        # TODO: Test QDesktopServices on Linux & Mac
        # Open directory in Explorer
        # noinspection PyTypeChecker, PyCallByClass, PyArgumentList
        res = QDesktopServices.openUrl(QUrl(url, QUrl.TolerantMode))
        if not res:
            logging.error("Failed to open url")
        else:
            logging.debug("Url opened")
        return

    @busy_effect
    def populate_file_item_model(self, files, setup):
        """Show found files.

        Args:
            files (list): Found file names in a list
            setup (Setup): Selected Setup
        """
        self.file_item_model.clear()
        # Add header item that shows the input directory path
        header = QStandardItem("{}".format(setup.input_dir))
        # Increase font size
        font = header.font()
        font.setPointSize(10)
        header.setFont(font)
        # Set header
        self.file_item_model.setHorizontalHeaderItem(0, header)
        # If no files in input directory
        if not files:
            self.file_item_model.appendRow(QStandardItem("..."))
            return
        # Make an 'open directory' item
        folder_item = QStandardItem("Open Directory")
        folder_info = QFileInfo(setup.input_dir)
        icon_provider = QFileIconProvider()
        folder_icon = icon_provider.icon(folder_info)
        folder_item.setData(folder_icon, Qt.DecorationRole)
        folder_item.setData(setup.input_dir, Qt.UserRole)  # Set folder path as item data
        self.file_item_model.appendRow(folder_item)
        for file in files:
            # Make an item for the model
            item = QStandardItem(file)
            file_path = os.path.join(setup.input_dir, file)
            # Get the icon that is used by explorer and show that with the file
            file_info = QFileInfo(file_path)
            icon_provider = QFileIconProvider()
            icon = icon_provider.icon(file_info)
            item.setData(icon, Qt.DecorationRole)
            # Set file path to item data
            item.setData(file_path, Qt.UserRole)  # Set file path as item data
            # Append file item into model
            self.file_item_model.appendRow(item)
        return

    def input_files(self, setup):
        """Returns a list of files and folders in the Setup's input directory.

        Args:
            setup (QModelIndex): Setup index
        """
        file_list = list()
        input_dir = setup.internalPointer().input_dir
        file_list = os.listdir(input_dir)
        # logging.debug("Input dir: {0}\nfiles: {1}".format(input_dir, file_list))
        return file_list

    def keyPressEvent(self, e):
        """Handle key presses.

        Args:
            e (QKeyEvent): Received key press event.
        """
        if e.key() == Qt.Key_Return or e.key() == Qt.Key_Enter:
            index = self.ui.tableView_file_explorer.currentIndex()
            if index.isValid():
                self.open_file(index)
        if e.key() == Qt.Key_Escape:
            self.close()

    def closeEvent(self, event=None):
        """Handle close window.

        Args:
            event (QEvent): Closing event if 'X' is clicked.
        """
        if event:
            event.accept()
