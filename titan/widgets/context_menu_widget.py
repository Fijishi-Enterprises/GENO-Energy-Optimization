"""
Class for a custom context menu.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   5.4.2015
"""

from PyQt5.QtWidgets import QMenu


class ContextMenuWidget(QMenu):
    """ Main class for a context menu."""

    def __init__(self, position, ind):
        super().__init__()
        self.ind = ind
        self.option = "None"
        if not ind.isValid():
            self.add_action("Add New Base")
        else:
            self.add_action("Add New Base")
            self.add_action("Add Child")
            self.add_action("Edit")
            self.add_action("Execute")
        self.exec_(position)

    def add_action(self, text):
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
