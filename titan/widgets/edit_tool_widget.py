"""
Widget to change the Tool of a selected Setup.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   1.6.2016
"""

import os
from PyQt5.QtWidgets import QWidget, QStatusBar
from PyQt5.QtCore import pyqtSlot, QModelIndex, Qt
import ui.edit_tool_form
import logging


class EditToolWidget(QWidget):
    """ A widget to edit Tool for a Setup.

    Attributes:
        parent: PyQt parent widget.
    """
    def __init__(self, parent, index):
        """ Initialize class. """
        super().__init__()
        self._parent = parent  # QWidget parent
        #  Set up the user interface from Designer.
        self.ui = ui.edit_tool_form.Ui_Form()
        self.ui.setupUi(self)
        # Ensure this window gets garbage-collected when closed
        self.setAttribute(Qt.WA_DeleteOnClose)
        # Class attributes
        self.index = index  # Selected Setup index
        self.setup = index.internalPointer()
        self.tool = self.setup.tool
        self.cmdline_args = self.setup.cmdline_args
        # self.ui.pushButton_ok.setDefault(True)
        self.ui.comboBox_tool.setFocus()
        # Load Tool model to comboBox
        self.ui.comboBox_tool.setModel(self._parent.tool_model)
        # Set the correct tool into comboBox according to current Setup Tool
        if not self.tool:
            row = 0
        else:
            tool_name = self.tool.name
            for i in range(self._parent.tool_model.rowCount()):
                if i == 0:
                    # Skip tool_model._tools[0] because it is a string
                    continue
                if tool_name == self._parent.tool_model.tool(i).name:
                    # Set Tool command line arguments to readonly line_edit as default
                    self.ui.comboBox_tool.setCurrentIndex(i)
                    tool_args = self.tool.cmdline_args
                    self.ui.lineEdit_tool_args.setText(tool_args)
        # Set current command line arguments to lineEdit as default
        self.ui.lineEdit_cmdline_params.setText(self.cmdline_args)
        self.connect_signals()

    def connect_signals(self):
        """ Connect PyQt signals. """
        # Button clicked handlers
        self.ui.pushButton_ok.clicked.connect(self.ok_clicked)
        self.ui.pushButton_cancel.clicked.connect(self.close)
        self.ui.comboBox_tool.currentIndexChanged.connect(self.update)

    @pyqtSlot(int)
    def update(self, row):
        """Show Tool command line arguments in a line edit (read-only)."""
        if row == 0:
            # No Tool selected
            self.ui.lineEdit_tool_args.setText("")
            return
        selected_tool = self._parent.tool_model.tool(row)
        args = selected_tool.cmdline_args
        if not args:
            # Tool cmdline_args is None if the line does not exist in Tool definition file
            args = ''
        self.ui.lineEdit_tool_args.setText("{0}".format(args))
        return

    @pyqtSlot()
    def ok_clicked(self):
        """Change Tool and command line parameters for selected Setup."""
        tool_text = self.ui.comboBox_tool.currentText()
        cmd_args = self.ui.lineEdit_cmdline_params.text()

        # self.cmdline_args = self.ui.lineEdit_cmdline_params.text()
        logging.debug("sel_tool:%s, args:%s" % (tool_text, cmd_args))
        c_index = self.ui.comboBox_tool.currentIndex()
        if c_index == 0:
            selected_tool = None
        else:
            selected_tool = self._parent.tool_model.tool(c_index)

        if self.cmdline_args == cmd_args and selected_tool == self.tool:
            # Tool and command line args did not change
            logging.debug("No changes in Tool or command line arguments")
        else:
            self._parent.edit_tool(self.setup, selected_tool, cmd_args)
        self.close()

    def keyPressEvent(self, e):
        """Close form when escape key is pressed.

        Args:
            e (QKeyEvent): Received key press event.
        """
        if e.key() == Qt.Key_Escape:
            self.close()

    def closeEvent(self, event=None):
        """Handle close window.

        Args:
            event (QEvent): Closing event if 'X' is clicked.
        """
        if event:
            event.accept()
