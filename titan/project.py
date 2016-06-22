"""
:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   16/03/2016
"""

import os
import logging
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
        if not os.path.exists(self.project_dir):
            try:
                os.makedirs(self.project_dir, exist_ok=True)
            except OSError:
                logging.exception("Could not create new project")
        else:
            # TODO: Notice that project already exists...
            pass

    def save(self):
        pass

    def load(self):
        pass

    # def execute(self):
    #     """Execute all setups in this project
    #     """

