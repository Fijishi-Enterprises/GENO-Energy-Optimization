"""
Widget to ask the user for created Setup details.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   5.4.2015
"""

from PyQt5.QtWidgets import QWidget, QStatusBar
from PyQt5 import QtCore
import ui.setup_popup
import logging


class SetupPopupWidget(QWidget):
    """ A widget to query user's preferences for created Setup

    Attributes:
        parent: PyQt parent widget.
    """

    create_base_signal = QtCore.pyqtSignal(str, str)
    create_child_signal = QtCore.pyqtSignal(str, str, "QModelIndex")

    def __init__(self, parent, index):
        """ Initialize class. """
        super().__init__()
        self._parent = parent
        self._create_base = True
        if index is not None:
            self._index = index  # Parent (index) of the child Setup
            self._create_base = False
        #  Set up the user interface from Designer.
        self.ui = ui.setup_popup.Ui_Form()
        self.ui.setupUi(self)
        # Add Status Bar to widget
        self.statusbar = QStatusBar(self)
        self.ui.verticalLayout.addWidget(self.statusbar)
        self.statusbar.setSizeGripEnabled(False)
        self.connect_signals()
        self.ui.pushButton_ok.setDefault(True)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(QtCore.Qt.WA_DeleteOnClose)

    def connect_signals(self):
        """ Connect PyQt signals. """
        # Button clicked handlers
        self.ui.pushButton_ok.clicked.connect(self.ok_clicked)
        self.ui.pushButton_cancel.clicked.connect(self.close)

    @QtCore.pyqtSlot()
    def ok_clicked(self):
        """Check that Setup name is valid and create Setup."""
        name = self.ui.lineEdit_name.text()
        description = self.ui.lineEdit_description.text()
        # Check for invalid characters for a folder name
        invalid_chars = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*", "."]
        # "." is actually valid in a folder name but
        # this is to prevent creating folders like "...."
        if any((True for x in name if x in invalid_chars)):
            self.statusbar.showMessage("Name not valid for a folder name", 3000)
            return
        # Check that Setup name is not 'root'
        if name.lower() == 'root':
            msg = "'root' is reserved. Use another name for Setup"
            self.statusbar.showMessage(msg, 3000)
            return
        model = self._parent.setup_model
        start_index = model.index(0, 0, QtCore.QModelIndex())
        # Check start index
        if not start_index.isValid():
            logging.debug("No Setups in model")
            self.create_base_signal.emit(name, description)
            return
        matching_index = model.match(
            start_index, QtCore.Qt.DisplayRole, name, 1, QtCore.Qt.MatchFixedString | QtCore.Qt.MatchRecursive)
        # Match found
        if len(matching_index) > 0:
            msg = "Setup '%s' already exists" % name
            self.statusbar.showMessage(msg, 3000)
            return
        # Check that existing Setups' short names doesn't match the new Setup's short name
        # This is to prevent two Setups of using the same folder
        all_setups = model.match(
            start_index, QtCore.Qt.DisplayRole, '.*', -1, QtCore.Qt.MatchRegExp | QtCore.Qt.MatchRecursive)
        logging.debug("Found %d" % len(all_setups))
        new_setup_short_name = name.lower().replace(' ', '_')
        for setup in all_setups:
            # logging.debug("'%s' found. Short name:%s"
            #  % (setup.internalPointer().name, setup.internalPointer().short_name))
            setup_short_name = setup.internalPointer().short_name
            if setup_short_name == new_setup_short_name:
                msg = "Setup with short name '%s' already exists" % setup_short_name
                self.statusbar.showMessage(msg, 3000)
                return
        # Create new Setup
        else:
            if self._create_base:
                self.create_base_signal.emit(name, description)
            else:
                self.create_child_signal.emit(name, description, self._index)
            return
        # ui_main closes widget when Ok button is pressed

    def closeEvent(self, event):
        """Handle close window.

        Args:
            event (QEvent): Closing event if 'X' is clicked.
        """
        self.close()
