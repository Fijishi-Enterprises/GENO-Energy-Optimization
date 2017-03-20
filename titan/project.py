"""
Class to handle Sceleton projects.

:authors: Erkka Rinne <erkka.rinne@vtt.fi>, Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   16.03.2016
"""

import os
import logging
import json
from collections import Counter
from metaobject import MetaObject
from helpers import find_duplicates, project_dir, create_dir
from config import DEFAULT_WORK_DIR


class SceletonProject(MetaObject):
    """Class for Sceleton projects."""

    def __init__(self, name, description, configs, ext='.json'):
        """Class constructor.

        Args:
            name (str): Project name
            description (str): Project description
            ext (str): Project save file extension (.json or .xlsx)
        """
        super().__init__(name, description)
        self._configs = configs
        self.project_dir = os.path.join(project_dir(self._configs), self.short_name)
        self.work_dir = DEFAULT_WORK_DIR
        self.filename = self.short_name + ext
        self.path = os.path.join(project_dir(self._configs), self.filename)
        self.dirty = False  # TODO: Indicates if project has changed since loading
        self.setup_dict = dict()
        if not os.path.exists(self.project_dir):
            try:
                os.makedirs(self.project_dir, exist_ok=True)
            except OSError:
                logging.exception("Could not create new project")
        else:
            # TODO: Notice that project already exists...
            pass

    def set_name(self, name):
        """Change project name. Calls superclass method.

        Args:
            name (str): Project name
        """
        super().set_name(name)

    def set_description(self, desc):
        """Change project description. Calls superclass method.

        Args:
            desc (str): Project description
        """
        super().set_description(desc)

    def change_filename(self, new_filename):
        """Change the save filename associated with this project.

        Args:
            new_filename (str): Filename used in saving the project. No full path. Example 'project.json'
        """
        # TODO: Add checks for file extension (.json or .xlsx supported)
        self.filename = new_filename
        self.path = os.path.join(project_dir(self._configs), self.filename)

    def change_work_dir(self, work_path):
        """Change project work directory.

        Args:
            work_path (str): Absolute path to work directory
        """
        if not work_path:
            self.work_dir = DEFAULT_WORK_DIR
            return
        if not create_dir(work_path):
            logging.error("Could not change project work directory")
            return
        self.work_dir = work_path
        return

    def save(self, filepath, root):
        """Project information and Setups are collected to their own dictionaries.
        These dictionaries are then saved into another dictionary, which is saved to a
        JSON file.

        Args:
            filepath (str): Path to the save file
            root (Setup): Root Setup of SetupModel
        """
        # Clear Setup dictionary
        self.setup_dict.clear()
        project_dict = dict()  # This is written to JSON file
        dic = dict()  # This is an intermediate dictionary to hold project info
        dic['name'] = self.name
        dic['desc'] = self.description
        dic['work_dir'] = self.work_dir
        # Save project stuff
        project_dict['project'] = dic

        def traverse(item):
            # Helper function to traverse tree
            # logging.debug("\t" * traverse.level + item.name)
            if not item.name == 'root':
                self.update_json_dict(item)
            for kid in item.children():
                traverse.level += 1
                traverse(kid)
                traverse.level -= 1
        traverse.level = 1
        # Traverse tree starting from root
        if not root:
            logging.debug("No Setups to save")
        else:
            traverse(root)

        # Save Setups into dictionary
        project_dict['setups'] = self.setup_dict
        # Write into JSON file
        with open(filepath, 'w') as fp:
            json.dump(project_dict, fp, indent=4)

    def update_json_dict(self, setup):
        """Update tree dictionary with Setup dictionary. Setups will be written as a nested dictionary.
        I.e. child dictionaries are inserted into the parent Setups dictionary with key '.kids'.
        '.kids' was chosen because this is not allowed as a Setup name.

        Args:
            setup (Setup): Setup object to save
        """
        # TODO: Add all necessary attributes from Setup objects here
        setup_name = setup.name
        setup_short_name = setup.short_name
        parent_name = setup.parent().name
        parent_short_name = setup.parent().short_name
        the_dict = dict()
        the_dict['name'] = setup_name
        the_dict['desc'] = setup.description
        if setup.tool:
            the_dict['tool'] = setup.tool.name
            # Save only Setup cmdline_args. Tool cmdline_args will be added to Setups when the Tool is added
            the_dict['cmdline_args'] = setup.cmdline_args
        else:
            the_dict['tool'] = None
            the_dict['cmdline_args'] = ""
        the_dict['is_ready'] = setup.is_ready
        the_dict['failed'] = setup.failed
        the_dict['n_child'] = setup.child_count()
        if setup.parent() is not None:
            the_dict['parent'] = parent_name
        else:
            logging.debug("Setup {0} parent is None".format(setup_name))
            the_dict['parent'] = None
        the_dict['.kids'] = dict()  # Note: '.' is because it is not allowed as a Setup name
        # Add this Setup under the appropriate Setups children
        if parent_name == 'root':
            self.setup_dict[setup_short_name] = the_dict
        else:
            # Find the parent dictionary where this setup should be inserted
            diction = self._finditem(self.setup_dict, parent_short_name)
            try:
                diction['.kids'][setup_short_name] = the_dict
            except KeyError:
                logging.error("_finditem() error while saving. Parent setup dictionary not found")
        return

    def _finditem(self, obj, key):
        """Finds a key recursively from a nested dictionary.

        Args:
            obj: Dictionary to search
            key: Key to find

        Returns:
            Dictionary with the given key.
        """
        if key in obj:
            return obj[key]
        for k, v in obj.items():
            if isinstance(v, dict):
                item = self._finditem(v, key)
                if item is not None:
                    return item

    def parse_setups(self, setup_dict, setup_model, tool_model, ui):
        """Loads project's Setups from JSON formatted Setup dictionary.
        The dictionary is loaded from a saved JSON project file. Setups
        are parsed recursively and then added to project's SetupModel.

        Args:
            setup_dict (dict): Dictionary of Setups in JSON format
            setup_model (SetupModel): SetupModel for this project
            tool_model (ToolModel): ToolModel for this project
            ui (TitanUI): Titan user interface
        """
        for k, v in setup_dict.items():
            if isinstance(v, dict):
                if not k == '.kids':
                    # Add Setup
                    name = v['name']  # Setup name
                    desc = v['desc']
                    parent_name = v['parent']
                    tool_name = v['tool']
                    cmdline_args = v['cmdline_args']
                    is_ready = False
                    failed = False
                    try:
                        is_ready = v['is_ready']
                    except KeyError:
                        logging.debug("is_ready not found")
                    try:
                        failed = v['failed']
                    except KeyError:
                        logging.debug("failed not found")
                    logging.info("Loading Setup '%s'" % name)
                    ui.add_msg_signal.emit("Loading Setup <b>{0}</b>".format(name), 0)
                    if parent_name == 'root':
                        if not setup_model.insert_setup(name, desc, self, 0):
                            logging.error("Inserting base Setup %s failed" % name)
                            ui.add_msg_signal.emit("Loading Setup <b>{0}</b> failed. Parent Setup: <b>{1}</b>"
                                                   .format(name, parent_name), 2)
                    else:
                        parent_index = setup_model.find_index(parent_name)
                        parent_row = parent_index.row()
                        if not setup_model.insert_setup(name, desc, self, parent_row, parent_index):
                            logging.error("Inserting child Setup %s failed" % name)
                            ui.add_msg_signal.emit("Loading Setup <b>{0}</b> failed. Parent Setup: <b>{1}</b>"
                                                   .format(name, parent_name), 2)
                    setup_index = setup_model.find_index(name)
                    setup = setup_model.get_setup(setup_index)
                    if tool_name is not None:
                        # Get tool from ToolModel
                        tool = tool_model.find_tool(tool_name)
                        if not tool:
                            logging.error("Could not add Tool to Setup. Tool '%s' not found" % tool_name)
                            ui.add_msg_signal.emit("Could not find Tool <b>{0}</b> for Setup <b>{1}</b>."
                                                   " Add Tool and reload project."
                                                   .format(tool_name, name), 2)
                        else:
                            # Add tool to Setup
                            setup.attach_tool(tool, cmdline_args=cmdline_args)
                    # Set flags for Setup
                    setup.is_ready = is_ready
                    setup.failed = failed
                self.parse_setups(v, setup_model, tool_model, ui)

    def parse_excel_setups(self, setup_model, tool_model, wb, ui):
        """Parse Setups from Excel file and create them to this project.

        Args:
            setup_model (SetupModel): SetupModel for this project
            tool_model (ToolModel): ToolModel for this project
            wb (ExcelHandler): Excel workbook
            ui (TitanUI): Titan user interface
        """
        items = wb.import_setups()
        # logging.debug("setups:\n%s" % items)
        duplicates = find_duplicates(items[1])
        if len(duplicates) > 0:
            ui.add_msg_signal.emit("File contains more than one Setup with the same name."
                                   " Remove duplicates and try loading again. List of duplicates: {0}"
                                   .format(duplicates), 2)
            return
        for i in range(len(items[0])):
            # Add Setup
            parent_name = items[0][i]
            name = items[1][i]  # Setup name
            tool_name = items[2][i]
            cmdline_args = items[3][i]
            desc = items[4][i]
            is_ready = items[5][i]  # This might be a boolean already
            failed = items[6][i]
            logging.debug("{0} is_ready: {1} type: {2}".format(name, is_ready, type(is_ready)))
            # Make is_ready a boolean
            if not type(is_ready) == bool:
                if not is_ready:  # is_ready can be None
                    is_ready = False
                elif is_ready.lower() == 'true' or is_ready.lower() == 'yes':
                    is_ready = True
                else:
                    is_ready = False
            logging.debug("{0} failed: {1} type: {2}".format(name, failed, type(failed)))
            # Make failed a boolean
            if not type(failed) == bool:
                if not failed:  # is_ready can be None
                    failed = False
                elif failed.lower() == 'true' or failed.lower() == 'yes':
                    failed = True
                else:
                    failed = False
            # Continue from next Setup if name is missing
            if not name:
                ui.add_msg_signal.emit("Could not load Setup. Name missing.", 2)
                continue
            logging.info("Loading Setup '%s'" % name)
            ui.add_msg_signal.emit("Loading Setup <b>{0}</b>".format(name), 0)
            if not parent_name or parent_name.lower() == 'root':
                if not setup_model.insert_setup(name, desc, self, 0):
                    logging.error("Inserting base Setup %s failed" % name)
                    ui.add_msg_signal.emit("Loading Setup <b>{0}</b> failed. Parent Setup: <b>{1}</b>"
                                           .format(name, parent_name), 2)
            else:
                parent_index = setup_model.find_index(parent_name)
                if not parent_index:
                    # Parent not found
                    ui.add_msg_signal.emit("Parent <b>{0}</b> of Setup <b>{1}</b> not found"
                                           .format(parent_name, name), 2)
                    continue
                parent_row = parent_index.row()
                if not setup_model.insert_setup(name, desc, self, parent_row, parent_index):
                    logging.error("Inserting child Setup %s failed" % name)
                    ui.add_msg_signal.emit("Loading Setup <b>{0}</b> failed. Parent Setup: <b>{1}</b>"
                                           .format(name, parent_name), 2)
            setup_index = setup_model.find_index(name)
            setup = setup_model.get_setup(setup_index)
            if tool_name is not None:
                # Get tool from ToolModel
                tool = tool_model.find_tool(tool_name)
                if not tool:
                    logging.error("Could not add Tool to Setup. Tool '%s' not found" % tool_name)
                    ui.add_msg_signal.emit("Could not find Tool <b>{0}</b> for Setup <b>{1}</b>."
                                           " Add Tool and reload project."
                                           .format(tool_name, name), 2)
                else:
                    # Add tool to Setup
                    # setup_index = setup_model.find_index(name)
                    # setup = setup_model.get_setup(setup_index)
                    setup.attach_tool(tool, cmdline_args=cmdline_args)
            # Set flags for Setup
            setup.is_ready = is_ready
            setup.failed = failed
        return

    def make_data_files(self, setup_model, wb, ui):
        """Reads data from Excel and creates GAMS compliant (text) data files.

        Args:
            setup_model (SetupModel): SetupModel for this project
            wb (ExcelHandler): Excel workbook
            ui (TitanUI): Titan user interface
        """
        sheet_names = wb.sheet_names()
        n_data_sheets = 0
        excel_fname = os.path.split(wb.path)[1]
        for sheet in sheet_names:
            if sheet.lower() == 'project' or sheet.lower() == 'setups' or sheet.lower() == 'recipes':
                continue
            n_data_sheets += 1
            try:
                ui.add_msg_signal.emit("<br/>Processing sheet '{0}'".format(sheet), 0)
                [headers, filename, setup, sets, value, n_rows] = wb.read_data_sheet(sheet)
            except ValueError:  # No data found
                ui.add_msg_signal.emit("No data found on sheet '{0}'".format(sheet), 0)
                continue
            # Get the file name found on this sheet
            filename = set(filename)
            # If more than one file name on sheet. Skip whole sheet.
            if len(filename) > 1:
                ui.add_msg_signal.emit("Sheet '{0}' has {1} file names. Only one file name per sheet allowed."
                                       " Data files not created.".format(sheet, len(filename)), 2)
                continue
            # Make a dictionary where key is Setup name and value is a list
            data = dict()
            setups = Counter(setup).keys()
            for setup_name in setups:
                data[setup_name] = list()
            n_sets = len(sets)
            # Collect data into dictionary
            for i in range(n_rows-1):  # subtract header row
                if not sets[0][i]:  # Check that first set is not '' or None
                    line = ''
                else:
                    line = sets[0][i]
                if n_sets > 1:
                    for j in range(n_sets-1):  # Subtract first set
                        if sets[j+1][i]:  # Skip '' and None sets
                            if line == '':  # This happens when first set is empty
                                line = sets[j+1][i]
                            else:
                                line += '.' + sets[j+1][i]  # Append new set on line
                # Add '=' and value to line
                # Do not use if not value[i]: because if value is 0, it will not be written
                if value[i] == '' or value[i] == None:
                    line += '=\n'
                else:
                    line += '=' + str(value[i]) + '\n'
                data[setup[i]].append(line)
            # Write values from dictionary to files
            for key, value in data.items():
                index = setup_model.find_index(key)
                # Skip if Setup does not exist
                if not index:
                    ui.add_msg_signal.emit("Setup <b>{0}</b> not found".format(key), 2)
                    continue
                input_dir = index.internalPointer().input_dir
                fname = list(filename)[0]
                d_file = os.path.join(input_dir, fname)
                try:
                    with open(d_file, 'w') as d:
                        d.write("$offlisting\n")
                        d.writelines(value)
                    ui.add_msg_signal.emit("File {0} written to Setup <b>{1}</b> input directory ({2} lines) "
                                           .format(fname, key, len(value)+1), 0)
                except OSError:
                    ui.add_msg_signal.emit("OSError: Writing to file '{0}' failed".format(d_file), 2)
            ui.add_msg_signal.emit("Processing sheet '{0}' done".format(sheet), 1)
        if n_data_sheets == 0:
            ui.add_msg_signal.emit("No data sheets found", 0)
        else:
            ui.add_msg_signal.emit("Processed {0} data sheets in file {1}".format(n_data_sheets, excel_fname), 0)
        ui.add_msg_signal.emit("Done", 1)
