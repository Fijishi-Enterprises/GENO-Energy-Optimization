# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/main.ui'
#
# Created by: PyQt5 UI code generator 5.4.1
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(1106, 744)
        MainWindow.setMinimumSize(QtCore.QSize(800, 600))
        self.centralwidget = QtWidgets.QWidget(MainWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.gridLayout_3 = QtWidgets.QGridLayout(self.centralwidget)
        self.gridLayout_3.setObjectName("gridLayout_3")
        self.gridLayout = QtWidgets.QGridLayout()
        self.gridLayout.setObjectName("gridLayout")
        spacerItem = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.gridLayout.addItem(spacerItem, 1, 7, 1, 1)
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.gridLayout.addItem(spacerItem1, 1, 3, 1, 1)
        spacerItem2 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.gridLayout.addItem(spacerItem2, 1, 5, 1, 1)
        spacerItem3 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.gridLayout.addItem(spacerItem3, 1, 1, 1, 1)
        self.checkBox_debug = QtWidgets.QCheckBox(self.centralwidget)
        self.checkBox_debug.setLayoutDirection(QtCore.Qt.RightToLeft)
        self.checkBox_debug.setChecked(True)
        self.checkBox_debug.setObjectName("checkBox_debug")
        self.gridLayout.addWidget(self.checkBox_debug, 0, 8, 1, 1)
        self.pushButton_create_test_setups = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_create_test_setups.setObjectName("pushButton_create_test_setups")
        self.gridLayout.addWidget(self.pushButton_create_test_setups, 1, 2, 1, 1)
        self.pushButton_create_setups_3 = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_create_setups_3.setObjectName("pushButton_create_setups_3")
        self.gridLayout.addWidget(self.pushButton_create_setups_3, 1, 8, 1, 1)
        self.pushButton_create_setups_1 = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_create_setups_1.setObjectName("pushButton_create_setups_1")
        self.gridLayout.addWidget(self.pushButton_create_setups_1, 1, 4, 1, 1)
        self.pushButton_create_setups_2 = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_create_setups_2.setObjectName("pushButton_create_setups_2")
        self.gridLayout.addWidget(self.pushButton_create_setups_2, 1, 6, 1, 1)
        self.gridLayout_2 = QtWidgets.QGridLayout()
        self.gridLayout_2.setObjectName("gridLayout_2")
        self.pushButton_test = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_test.setObjectName("pushButton_test")
        self.gridLayout_2.addWidget(self.pushButton_test, 0, 1, 1, 1)
        self.pushButton_execute = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_execute.setObjectName("pushButton_execute")
        self.gridLayout_2.addWidget(self.pushButton_execute, 1, 0, 1, 1)
        self.pushButton_add_base = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_add_base.setObjectName("pushButton_add_base")
        self.gridLayout_2.addWidget(self.pushButton_add_base, 0, 0, 1, 1)
        self.pushButton_delete_all = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_delete_all.setObjectName("pushButton_delete_all")
        self.gridLayout_2.addWidget(self.pushButton_delete_all, 1, 2, 1, 1)
        self.pushButton_delete_setup = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_delete_setup.setObjectName("pushButton_delete_setup")
        self.gridLayout_2.addWidget(self.pushButton_delete_setup, 0, 2, 1, 1)
        self.gridLayout.addLayout(self.gridLayout_2, 0, 0, 2, 1)
        self.gridLayout_3.addLayout(self.gridLayout, 0, 0, 1, 2)
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        self.treeView_setups = QtWidgets.QTreeView(self.centralwidget)
        self.treeView_setups.setContextMenuPolicy(QtCore.Qt.CustomContextMenu)
        self.treeView_setups.setObjectName("treeView_setups")
        self.horizontalLayout.addWidget(self.treeView_setups)
        self.verticalLayout_2 = QtWidgets.QVBoxLayout()
        self.verticalLayout_2.setObjectName("verticalLayout_2")
        self.label_3 = QtWidgets.QLabel(self.centralwidget)
        self.label_3.setAlignment(QtCore.Qt.AlignCenter)
        self.label_3.setObjectName("label_3")
        self.verticalLayout_2.addWidget(self.label_3)
        self.listView_tools = QtWidgets.QListView(self.centralwidget)
        self.listView_tools.setMaximumSize(QtCore.QSize(200, 16777215))
        self.listView_tools.setObjectName("listView_tools")
        self.verticalLayout_2.addWidget(self.listView_tools)
        self.label_4 = QtWidgets.QLabel(self.centralwidget)
        self.label_4.setAlignment(QtCore.Qt.AlignCenter)
        self.label_4.setObjectName("label_4")
        self.verticalLayout_2.addWidget(self.label_4)
        self.listView_dataformats_input = QtWidgets.QListView(self.centralwidget)
        self.listView_dataformats_input.setMaximumSize(QtCore.QSize(200, 16777215))
        self.listView_dataformats_input.setObjectName("listView_dataformats_input")
        self.verticalLayout_2.addWidget(self.listView_dataformats_input)
        self.label_5 = QtWidgets.QLabel(self.centralwidget)
        self.label_5.setAlignment(QtCore.Qt.AlignCenter)
        self.label_5.setObjectName("label_5")
        self.verticalLayout_2.addWidget(self.label_5)
        self.listView_dataformats_output = QtWidgets.QListView(self.centralwidget)
        self.listView_dataformats_output.setObjectName("listView_dataformats_output")
        self.verticalLayout_2.addWidget(self.listView_dataformats_output)
        self.horizontalLayout.addLayout(self.verticalLayout_2)
        self.gridLayout_3.addLayout(self.horizontalLayout, 1, 0, 1, 1)
        self.verticalLayout = QtWidgets.QVBoxLayout()
        self.verticalLayout.setObjectName("verticalLayout")
        self.label = QtWidgets.QLabel(self.centralwidget)
        self.label.setAlignment(QtCore.Qt.AlignCenter)
        self.label.setObjectName("label")
        self.verticalLayout.addWidget(self.label)
        self.textBrowser_main = QtWidgets.QTextBrowser(self.centralwidget)
        self.textBrowser_main.setMinimumSize(QtCore.QSize(719, 0))
        self.textBrowser_main.setObjectName("textBrowser_main")
        self.verticalLayout.addWidget(self.textBrowser_main)
        self.label_2 = QtWidgets.QLabel(self.centralwidget)
        self.label_2.setAlignment(QtCore.Qt.AlignCenter)
        self.label_2.setObjectName("label_2")
        self.verticalLayout.addWidget(self.label_2)
        self.textBrowser_process_output = QtWidgets.QTextBrowser(self.centralwidget)
        self.textBrowser_process_output.setMinimumSize(QtCore.QSize(719, 0))
        self.textBrowser_process_output.setObjectName("textBrowser_process_output")
        self.verticalLayout.addWidget(self.textBrowser_process_output)
        self.gridLayout_3.addLayout(self.verticalLayout, 1, 1, 1, 1)
        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QtWidgets.QMenuBar(MainWindow)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 1106, 21))
        self.menubar.setObjectName("menubar")
        self.menuFile = QtWidgets.QMenu(self.menubar)
        self.menuFile.setMinimumSize(QtCore.QSize(200, 0))
        self.menuFile.setObjectName("menuFile")
        self.menuHelp = QtWidgets.QMenu(self.menubar)
        self.menuHelp.setObjectName("menuHelp")
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QtWidgets.QStatusBar(MainWindow)
        self.statusbar.setObjectName("statusbar")
        MainWindow.setStatusBar(self.statusbar)
        self.actionQuit = QtWidgets.QAction(MainWindow)
        self.actionQuit.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionQuit.setObjectName("actionQuit")
        self.actionAbout = QtWidgets.QAction(MainWindow)
        self.actionAbout.setObjectName("actionAbout")
        self.actionNew = QtWidgets.QAction(MainWindow)
        font = QtGui.QFont()
        font.setUnderline(False)
        self.actionNew.setFont(font)
        self.actionNew.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionNew.setObjectName("actionNew")
        self.actionLoad = QtWidgets.QAction(MainWindow)
        self.actionLoad.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionLoad.setObjectName("actionLoad")
        self.actionHelp = QtWidgets.QAction(MainWindow)
        self.actionHelp.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionHelp.setObjectName("actionHelp")
        self.actionSave = QtWidgets.QAction(MainWindow)
        self.actionSave.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionSave.setObjectName("actionSave")
        self.actionSave_As = QtWidgets.QAction(MainWindow)
        self.actionSave_As.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionSave_As.setObjectName("actionSave_As")
        self.actionImport = QtWidgets.QAction(MainWindow)
        self.actionImport.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionImport.setObjectName("actionImport")
        self.actionExport = QtWidgets.QAction(MainWindow)
        self.actionExport.setShortcutContext(QtCore.Qt.WindowShortcut)
        self.actionExport.setObjectName("actionExport")
        self.menuFile.addAction(self.actionNew)
        self.menuFile.addAction(self.actionSave)
        self.menuFile.addAction(self.actionSave_As)
        self.menuFile.addAction(self.actionLoad)
        self.menuFile.addSeparator()
        self.menuFile.addAction(self.actionImport)
        self.menuFile.addAction(self.actionExport)
        self.menuFile.addSeparator()
        self.menuFile.addAction(self.actionQuit)
        self.menuHelp.addAction(self.actionHelp)
        self.menuHelp.addAction(self.actionAbout)
        self.menubar.addAction(self.menuFile.menuAction())
        self.menubar.addAction(self.menuHelp.menuAction())

        self.retranslateUi(MainWindow)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

    def retranslateUi(self, MainWindow):
        _translate = QtCore.QCoreApplication.translate
        MainWindow.setWindowTitle(_translate("MainWindow", "Sceleton Titan"))
        self.checkBox_debug.setToolTip(_translate("MainWindow", "<html><head/><body><p>Switch logging verbosity</p></body></html>"))
        self.checkBox_debug.setText(_translate("MainWindow", "Debug"))
        self.pushButton_create_test_setups.setText(_translate("MainWindow", "Test Setups"))
        self.pushButton_create_setups_3.setText(_translate("MainWindow", "Setups\n"
"\'invest\' -> \'MIP\' and\n"
"\'invest\' -> \'LP\'"))
        self.pushButton_create_setups_1.setText(_translate("MainWindow", "Setups \n"
" \'base\' -> \'setup A\'"))
        self.pushButton_create_setups_2.setText(_translate("MainWindow", "Setups\n"
"\'invest -> \'MIP\'"))
        self.pushButton_test.setText(_translate("MainWindow", "Test"))
        self.pushButton_execute.setText(_translate("MainWindow", "Execute"))
        self.pushButton_add_base.setText(_translate("MainWindow", "Add Base"))
        self.pushButton_delete_all.setToolTip(_translate("MainWindow", "<html><head/><body><p>Delete all Setups in the project</p></body></html>"))
        self.pushButton_delete_all.setText(_translate("MainWindow", "Delete All"))
        self.pushButton_delete_setup.setToolTip(_translate("MainWindow", "<html><head/><body><p>Delete selected Setup and all of it\'s children</p></body></html>"))
        self.pushButton_delete_setup.setText(_translate("MainWindow", "Delete Setup"))
        self.label_3.setText(_translate("MainWindow", "Tool"))
        self.label_4.setText(_translate("MainWindow", "Input formats"))
        self.label_5.setText(_translate("MainWindow", "Output formats"))
        self.label.setText(_translate("MainWindow", "Titan Output"))
        self.label_2.setText(_translate("MainWindow", "GAMS Output"))
        self.menuFile.setTitle(_translate("MainWindow", "File"))
        self.menuHelp.setTitle(_translate("MainWindow", "Help"))
        self.actionQuit.setText(_translate("MainWindow", "Exit"))
        self.actionQuit.setToolTip(_translate("MainWindow", "Quit Sceleton"))
        self.actionQuit.setShortcut(_translate("MainWindow", "Ctrl+Q"))
        self.actionAbout.setText(_translate("MainWindow", "About Sceleton"))
        self.actionNew.setText(_translate("MainWindow", "New Project..."))
        self.actionNew.setShortcut(_translate("MainWindow", "Ctrl+N"))
        self.actionLoad.setText(_translate("MainWindow", "Load Project..."))
        self.actionLoad.setShortcut(_translate("MainWindow", "Ctrl+L"))
        self.actionHelp.setText(_translate("MainWindow", "Help"))
        self.actionHelp.setToolTip(_translate("MainWindow", "Sceleton documentation"))
        self.actionHelp.setShortcut(_translate("MainWindow", "F1"))
        self.actionSave.setText(_translate("MainWindow", "Save Project"))
        self.actionSave.setShortcut(_translate("MainWindow", "Ctrl+S"))
        self.actionSave_As.setText(_translate("MainWindow", "Save Project As..."))
        self.actionSave_As.setShortcut(_translate("MainWindow", "Ctrl+A"))
        self.actionImport.setText(_translate("MainWindow", "Import Project..."))
        self.actionImport.setShortcut(_translate("MainWindow", "Ctrl+I"))
        self.actionExport.setText(_translate("MainWindow", "Export Project..."))
        self.actionExport.setShortcut(_translate("MainWindow", "Ctrl+E"))

