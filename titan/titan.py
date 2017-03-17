#!/usr/bin/env python3
"""
An application combining multiple energy system simulation models.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.10.2015
"""

import sys
import logging
from PyQt5.QtWidgets import QApplication
from ui_main import TitanUI


def main(argv):
    """Launch application.

    Args:
        argv (list): Command line arguments
    """
    logging.basicConfig(stream=sys.stderr, level=logging.DEBUG,
                        format='%(asctime)s %(levelname)s: %(message)s',
                        datefmt='%Y-%m-%d %H:%M:%S')
    app = QApplication(argv)
    window = TitanUI()
    window.show()
    # Enter main event loop and wait until exit() is called
    return_code = app.exec_()
    return return_code

if __name__ == '__main__':
    sys.exit(main(sys.argv))
