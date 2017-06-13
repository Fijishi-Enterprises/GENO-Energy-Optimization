# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/input_explorer_form.ui'
#
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_Form(object):
    def setupUi(self, Form):
        Form.setObjectName("Form")
        Form.setWindowModality(QtCore.Qt.ApplicationModal)
        Form.resize(640, 463)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(Form.sizePolicy().hasHeightForWidth())
        Form.setSizePolicy(sizePolicy)
        Form.setMaximumSize(QtCore.QSize(16777215, 16777215))
        self.verticalLayout = QtWidgets.QVBoxLayout(Form)
        self.verticalLayout.setObjectName("verticalLayout")
        self.splitter_2 = QtWidgets.QSplitter(Form)
        self.splitter_2.setOrientation(QtCore.Qt.Vertical)
        self.splitter_2.setObjectName("splitter_2")
        self.splitter = QtWidgets.QSplitter(self.splitter_2)
        self.splitter.setOrientation(QtCore.Qt.Horizontal)
        self.splitter.setObjectName("splitter")
        self.treeView_setups = QtWidgets.QTreeView(self.splitter)
        self.treeView_setups.setStyleSheet(":focus {border: 2px groove;}")
        self.treeView_setups.setEditTriggers(QtWidgets.QAbstractItemView.NoEditTriggers)
        self.treeView_setups.setAlternatingRowColors(True)
        self.treeView_setups.setObjectName("treeView_setups")
        self.textBrowser_preview = QtWidgets.QTextBrowser(self.splitter)
        self.textBrowser_preview.setFocusPolicy(QtCore.Qt.NoFocus)
        self.textBrowser_preview.setAutoFillBackground(False)
        self.textBrowser_preview.setStyleSheet(":focus {border: 2px groove;}")
        self.textBrowser_preview.setLineWrapMode(QtWidgets.QTextEdit.NoWrap)
        self.textBrowser_preview.setCursorWidth(1)
        self.textBrowser_preview.setTextInteractionFlags(QtCore.Qt.TextSelectableByKeyboard|QtCore.Qt.TextSelectableByMouse)
        self.textBrowser_preview.setOpenLinks(False)
        self.textBrowser_preview.setObjectName("textBrowser_preview")
        self.tableView_file_explorer = QtWidgets.QTableView(self.splitter_2)
        self.tableView_file_explorer.setStyleSheet(":focus {border: 2px groove;}")
        self.tableView_file_explorer.setEditTriggers(QtWidgets.QAbstractItemView.NoEditTriggers)
        self.tableView_file_explorer.setTabKeyNavigation(False)
        self.tableView_file_explorer.setSelectionMode(QtWidgets.QAbstractItemView.SingleSelection)
        self.tableView_file_explorer.setShowGrid(False)
        self.tableView_file_explorer.setCornerButtonEnabled(False)
        self.tableView_file_explorer.setObjectName("tableView_file_explorer")
        self.tableView_file_explorer.horizontalHeader().setHighlightSections(False)
        self.tableView_file_explorer.horizontalHeader().setStretchLastSection(True)
        self.tableView_file_explorer.verticalHeader().setVisible(False)
        self.tableView_file_explorer.verticalHeader().setDefaultSectionSize(20)
        self.tableView_file_explorer.verticalHeader().setMinimumSectionSize(10)
        self.verticalLayout.addWidget(self.splitter_2)
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        spacerItem = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem)
        self.pushButton_close = QtWidgets.QPushButton(Form)
        self.pushButton_close.setFocusPolicy(QtCore.Qt.NoFocus)
        self.pushButton_close.setDefault(True)
        self.pushButton_close.setObjectName("pushButton_close")
        self.horizontalLayout.addWidget(self.pushButton_close)
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem1)
        self.verticalLayout.addLayout(self.horizontalLayout)

        self.retranslateUi(Form)
        QtCore.QMetaObject.connectSlotsByName(Form)
        Form.setTabOrder(self.treeView_setups, self.tableView_file_explorer)
        Form.setTabOrder(self.tableView_file_explorer, self.textBrowser_preview)
        Form.setTabOrder(self.textBrowser_preview, self.pushButton_close)

    def retranslateUi(self, Form):
        _translate = QtCore.QCoreApplication.translate
        Form.setWindowTitle(_translate("Form", "Input Explorer"))
        self.textBrowser_preview.setPlaceholderText(_translate("Form", "No preview available"))
        self.pushButton_close.setText(_translate("Form", "Close"))

