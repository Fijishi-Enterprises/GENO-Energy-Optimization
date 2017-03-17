"""
Widget to ask the user for new project details.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   10.5.2016
"""

import os
from PyQt5.QtWidgets import QWidget, QStatusBar
from PyQt5.QtCore import pyqtSlot, Qt
from config import STATUSBAR_STYLESHEET
import ui.project_form
from helpers import project_dir


class ProjectFormWidget(QWidget):
    """ A widget to query user's preferences for created project

    Attributes:
        parent: PyQt parent widget.
    """
    def __init__(self, parent, configs):
        """ Initialize class. """
        super().__init__(flags=Qt.Window)
        self._parent = parent  # QWidget parent
        self._configs = configs
        #  Set up the user interface from Designer.
        self.ui = ui.project_form.Ui_Form()
        self.ui.setupUi(self)
        # Add status bar to form
        self.statusbar = QStatusBar(self)
        self.statusbar.setFixedHeight(20)
        self.statusbar.setSizeGripEnabled(False)
        self.statusbar.setStyleSheet(STATUSBAR_STYLESHEET)
        self.ui.horizontalLayout_statusbar_placeholder.addWidget(self.statusbar)
        # Class attributes
        self.name = ''  # Project name
        self.description = ''  # Project description
        self.connect_signals()
        # self.ui.pushButton_ok.setDefault(True)
        self.ui.lineEdit_project_name.setFocus()
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)

    def connect_signals(self):
        """ Connect PyQt signals. """
        # Project name lineEdit textChanged signal
        self.ui.lineEdit_project_name.textChanged.connect(self.name_changed)
        # Button clicked handlers
        self.ui.pushButton_ok.clicked.connect(self.ok_clicked)
        self.ui.pushButton_cancel.clicked.connect(self.close)

    @pyqtSlot(name='name_changed')
    def name_changed(self):
        """Update label to show upcoming folder name."""
        project_name = self.ui.lineEdit_project_name.text()
        default = "Project folder:"
        if project_name == '':
            self.ui.label_folder.setText(default)
        else:
            folder_name = project_name.lower().replace(' ', '_')
            msg = default + " " + folder_name
            self.ui.label_folder.setText(msg)

    @pyqtSlot(name='ok_clicked')
    def ok_clicked(self):
        """Check that project name is valid and create project."""
        self.name = self.ui.lineEdit_project_name.text()
        self.description = self.ui.textEdit_description.toPlainText()
        if self.name == '':
            self.statusbar.showMessage("No project name given", 5000)
            return
        # Check for invalid characters for a folder name
        invalid_chars = ["<", ">", ":", "\"", "/", "\\", "|", "?", "*", "."]
        # "." is actually valid in a folder name but
        # this is to prevent creating folders like "...."
        if any((True for x in self.name if x in invalid_chars)):
            self.statusbar.showMessage("Project name contains invalid character(s) for a folder name", 5000)
            return
        # Check if project with same name already exists
        short_name = self.name.lower().replace(' ', '_')
        project_folder = os.path.join(project_dir(self._configs), short_name)
        if os.path.isdir(project_folder):
            self.statusbar.showMessage("Project already exists", 5000)
            return
        # Create new project
        self.call_create_project()
        self.close()

    def call_create_project(self):
        """Call create_project() method in ui_main()."""
        self._parent.create_project(self.name, self.description)

    def keyPressEvent(self, e):
        """Close project form when escape key is pressed.

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
