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
FUEL_MODEL_PATH = os.path.join(APPLICATION_PATH, '..', 'fuel', 'fuel.gms')
# r"C:\Data\GIT\Titan\fuel\fuel.gms",
# Model input/output directories
INPUT_STORAGE_DIR = os.path.join(APPLICATION_PATH, '..', 'input')
OUTPUT_STORAGE_DIR = os.path.join(APPLICATION_PATH, '..', 'output')
# Model configuration input/output directories
CONFIG_INPUT_DIR_BASE = os.path.join(APPLICATION_PATH, '..', 'configs', 'input')      # INPUT_DIR_BASE
CONFIG_OUTPUT_DIR_BASE = os.path.join(APPLICATION_PATH, '..', 'configs', 'output')    # OUTPUT_DIR_BASE

# GAMS
GAMS_EXECUTABLE = 'gams'
GAMS_RETURN_CODES = {
    0: "normal return",
    1: "solver is to be called the system should never return this number",
    2: "there was a compilation error",
    3: "there was an execution error",
    4: "system limits were reached",
    5:  "there was a file error",
    6:  "there was a parameter error",
    7:  "there was a licensing error",
    8:  "there was a GAMS system error",
    9:  "GAMS could not be started",
    10: "out of memory",
    11: "out of disk"}
