"""
Widget to show Setup result files.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.3.2017
"""

import os
import logging
import datetime
from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import pyqtSlot, Qt, QModelIndex, QFileInfo, QItemSelectionModel
from PyQt5.Qt import QStandardItem, QStandardItemModel, QFileIconProvider, \
    QDesktopServices, QUrl, QTextCursor, QIcon, QPixmap
import ui.output_explorer_form
from helpers import busy_effect
from models import SetupProxyModel


class OutputExplorerWidget(QWidget):
    """Class constructor.

    Attributes:
        parent (QWidget): PyQt parent widget.
        setup_model (QAbstractItemModel): Setup model
    """
    def __init__(self, parent, setup_model, project_dir):
        """ Initialize class. """
        super().__init__(flags=Qt.Window)
        self._parent = parent  # QWidget parent
        #  Set up the user interface from Designer.
        self.ui = ui.output_explorer_form.Ui_Form()
        self.ui.setupUi(self)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.ui.label_project_dir.setText("Project directory: <b>{0}</b>".format(project_dir))
        self.goto_dir_icon = QIcon()
        self.goto_dir_icon.addPixmap(QPixmap(":/icons/goto_directory.png"))
        # Data models
        self.setup_model = setup_model
        self.folder_model = QStandardItemModel(self)
        self.file_model = QStandardItemModel(self)
        # Make proxy model for filtering out the Tool and cmdline_args columns
        self.proxy_setup_model = SetupProxyModel()
        self.proxy_setup_model.setSourceModel(self.setup_model)
        # Set models to views
        self.ui.tableView_folders.setModel(self.folder_model)
        self.ui.tableView_files.setModel(self.file_model)
        self.ui.treeView_setups.setModel(self.proxy_setup_model)
        self.ui.treeView_setups.expandAll()
        # Get index of first Setup from proxy model
        index = self.proxy_setup_model.index(0, 0, QModelIndex())
        # Set first Setup selected and current
        self.ui.treeView_setups.selectionModel().select(index, QItemSelectionModel.SelectCurrent)
        # Get index of first Setup from the source model
        mapped_index = self.proxy_setup_model.mapToSource(index)
        s = mapped_index.internalPointer()
        # Show output folders of the first Setup in the model
        folders = self.output_folders(mapped_index)
        self.populate_folder_model(folders, s)
        # Connect signals
        self.connect_signals()

    def connect_signals(self):
        """ Connect PyQt signals. """
        self.ui.pushButton_close.clicked.connect(self.close)
        self.ui.treeView_setups.selectionModel().currentChanged.connect(self.current_setup_changed)
        self.ui.tableView_folders.selectionModel().currentChanged.connect(self.current_folder_changed)
        self.ui.tableView_folders.doubleClicked.connect(self.open_file)
        self.ui.tableView_files.doubleClicked.connect(self.open_file)
        self.ui.tableView_files.selectionModel().currentChanged.connect(self.show_preview)
        self.ui.radioButton_show_all.toggled.connect(self.radiobuttons_toggled)
        self.ui.radioButton_show_newest.toggled.connect(self.radiobuttons_toggled)
        self.ui.radioButton_show_today.toggled.connect(self.radiobuttons_toggled)
        self.ui.radioButton_show_failed.toggled.connect(self.radiobuttons_toggled)

    def radiobuttons_toggled(self, checked):
        """Radio buttons toggled handler.

        Args:
            checked (bool): True if any radio button is checked.
        """
        if checked:
            self.file_model.clear()
            self.ui.textBrowser_preview.clear()
            # Get selected Setup and its output folders
            try:
                index = self.ui.treeView_setups.selectedIndexes()[0]
            except IndexError:
                # Nothing selected
                return
            mapped_index = self.proxy_setup_model.mapToSource(index)
            setup = mapped_index.internalPointer()
            self.populate_folder_model(os.listdir(setup.output_dir), setup)

    @pyqtSlot(QModelIndex, QModelIndex, name="current_changed")
    def current_setup_changed(self, current, previous):
        """Update shown output folders when selected Setup changes.

        Args:
            current (QModelIndex): Current selected Setup
            previous (QModelIndex): Previously selected Setup
        """
        self.file_model.clear()
        if not current:
            logging.debug("Nothing selected")
            return
        # Map proxy model index to source model index
        mapped_index = self.proxy_setup_model.mapToSource(current)
        folders = self.output_folders(mapped_index)
        self.populate_folder_model(folders, mapped_index.internalPointer())

    @busy_effect
    @pyqtSlot(QModelIndex, QModelIndex, name="current_folder_changed")
    def current_folder_changed(self, current, previous):
        """Show contents of selected folder in file QTableView.

        Args:
            previous (QModelIndex): Previously selected folder item
            current (QModelIndex): Current selected folder item
        """
        if not current:
            logging.debug("No folder selected")
            return
        folder = current.data(Qt.UserRole)
        if not folder:
            return
        item_text = current.data(Qt.DisplayRole)
        if item_text == 'failed' or item_text == '..':
            self.file_model.clear()
            return
        files = self.output_files(folder)
        self.populate_file_model(files, folder)

    @busy_effect
    @pyqtSlot(QModelIndex, QModelIndex, name="show_preview")
    def show_preview(self, current, previous):
        """Show contents of selected file if it is known to be a text file.

        Args:
            previous (QModelIndex): Previously selected item
            current (QModelIndex): Current selected item
        """
        self.ui.textBrowser_preview.clear()
        item = self.file_model.itemFromIndex(current)
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
                logging.error("Could not determine size of file: {}".format(item_data))
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

    @busy_effect
    @pyqtSlot(QModelIndex, name="open_file")
    def open_file(self, ind):
        """Open file or directory embedded into item's data (user role).
        Given index points to the item.

        Args:
            ind (QModelIndex): Index of the double-clicked QStandardItem
        """
        model = ind.model()  # Could be folder_model or file_model
        item = model.itemFromIndex(ind)
        item_data = item.data(Qt.UserRole)  # Contains path to folder or file
        if not item_data:
            return
        item_text = item.data(Qt.DisplayRole)
        if item_text == 'failed':
            self.populate_failed_folder(item_data)
            return
        elif item_text == '..':
            # Get selected Setup
            try:
                index = self.ui.treeView_setups.selectedIndexes()[0]
            except IndexError:
                # Nothing selected
                index = self.setup_model.index(0, 0, QModelIndex())
            mapped_index = self.proxy_setup_model.mapToSource(index)
            setup = mapped_index.internalPointer()
            logging.debug("Selected Setup: {}".format(setup.name))
            self.populate_folder_model(os.listdir(setup.output_dir), setup)
            return
        url = "file:///" + item_data
        file_ext = url[-4:]
        if file_ext == '.bat' or file_ext == '.exe':
            logging.debug("Executable file double-clicked")
            return
        # TODO: Test QDesktopServices on Linux & Mac
        # noinspection PyTypeChecker, PyCallByClass, PyArgumentList
        res = QDesktopServices.openUrl(QUrl(url, QUrl.TolerantMode))
        if not res:
            logging.error("Failed to open url")
        return

    @busy_effect
    def populate_folder_model(self, folders, setup):
        """Update folder model with Setup's output folders.

        Args:
            folders (list): List of folder names
            setup (Setup): Selected Setup
        """
        self.folder_model.clear()
        # Add header item that shows the input directory path
        header = QStandardItem("{}".format(setup.output_dir))
        # Increase font size
        font = header.font()
        font.setPointSize(10)
        header.setFont(font)
        # Set header
        header.setData(setup.output_dir, Qt.ToolTipRole)
        header.setData(Qt.AlignLeft, Qt.TextAlignmentRole)
        self.folder_model.setHorizontalHeaderItem(0, header)
        if not setup.tool:
            self.folder_model.appendRow(QStandardItem("No Tool. No Results."))
            return
        if not folders:
            self.folder_model.appendRow(QStandardItem("..."))
            return
        # Check for applied filters
        folders = self.check_filters(folders)
        icon_provider = QFileIconProvider()
        for folder in folders:
            item = QStandardItem(folder)
            folder_path = os.path.join(setup.output_dir, folder)
            # Set custom icon to failed folder
            if folder == 'failed':
                item.setData(self.goto_dir_icon, Qt.DecorationRole)
                # Set failed folder path to item data
                item.setData(folder_path, Qt.UserRole)
            else:
                # Get the icon that is used by explorer and show as decoration role
                folder_info = QFileInfo(folder_path)
                icon = icon_provider.icon(folder_info)
                item.setData(icon, Qt.DecorationRole)
            # Set folder path to item data
            item.setData(folder_path, Qt.UserRole)
            # Append row to folder model
            self.folder_model.appendRow(item)
        return

    def check_filters(self, folders):
        """Check which radiobutton is selected and modify folder list accordingly.

        Args:
            folders (list): List of folder names

        Returns:
            Modified folder list
        """
        if self.ui.radioButton_show_all.isChecked():
            return folders
        elif self.ui.radioButton_show_newest.isChecked():
            # Remove all folders from except the newest
            return self.apply_newest_filter(folders)
        elif self.ui.radioButton_show_today.isChecked():
            # Remove all folders from list that are not made today
            filtered_list = self.apply_today_filter(folders)
            return filtered_list
        elif self.ui.radioButton_show_failed.isChecked():
            filtered_list = list()
            if 'failed' in folders:
                filtered_list.append('failed')
            return filtered_list
        else:
            logging.error("Unknown radio button checked.")
            return folders

    def apply_today_filter(self, folders):
        """Return only the folders that have today's timestamp."""
        date = datetime.datetime.today()
        f_dict = dict()
        returned_list = list()
        for folder in folders:
            # folder is a timestamp
            try:
                date_obj = datetime.datetime.strptime(folder, '%Y-%m-%dT%H.%M.%S')
            except ValueError:
                continue
            # Populate dictionary with parsed datetime object as key and folder name as value
            f_dict[date_obj] = folder
        # Return empty list if no timestamped folders found
        if not f_dict:
            return list()
        # Compare timestamps to today's date
        for key, value in f_dict.items():
            # logging.debug("key:{0} {1}.{2}.{3}".format(key, key.day, key.month, key.year))
            # logging.debug("value:{}".format(value))
            if key.day == date.day and key.month == date.month and key.year == date.year:
                returned_list.append(value)
        return returned_list
        # return list()
        # latest_date = max(f_dict.keys())


    def apply_newest_filter(self, folders):
        """Return only the newest folder from the given list."""
        base_path = os.path.split(folders[0])[0]
        folder_names = [os.path.basename(folder) for folder in folders]
        f_dict = dict()
        for folder_name in folder_names:
            # folder_name is a timestamp
            try:
                date_obj = datetime.datetime.strptime(folder_name, '%Y-%m-%dT%H.%M.%S')
            except ValueError:
                # logging.debug("Tried to get time stamp from folder: {0}".format(folder_name))
                continue
            # Populate dictionary with parsed datetime object as key and folder name as value
            f_dict[date_obj] = folder_name
        # Return None if no timestamped folders found
        if not f_dict:
            return list()
        # Get the latest date
        latest_date = max(f_dict.keys())
        # Get the folder corresponding to the latest date
        newest_folder_name = f_dict.get(latest_date)
        # logging.debug("latest date:{0}. latest folder:{1}".format(latest_date, latest_folder_name))
        latest_folder_path = os.path.join(base_path, newest_folder_name)
        return [latest_folder_path]

    @busy_effect
    def populate_file_model(self, files, folder):
        """Update file model with given files.

        Args:
            files (list): List of files
            folder (str): Abs. path to current folder

        """
        self.file_model.clear()
        # Add header item that shows the input directory path
        header = QStandardItem("{}".format(os.path.basename(folder)))
        # Increase font size
        font = header.font()
        font.setPointSize(10)
        header.setFont(font)
        # Set header to model
        self.file_model.setHorizontalHeaderItem(0, header)
        if not files:
            self.file_model.appendRow(QStandardItem("..."))
            return
        icon_provider = QFileIconProvider()
        # Make an 'open directory' item
        dir_item = QStandardItem(".")
        dir_info = QFileInfo(folder)
        dir_icon = icon_provider.icon(dir_info)
        dir_item.setData(dir_icon, Qt.DecorationRole)
        dir_item.setData(folder, Qt.UserRole)  # Set parent directory as item data
        dir_item.setData(folder, Qt.ToolTipRole)
        self.file_model.appendRow(dir_item)
        for file in files:
            item = QStandardItem(file)
            file_path = os.path.join(folder, file)
            # Get the icon that is used by explorer and show as decoration role
            info = QFileInfo(file_path)
            icon = icon_provider.icon(info)
            item.setData(icon, Qt.DecorationRole)
            # Set folder path to item data
            item.setData(file_path, Qt.UserRole)
            item.setData(file_path, Qt.ToolTipRole)
            # Append row to folder model
            self.file_model.appendRow(item)
        return

    def populate_failed_folder(self, folder_path):
        """Populate failed folder contents into folder model.

        Args:
            folder_path (str): Abs. path to failed folder
        """
        self.file_model.clear()
        self.folder_model.clear()
        # Add header item that shows the input directory path
        header = QStandardItem("{}".format(folder_path))
        # Increase font size
        font = header.font()
        font.setPointSize(10)
        header.setFont(font)
        # Set header
        header.setData(folder_path, Qt.ToolTipRole)
        header.setData(Qt.AlignLeft, Qt.TextAlignmentRole)
        self.folder_model.setHorizontalHeaderItem(0, header)
        folders = os.listdir(folder_path)
        if not folders:
            self.folder_model.appendRow(QStandardItem("..."))
            return
        icon_provider = QFileIconProvider()
        # Make a 'go to parent directory' item
        parent_dir_path = os.path.abspath(os.path.join(folder_path, os.path.pardir))
        parent_dir_item = QStandardItem("..")
        parent_dir_item.setData(self.goto_dir_icon, Qt.DecorationRole)
        parent_dir_item.setData(parent_dir_path, Qt.UserRole)  # Set parent directory as item data
        parent_dir_item.setToolTip(parent_dir_path)
        self.folder_model.appendRow(parent_dir_item)
        for folder in folders:
            item = QStandardItem(folder)
            item_path = os.path.join(folder_path, folder)
            # Get the icon that is used by explorer and show as decoration role
            folder_info = QFileInfo(item_path)
            icon = icon_provider.icon(folder_info)
            item.setData(icon, Qt.DecorationRole)
            # Set folder path to item data
            item.setData(item_path, Qt.UserRole)
            # Append row to folder model
            self.folder_model.appendRow(item)
        return

    # noinspection PyMethodMayBeStatic
    def output_files(self, folder):
        """Return a list of files in the Setup's output directory.

        Args:
            folder (str): Abs. path to folder
        """
        return os.listdir(folder)

    # noinspection PyMethodMayBeStatic
    def output_folders(self, setup):
        """Return a list of folders in the Setup's output directory.

        Args:
            setup (QModelIndex): Setup index
        """
        output_dir = setup.internalPointer().output_dir
        return os.listdir(output_dir)

    def keyPressEvent(self, e):
        """Handle key presses.

        Args:
            e (QKeyEvent): Received key press event.
        """
        if e.key() == Qt.Key_Return or e.key() == Qt.Key_Enter:
            index = self.ui.tableView_folders.currentIndex()
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
