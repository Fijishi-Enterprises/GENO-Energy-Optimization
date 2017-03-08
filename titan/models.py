"""
Classes to handle PyQt's model/view frameworks model part.
Note: These models have nothing to do with Backbone, Balmorel, WILMAR, etc.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   2.4.2016
"""

import logging
from PyQt5.QtCore import Qt, QVariant, QAbstractItemModel, \
    QAbstractListModel, QModelIndex, QSortFilterProxyModel, QMimeData
from PyQt5.Qt import QBrush, QColor
from setup import Setup
from helpers import AnimatedSpinningWheelIcon


class SetupModel(QAbstractItemModel):
    """Class to store Setup objects. Can be used by any PyQt view widget.

    Attributes:
        root (Setup): Root Setup of the model. Note: Base Setups are children of root Setups.
        parent (Setup): Not used
    """
    def __init__(self, root, parent=None):
        super().__init__(parent)
        self._root_setup = root
        self._base_index = None  # Used in tree traversal algorithms
        self.next_setup = None  # Used with depth-first algorithm
        self.animated_icon = AnimatedSpinningWheelIcon()

    def get_root(self):
        """Returns root Setup."""
        return self._root_setup

    def set_base(self, ind):
        """Set base index for this tree. Used to determine the starting point
        for tree traversal algorithms.

        Args:
            ind (QModelIndex): Index of the new base Setup.
        """
        if not ind.isValid():
            logging.error("Index not valid for a base Setup")
            return
        self._base_index = ind

    def get_base(self):
        """Returns base Setup index for this model."""
        return self._base_index

    def rowCount(self, parent=None, *args, **kwargs):
        """Returns row count of the model for the view.

        Args:
            parent (QModelIndex): Index of parent Setup
        """
        if parent.column() > 0:
            return 0
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
        return 3

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
        if not role == Qt.DisplayRole and not role == Qt.DecorationRole:
            # logging.debug("index row:%d, role:%s" % (index.row(), role))
            return None
        setup = index.internalPointer()
        # Show DecorationRole
        if role == Qt.DecorationRole:
            if index.column() == 0:
                if setup.running:
                    # Return the current frame of the QMovie
                    return self.animated_icon.get_icon()
                else:
                    return None
            else:
                return None
        # Return DisplayRole
        if role == Qt.DisplayRole:
            if index.column() == 0:
                # Show Setup name
                return setup.name
            elif index.column() == 1:
                # Show Tool name
                if not setup.tool:
                    return ''
                else:
                    return setup.tool.name
            elif index.column() == 2:
                # Show cmdline_args
                if not setup.tool:
                    return ''
                else:
                    tool_args = setup.tool.cmdline_args
                    setup_args = setup.cmdline_args
                    if not tool_args:
                        tool_args = ''
                    if not setup_args:
                        setup_args = ''
                    if tool_args == '':
                        return setup_args
                    elif setup_args == '':
                        return tool_args
                    else:
                        return tool_args + ' ' + setup_args
            else:
                return None

    def flags(self, index):
        """Set flags for the item requested by view.

        Args:
            index (QModelIndex): Index of item.

        Returns:
            Flags
        """
        return Qt.ItemIsEnabled | Qt.ItemIsSelectable | Qt.ItemIsDragEnabled | Qt.ItemIsDropEnabled

    def supportedDropActions(self):
        """Enable item moving."""
        return Qt.MoveAction

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
                return "Name"
            elif section == 1:
                return "Tool"
            elif section == 2:
                return "Command Line Args"
        else:
            return None

    def parent(self, index=None):
        """Gives parent of the setup with the given QModelIndex.

        Args:
            index (QModelIndex): Given index

        Returns:
            Parent of the setup with the given QModelIndex
        """
        setup = self.get_setup(index)
        parent_setup = setup.parent()

        if not parent_setup:
            return QModelIndex()

        if parent_setup == self._root_setup:
            return QModelIndex()

        return self.createIndex(parent_setup.row(), 0, parent_setup)

    def index(self, row, column, parent=QModelIndex(), *args, **kwargs):
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
        # TODO: Add new Setup to the end of the list
        parent_setup = self.get_setup(parent)
        self.beginInsertRows(parent, row, row)
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

    def mimeTypes(self):
        return ['text/plain']

    def mimeData(self, indexes):
        """Reimplemented mimeData.

        Args:
            indexes (list): Probably includes three indexes because model has 3 columns
        """
        names = [a.internalPointer().name for a in indexes]
        data = QMimeData()
        data.setText(names[0])
        return data

    def dropMimeData(self, data, action, row, column, parent):
        """Reimplemented dropMimeData.

        Args:
            data (QMimeData): Data of the dropped item
            action (DropAction): Action (Qt.DropAction)
            row (int): Row
            column (int): Column
            parent (QModelIndex): Parent index
        """
        if action == Qt.MoveAction:  # :2
            setup_name = data.text()
            setup_index = self.find_index(setup_name)  # Index of dropped Setup
            # Check that dropped Setup index was found successfully
            if not setup_index:
                logging.error("Setup corresponding to name {} not found".format(setup_name))
                return False
            # Get source parent and row
            source_parent = setup_index.parent()
            source_row = setup_index.row()
            # Get destination Setup parent name
            if not parent:
                logging.error("Parent is None")
                return False
            elif not parent.isValid():
                parent_name = 'root'
            else:
                parent_name = parent.internalPointer().name
            if row == -1 and column == -1:
                # Item dropped on item at index parent. Make dropped item the first child of parent.
                if parent_name == 'root':
                    # Item dropped in invalid spot
                    logging.debug("Invalid index")
                    return False
                if not self.moveRow(source_parent, source_row, parent, 0):
                    logging.debug("Move dismissed")
                    return False
                return True
            else:
                # Item dropped between items. Move dropped item on row row and set parent as parent, ignore column
                if parent_name == 'root':
                    parent = QModelIndex()
                if not self.moveRow(source_parent, source_row, parent, row):
                    logging.debug("Move dismissed")
                    return False
                return True
        else:
            logging.error("Unsupported action ({}) in dropMimeData".format(action))
            return False

    def moveRow(self, src_parent, src_row, dst_parent, dst_row):
        """Reimplemented moveRow method. Move Setups in the model.

        Args:
            src_parent (QModelIndex): Source Setup parent index
            src_row (int): Source row
            dst_parent (QModelIndex): Destination Setup parent index
            dst_row (int): Destination row
        """
        # Move Setup within same parent
        if src_parent == dst_parent:
            if not src_parent.isValid():
                # Move base Setup
                begin_move_success = self.beginMoveRows(QModelIndex(), src_row, src_row, QModelIndex(), dst_row)
                if not begin_move_success:
                    return False
                self._root_setup.move_child(src_row, self._root_setup, dst_row)
                self.endMoveRows()
            else:
                # Move within same parent (not root)
                begin_move_success = self.beginMoveRows(src_parent, src_row, src_row, dst_parent, dst_row)
                if not begin_move_success:
                    return False
                src_parent.internalPointer().move_child(src_row, dst_parent.internalPointer(), dst_row)
                self.endMoveRows()
            return True
        # Move Setup from one parent to another
        else:
            if not src_parent.isValid():
                # Move base Setup to another parent
                begin_move_success = self.beginMoveRows(QModelIndex(), src_row, src_row, dst_parent, dst_row)
                if not begin_move_success:
                    return False
                self._root_setup.move_child(src_row, dst_parent.internalPointer(), dst_row)
                self.endMoveRows()
            elif not dst_parent.isValid():
                # Move Setup from a parent to be a base Setup
                begin_move_success = self.beginMoveRows(src_parent, src_row, src_row, QModelIndex(), dst_row)
                if not begin_move_success:
                    return False
                src_parent.internalPointer().move_child(src_row, self._root_setup, dst_row)
                self.endMoveRows()
            else:
                # Move Setup from one parent to another
                begin_move_success = self.beginMoveRows(src_parent, src_row, src_row, dst_parent, dst_row)
                if not begin_move_success:
                    return False
                src_parent.internalPointer().move_child(src_row, dst_parent.internalPointer(), dst_row)
                self.endMoveRows()
            return True

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

    def get_next_setup_selected(self, selected_index):
        """Get next Setup when executing a Setup chain.
        Returns the first parent of selected index that
        is not ready. Returns None if all parents and the
        selected index have been executed.

        Args:
            selected_index (QModelIndex): Selected Setup index
        """
        if not selected_index:
            return None  # Happens if user deselects Setup while simulation is running
        # If base has no children, return None
        n_children = self._base_index.internalPointer().child_count()
        # Stop execution if Base has no children
        if n_children == 0:
            return None
        # Get all parents of selected index into a list
        exec_list = list()
        exec_list.append(selected_index)
        parent = self.parent(selected_index)
        while parent.isValid():
            exec_list.append(parent)
            parent = self.parent(parent)
        # Remove base Setup from list because it has already been executed
        exec_list.pop(-1)
        # Reverse list so execution starts from the bottom
        exec_list.reverse()
        # Return first index from list that is not ready
        for index in exec_list:
            if not index.internalPointer().is_ready:
                return index
        return None

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
            next_setup = self.depth_first()
        if not next_setup:
            return None
        return next_setup

    def breadth_first(self, siblings):
        """Traverse Setup tree by levels (breadth-first traversal algorithm).
        Visit every node on a level before going to a lower level. Note:
        The algorithm starts on the second level so that 1st level (base) Setups
        are not part of this algorithm.

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

    def depth_first(self):
        """Traverse Setup tree using pre-order depth-first algorithm.
        Ugly hack but gets the job done.

        Returns:
            First encountered Setup, which is not ready or None if all Setups ready
        """
        self.next_setup = None

        def traverse(setup):
            # Helper function to traverse tree
            # logging.debug("Setup name: %s (%s)" % (setup.name, setup.is_ready))
            if not setup.is_ready and self.no_next_setup():
                if setup.parent().name == 'root':
                    # logging.debug("Skipping base Setup")
                    pass
                else:
                    self.update_next_setup(setup)
                    return
            for kid in setup.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from base
        traverse(self.get_base().internalPointer())
        if not self.next_setup:
            return None
        else:
            return self.find_index(self.next_setup.name)

    def no_next_setup(self):
        """Helper method for depth-first algorithm."""
        if not self.next_setup:
            return True
        return False

    def update_next_setup(self, item):
        """Helper method for depth-first algorithm.

        Args:
            item (Setup): Next Setup to be executed
        """
        self.next_setup = item

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


class SetupProxyModel(QSortFilterProxyModel):
    """Proxy model to filter out other columns than the first one. Do not show decoration."""
    def __init__(self):
        super().__init__()

    def columnCount(self, parent=None, *args, **kwargs):
        """Get the number of hierarchy levels from the source model.

        Args:
            parent (QModelIndex): Parent index
        """
        return 1

    def data(self, index, role=None):
        """Reimplemented method to hide the decoration.

        Args:
            index (QModelIndex): Requested index
            role (int): Requested role
        """
        if not role == Qt.DisplayRole:
            return None
        source_index = self.mapToSource(index)
        if source_index.isValid():
            return source_index.internalPointer().name
        else:
            return None


class SetupAndToolProxyModel(QSortFilterProxyModel):
    """Proxy model to show the name and tool columns from the Setup model."""
    def __init__(self):
        super().__init__()
        self.green_brush = QBrush(QColor('lightgreen'))
        self.red_brush = QBrush(QColor('salmon'))

    def columnCount(self, parent=None, *args, **kwargs):
        """Get the number of hierarchy levels from the source model.

        Args:
            parent (QModelIndex): Parent index
        """
        return 2

    def data(self, index, role=None):
        """Reimplemented method to hide the decoration.

        Args:
            index (QModelIndex): Requested index
            role (int): Requested role
        """
        if role == Qt.BackgroundRole:
            source_index = self.mapToSource(index)
            if not source_index.internalPointer().ready_to_run:
                return None
            elif source_index.internalPointer().ready_to_run == 1:
                return self.green_brush
            elif source_index.internalPointer().ready_to_run == 2:
                return self.red_brush
        if role == Qt.DisplayRole:
            source_index = self.mapToSource(index)
            if not source_index.isValid():
                return None
            if index.column() == 0:
                return source_index.internalPointer().name
            elif index.column() == 1:
                if not source_index.internalPointer().tool:
                    return None
                else:
                    return source_index.internalPointer().tool.name
        else:
            return None

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
            Tool name when display role requested
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
        """Returns enabled flags for the given index.

        Args:
            index (QModelIndex): Index of Tool
        """
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
            Nothing
        """
        self.beginInsertRows(parent, row, row)
        self._tools.append(tool)
        self.endInsertRows()

    def removeRow(self, row, parent=QModelIndex(), *args, **kwargs):
        """Remove row (tool) from model.

        Args:
            row (int): Row to remove the tool from
            parent (QModelIndex): Parent of tool on row (not used)
            *args:
            **kwargs:

        Returns:
            Nothing
        """
        if row < 0 or row > self.rowCount():
            logging.error("Invalid row number")
            return False
        self.beginRemoveRows(parent, row, row)
        self._tools.pop(row)
        self.endRemoveRows()
        return True

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
                if name.lower() == tool.name.lower():
                    return tool
        return False
