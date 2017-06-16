"""
Class for a custom QTextBrowser to add actions to its default context menu.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   16.6.2017
"""

from PyQt5.QtWidgets import QTextBrowser, QAction
from PyQt5.Qt import QIcon, QPixmap


class CustomQTextBrowser(QTextBrowser):
    """Custom QTextBrowser class."""

    def __init__(self, parent):
        super().__init__()
        self._parent = parent

    def contextMenuEvent(self, event):
        """Reimplemented method to add a clear action into the default context menu.

        Args:
            event (QContextMenuEvent): Received event
        """
        icon = QIcon()
        icon.addPixmap(QPixmap(":/toolButtons/clear_qtextbrowser.png"), QIcon.Normal, QIcon.On)
        clear_action = QAction(icon, "Clear", self)
        # noinspection PyUnresolvedReferences
        clear_action.triggered.connect(lambda: self.clear())
        menu = self.createStandardContextMenu()
        menu.addSeparator()
        menu.addAction(clear_action)
        menu.exec_(event.globalPos())
