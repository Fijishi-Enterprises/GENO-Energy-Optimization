"""
Default configurations for Sceleton Titan.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   21.1.2016
"""

import sys
import os
from PyQt5.QtGui import QColor

# General
SCELETON_VERSION = '0.1.10'
ERROR_COLOR = QColor('red')
SUCCESS_COLOR = QColor('green')
NEUTRAL_COLOR = QColor('blue')
BLACK_COLOR = QColor('black')

# Application path
if getattr(sys, 'frozen', False):
    APPLICATION_PATH = os.path.realpath(os.path.dirname(sys.executable))
else:
    APPLICATION_PATH = os.path.realpath(os.path.dirname(__file__))

# Sceleton configuration file and default project directory paths
CONFIGURATION_FILE = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'conf', 'titan.conf'))
DEFAULT_PROJECT_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'projects'))

# Project input/output directory names
INPUT_STORAGE_DIR = 'input'
OUTPUT_STORAGE_DIR = 'output'

# Work directory
DEFAULT_WORK_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'work'))

# GAMS
if not sys.platform == 'win32':
    GAMS_EXECUTABLE = 'gams'
    GAMSIDE_EXECUTABLE = 'gamside'
else:
    GAMS_EXECUTABLE = 'gams.exe'
    GAMSIDE_EXECUTABLE = 'gamside.exe'

# Others
UI_RESOURCES = os.path.abspath(os.path.join(APPLICATION_PATH, 'ui', 'resources'))
# Required and optional keywords for Tool definition files
REQUIRED_KEYS = ['name', 'description', 'files']
OPTIONAL_KEYS = ['short_name', 'datafiles', 'datafiles_opt', 'outfiles', 'cmdline_args']
LIST_REQUIRED_KEYS = ['files', 'datafiles', 'datafiles_opt', 'outfiles']  # These should be lists

# Style sheets
STATUSBAR_STYLESHEET = "QStatusBar{border-width: 2px;\n" \
                       "border-color: 'gainsboro';\n" \
                       "border-style: groove;\n" \
                       "border-radius: 2px;\n}"

TOOLBAR_STYLESHEET = "QToolBar{spacing: 5px;\n" \
                     "background-color: 'lightsalmon';\n" \
                     "padding: 4px;\n}" \
                     "QToolButton{background-color: rgb(255, 255, 255);\n" \
                     "border-width: 2px;\n" \
                     "border-style: outset;\n" \
                     "border-color: gray;\n" \
                     "border-radius: 6px;\n}"

SETTINGS_GROUPBOX_STYLESHEET = "QGroupBox{border: 1px solid gray; " \
                               "border-radius: 9px; " \
                               "margin-top: 0.5em}" \
                               "QGroupBox:title{subcontrol-origin: margin; " \
                               "left: 10px; " \
                               "padding-top: 0px; " \
                               "padding-bottom: 0px; " \
                               "padding- right: 2px; " \
                               "padding-left: 2px;}"

# Default options and settings
GENERAL_OPTIONS = {'previous_project': '',
                   'gams_path': ''}

SETTINGS = {'save_at_exit': '1',
            'confirm_exit': '2',
            'delete_work_dirs': '1',
            'debug_messages': '2',
            'logoption': '3',
            'cerr': '1',
            'clear_flags': 'false',
            'delete_input_dirs': 'false',
            'project_dir': ''}
