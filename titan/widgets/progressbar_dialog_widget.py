"""
Class for a progress bar dialog showing the progress in deleting work directories.

@author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
@date 20.6.2017
"""

import shutil
import logging
from PyQt5.QtWidgets import QDialog, QApplication
from PyQt5.QtCore import Qt, pyqtSignal
import ui.progressbar_dialog
from helpers import busy_effect


class ProgressBarDialog(QDialog):
    """ A class for a progress bar dialog.

    Attributes:
        parent: The Qt parent widget.
        dirs: Paths of directories to delete
    """

    done_signal = pyqtSignal(name='done_signal')

    def __init__(self, parent, dirs):
        """ Initialize progress bar dialog. """
        super().__init__(flags=Qt.Window)
        self._parent = parent
        self._dirs = dirs  # Directory paths to delete
        #  Set up the user interface from Designer.
        self.ui = ui.progressbar_dialog.Ui_Dialog()
        self.ui.setupUi(self)
        self.setWindowFlags(Qt.CustomizeWindowHint)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        self.done_signal.connect(self._parent.quit_application)
        self.ui.label.setText("Deleting directories (0/{0})".format(len(self._dirs)))
        self.ui.progressBar.setValue(0)

    @busy_effect
    def remove_work_dirs(self):
        """Used to remove work directories when exiting Sceleton."""
        n = len(self._dirs)
        i = 1
        percent = 0
        for directory in self._dirs:
            # noinspection PyArgumentList
            QApplication.processEvents()
            try:
                shutil.rmtree(directory)
            except OSError:
                logging.error("OSError while removing directory {}. Check permissions.".format(directory))
                continue
            self.ui.label.setText("Deleting directories ({0}/{1})".format(i, n))
            self.ui.progressBar.setValue(percent)
            i += 1
            percent = i/n * 100
        self.ui.label.setText("Deleting directories ({0}/{1})".format(i, n))
        self.ui.progressBar.setValue(percent)
        logging.debug("Deleted {0} directories".format(i-1))
        self.done_signal.emit()
        self.close()
