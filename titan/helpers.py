"""
General helper functions and classes.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   27.10.2015
"""

import logging
import subprocess
import glob
import shutil
import os
import datetime
import time
import collections
from metaobject import MetaObject
# from collections import OrderedDict
from PyQt5.QtCore import pyqtSignal, pyqtSlot
from PyQt5.QtWidgets import QApplication
from PyQt5.Qt import QCursor, Qt
from config import WORK_DIR


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


def find_work_dirs():
    """Returns a list of work directory paths."""
    work_dirs = list()
    entries = os.listdir(WORK_DIR)
    for entry in entries:
        dir_path = os.path.join(WORK_DIR, entry)
        if os.path.isdir(dir_path):
            work_dirs.append(dir_path)
    return work_dirs


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
    # TODO: Remove mutable default arguments
    """Method for copying files. Does not copy folders.

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
        if os.path.isdir(filename):
            continue
        if filename not in exclude_files:
            shutil.copy(filename, dst_dir)
            count += 1

    return count


def create_results_dir(path, name, simulation_failed=False):
    """ Creates a new directory for storing simulation results.
    The new directory is named as follows: "name-time_stamp". If a folder
    with the same name already exists an underscore and index number is
    added at the end of folder name.

    Args:
        path (str): Path where the new directory should be created.
        name (str): Basename (Setup name) for the directory.
        simulation_failed (boolean): If True, concatenates '(Failed) ' to the result folder name.

    Returns:
        Absolute path to the new results directory or None if failed.
    """
    # Check that the output directory is writable
    if not os.access(path, os.W_OK):
        logging.error('Results folder (%s) missing.' % path)
        return None
    # Add timestamp to filename
    try:
        stamp = datetime.datetime.fromtimestamp(time.time())
    except OverflowError:
        logging.error('Timestamp out of range.')
        return None
    dir_name = name + '-' + stamp.strftime('%Y-%m-%dT%H.%M.%S')
    if simulation_failed:
        dir_name = '(Failed) ' + dir_name
    results_path = path + os.sep + dir_name
    #  Create a new directory for storing results.
    counter = 1
    while True:
        if not os.path.exists(results_path):
            os.makedirs(results_path)
            break
        else:
            results_path = (path + os.sep + dir_name + '_' +
                            str(counter))
            counter += 1
            if counter >= 1000:
                logging.error('Unable to create results folder.')
                return None
    logging.debug('Created results directory: %s' % results_path)
    return results_path


def create_output_dir_timestamp():
    """ Creates a new string to be extended to the end of the output
    directory. This is a timestamp that can be added to the directory
    name.

    Returns:
        Timestamp string or empty string if failed.
    """
    try:
        # Create timestamp
        stamp = datetime.datetime.fromtimestamp(time.time())
    except OverflowError:
        logging.error('Timestamp out of range.')
        return ''
    extension = '-' + stamp.strftime('%Y-%m-%dT%H.%M.%S')
    return extension


def find_in_latest_output_folder(setup_name, base_output_path, folders, fname=''):
    """Finds a file from the most recent folder in the given folder list. Folder names are ranked
     according to the timestamp in their name.

    Args:
        setup_name (str): Setup short name
        base_output_path (str): Path of Setups' 'base' output path. eg. ..\project1\output\setup1\
        folders (list): List of folder names
        fname (str): File name that is being searched

    Returns:
        Name of the newest folder if it contains the given file or None if it does not or None
        if folders parameter does not have any folders. If fname not given then this function
        is used with find_input_files method which only needs the folder name.
    """
    # TODO: Remove fname argument and just return the most recent folder
    if len(folders) == 0:
        return None
    f_dict = dict()
    st = setup_name + '-'  # String that is stripped from the folder name to get the timestamp
    for folder_name in folders:
        # Get time stamp by stripping the Setup name and '-' from it
        timestamp = folder_name.strip(st)
        try:
            date_obj = datetime.datetime.strptime(timestamp, '%Y-%m-%dT%H.%M.%S')
        except ValueError:
            logging.debug("Tried to get time stamp from folder: {0}".format(folder_name))
            continue
        # Populate dictionary with parsed datetime object as key and folder name as value
        f_dict[date_obj] = folder_name
    # Get the latest date
    latest_date = max(f_dict.keys())
    # Get the folder corresponding to the latest date
    latest_folder_name = f_dict.get(latest_date)
    # logging.debug("latest date:{0}. latest folder:{1}".format(latest_date, latest_folder_name))
    latest_folder_path = os.path.join(base_output_path, latest_folder_name)
    files = os.listdir(latest_folder_path)
    if fname == '':
        # logging.debug("Returning latest output path")
        return latest_folder_path
    if fname in files:
        logging.debug("Found file '{0}' in folder '{1}'".format(fname, latest_folder_path))
        return latest_folder_path
    else:
        logging.debug("Did not find file '{0}' in folder '{1}'".format(fname, latest_folder_path))
        return None


def find_duplicates(a):
    """Finds duplicates in a list. Returns a list with the duplicates or an empty list if none found."""
    return [item for item, count in collections.Counter(a).items() if count > 1]


def busy_effect(function):
    """ Decorator to change the mouse cursor to 'busy' while a function is processed.

    Args:
        function: Decorated function.
    """
    def new_function(*args, **kwargs):
        # noinspection PyTypeChecker, PyArgumentList, PyCallByClass
        QApplication.setOverrideCursor(QCursor(Qt.BusyCursor))
        try:
            return function(*args, **kwargs)
        except Exception as e:
            logging.exception("Error {}".format(e.args[0]))
            raise e
        finally:
            # noinspection PyArgumentList
            QApplication.restoreOverrideCursor()
    return new_function


class SetupTree(MetaObject):
    """Class to store Setups for a single simulation run."""

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
        self.setup_dict = collections.OrderedDict()
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
