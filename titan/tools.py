"""
:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   27/10/2015
"""

import logging
import subprocess
import glob
import shutil
import os


def run(command):
    """ Run a sub-process.

    Args:
        command (str): Sub-process command as string.

    Returns:
        Normal and possible error output of the sub-process.
    """
    logging.debug("Starting sub-process: '{}'.".format(command))
    return subprocess.call(command)

def copy_files(src_dir, dst_dir, extension = '*'):
    """Method for copying files
    """
    src_files = os.path.join(src_dir, '*.{}'.format(extension.lower()))
    for file in glob.iglob(src_files):
        shutil.copy(file, dst_dir)

