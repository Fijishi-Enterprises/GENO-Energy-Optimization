# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/output_explorer_form.ui'
#
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_Form(object):
    def setupUi(self, Form):
        Form.setObjectName("Form")
        Form.setWindowModality(QtCore.Qt.ApplicationModal)
        Form.resize(760, 560)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(Form.sizePolicy().hasHeightForWidth())
        Form.setSizePolicy(sizePolicy)
        Form.setMaximumSize(QtCore.QSize(16777215, 16777215))
        self.verticalLayout = QtWidgets.QVBoxLayout(Form)
        self.verticalLayout.setSpacing(0)
        self.verticalLayout.setObjectName("verticalLayout")
        self.label_project_dir = QtWidgets.QLabel(Form)
        self.label_project_dir.setAlignment(QtCore.Qt.AlignCenter)
        self.label_project_dir.setObjectName("label_project_dir")
        self.verticalLayout.addWidget(self.label_project_dir)
        self.groupBox = QtWidgets.QGroupBox(Form)
        self.groupBox.setObjectName("groupBox")
        self.horizontalLayout_2 = QtWidgets.QHBoxLayout(self.groupBox)
        self.horizontalLayout_2.setContentsMargins(-1, 2, -1, 4)
        self.horizontalLayout_2.setObjectName("horizontalLayout_2")
        self.radioButton_show_all = QtWidgets.QRadioButton(self.groupBox)
        self.radioButton_show_all.setFocusPolicy(QtCore.Qt.StrongFocus)
        self.radioButton_show_all.setChecked(True)
        self.radioButton_show_all.setObjectName("radioButton_show_all")
        self.horizontalLayout_2.addWidget(self.radioButton_show_all)
        self.radioButton_show_newest = QtWidgets.QRadioButton(self.groupBox)
        self.radioButton_show_newest.setObjectName("radioButton_show_newest")
        self.horizontalLayout_2.addWidget(self.radioButton_show_newest)
        self.radioButton_show_today = QtWidgets.QRadioButton(self.groupBox)
        self.radioButton_show_today.setFocusPolicy(QtCore.Qt.StrongFocus)
        self.radioButton_show_today.setObjectName("radioButton_show_today")
        self.horizontalLayout_2.addWidget(self.radioButton_show_today)
        self.radioButton_show_failed = QtWidgets.QRadioButton(self.groupBox)
        self.radioButton_show_failed.setObjectName("radioButton_show_failed")
        self.horizontalLayout_2.addWidget(self.radioButton_show_failed)
        self.verticalLayout.addWidget(self.groupBox)
        self.splitter_3 = QtWidgets.QSplitter(Form)
        self.splitter_3.setOrientation(QtCore.Qt.Vertical)
        self.splitter_3.setChildrenCollapsible(False)
        self.splitter_3.setObjectName("splitter_3")
        self.splitter = QtWidgets.QSplitter(self.splitter_3)
        self.splitter.setOrientation(QtCore.Qt.Horizontal)
        self.splitter.setChildrenCollapsible(False)
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
        self.splitter_2 = QtWidgets.QSplitter(self.splitter_3)
        self.splitter_2.setOrientation(QtCore.Qt.Horizontal)
        self.splitter_2.setChildrenCollapsible(False)
        self.splitter_2.setObjectName("splitter_2")
        self.tableView_folders = QtWidgets.QTableView(self.splitter_2)
        self.tableView_folders.setStyleSheet(":focus {border: 2px groove;}")
        self.tableView_folders.setEditTriggers(QtWidgets.QAbstractItemView.NoEditTriggers)
        self.tableView_folders.setTabKeyNavigation(False)
        self.tableView_folders.setSelectionMode(QtWidgets.QAbstractItemView.SingleSelection)
        self.tableView_folders.setShowGrid(False)
        self.tableView_folders.setCornerButtonEnabled(False)
        self.tableView_folders.setObjectName("tableView_folders")
        self.tableView_folders.horizontalHeader().setHighlightSections(False)
        self.tableView_folders.horizontalHeader().setStretchLastSection(True)
        self.tableView_folders.verticalHeader().setVisible(False)
        self.tableView_folders.verticalHeader().setDefaultSectionSize(20)
        self.tableView_folders.verticalHeader().setMinimumSectionSize(10)
        self.tableView_files = QtWidgets.QTableView(self.splitter_2)
        self.tableView_files.setStyleSheet(":focus {border: 2px groove;}")
        self.tableView_files.setEditTriggers(QtWidgets.QAbstractItemView.NoEditTriggers)
        self.tableView_files.setTabKeyNavigation(False)
        self.tableView_files.setSelectionMode(QtWidgets.QAbstractItemView.SingleSelection)
        self.tableView_files.setShowGrid(False)
        self.tableView_files.setCornerButtonEnabled(False)
        self.tableView_files.setObjectName("tableView_files")
        self.tableView_files.horizontalHeader().setHighlightSections(False)
        self.tableView_files.horizontalHeader().setStretchLastSection(True)
        self.tableView_files.verticalHeader().setVisible(False)
        self.tableView_files.verticalHeader().setDefaultSectionSize(20)
        self.tableView_files.verticalHeader().setMinimumSectionSize(10)
        self.verticalLayout.addWidget(self.splitter_3)
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setContentsMargins(-1, 9, -1, -1)
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
        Form.setTabOrder(self.treeView_setups, self.tableView_folders)
        Form.setTabOrder(self.tableView_folders, self.tableView_files)
        Form.setTabOrder(self.tableView_files, self.radioButton_show_all)
        Form.setTabOrder(self.radioButton_show_all, self.radioButton_show_newest)
        Form.setTabOrder(self.radioButton_show_newest, self.radioButton_show_today)

    def retranslateUi(self, Form):
        _translate = QtCore.QCoreApplication.translate
        Form.setWindowTitle(_translate("Form", "Result Explorer"))
        self.label_project_dir.setText(_translate("Form", "Directory"))
        self.groupBox.setTitle(_translate("Form", "Show"))
        self.radioButton_show_all.setToolTip(_translate("Form", "<html><head/><body><p>Show all results</p></body></html>"))
        self.radioButton_show_all.setText(_translate("Form", "All"))
        self.radioButton_show_newest.setText(_translate("Form", "Newest"))
        self.radioButton_show_today.setToolTip(_translate("Form", "<html><head/><body><p>Show only results from today</p></body></html>"))
        self.radioButton_show_today.setText(_translate("Form", "Today"))
        self.radioButton_show_failed.setText(_translate("Form", "Failed"))
        self.textBrowser_preview.setPlaceholderText(_translate("Form", "No preview available"))
        self.pushButton_close.setText(_translate("Form", "Close"))
