#!/usr/bin/env python3
"""
An application combining multiple energy system simulation models.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import sys
import logging
from PyQt5 import QtWidgets
from ui_main import TitanUI


def main(argv):
    """Launch application."""
    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
    #  GUI
    app = QtWidgets.QApplication(argv)
    window = TitanUI()
    window.show()
    sys.exit(app.exec_())


if __name__ == '__main__':
    sys.exit(main(sys.argv))
