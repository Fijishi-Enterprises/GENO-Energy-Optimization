"""
Default configurations for Sceleton Titan.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.1.2016
"""

import sys
import os
from PyQt5.QtGui import QColor

# General
SCELETON_VERSION = '0.0.1'
ERROR_TEXT_COLOR = QColor('red')
SUCCESS_TEXT_COLOR = QColor('green')
NEUTRAL_TEXT_COLOR = QColor('blue')

# Paths
if getattr(sys, 'frozen', False):
    APPLICATION_PATH = os.path.realpath(os.path.dirname(sys.executable))
else:
    APPLICATION_PATH = os.path.realpath(os.path.dirname(__file__))

PROJECT_DIR = os.path.join(APPLICATION_PATH, os.path.pardir, 'projects')
# Model input/output directories
INPUT_STORAGE_DIR = 'input'
OUTPUT_STORAGE_DIR = 'output'
WORK_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'work'))

# Model path
MAGIC_MODEL_PATH = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'models', 'magic'))
OLD_MAGIC_MODEL_PATH = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'models', 'old_magic'))

# GAMS
GAMS_EXECUTABLE ='gams'

IGNORE_PATTERNS = ('.git', '.gitignore')
