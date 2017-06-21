"""
General helper functions and classes.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   27.10.2015
"""

import logging
import glob
import shutil
import os
import datetime
import time
import collections
import json
from PyQt5.QtCore import QObject, pyqtSlot
from PyQt5.QtWidgets import QApplication
from PyQt5.Qt import Qt
from PyQt5.QtGui import QIcon, QMovie, QCursor
from config import UI_RESOURCES, DEFAULT_PROJECT_DIR


class AnimatedSpinningWheelIcon(QObject):
    """Class to handle a spinning wheel animated
    icon used as an icon for the running Setup."""
    def __init__(self):
        """Class constructor."""
        super().__init__()
        self.movie = QMovie(os.path.join(UI_RESOURCES, 'spinningwheel.gif'))
        self.movie.setCacheMode(QMovie.CacheAll)
        # noinspection PyUnresolvedReferences
        self.movie.frameChanged.connect(self.update_icon)
        self.icon = None

    @pyqtSlot(int, name='update_icon')
    def update_icon(self, current_frame):
        """Save current frame as a QIcon."""
        self.icon = QIcon()
        self.icon.addPixmap(self.movie.currentPixmap())

    def get_icon(self):
        """Get current movie frame as a QIcon."""
        return self.icon

    def start(self):
        """Start the movie."""
        self.movie.start()

    def stop(self):
        """Stop the movie."""
        self.movie.stop()


class MyEncoder(json.JSONEncoder):
    def default(self, o):
        if isinstance(o, set):
            return list(o)
        try:
            return o.__dict__
        except AttributeError:
            pass


def find_work_dirs(project):
    """Returns a list of work directory paths. Note: Contains
    also non Sceleton related directories.

    Args:
        project (SceletonProject): Current project

    Returns:
        List of all directories in the project work path
    """
    work_dirs = list()
    entries = os.listdir(project.work_dir)
    for entry in entries:
        dir_path = os.path.join(project.work_dir, entry)
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
        # logging.debug("Found directory: {0}".format(directory))
        return directory
    else:
        try:
            os.makedirs(directory, exist_ok=True)
        except OSError as e:
            logging.error("Could not create directory: {0}\nReason: {1}".format(directory, e))
            return None
        logging.debug("Created directory: {0}".format(directory))
        return directory


def copy_files(src_dir, dst_dir, includes=None, excludes=None):
    """Method for copying files. Does not copy folders.

    Args:
        src_dir (str): Source directory
        dst_dir (str): Destination directory
        includes (list): Included files (wildcards accepted)
        excludes (list): Excluded files (wildcards accepted)

    Returns:
        count (int): Number of files copied
    """
    if not includes:
        includes = ['*']
    if not excludes:
        excludes = []
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
                logging.error('Unable to create result folder')
                return None
    logging.debug('Created result directory: %s' % results_path)
    return results_path


def create_output_dir_timestamp():
    """ Creates a new timestamp string that is used as a Setup output
    directory.

    Returns:
        Timestamp string or empty string if failed.
    """
    try:
        # Create timestamp
        stamp = datetime.datetime.fromtimestamp(time.time())
    except OverflowError:
        logging.error('Timestamp out of range.')
        return ''
    extension = stamp.strftime('%Y-%m-%dT%H.%M.%S')
    return extension


def find_latest_output_folder(base_output_path, folders):
    """Finds the most recent folder in the given folder list. Folder names are ranked
     according to the timestamp in their name.

    Args:
        base_output_path (str): Path of Setups' 'base' output path. eg. ..\project1\output\setup1\
        folders (list): List of folder names

    Returns:
        Name of the newest folder if it contains the given file or None if it does not or None
        if 'folders' parameter does not have any folders. If fname not given then this function
        is used with find_input_files method which only needs the folder name.
    """
    if len(folders) == 0:
        return None
    f_dict = dict()
    for folder_name in folders:
        # Folder name is the timestamp
        try:
            date_obj = datetime.datetime.strptime(folder_name, '%Y-%m-%dT%H.%M.%S')
        except ValueError:
            # logging.debug("Tried to get time stamp from folder: {0}".format(folder_name))
            continue
        # Populate dictionary with parsed datetime object as key and folder name as value
        f_dict[date_obj] = folder_name
    # Return None if no timestamped folders found
    if not f_dict:
        return None
    # Get the latest date
    latest_date = max(f_dict.keys())
    # Get the folder corresponding to the latest date
    latest_folder_name = f_dict.get(latest_date)
    # logging.debug("latest date:{0}. latest folder:{1}".format(latest_date, latest_folder_name))
    latest_folder_path = os.path.join(base_output_path, latest_folder_name)
    return latest_folder_path


def find_duplicates(a):
    """Finds duplicates in a list. Returns a list with the duplicates or an empty list if none found.

    Args:
        a (list): List
    """
    # noinspection PyArgumentList
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


@busy_effect
def erase_dir(path):
    """Delete directory and all its contents without prompt.

    Args:
        path (str): Path to directory
    """
    if not os.path.exists(path):
        logging.debug("Path does not exist: {}".format(path))
        return False
    logging.debug("Deleting directory {0}".format(path))
    try:
        shutil.rmtree(path)
    except OSError:
        raise
    return True


def layout_widgets(layout):
    """Return a generator containing all widgets in the given layout.

    Args:
        layout (QLayout): Layout containing widgets
    """
    return (layout.itemAt(i) for i in range(layout.count()))


def project_dir(configs=None):
    """Returns current project directory.

    Args:
        configs (ConfigurationParser): Configuration parser object. Default value is for unit tests.
    """
    if not configs:
        return DEFAULT_PROJECT_DIR
    proj_dir = configs.get('settings', 'project_dir')
    if not proj_dir:
        return DEFAULT_PROJECT_DIR
    else:
        return proj_dir

