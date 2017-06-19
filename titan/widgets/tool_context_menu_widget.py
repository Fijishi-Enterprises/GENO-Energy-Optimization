"""
Class for a custom context menu for tool listView.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   19.6.2017
"""

from PyQt5.QtWidgets import QMenu


class ToolContextMenuWidget(QMenu):
    """ Main class for a context menu."""

    def __init__(self, parent, position):
        super().__init__()
        self._parent = parent
        self.option = "None"
        self.add_action("Add Tool")
        self.add_action("Refresh Tools")
        self.add_action("Remove Tool")
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
