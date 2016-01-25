"""
Default configurations for Sceleton Titan.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.1.2016
"""

import sys
import os
from PyQt5 import QtGui

# General
SCELETON_VERSION = '0.0.1'
ERROR_TEXT_COLOR = QtGui.QColor('red')
SUCCESS_TEXT_COLOR = QtGui.QColor('green')
NEUTRAL_TEXT_COLOR = QtGui.QColor('blue')

# Paths
if getattr(sys, 'frozen', False):
    APPLICATION_PATH = os.path.dirname(sys.executable)
else:
    APPLICATION_PATH = os.path.dirname(__file__)

# Model path
MAGIC_MODEL_PATH = os.path.join(APPLICATION_PATH, '..', 'magic', 'magic.gms')
# r"C:\Data\GIT\Titan\fuel\fuel.gms",
# Model input/output directories
INPUT_STORAGE_DIR = os.path.join(APPLICATION_PATH, '..', 'input')
OUTPUT_STORAGE_DIR = os.path.join(APPLICATION_PATH, '..', 'output')

# GAMS
GAMS_EXECUTABLE ='gams'
