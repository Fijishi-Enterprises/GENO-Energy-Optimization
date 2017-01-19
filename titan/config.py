"""
Default configurations for Sceleton Titan.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.1.2016
"""

import sys
import os
from PyQt5.QtGui import QColor

# General
SCELETON_VERSION = '0.1'
ERROR_COLOR = QColor('red')
SUCCESS_COLOR = QColor('green')
NEUTRAL_COLOR = QColor('blue')
BLACK_COLOR = QColor('black')  # Default text color

# Application path
if getattr(sys, 'frozen', False):
    APPLICATION_PATH = os.path.realpath(os.path.dirname(sys.executable))
else:
    APPLICATION_PATH = os.path.realpath(os.path.dirname(__file__))

# Sceleton configuration file
CONFIGURATION_FILE = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'conf', 'titan.conf'))
# Project directory
PROJECT_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'projects'))
# Project input/output directory names
INPUT_STORAGE_DIR = 'input'
OUTPUT_STORAGE_DIR = 'output'
# Work directory
WORK_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'work'))
# GAMS
GAMS_EXECUTABLE = 'gams.exe'
GAMSIDE_EXECUTABLE = 'gamside.exe'
# Random
ANIMATED_ICON_PATH = os.path.abspath(os.path.join(APPLICATION_PATH, 'ui', 'resources', 'spinningwheel.gif'))

# Default options and settings
GENERAL_OPTIONS = {'project_path': '',
                   'tools': '',
                   'gams_path': ''}

SETTINGS = {'save_at_exit': '1',
            'confirm_exit': '2',
            'delete_work_dirs': '1',
            'debug_messages': '2'}
