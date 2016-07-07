"""
:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   16/03/2016
"""

import os
import logging
import json
from metaobject import MetaObject
from config import PROJECT_DIR


class SceletonProject(MetaObject):
    """Class for Sceleton projects."""

    def __init__(self, name, description):
        """Class constructor.

        Args:
            name (str): Project name
            description (str): Project description
        """
        super().__init__(name, description)
        self.project_dir = os.path.join(PROJECT_DIR, self.short_name)
        self.filename = self.short_name + '.json'
        self.path = os.path.join(PROJECT_DIR, self.filename)
        self.dirty = False  # Indicates if the project has changed since loading
        self.setup_dict = dict()
        if not os.path.exists(self.project_dir):
            try:
                os.makedirs(self.project_dir, exist_ok=True)
            except OSError:
                logging.exception("Could not create new project")
        else:
            # TODO: Notice that project already exists...
            pass

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
        # Save project stuff
        project_dict['project'] = dic

        def traverse(item):
            # Helper function to traverse tree
            logging.debug("\t" * traverse.level + item.name)
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
            the_dict['cmdline_args'] = setup.cmdline_args
        else:
            the_dict['tool'] = None
            the_dict['cmdline_args'] = ""
        the_dict['is_ready'] = setup.is_ready
        the_dict['n_child'] = setup.child_count()
        if setup.parent() is not None:
            the_dict['parent'] = parent_name
        else:
            logging.debug("Setup '%s' parent is None" % setup_name)
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
                    logging.info("Loading Setup '%s'" % name)
                    ui.add_msg_signal.emit("Loading Setup '{0}'".format(name), 0)
                    if parent_name == 'root':
                        if not setup_model.insert_setup(name, desc, self, 0):
                            logging.error("Inserting base Setup %s failed" % name)
                            ui.add_msg_signal.emit("Loading Setup '%s' failed. Parent Setup: '%s'"
                                                   % (name, parent_name), 2)
                    else:
                        parent_index = setup_model.find_index(parent_name)
                        parent_row = parent_index.row()
                        if not setup_model.insert_setup(name, desc, self, parent_row, parent_index):
                            logging.error("Inserting child Setup %s failed" % name)
                            ui.add_msg_signal.emit("Loading Setup '%s' failed. Parent Setup: '%s'"
                                                   % (name, parent_name), 2)
                    if tool_name is not None:
                        # Get tool from ToolModel
                        tool = tool_model.find_tool(tool_name)
                        if not tool:
                            logging.error("Could not add Tool to Setup. Tool '%s' not found" % tool_name)
                            ui.add_msg_signal.emit("Could not find Tool '%s' for Setup '%s'."
                                                   " Add Tool and reload project."
                                                   % (tool_name, name), 2)
                        else:
                            # Add tool to Setup
                            setup_index = setup_model.find_index(name)
                            setup = setup_model.get_setup(setup_index)
                            setup.attach_tool(tool, cmdline_args=cmdline_args)
                self.parse_setups(v, setup_model, tool_model, ui)

    def load(self):
        raise NotImplementedError
