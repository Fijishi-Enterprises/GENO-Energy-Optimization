"""
:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   16/03/2016
"""

import os.path
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
        self.dirty = False  # Indicates if the project has changed since loading
        if not os.path.exists(PROJECT_DIR):
            os.makedirs(PROJECT_DIR, exist_ok=True)
        else:
            # TODO: Notice that project already exists...
            pass

    def save(self):
        pass

    def load(self):
        pass

    # def add_setup(self, name, description, parent=None):
    #
    #     self._setups[name] = Setup(name, description, self, parent)
    #
    # def execute(self):
    #     """Execute all setups in this project
    #     """

