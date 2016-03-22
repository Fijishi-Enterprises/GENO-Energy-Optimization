"""
:author: Erkka Rinne <erkka.rinne@vtt.fi>
:date:   16/03/2016
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
        super().__init__()
        self.name = name
        if short_name is not None:
            self.short_name = short_name
        else:
            self.short_name = name.lower().replace(' ', '_')
        self.description = description
