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
    """

    def __init__(self, name, description):
        super().__init__()
        self.name = name
        self.short_name = name.lower().replace(' ', '_')
        self.description = description
