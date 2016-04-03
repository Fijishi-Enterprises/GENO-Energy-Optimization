"""
Classes to handle PyQt's model/view frameworks model part.
Note: These models have nothing to do with Balmorel, WILMAR or PSS-E.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   2.4.2016
"""

import logging
from PyQt5.QtCore import Qt, QVariant, QAbstractItemModel, \
    QAbstractListModel, QModelIndex, QSortFilterProxyModel
from tool import Setup


class SetupModel(QAbstractItemModel):
    """Class to store Setup objects. Can be used by any PyQt view widget.

    Attributes:
        root (Setup): Root Setup of the model. Note: Base Setups are children of root Setups.
        parent (Setup): Not used
    """
    def __init__(self, root, parent=None):
        """SetupModel constructor."""
        super().__init__(parent)
        self._root_setup = root

    def rowCount(self, parent=None, *args, **kwargs):
        """Returns row count of the model for the view.

        Args:
            parent (QModelIndex): Index of parent Setup
        """
        if not parent.isValid():
            parent_setup = self._root_setup
        else:
            parent_setup = parent.internalPointer()

        return parent_setup.child_count()

    def columnCount(self, parent=None, *args, **kwargs):
        """Returns column count for the view.

        Args:
            parent (QModelIndex): Index of parent Setup
        """
        return 1

    def data(self, index, role=None):
        """Set data for model
        Args:
            index (QModelIndex): Index to edit
            role (int): Edited role

        Returns:
            QVariant depending on role.
        """
        if not index.isValid():
            return None

        setup = index.internalPointer()

        if role == Qt.DisplayRole:
            if index.column() == 0:
                if setup.is_ready:
                    return setup.name + " (Ready)"
                return setup.name

    def flags(self, index):
        """Set flags for the item requested by view.

        Args:
            index (QModelIndex): Index of item.

        Returns:
            Flags
        """
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable

    def headerData(self, section, orientation, role=None):
        """Set data for header.

        Args:
            section (int): Section to edit
            orientation (Orientation): Orientation (Rows or columns)
            role (int): Role to edit

        Returns:
            QVariant depending on role.
        """
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
            parent (QModelIndex): Index of parent Setup

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
            index (QModelIndex): Index of Setup

        Returns:
            Setup at given index or Root Setup if index is not valid
        """
        if index.isValid():
            setup = index.internalPointer()
            if setup:
                return setup
        return self._root_setup

    def insert_setup(self, name, description, project, row, parent=QModelIndex()):
        """Add new Setup to model.

        Args:
            name (str): Setup name
            description (str): Setup description
            project (object): User's project
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
        """Updates the view. Can be used when data (Setup) changes."""
        # noinspection PyUnresolvedReferences
        self.dataChanged.emit(QModelIndex(), QModelIndex())

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

    # def add_data(self, row, d, parent=QModelIndex()):
    #     """Append new object as the root setup.
    #
    #     Args:
    #         row (int): Row where to insert new setup
    #         d (Setup): New Setup object
    #         parent (QModelIndex): Index of parent. Will be invalid if parent is root.
    #
    #     Returns:
    #         True if successful, False otherwise
    #     """
    #     parent_setup = self.get_setup(parent)
    #
    #     # self.beginInsertRows(QModelIndex(), len(self._root_setup), len(self._root_setup))
    #     self.beginInsertRows(parent, row, row)
    #     retval = parent_setup.add_child(d)
    #     # self._root_setup = d
    #     self.endInsertRows()
    #     return retval


class ToolProxyModel(QSortFilterProxyModel):
    """Proxy model for SetupModels to show only the tool associated with a selected Setup.

    Attributes:
        ui (TitanUI): Needed to get selected item from QTreeView
    """
    def __init__(self, ui):
        """Class constructor."""
        super().__init__()
        self._ui = ui

    def rowCount(self, parent=None, *args, **kwargs):
        """Return number of rows depending on if the selected Setup has a tool.

        Args:
            parent (QModelIndex): Index of parent. Not needed in a QListView.
        """
        n = len(self._ui.treeView_setups.selectedIndexes())
        if n == 1:
            try:
                index = self._ui.treeView_setups.selectedIndexes()[0]
            except IndexError:
                return 0
            setup = index.internalPointer()
            tools_list = list(setup.tools.items())
            if not tools_list:  # No tool in setup
                return 0
            return 1
        else:
            return 0

    def emit_data_changed(self):
        """Updates the view."""
        # noinspection PyUnresolvedReferences
        self.dataChanged.emit(QModelIndex(), QModelIndex())

    def data(self, index, role=None):
        """Return tool name if Setup has one.
        Args:
            index (QModelIndex): Index in tool view
            role (int): Role to edit

        Returns:
            Tool name if available
        """
        if not index.isValid():
            logging.error("index not valid %s" % index)
            return
        if role == Qt.DisplayRole:
            try:
                index = self._ui.treeView_setups.selectedIndexes()[0]
            except IndexError:
                logging.error("ToolProxyModel: Nothing selected")
                return ""

            setup = index.internalPointer()
            # Get tool name associated with Setup
            tools_list = list(setup.tools.items())
            if not tools_list:  # No tool in setup
                logging.error("No tool in selected Setup")
                return ""
            tool = tools_list[0][0]
            return tool.name


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


