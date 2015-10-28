"""
Module for main GUI functions.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import locale
from PyQt5 import QtGui, QtCore, QtWidgets
from ui.main import Ui_MainWindow


class TitanUI(QtWidgets.QMainWindow):
    """Class for application main GUI functions."""

    def __init__(self):
        """ Initialize GUI """
        super().__init__()
        # Set locale to use ',' as '.' in scalar number strings
        locale.setlocale(locale.LC_NUMERIC, '')
        #  Set up the user interface from Designer.
        self.ui = Ui_MainWindow()
        self.ui.setupUi(self)
