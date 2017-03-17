"""
Widget to ask the user for created Setup details.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   5.4.2016
"""

import logging
from PyQt5.QtWidgets import QWidget, QStatusBar
from PyQt5.QtCore import pyqtSlot, QModelIndex, Qt
import ui.setup_form
from config import STATUSBAR_STYLESHEET


class SetupFormWidget(QWidget):
    """ A widget to query user's preferences for created Setup

    Attributes:
        parent: PyQt parent widget.
    """
    def __init__(self, parent, index):
        """ Initialize class. """
        super().__init__(flags=Qt.Window)
        self._parent = parent  # QWidget parent
        #  Set up the user interface from Designer.
        self.ui = ui.setup_form.Ui_Form()
        self.ui.setupUi(self)
        # Add status bar to form
        self.statusbar = QStatusBar(self)
        self.statusbar.setFixedHeight(20)
        self.statusbar.setSizeGripEnabled(False)
        self.statusbar.setStyleSheet(STATUSBAR_STYLESHEET)
        self.ui.horizontalLayout_statusbar_placeholder.addWidget(self.statusbar)
        # Class attributes
        self.create_base = True
        self.parent_index = index  # Parent Setup index
        if index.isValid():
            self.create_base = False
        self.setupname = ''
        self.setupdescription = ''
        # Add ToolModel into ComboBox view
        self.ui.comboBox_tool.setModel(self._parent.tool_model)
        self.connect_signals()
        self.ui.lineEdit_name.setFocus()
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)

    def connect_signals(self):
        """ Connect PyQt signals. """
        # Setup name -> folder name connection
        self.ui.lineEdit_name.textChanged.connect(self.name_changed)
        # Button clicked handlers
        self.ui.pushButton_ok.clicked.connect(self.ok_clicked)
        self.ui.pushButton_cancel.clicked.connect(self.close)
        self.ui.comboBox_tool.currentIndexChanged.connect(self.update_args)

    @pyqtSlot(int, name='update_args')
    def update_args(self, row):
        """Show Tool command line arguments in text input.

        Args:
            row (int): Selected row number
        """
        if row == 0:
            # No Tool selected
            self.ui.lineEdit_tool_args.setText("")
            return
        selected_tool = self._parent.tool_model.tool(row)
        args = selected_tool.cmdline_args
        if not args:
            # Tool cmdline_args is None if the line does not exist in Tool definition file
            args = ''
        self.ui.lineEdit_tool_args.setText("{0}".format(args))
        return

    @pyqtSlot(name='name_changed')
    def name_changed(self):
        """Update label to show upcoming folder name."""
        setup_name = self.ui.lineEdit_name.text()
        default = "Folder name:"
        if setup_name == '':
            self.ui.label_setup_folder.setText(default)
        else:
            folder_name = setup_name.lower().replace(' ', '_')
            msg = default + " " + folder_name
            self.ui.label_setup_folder.setText(msg)

    @pyqtSlot(name='ok_clicked')
    def ok_clicked(self):
        """Check that Setup name is valid and create Setup."""
        self.setupname = self.ui.lineEdit_name.text()
        self.setupdescription = self.ui.lineEdit_description.text()
        # Check for invalid characters for a folder name
        invalid_chars = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*", "."]
        # "." is actually valid in a folder name but
        # this is to prevent creating folders like "...."
        if any((True for x in self.setupname if x in invalid_chars)):
            self.statusbar.showMessage("Name not valid for a folder name", 3000)
            return
        # Check that Setup name is not 'root'
        if self.setupname.lower() == 'root':
            msg = "'root' is reserved. Use another name for Setup"
            self.statusbar.showMessage(msg, 3000)
            return
        model = self._parent.setup_model
        start_index = model.index(0, 0, QModelIndex())
        # Check if Setup with the same name already exists
        if start_index.isValid():
            matching_index = model.match(
                start_index, Qt.DisplayRole, self.setupname, 1, Qt.MatchFixedString | Qt.MatchRecursive)
            if len(matching_index) > 0:
                # Match found
                msg = "Setup '%s' already exists" % self.setupname
                self.statusbar.showMessage(msg, 3000)
                return
            # Check that no existing Setup short name matches the new Setup's short name.
            # This is to prevent two Setups of using the same folder.
            all_setups = model.match(
                start_index, Qt.DisplayRole, '.*', -1, Qt.MatchRegExp | Qt.MatchRecursive)
            logging.debug("%d Setups in model" % len(all_setups))
            new_setup_short_name = self.setupname.lower().replace(' ', '_')
            for setup in all_setups:
                # logging.debug("'%s' found. Short name:%s"
                #  % (setup.internalPointer().name, setup.internalPointer().short_name))
                setup_short_name = setup.internalPointer().short_name
                if setup_short_name == new_setup_short_name:
                    msg = "Setup using folder name '%s' already exists" % setup_short_name
                    self.statusbar.showMessage(msg, 3000)
                    return
        # Create new Setup
        if not start_index.isValid():
            logging.debug("Adding first Setup to model")
        self.call_add_setup()
        self.close()

    def call_add_setup(self):
        """Creates new Setup according to user's input."""
        logging.debug("Creating Setup")
        c_index = self.ui.comboBox_tool.currentIndex()
        if c_index == 0:
            logging.debug("No tool selected for this Setup")
            selected_tool = None
        else:
            c_text = self.ui.comboBox_tool.currentText()
            logging.debug("Adding tool '{0}' to Setup '{1}'".format(c_text, self.setupname))
            selected_tool = self._parent.tool_model.tool(c_index)
        cmdline_params = self.ui.lineEdit_cmdline_params.text()  # Setup cmdline_args
        logging.debug("command line arguments: '%s'" % cmdline_params)
        self._parent.add_setup(self.setupname, self.setupdescription, selected_tool, cmdline_params, self.parent_index)

    def keyPressEvent(self, e):
        """Close Setup form when escape key is pressed.

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
