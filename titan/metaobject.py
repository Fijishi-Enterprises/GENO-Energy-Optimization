"""
MetaObject class.

:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   16.03.2016
"""

from PyQt5.QtCore import QObject


class MetaObject(QObject):
    """Class for an object which has a name and some description.

    Attributes:
        name (str): The name of the object
        short_name (str): Short name that can be used in file names etc.
        description (str): Description of the object
        short_name (str, optional): Short name
    """

    def __init__(self, name, description, short_name=None):
        """Class constructor."""
        super().__init__()
        self.name = name
        if short_name is not None:
            self.short_name = short_name
        else:
            self.short_name = name.lower().replace(' ', '_')
        self.description = description

    def set_name(self, new_name):
        """Change object name and short name.
        Note: Check conflicts (e.g. name already exists)
        before calling this method.

        Args:
            new_name (str): New (long) name for this object
        """
        self.name = new_name
        self.short_name = new_name.lower().replace(' ', '_')

    def set_description(self, desc):
        """Set object description.

        Args:
            desc (str): Object description
        """
        self.description = desc
