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
# Project input/output directory names
INPUT_STORAGE_DIR = 'input'
OUTPUT_STORAGE_DIR = 'output'
# Work directory
WORK_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'work'))

# Tool path (obsolete)
# MAGIC_MODEL_PATH = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'tools', 'magic'))

# GAMS
GAMS_EXECUTABLE = 'gams'

GENERAL_OPTIONS = {'project_path': '',
                   'tools': ''}

SETTINGS = {'save_at_exit': 'False',
            'confirm_exit': 'False',
            'delete_work_dirs': 'False'}
