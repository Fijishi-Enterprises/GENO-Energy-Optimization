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
    """ A widget class to query user's preferences for created Setup(s)

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
        logging.debug("OK clicked")
        name = self.ui.lineEdit_name.text()
        description = self.ui.lineEdit_description.text()
        if not self.setup_exists(name):
            if self._create_base:
                self.create_base_signal.emit(name, description)
            else:
                self.create_child_signal.emit(name, description, self._index)
            return
        # ui_main closes widget when Ok button is pressed
        else:
            msg = "Setup '%s' already exists" % name
            self.statusbar.showMessage(msg, 3000)
        return

    def setup_exists(self, name):
        model = self._parent.setup_model
        start_index = model.index(0, 0, QtCore.QModelIndex())
        if not start_index.isValid():
            logging.debug("No items in QTreeView")
            return False
        ret_index_list = model.match(
            start_index, QtCore.Qt.DisplayRole, name, 1, QtCore.Qt.MatchFixedString | QtCore.Qt.MatchRecursive)
        if len(ret_index_list) > 0:
            for ind in ret_index_list:
                logging.debug("Setup '%s' already present" % name)
            return True
        else:
            logging.debug("'%s' not found" % name)
            return False

    def closeEvent(self, event):
        """ Handle close window. """
        logging.debug("Closing Setup popup")
        self.close()
