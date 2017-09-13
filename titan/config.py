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

# Application, Configuration file, default project and work directory paths
if getattr(sys, 'frozen', False):
    APPLICATION_PATH = os.path.realpath(os.path.dirname(sys.executable))
    CONFIGURATION_FILE = os.path.abspath(os.path.join(APPLICATION_PATH, 'titan.conf'))
    DEFAULT_PROJECT_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, 'projects'))
    DEFAULT_WORK_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, 'work'))
else:
    APPLICATION_PATH = os.path.realpath(os.path.dirname(__file__))
    CONFIGURATION_FILE = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'conf', 'titan.conf'))
    DEFAULT_PROJECT_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'projects'))
    DEFAULT_WORK_DIR = os.path.abspath(os.path.join(APPLICATION_PATH, os.path.pardir, 'work'))

# Project input/output directory names
INPUT_STORAGE_DIR = 'input'
OUTPUT_STORAGE_DIR = 'output'

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

# Stylesheets
STATUSBAR_STYLESHEET = "QStatusBar{border-width: 2px;\n" \
                       "border-color: 'gainsboro';\n" \
                       "border-style: groove;\n" \
                       "border-radius: 2px;\n}"

ICON_TOOLBAR_STYLESHEET = "QToolBar{spacing: 6px;" \
                     "background-color: qlineargradient(" \
                          "x1: 1, y1: 1, x2: 0, y2: 0, stop: 0 #E0E0E0, stop: 1 #A3AFFF);" \
                     "padding: 6px;}" \
                     "QToolButton{background-color: white;" \
                     "border-width: 1px;" \
                     "border-style: inset;" \
                     "border-color: darkslategray;" \
                     "border-radius: 2px;}"

GENERAL_TOOLBAR_STYLESHEET = "QToolBar{spacing: 5px;" \
                             "background-color: qlineargradient(" \
                             "x1: 1, y1: 1, x2: 0, y2: 0, stop: 0 #E0E0E0, stop: 1 #A3AFFF);" \
                             "padding: 4px;}" \
                             "QToolButton{background-color: qlineargradient(" \
                             "x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 white, stop: 1 gainsboro);" \
                             "border-width: 1px;" \
                             "border-style: outset;" \
                             "border-color: gray;" \
                             "border-radius: 2px;}" \
                             "QComboBox{background-color: qlineargradient(" \
                             "x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 white, stop: 1 gainsboro);" \
                             "width: 5em;" \
                             "border-width: 1px;" \
                             "border-style: outset;" \
                             "border-color: gray;" \
                             "border-radius: 2px;}"

SETTINGS_GROUPBOX_STYLESHEET = "QGroupBox{border: 2px solid gray;" \
                               "background-color: qlineargradient(" \
                               "x1: 1, y1: 0, x2: 0, y2: 0, stop: 0 #E0E0E0, stop: 1 #A3AFFF);" \
                               "border-radius: 5px;" \
                               "margin-top: 1.1em;}" \
                               "QGroupBox:title{subcontrol-origin: margin;" \
                               "subcontrol-position: top center;" \
                               "padding-top: 0px; " \
                               "padding-bottom: 0px; " \
                               "padding-right: 3px; " \
                               "padding-left: 3px;}" \

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
