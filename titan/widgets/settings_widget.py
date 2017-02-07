"""
Widget for configuring user settings.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   17.8.2016
"""

import logging
import os
from PyQt5.QtWidgets import QWidget, QFileDialog, QStatusBar
from PyQt5.QtCore import pyqtSlot, Qt
import ui.settings
from config import GAMS_EXECUTABLE, GAMSIDE_EXECUTABLE


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
        self.statusbar = QStatusBar(self)
        self.ui.verticalLayout.addWidget(self.statusbar)
        self.statusbar.setSizeGripEnabled(False)
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
        self.ui.pushButton_browse_gamside.clicked.connect(self.open_gamside_browser)

    def open_gamside_browser(self):
        """Open dialog where user can select the desired GAMS version."""
        # noinspection PyCallByClass, PyTypeChecker
        answer = QFileDialog.getExistingDirectory(self, 'Select GAMS Directory', os.path.abspath('C:\\'))
        if answer == '':  # Cancel button clicked
            return
        selected_path = os.path.abspath(answer)
        gams_path = os.path.join(selected_path, GAMS_EXECUTABLE)
        gamside_path = os.path.join(selected_path, GAMSIDE_EXECUTABLE)
        if not os.path.isfile(gams_path) and not os.path.isfile(gamside_path):
            logging.debug("Selected directory is not valid GAMS directory:{0}".format(selected_path))
            self.statusbar.showMessage("gams.exe and gamside.exe not found in selected directory", 6000)
            self.ui.lineEdit_gamside_path.setText("")
            return
        else:
            logging.debug("Selected directory is valid GAMS directory")
            self.ui.lineEdit_gamside_path.setText(selected_path)
        return

    def read_settings(self):
        """Read current settings from config file and update UI to show them."""
        a = self._configs.get('settings', 'save_at_exit')
        b = self._configs.get('settings', 'confirm_exit')
        c = self._configs.get('settings', 'delete_work_dirs')
        d = self._configs.get('settings', 'debug_messages')
        e = self._configs.get('settings', 'logoption')
        f = self._configs.get('settings', 'cerr')
        gamsdir = self._configs.get('general', 'gams_path')
        if a == '1':
            self.ui.checkBox_save_at_exit.setCheckState(Qt.PartiallyChecked)
        elif a == '2':
            self.ui.checkBox_save_at_exit.setCheckState(Qt.Checked)
        if b == '2':
            self.ui.checkBox_exit_dialog.setCheckState(Qt.Checked)
        if c == '1':
            self.ui.checkBox_del_work_dirs.setCheckState(Qt.PartiallyChecked)
        elif c == '2':
            self.ui.checkBox_del_work_dirs.setCheckState(Qt.Checked)
        if d == '2':
            self.ui.checkBox_debug.setCheckState(Qt.Checked)
        if e == '4':
            self.ui.checkBox_logoption.setCheckState(Qt.Checked)
        self.ui.spinBox_cerr.setValue(int(f))
        # Set saved GAMS directory to lineEdit
        self.ui.lineEdit_gamside_path.setText(gamsdir)

    @pyqtSlot(name='ok_clicked')
    def ok_clicked(self):
        """Get selections and save them to conf file."""
        a = str(self.ui.checkBox_save_at_exit.checkState())
        b = str(self.ui.checkBox_exit_dialog.checkState())
        c = str(self.ui.checkBox_del_work_dirs.checkState())
        d = str(self.ui.checkBox_debug.checkState())
        e = self.ui.checkBox_logoption.checkState()
        if e == Qt.Unchecked:
            logoption_value = '3'
        else:
            logoption_value = '4'
        f = self.ui.spinBox_cerr.value()
        self._configs.set('settings', 'save_at_exit', a)
        self._configs.set('settings', 'confirm_exit', b)
        self._configs.set('settings', 'delete_work_dirs', c)
        self._configs.set('settings', 'debug_messages', d)
        self._configs.set('settings', 'cerr', str(f))
        self._configs.set('settings', 'logoption', logoption_value)
        self._configs.set('general', 'gams_path', self.ui.lineEdit_gamside_path.text())
        self._configs.save()
        # Set logging level
        self._parent.set_debug_level(d)
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
