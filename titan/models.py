"""
Classes to handle PyQt's model/view frameworks model part.
Note: These models have nothing to do with Balmorel, WILMAR or PSS-E.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   2.4.2016
"""

import logging
from PyQt5.QtCore import Qt, QVariant, QAbstractItemModel, \
    QAbstractListModel, QModelIndex, QSortFilterProxyModel, QSize
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
        self._base_index = None  # Used in tree traversal algorithms

    def get_root(self):
        """Returns root Setup."""
        return self._root_setup

    def set_base(self, ind):
        """Set base index for this tree. Used to determine the starting point
        for tree traversal algorithms. If the whole project should be
        executed. This should be set to Root.

        Args:
            ind (QModelIndex): Index of Base Setup.
        """
        # TODO: Test with root setup if the whole project is executed
        self._base_index = ind

    def get_base(self):
        """Returns base Setup index for this model."""
        return self._base_index

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
        """Set data for model.

        Args:
            index (QModelIndex): Index to edit
            role (int): Edited role

        Returns:
            QVariant depending on role.
        """
        if not index.isValid():
            return None
        if not role == Qt.DisplayRole:
            # logging.debug("index row:%d, role:%s" % (index.row(), role))
            return None
        setup = index.internalPointer()
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
        # elif role == Qt.SizeHintRole:
        #     logging.debug("SizeHintRole, section:%d, orientation:%s" % (section, orientation))
        #     return QSize(40, 20)
        else:
            # return super().headerData(section, orientation, role)
            return QVariant()

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

        if not parent_setup:
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
        if row < 0 or row >= self.rowCount(parent) or column < 0 or column >= self.columnCount(parent):
            return QModelIndex()

        parent_setup = self.get_setup(parent)
        child_setup = parent_setup.child(row)

        if child_setup:
            return self.createIndex(row, column, child_setup)
        else:
            return QModelIndex()

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

    def remove_setup(self, row, parent=QModelIndex()):
        """Remove Setup with given parent and row.

        Args:
            row (int): Row of the removed Setup
            parent (QModelIndex): Index of parent. Invalid if parent is root.

        Returns:
            True if successful, False otherwise
        """
        parent_setup = self.get_setup(parent)
        self.beginRemoveRows(parent, row, row)
        retval = parent_setup.remove_child(row)
        self.endRemoveRows()
        return retval

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

    def find_index(self, setup_name):
        """Finds the QModelIndex of a Setup with the given name.

        Args:
            setup_name (str): The searched Setup

        Returns:
            QModelIndex of a Setup with the given name or None if not found
        """
        # model = self.setup_model
        start_index = self.index(0, 0, QModelIndex())
        if start_index.isValid():
            matching_index = self.match(
                start_index, Qt.DisplayRole, setup_name, 1, Qt.MatchFixedString | Qt.MatchRecursive)
            if len(matching_index) == 0:
                # Match not found
                return None
            elif len(matching_index) == 1:
                # Match found
                return matching_index[0]
            else:
                logging.error("Found multiple matching indices with name '%s'). Fix this." % setup_name)
                return matching_index[0]

    def get_siblings(self, index):
        """Return Setup indices on the same row as the given index (siblings).

        Args:
            index (QModelIndex): Index of a Setup which siblings are needed

        Returns:
            List of indices pointing to Setups on the same row.
            Includes also the given index. Returns empty list if
            index is not valid.
        """
        # Number of siblings on given row
        rows = self.rowCount(index.parent())
        if rows == 0:
            return list()
        sibling_list = list()
        for i in range(rows):
            sib = self.index(i, 0, index.parent())
            sibling_list.append(sib)
        return sibling_list

    def get_next_setup(self, breadth_first=True):
        """Get next Setup depending on the tree traversal algorithm in use.

        Args:
            breadth_first (boolean): Tree traversal algorithm. True: breadth_first, False: depth_first

        Returns:
            Index of the first encountered not ready Setup
        """
        # If base has no children, return None
        n_children = self._base_index.internalPointer().child_count()
        # Stop execution if Base has no children
        if n_children == 0:
            return None
        # First child index
        child_index = self._base_index.child(0, 0)
        # Siblings of first child
        siblings = self.get_siblings(child_index)
        if breadth_first:
            next_setup = self.breadth_first(siblings)
        else:
            next_setup = self.depth_first(siblings)
        if not next_setup:
            return None
        return next_setup

    def breadth_first(self, siblings):
        """Traverse Setup tree by levels (breadth-first traversal algorithm).
        Visit every node on a level before going to a lower level.

        Args:
            siblings (list): List of sibling indices

        Returns:
            First encountered Setup, which is not ready
        """
        # Make sure that siblings are in a list, even if only one sibling present
        if not siblings.__class__ == list:
            siblings = list([siblings])
        children_found = False
        index_has_children = None
        for sib in siblings:
            if sib.internalPointer().child_count() is not 0:
                children_found = True
                index_has_children = sib
            if not sib.internalPointer().is_ready:
                return sib
        # First level ready. Get next generation.
        if not children_found:
            logging.debug("Next generation not found")
            return None
        else:
            parent = index_has_children
            next_gen = self.get_next_generation(parent)
            return self.breadth_first(next_gen)

    def depth_first(self, siblings):
        """Traverse Setup tree by levels by pre-order breadth-first algorithm.

        Args:
            siblings (list): List of sibling indices

        Returns:
            First encountered Setup, which is not ready
        """
        # TODO: Fix this algorithm
        # Make sure that siblings are in a list, even if only one sibling present
        if not siblings.__class__ == list:
            siblings = list([siblings])
        for sib in siblings:
            if not sib.internalPointer().is_ready:
                return sib
            else:
                # Check if sib has children
                n_sib_children = sib.internalPointer().child_count()
                if n_sib_children == 0:
                    # Get next sib from siblings
                    continue
                else:
                    # sib has children. Get siblings of the next level
                    child_of_sib = sib.child(0, 0)
                    siblings_of_sib = self.get_siblings(child_of_sib)
                    return self.depth_first(siblings_of_sib)

    def get_next_generation(self, index):
        """Given an index, returns indices of all children on the next level (generation).

        Args:
            index (QModelIndex): index of one parent

        Returns:
            Indices of the next generation (list) or an empty list if none found
        """
        next_gen = list()
        siblings = self.get_siblings(index)
        for sib in siblings:
            n = sib.internalPointer().child_count()
            if n == 0:
                continue
            else:
                first_child = sib.child(0, 0)
                child_siblings = self.get_siblings(first_child)
                for child in child_siblings:
                    next_gen.append(child)
        return next_gen

    def emit_data_changed(self):
        """Updates the view. Can be used when data (Setup) changes."""
        # noinspection PyUnresolvedReferences
        self.dataChanged.emit(QModelIndex(), QModelIndex())


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
            if not setup.tool:  # No tool in setup
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
            role (int): Requested role

        Returns:
            Tool name if available
        """
        if not index.isValid():
            logging.debug("index not valid %s" % index)
            return
        if role == Qt.DisplayRole:
            try:
                index = self._ui.treeView_setups.selectedIndexes()[0]
            except IndexError:
                logging.debug("ToolProxyModel: Nothing selected")
                return ""

            setup = index.internalPointer()
            # Get tool name and command line args associated with Setup
            if not setup.tool:  # No tool in setup
                logging.debug("No tool in selected Setup")
                return ""
            tool_name = setup.tool.name
            cmd = setup.cmdline_args
            return tool_name + "   ['" + cmd + "']"


class ToolModel(QAbstractListModel):
    """Class to store available tools such as Balmorel, Wilmar, etc."""
    def __init__(self, parent=None):
        super().__init__()
        self._tools = list()
        self._tools.append('No tool')
        self._parent = parent

    def rowCount(self, parent=None, *args, **kwargs):
        """Must be reimplemented when subclassing.

        Args:
            parent (QModelIndex): Not used (because this is a list)
            *args:
            **kwargs:

        Returns:
            Number of rows (available tools) in the model
        """
        return len(self._tools)

    def data(self, index, role=None):
        """Must be reimplemented when subclassing.

        Args:
            index (QModelIndex): Requested index
            role (int): Data role

        Returns:
            Tool name when displayrole requested
        """
        if not index.isValid() or self.rowCount() == 0:
            return QVariant()

        if role == Qt.DisplayRole:
            row = index.row()
            if row == 0:
                return self._tools[0]
            else:
                toolname = self._tools[row].name
                return toolname

    def flags(self, index):
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable

    def insertRow(self, tool, row=0, parent=QModelIndex(), *args, **kwargs):
        """Insert tool into model.

        Args:
            tool (Tool): Tool added to the model
            row (str): Row to insert tool to
            parent (QModelIndex): Parent of child (not used)
            *args:
            **kwargs:

        Returns:
            Boolean value depending on operation success
        """
        self.beginInsertRows(parent, row, row)
        self._tools.append(tool)
        self.endInsertRows()

    def tool(self, row):
        """Returns tool located at row

        Args:
            row (int): Row of tool

        Returns:
            Tool from tools list
        """
        return self._tools[row]

    def find_tool(self, name):
        """Returns tool with the given name.

        Args:
            name (str): Name of tool to be found
        """
        for tool in self._tools:
            if isinstance(tool, str):
                continue
            else:
                if name == tool.name:
                    return tool
        return False


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
