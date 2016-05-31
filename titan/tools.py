"""
:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   27/10/2015
"""

import logging
import subprocess
import glob
import shutil
import os
from metaobject import MetaObject
from collections import OrderedDict
from PyQt5.QtCore import pyqtSignal, pyqtSlot


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


def create_dir(base_path, folder=''):
    """Create (input/output) directories for Setup recursively.

    Args:
        base_path (str): Absolute path to wanted dir. Usually setup storage dir.
        folder (str): (Optional) Folder name. Usually short name of Setup.

    Returns:
        Absolute path to the created directory or None if operation failed.
    """
    directory = os.path.join(base_path, folder)
    if os.path.exists(directory):
        logging.debug("Found directory: %s" % directory)
        return directory
    else:
        try:
            os.makedirs(directory, exist_ok=True)
        except OSError as e:
            logging.error("Could not create directory: %s\nReason: %s" % (directory, e))
            return None
        logging.debug("Created directory: %s" % directory)
        return directory


def copy_files(src_dir, dst_dir, includes=['*'], excludes=[]):
    """Method for copying files.

    Args:
        src_dir (str): Source directory
        dst_dir (str): Destination directory
        includes (reg. exp): Included files
        excludes (reg. exp): Excluded files

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


class SetupTree(MetaObject):
    """Class to store Setups for a single simulation run."""
    # TODO: Rename this class to SetupBranch

    setuptree_finished_signal = pyqtSignal()

    def __init__(self, name, description, setup, last=True):
        """SetupTree constructor.

        Args:
            name (str): Name of SetupTree
            description (str): Description of SetupTree
            setup (Setup): Setup from which the SetupTree is built toward the root
            last (boolean): Parameter to set SetupTree popping order. if True, SetupTree
                is LIFO, if False, SetupTree is FIFO.
        """
        super().__init__(name, description)
        self.setup = setup
        self.last = last  # True -> LIFO, False -> FIFO
        self.setup_dict = OrderedDict()
        self.n = 0  # Number of Setups in SetupTree
        self.build_tree()

    def build_tree(self):
        """Add Setup and all it's parent Setups into an ordered dictionary.

        Returns:
            (boolean): True if successful, False otherwise.
        """
        # Setups are added from the leaf toward the root. E.g. last added item is base.
        item = self.setup
        while item is not None:
            self.n += 1
            self.setup_dict.update({self.n: item})
            item = item.parent()

    def get_next_setup(self):
        """Get the next Setup to execute.

        Returns:
            Next Setup object or None if dictionary empty
        """
        try:
            # Pop the last added Setup (LIFO). Note: To get FIFO, set popitem kwarg last=False.
            item = self.setup_dict.popitem(last=self.last)  # item is (key, value) tuple
            setup = item[1]
            self.n -= 1
        except KeyError:
            logging.debug("SetupTree <{0}> empty".format(self.name))
            self.n = 0
            setup = None
        return setup

    @pyqtSlot()
    def run(self):
        """Start running Setups in SetupTree."""
        logging.debug("Popping next Setup from SetupTree <{}>".format(self.name))
        self.setup = self.get_next_setup()
        if self.setup is not None:
            try:
                # Disconnect setup_finished_signal to prevent it from
                # being connected to multiple SetupTree instances.
                # NOTE: This is required when Setup is part of multiple
                # SetupTrees.
                self.setup.setup_finished_signal.disconnect()
            except TypeError:
                # logging.warning("setup_finished_signal not connected")
                pass
            try:
                # Connect setup_finished_signal to run()
                self.setup.setup_finished_signal.connect(self.run)
            except Exception as e:
                logging.exception("Could not connect setup_finished_signal: Reason:{}".format(e.args[0]))
                return  # No reason to continue if signal could not be connected
            # Execute Setup
            self.setup.execute()
        else:
            # All Setups in SetupTree finished
            self.setuptree_finished_signal.emit()
        return
