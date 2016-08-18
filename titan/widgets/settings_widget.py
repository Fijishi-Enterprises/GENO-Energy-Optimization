"""
Widget for configuring user settings.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   17.8.2016
"""

import logging
from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import pyqtSlot, Qt
import ui.settings


class SettingsWidget(QWidget):
    """ A widget to query user's preferred settings.

    Attributes:
        parent: PyQt parent widget.
    """
    def __init__(self, parent, configs):
        """ Initialize class. """
        super().__init__()
        # Set up the user interface from Designer.
        self.ui = ui.settings.Ui_SettingsForm()
        self.ui.setupUi(self)
        self.setWindowFlags(Qt.CustomizeWindowHint)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.ui.pushButton_ok.setDefault(True)
        # Class attributes
        self._parent = parent  # QWidget parent
        self._mousePressPos = None
        self._mouseReleasePos = None
        self._mouseMovePos = None
        self._configs = configs
        self.connect_signals()
        self.read_settings()

    def connect_signals(self):
        """ Connect PyQt signals. """
        self.ui.pushButton_ok.clicked.connect(self.ok_clicked)
        self.ui.pushButton_cancel.clicked.connect(self.close)

    def read_settings(self):
        """Read current settings from config file and update UI to show them."""
        a = self._configs.get('settings', 'save_at_exit')
        b = self._configs.get('settings', 'confirm_exit')
        c = self._configs.get('settings', 'delete_work_dirs')
        if a == '1':
            self.ui.checkBox_save_at_exit.setCheckState(Qt.PartiallyChecked)
        elif a == '2':
            self.ui.checkBox_save_at_exit.setCheckState(Qt.Checked)
        if b == '2':
            self.ui.checkBox_exit_dialog.setCheckState(Qt.Checked)
        if c == 'True':
            self.ui.checkBox_del_work_dirs.setChecked(True)
        # logging.debug("save at exit:{0}. confirm exit:{1}. delete work dirs:{2}.".format(a, b, c))

    @pyqtSlot()
    def ok_clicked(self):
        a = str(self.ui.checkBox_save_at_exit.checkState())
        b = str(self.ui.checkBox_exit_dialog.checkState())
        c = self.ui.checkBox_del_work_dirs.checkState()

        self._configs.set('settings', 'save_at_exit', a)
        self._configs.set('settings', 'confirm_exit', b)

        if c == 2:
            self._configs.set('settings', 'delete_work_dirs', 'True')
        else:
            self._configs.set('settings', 'delete_work_dirs', 'False')
        self._configs.save()
        # logging.debug("save at exit:{0}. confirm exit:{1}. delete work dirs:{2}.".format(a, b, c))
        self.close()

    def keyPressEvent(self, e):
        """Close settings form when escape key is pressed.

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

    def mousePressEvent(self, e):
        """Save mouse position at the start of dragging.

        Args:
            e (QMouseEvent): Mouse event
        """
        self._mousePressPos = e.globalPos()
        self._mouseMovePos = e.globalPos()
        super().mousePressEvent(e)

    def mouseReleaseEvent(self, e):
        """Save mouse position at the end of dragging.

        Args:
            e (QMouseEvent): Mouse event
        """
        if self._mousePressPos is not None:
            self._mouseReleasePos = e.globalPos()
            moved = self._mouseReleasePos - self._mousePressPos
            if moved.manhattanLength() > 3:
                e.ignore()
                return

    def mouseMoveEvent(self, e):
        """Moves the window when mouse button is pressed and mouse cursor is moved.

        Args:
            e (QMouseEvent): Mouse event
        """
        # logging.debug("MouseMoveEvent at pos:%s" % e.pos())
        # logging.debug("MouseMoveEvent globalpos:%s" % e.globalPos())
        currentpos = self.pos()
        globalpos = e.globalPos()
        diff = globalpos - self._mouseMovePos
        newpos = currentpos + diff
        self.move(newpos)
        self._mouseMovePos = globalpos
