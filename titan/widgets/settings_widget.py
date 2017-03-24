"""
Widget for configuring user settings.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   17.8.2016
"""

import logging
import os
from PyQt5.QtWidgets import QWidget, QFileDialog, QStatusBar, QMessageBox
from PyQt5.QtCore import pyqtSlot, Qt
import ui.settings
from config import GAMS_EXECUTABLE, GAMSIDE_EXECUTABLE, \
    STATUSBAR_STYLESHEET, SETTINGS_GROUPBOX_STYLESHEET, \
    DEFAULT_PROJECT_DIR, DEFAULT_WORK_DIR


class SettingsWidget(QWidget):
    """ A widget to query user's preferred settings.

    Attributes:
        parent (QObject): PyQt parent widget.
        configs (ConfigurationParser): Configuration object
    """
    def __init__(self, parent, configs):
        """ Initialize class. """
        super().__init__(flags=Qt.Window)
        self._parent = parent  # QWidget parent
        self._configs = configs
        self._project = parent.current_project()
        self.orig_project_dir = ''  # Variable for project dir at widget startup
        self.orig_work_dir = ''  # Variable for work dir at widget startup
        # Set up the user interface from Designer.
        self.ui = ui.settings.Ui_SettingsForm()
        self.ui.setupUi(self)
        self.setWindowFlags(Qt.CustomizeWindowHint)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.statusbar = QStatusBar(self)
        self.statusbar.setFixedHeight(20)
        self.statusbar.setSizeGripEnabled(False)
        self.statusbar.setStyleSheet(STATUSBAR_STYLESHEET)
        self.ui.horizontalLayout_statusbar_placeholder.addWidget(self.statusbar)
        self.ui.groupBox_general.setStyleSheet(SETTINGS_GROUPBOX_STYLESHEET)
        self.ui.groupBox_setup.setStyleSheet(SETTINGS_GROUPBOX_STYLESHEET)
        self.ui.groupBox_gams.setStyleSheet(SETTINGS_GROUPBOX_STYLESHEET)
        self.ui.groupBox_project.setStyleSheet(SETTINGS_GROUPBOX_STYLESHEET)
        self.ui.pushButton_ok.setDefault(True)
        self._mousePressPos = None
        self._mouseReleasePos = None
        self._mouseMovePos = None
        self.connect_signals()
        self.read_settings()
        self.read_project_settings()

    def connect_signals(self):
        """ Connect PyQt signals. """
        self.ui.pushButton_ok.clicked.connect(self.ok_clicked)
        self.ui.pushButton_cancel.clicked.connect(self.close)
        self.ui.pushButton_browse_project_dir.clicked.connect(self.select_project_dir)
        self.ui.pushButton_browse_work_dir.clicked.connect(self.select_work_dir)
        self.ui.pushButton_browse_gamside.clicked.connect(self.open_gamside_browser)

    @pyqtSlot(name='select_project_dir')
    def select_project_dir(self):
        """Open dialog to select project directory location."""
        # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
        answer = QFileDialog.getExistingDirectory(self, 'Select Projects Directory Location', os.path.abspath('C:\\'))
        if answer == '':  # Cancel button clicked
            return
        selected_path = os.path.abspath(answer)
        self.ui.lineEdit_project_dir_location.setText(selected_path)

    @pyqtSlot(name='select_work_dir')
    def select_work_dir(self):
        """Open dialog to select work directory location."""
        # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
        answer = QFileDialog.getExistingDirectory(self, 'Select Work Directory Location', os.path.abspath('C:\\'))
        if answer == '':  # Cancel button clicked
            return
        selected_path = os.path.abspath(answer)
        self.ui.lineEdit_work_dir_location.setText(selected_path)

    @pyqtSlot(name='open_gamside_browser')
    def open_gamside_browser(self):
        """Open dialog where user can select the desired GAMS version."""
        # noinspection PyCallByClass, PyTypeChecker, PyArgumentList
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
        """Read current settings from config object and update UI to show them."""
        a = self._configs.get('settings', 'save_at_exit')
        b = self._configs.get('settings', 'confirm_exit')
        c = self._configs.get('settings', 'delete_work_dirs')
        d = self._configs.get('settings', 'debug_messages')
        e = self._configs.get('settings', 'logoption')
        f = self._configs.get('settings', 'cerr')
        if not f:  # If cerr value is missing
            f = 1
        g = self._configs.getboolean('settings', 'clear_flags')
        h = self._configs.getboolean('settings', 'delete_input_dirs')
        project_dir = self._configs.get('settings', 'project_dir')
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
        if g:  # should be True or False
            self.ui.checkBox_clear_flags.setCheckState(Qt.Checked)
        if h:  # should be True or False
            self.ui.checkBox_del_input_dirs.setCheckState(Qt.Checked)
        self.ui.spinBox_cerr.setValue(int(f))
        # Set saved GAMS directory to lineEdit
        self.ui.lineEdit_gamside_path.setText(gamsdir)
        if not project_dir:
            project_dir = DEFAULT_PROJECT_DIR
        self.ui.lineEdit_project_dir_location.setText(project_dir)
        self.orig_project_dir = project_dir

    def read_project_settings(self):
        """Read project settings from config object and update settings widgets accordingly."""
        work_dir = DEFAULT_WORK_DIR
        if self._project:
            self.ui.lineEdit_project_name.setText(self._project.name)
            self.ui.textEdit_project_description.setText(self._project.description)
            work_dir = self._project.work_dir
        self.ui.lineEdit_work_dir_location.setText(work_dir)
        self.orig_work_dir = work_dir

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
        g = self.ui.checkBox_clear_flags.checkState()
        if g == Qt.Unchecked:
            self._configs.set('settings', 'clear_flags', 'false')
        else:
            self._configs.set('settings', 'clear_flags', 'true')
        h = self.ui.checkBox_del_input_dirs.checkState()
        if h == Qt.Unchecked:
            self._configs.set('settings', 'delete_input_dirs', 'false')
        else:
            self._configs.set('settings', 'delete_input_dirs', 'true')
        self._configs.set('general', 'gams_path', self.ui.lineEdit_gamside_path.text())
        # Set logging level
        self._parent.set_debug_level(d)
        # Update project settings
        self.update_project_settings()
        new_project_dir = self.ui.lineEdit_project_dir_location.text()
        if not new_project_dir:
            new_project_dir = DEFAULT_PROJECT_DIR
        # Check if project directory has been changed
        if not self.orig_project_dir == new_project_dir:
            if not self._project:
                logging.debug("No Project Available")
            else:
                # Project is available
                msg = "Project directory has changed. In order to complete the " \
                      "request, Sceleton needs to save the current project " \
                      "to the new location and reload the project. " \
                      "<br/><br/>Continue?"
                # noinspection PyCallByClass, PyTypeChecker
                answer = QMessageBox.question(self, "Reload project?", msg,
                                              QMessageBox.Yes, QMessageBox.No)
                if answer == QMessageBox.Yes:
                    # Update project dir to configs
                    self._configs.set('settings', 'project_dir', new_project_dir)
                    # Update path of current project file to configs
                    self._configs.set('general', 'previous_project', self._project.path)
                    # Update path of the project file in order to save the file to the new project directory
                    self._project.change_filename(self._project.filename)
                    # Save project to new project directory
                    self._parent.save_project()
                    # Reload project from the new project directory
                    if not self._parent.load_project(self._project.path):
                        logging.error("Loading project failed. File: {}".format(self._project.path))
                else:
                    logging.debug("Reloading project cancelled")
                    self.ui.lineEdit_project_dir_location.setText(self.orig_project_dir)
                    return
        self._configs.save()
        self.close()

    def update_project_settings(self):
        """Update project settings when Ok has been clicked."""
        if not self._project:
            return
        save = False
        new_work_dir = self.ui.lineEdit_work_dir_location.text()
        if not new_work_dir:
            new_work_dir = DEFAULT_WORK_DIR
        # Check if work directory has been changed
        if not self.orig_work_dir == new_work_dir:
            if not self._project:
                logging.debug("No Project Available")
            else:
                self._project.change_work_dir(new_work_dir)
                save = True
        if not self._project.description == self.ui.textEdit_project_description.toPlainText():
            # Set new project description
            self._project.set_description(self.ui.textEdit_project_description.toPlainText())
            save = True
        if save:
            self._parent.add_msg_signal.emit("Project settings changed", 0)
            self._parent.save_project()

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
