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


def copy_files(src_dir, dst_dir, includes=['*'], excludes=[]):
    """Method for copying files

    Args:
        src_dir (str): Source directory
        dst_dir (str): Destination directory
        extensions (str)

    Returns:
        count (int): Number of files copied
    """
    src_files = []
    for pattern in includes:
        src_files += glob.glob(os.path.join(src_dir, pattern))

    exclude_files = []
    for pattern in excludes:
        exclude_files += glob.glob(os.path.join(src_dir, pattern))

    count = 0
    for filename in src_files:
        if filename not in exclude_files:
            shutil.copy(filename, dst_dir)
            count += 1

    return count
