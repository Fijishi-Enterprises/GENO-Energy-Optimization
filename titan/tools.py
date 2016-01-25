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


def run2(command):
    """ Run a sub-process. Same as in Sceleton.

    Args:
        command (str): Sub-process command as string.

    Returns:
        Normal and possible error output of the sub-process.
    """
    logging.debug('Starting sub-process: <%s>.' % command)
    proc = subprocess.Popen(command, stdout=subprocess.PIPE,
                            stdin=subprocess.PIPE, stderr=subprocess.PIPE,
                            shell=True)
    out = proc.communicate()
    return out


def copy_files(src_dir, dst_dir, extension = '*'):
    """ Method for copying a directory.
    Args:
        src_dir: Source dir
        dst_dir: Destination dir
        extension: extension

    Returns: None
    """
    src_files = os.path.join(src_dir, '*.{}'.format(extension.lower()))
    for file in glob.iglob(src_files):
        shutil.copy(file, dst_dir)
