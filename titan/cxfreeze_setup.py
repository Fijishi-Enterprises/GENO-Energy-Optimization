"""
CX-FREEZE setup file for SCELETON TITAN.

    - Create a Windows Installer distribution package (.msi) with the following command:
        python cxfreeze_setup.py bdist_msi
    - Build the application into /build directory with the following command:
        python cxfreeze_setup.py build

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   13.9.2017
"""

import sys
from cx_Freeze import setup, Executable
from config import SCELETON_VERSION

# Dependencies are automatically detected, but it might need
# fine tuning.
buildOptions = dict(packages=[],
                    excludes=[],
                    includes=["atexit"],
                    include_files=["modeltest/"])

base = 'Win32GUI' if sys.platform == 'win32' else None

executables = [Executable('titan.py', base=base)]

setup(name='Sceleton Titan',
      version=SCELETON_VERSION,
      description='PyQt application for managing Power/Energy system simulation scenarios.',
      author="VTT Wind Power and Self-Organizing Networks teams",
      options=dict(build_exe=buildOptions),
      executables=executables)
