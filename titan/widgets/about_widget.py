"""
Class for About info widget.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date 9.3.2017
"""

from PyQt5.QtWidgets import QWidget
from PyQt5.QtCore import Qt
import ui.about


class AboutWidget(QWidget):
    """ A widget for presenting basic information about the application.

    Attributes:
        parent: The Qt parent widget.
        version: Application version number as string.
    """

    def __init__(self, parent, version):
        """ Initializes About widget. """
        self._parent = parent
        super().__init__(flags=Qt.Window)
        #  Set up the user interface from Designer.
        self.ui = ui.about.Ui_Form()
        self.ui.setupUi(self)
        self.setWindowFlags(Qt.CustomizeWindowHint)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.ui.label_version_str.setText("Version {0}".format(version))

    def keyPressEvent(self, e):
        """Close form when escape key is pressed.

        Args:
            e (QKeyEvent): Received key press event.
        """
        if e.key() == Qt.Key_Escape or e.key() == Qt.Key_Enter or e.key() == Qt.Key_Return or e.key() == Qt.Key_Space:
            self.close()

    def closeEvent(self, event=None):
        """Handle close window.

        Args:
            event (QEvent): Closing event if 'X' is clicked.
        """
        if event:
            event.accept()
