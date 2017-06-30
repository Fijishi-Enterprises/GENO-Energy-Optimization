"""
Class for a custom context menu.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   5.4.2016
"""

from PyQt5.QtWidgets import QMenu


class SetupContextMenuWidget(QMenu):
    """ Main class for a context menu."""

    def __init__(self, parent, position, ind):
        super().__init__()
        self._parent = parent
        self.ind = ind
        self.option = "None"
        if not ind.isValid():
            self.add_action("Add Setup")
            self.add_action("Execute Project")
            self.add_action("Verify Input Data")
            self.add_action("Explore Input Data")
            self.add_action("Clear All Flags")
        else:
            self.add_action("Add Setup")
            self.add_action("Add Child Setup")
            self.add_action("Edit Tool")
            self.add_action("Execute Single")
            self.add_action("Execute Selected")
            self.add_action("Execute Project")
            self.add_action("Verify Input Data")
            self.add_action("Explore Input Data")
            self.add_action("Clear Flags")
            self.add_action("Clear All Flags")
            self.add_action("Clone")
        self.exec_(position)

    def add_action(self, text, shortcut=None):
        """ Adds an action to the context menu.

        Args:
            text (str): Text description of the action
        """
        action = self.addAction(text)
        action.triggered.connect(lambda: self.set_action(text))

    def set_action(self, option):
        """Sets the action which was clicked.

        Args:
            option: string with the text description of the action
        """
        self.option = option

    def get_action(self):
        """ Returns the clicked action, a string with a description. """
        return self.option
