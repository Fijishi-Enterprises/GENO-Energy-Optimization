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
ERROR_COLOR = QColor('red')
SUCCESS_COLOR = QColor('green')
NEUTRAL_COLOR = QColor('blue')

# Paths
if getattr(sys, 'frozen', False):
    APPLICATION_PATH = os.path.realpath(os.path.dirname(sys.executable))
else:
    APPLICATION_PATH = os.path.realpath(os.path.dirname(__file__))

# General configurations file
CONFIGURATION_FILE = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'conf', 'titan.conf'))
# Directory for projects
PROJECT_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'projects'))
# Project input/output directories
INPUT_STORAGE_DIR = 'input'
OUTPUT_STORAGE_DIR = 'output'
# Work directory
WORK_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'work'))

# Tool model path
MAGIC_MODEL_PATH = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'tools', 'magic'))
# Tool configuration file paths
MAGIC_INVESTMENTS_JSON = os.path.join(MAGIC_MODEL_PATH, "magic_invest.json")
MAGIC_OPERATION_JSON = os.path.join(MAGIC_MODEL_PATH, "magic_operation.json")
OLD_MAGIC_MODEL_PATH = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'tools', 'old_magic'))

# GAMS
GAMS_EXECUTABLE = 'gams'
IGNORE_PATTERNS = ('.git', '.gitignore')

GENERAL_OPTIONS = {'project_path': ''}
