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
        MainWindow.resize(1230, 738)
        MainWindow.setMinimumSize(QtCore.QSize(800, 600))
        self.centralwidget = QtWidgets.QWidget(MainWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.gridLayout = QtWidgets.QGridLayout(self.centralwidget)
        self.gridLayout.setObjectName("gridLayout")
        self.verticalLayout_4 = QtWidgets.QVBoxLayout()
        self.verticalLayout_4.setSpacing(0)
        self.verticalLayout_4.setObjectName("verticalLayout_4")
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        self.groupBox_execute = QtWidgets.QGroupBox(self.centralwidget)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Preferred, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.groupBox_execute.sizePolicy().hasHeightForWidth())
        self.groupBox_execute.setSizePolicy(sizePolicy)
        self.groupBox_execute.setMinimumSize(QtCore.QSize(0, 160))
        self.groupBox_execute.setMaximumSize(QtCore.QSize(16777215, 160))
        self.groupBox_execute.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.groupBox_execute.setFlat(False)
        self.groupBox_execute.setObjectName("groupBox_execute")
        self.verticalLayout_3 = QtWidgets.QVBoxLayout(self.groupBox_execute)
        self.verticalLayout_3.setObjectName("verticalLayout_3")
        self.radioButton_breadth_first = QtWidgets.QRadioButton(self.groupBox_execute)
        self.radioButton_breadth_first.setChecked(True)
        self.radioButton_breadth_first.setObjectName("radioButton_breadth_first")
        self.verticalLayout_3.addWidget(self.radioButton_breadth_first)
        self.radioButton_depth_first = QtWidgets.QRadioButton(self.groupBox_execute)
        self.radioButton_depth_first.setObjectName("radioButton_depth_first")
        self.verticalLayout_3.addWidget(self.radioButton_depth_first)
        self.pushButton_execute_single = QtWidgets.QPushButton(self.groupBox_execute)
        self.pushButton_execute_single.setObjectName("pushButton_execute_single")
        self.verticalLayout_3.addWidget(self.pushButton_execute_single)
        self.pushButton_execute_branch = QtWidgets.QPushButton(self.groupBox_execute)
        self.pushButton_execute_branch.setObjectName("pushButton_execute_branch")
        self.verticalLayout_3.addWidget(self.pushButton_execute_branch)
        self.pushButton_execute_all = QtWidgets.QPushButton(self.groupBox_execute)
        self.pushButton_execute_all.setObjectName("pushButton_execute_all")
        self.verticalLayout_3.addWidget(self.pushButton_execute_all)
        self.horizontalLayout.addWidget(self.groupBox_execute)
        self.groupBox_delete = QtWidgets.QGroupBox(self.centralwidget)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.groupBox_delete.sizePolicy().hasHeightForWidth())
        self.groupBox_delete.setSizePolicy(sizePolicy)
        self.groupBox_delete.setMinimumSize(QtCore.QSize(104, 160))
        self.groupBox_delete.setMaximumSize(QtCore.QSize(104, 160))
        self.groupBox_delete.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.groupBox_delete.setFlat(False)
        self.groupBox_delete.setObjectName("groupBox_delete")
        self.verticalLayout_2 = QtWidgets.QVBoxLayout(self.groupBox_delete)
        self.verticalLayout_2.setObjectName("verticalLayout_2")
        spacerItem = QtWidgets.QSpacerItem(20, 40, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.verticalLayout_2.addItem(spacerItem)
        self.pushButton_delete_setup = QtWidgets.QPushButton(self.groupBox_delete)
        self.pushButton_delete_setup.setObjectName("pushButton_delete_setup")
        self.verticalLayout_2.addWidget(self.pushButton_delete_setup)
        self.pushButton_delete_all = QtWidgets.QPushButton(self.groupBox_delete)
        self.pushButton_delete_all.setObjectName("pushButton_delete_all")
        self.verticalLayout_2.addWidget(self.pushButton_delete_all)
        self.horizontalLayout.addWidget(self.groupBox_delete)
        self.groupBox_flags = QtWidgets.QGroupBox(self.centralwidget)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.groupBox_flags.sizePolicy().hasHeightForWidth())
        self.groupBox_flags.setSizePolicy(sizePolicy)
        self.groupBox_flags.setMinimumSize(QtCore.QSize(104, 160))
        self.groupBox_flags.setMaximumSize(QtCore.QSize(104, 160))
        self.groupBox_flags.setAlignment(QtCore.Qt.AlignLeading|QtCore.Qt.AlignLeft|QtCore.Qt.AlignVCenter)
        self.groupBox_flags.setFlat(False)
        self.groupBox_flags.setObjectName("groupBox_flags")
        self.verticalLayout_5 = QtWidgets.QVBoxLayout(self.groupBox_flags)
        self.verticalLayout_5.setObjectName("verticalLayout_5")
        spacerItem1 = QtWidgets.QSpacerItem(20, 40, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.verticalLayout_5.addItem(spacerItem1)
        self.pushButton_clear_ready_selected = QtWidgets.QPushButton(self.groupBox_flags)
        self.pushButton_clear_ready_selected.setObjectName("pushButton_clear_ready_selected")
        self.verticalLayout_5.addWidget(self.pushButton_clear_ready_selected)
        self.pushButton_clear_ready_all = QtWidgets.QPushButton(self.groupBox_flags)
        self.pushButton_clear_ready_all.setObjectName("pushButton_clear_ready_all")
        self.verticalLayout_5.addWidget(self.pushButton_clear_ready_all)
        self.horizontalLayout.addWidget(self.groupBox_flags)
        spacerItem2 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem2)
        self.verticalLayout_4.addLayout(self.horizontalLayout)
        self.label_4 = QtWidgets.QLabel(self.centralwidget)
        self.label_4.setFrameShape(QtWidgets.QFrame.Panel)
        self.label_4.setFrameShadow(QtWidgets.QFrame.Raised)
        self.label_4.setLineWidth(2)
        self.label_4.setAlignment(QtCore.Qt.AlignCenter)
        self.label_4.setObjectName("label_4")
        self.verticalLayout_4.addWidget(self.label_4)
        self.treeView_setups = QtWidgets.QTreeView(self.centralwidget)
        self.treeView_setups.setMinimumSize(QtCore.QSize(400, 0))
        self.treeView_setups.setContextMenuPolicy(QtCore.Qt.CustomContextMenu)
        self.treeView_setups.setObjectName("treeView_setups")
        self.verticalLayout_4.addWidget(self.treeView_setups)
        self.label_2 = QtWidgets.QLabel(self.centralwidget)
        self.label_2.setFrameShape(QtWidgets.QFrame.Panel)
        self.label_2.setFrameShadow(QtWidgets.QFrame.Raised)
        self.label_2.setLineWidth(2)
        self.label_2.setAlignment(QtCore.Qt.AlignCenter)
        self.label_2.setObjectName("label_2")
        self.verticalLayout_4.addWidget(self.label_2)
        self.listView_tools = QtWidgets.QListView(self.centralwidget)
        self.listView_tools.setObjectName("listView_tools")
        self.verticalLayout_4.addWidget(self.listView_tools)
        self.horizontalLayout_4 = QtWidgets.QHBoxLayout()
        self.horizontalLayout_4.setObjectName("horizontalLayout_4")
        self.toolButton_add_tool = QtWidgets.QToolButton(self.centralwidget)
        self.toolButton_add_tool.setObjectName("toolButton_add_tool")
        self.horizontalLayout_4.addWidget(self.toolButton_add_tool)
        self.toolButton_remove_tool = QtWidgets.QToolButton(self.centralwidget)
        self.toolButton_remove_tool.setObjectName("toolButton_remove_tool")
        self.horizontalLayout_4.addWidget(self.toolButton_remove_tool)
        self.verticalLayout_4.addLayout(self.horizontalLayout_4)
        self.pushButton_test = QtWidgets.QPushButton(self.centralwidget)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButton_test.sizePolicy().hasHeightForWidth())
        self.pushButton_test.setSizePolicy(sizePolicy)
        self.pushButton_test.setMinimumSize(QtCore.QSize(50, 17))
        self.pushButton_test.setMaximumSize(QtCore.QSize(50, 17))
        self.pushButton_test.setObjectName("pushButton_test")
        self.verticalLayout_4.addWidget(self.pushButton_test)
        self.gridLayout.addLayout(self.verticalLayout_4, 0, 0, 1, 1)
        self.verticalLayout = QtWidgets.QVBoxLayout()
        self.verticalLayout.setSpacing(0)
        self.verticalLayout.setObjectName("verticalLayout")
        self.horizontalLayout_2 = QtWidgets.QHBoxLayout()
        self.horizontalLayout_2.setObjectName("horizontalLayout_2")
        self.label = QtWidgets.QLabel(self.centralwidget)
        self.label.setFrameShape(QtWidgets.QFrame.Panel)
        self.label.setFrameShadow(QtWidgets.QFrame.Raised)
        self.label.setLineWidth(2)
        self.label.setAlignment(QtCore.Qt.AlignCenter)
        self.label.setContentsMargins(3, 3, 3, 3)
        self.label.setObjectName("label")
        self.horizontalLayout_2.addWidget(self.label)
        self.pushButton_clear_titan_output = QtWidgets.QPushButton(self.centralwidget)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButton_clear_titan_output.sizePolicy().hasHeightForWidth())
        self.pushButton_clear_titan_output.setSizePolicy(sizePolicy)
        self.pushButton_clear_titan_output.setMinimumSize(QtCore.QSize(40, 23))
        self.pushButton_clear_titan_output.setMaximumSize(QtCore.QSize(40, 23))
        self.pushButton_clear_titan_output.setObjectName("pushButton_clear_titan_output")
        self.horizontalLayout_2.addWidget(self.pushButton_clear_titan_output)
        self.verticalLayout.addLayout(self.horizontalLayout_2)
        self.textBrowser_main = QtWidgets.QTextBrowser(self.centralwidget)
        self.textBrowser_main.setMinimumSize(QtCore.QSize(800, 0))
        self.textBrowser_main.setObjectName("textBrowser_main")
        self.verticalLayout.addWidget(self.textBrowser_main)
        self.horizontalLayout_3 = QtWidgets.QHBoxLayout()
        self.horizontalLayout_3.setObjectName("horizontalLayout_3")
        self.label_5 = QtWidgets.QLabel(self.centralwidget)
        self.label_5.setFrameShape(QtWidgets.QFrame.Panel)
        self.label_5.setFrameShadow(QtWidgets.QFrame.Raised)
        self.label_5.setLineWidth(2)
        self.label_5.setAlignment(QtCore.Qt.AlignCenter)
        self.label_5.setContentsMargins(3, 3, 3, 3)
        self.label_5.setObjectName("label_5")
        self.horizontalLayout_3.addWidget(self.label_5)
        self.pushButton_clear_gams_output = QtWidgets.QPushButton(self.centralwidget)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.pushButton_clear_gams_output.sizePolicy().hasHeightForWidth())
        self.pushButton_clear_gams_output.setSizePolicy(sizePolicy)
        self.pushButton_clear_gams_output.setMinimumSize(QtCore.QSize(40, 23))
        self.pushButton_clear_gams_output.setMaximumSize(QtCore.QSize(40, 23))
        self.pushButton_clear_gams_output.setObjectName("pushButton_clear_gams_output")
        self.horizontalLayout_3.addWidget(self.pushButton_clear_gams_output)
        self.verticalLayout.addLayout(self.horizontalLayout_3)
        self.textBrowser_process_output = QtWidgets.QTextBrowser(self.centralwidget)
        self.textBrowser_process_output.setMinimumSize(QtCore.QSize(800, 0))
        self.textBrowser_process_output.setObjectName("textBrowser_process_output")
        self.verticalLayout.addWidget(self.textBrowser_process_output)
        self.checkBox_debug = QtWidgets.QCheckBox(self.centralwidget)
        self.checkBox_debug.setLayoutDirection(QtCore.Qt.RightToLeft)
        self.checkBox_debug.setChecked(True)
        self.checkBox_debug.setObjectName("checkBox_debug")
        self.verticalLayout.addWidget(self.checkBox_debug)
        self.gridLayout.addLayout(self.verticalLayout, 0, 1, 1, 1)
        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QtWidgets.QMenuBar(MainWindow)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 1230, 21))
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
        self.actionSettings = QtWidgets.QAction(MainWindow)
        self.actionSettings.setObjectName("actionSettings")
        self.menuFile.addAction(self.actionNew)
        self.menuFile.addAction(self.actionSave)
        self.menuFile.addAction(self.actionSave_As)
        self.menuFile.addAction(self.actionLoad)
        self.menuFile.addSeparator()
        self.menuFile.addAction(self.actionImport)
        self.menuFile.addAction(self.actionExport)
        self.menuFile.addSeparator()
        self.menuFile.addAction(self.actionSettings)
        self.menuFile.addSeparator()
        self.menuFile.addAction(self.actionQuit)
        self.menuHelp.addAction(self.actionHelp)
        self.menuHelp.addAction(self.actionAbout)
        self.menubar.addAction(self.menuFile.menuAction())
        self.menubar.addAction(self.menuHelp.menuAction())

        self.retranslateUi(MainWindow)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)
        MainWindow.setTabOrder(self.radioButton_breadth_first, self.radioButton_depth_first)
        MainWindow.setTabOrder(self.radioButton_depth_first, self.pushButton_execute_all)
        MainWindow.setTabOrder(self.pushButton_execute_all, self.pushButton_delete_all)
        MainWindow.setTabOrder(self.pushButton_delete_all, self.treeView_setups)

    def retranslateUi(self, MainWindow):
        _translate = QtCore.QCoreApplication.translate
        MainWindow.setWindowTitle(_translate("MainWindow", "Sceleton Titan"))
        self.groupBox_execute.setTitle(_translate("MainWindow", "Execute"))
        self.radioButton_breadth_first.setToolTip(_translate("MainWindow", "<html><head/><body><p>Breadth-first tree traversal algorithm. Determines the order of executed Setups when executing All Setups in the project.</p></body></html>"))
        self.radioButton_breadth_first.setText(_translate("MainWindow", "Breadth-first"))
        self.radioButton_depth_first.setToolTip(_translate("MainWindow", "<html><head/><body><p>[Not Implemented]. Depth-first tree traversal algorithm.</p></body></html>"))
        self.radioButton_depth_first.setText(_translate("MainWindow", "Depth-first"))
        self.pushButton_execute_single.setToolTip(_translate("MainWindow", "<html><head/><body><p>Executes only the selected Setup.</p></body></html>"))
        self.pushButton_execute_single.setText(_translate("MainWindow", "Single"))
        self.pushButton_execute_branch.setToolTip(_translate("MainWindow", "<html><head/><body><p>Execute selected Setup and its parents. Execution starts from selected Setups\' base Setup and traverses from the base until the selected Setup.</p></body></html>"))
        self.pushButton_execute_branch.setText(_translate("MainWindow", "Branch"))
        self.pushButton_execute_all.setToolTip(_translate("MainWindow", "<html><head/><body><p>Execute all Setups in the project by using the selected tree traversal algorithm.</p></body></html>"))
        self.pushButton_execute_all.setText(_translate("MainWindow", "Project"))
        self.groupBox_delete.setTitle(_translate("MainWindow", "Delete"))
        self.pushButton_delete_setup.setToolTip(_translate("MainWindow", "<html><head/><body><p>Delete selected Setup and all of it\'s children</p></body></html>"))
        self.pushButton_delete_setup.setText(_translate("MainWindow", "Single"))
        self.pushButton_delete_all.setToolTip(_translate("MainWindow", "<html><head/><body><p>Delete all Setups in the project</p></body></html>"))
        self.pushButton_delete_all.setText(_translate("MainWindow", "All"))
        self.groupBox_flags.setTitle(_translate("MainWindow", "Clear Ready Flag"))
        self.pushButton_clear_ready_selected.setToolTip(_translate("MainWindow", "<html><head/><body><p>Clear ready flag for the selected Setup</p></body></html>"))
        self.pushButton_clear_ready_selected.setText(_translate("MainWindow", "Single"))
        self.pushButton_clear_ready_all.setToolTip(_translate("MainWindow", "<html><head/><body><p>Clear ready flag for all Setups in the project</p></body></html>"))
        self.pushButton_clear_ready_all.setText(_translate("MainWindow", "All"))
        self.label_4.setText(_translate("MainWindow", "Setups"))
        self.label_2.setText(_translate("MainWindow", "Tools"))
        self.toolButton_add_tool.setText(_translate("MainWindow", "Add Tool"))
        self.toolButton_remove_tool.setText(_translate("MainWindow", "Remove Tool"))
        self.pushButton_test.setText(_translate("MainWindow", "Test"))
        self.label.setText(_translate("MainWindow", "Titan Output"))
        self.pushButton_clear_titan_output.setText(_translate("MainWindow", "Clear"))
        self.label_5.setText(_translate("MainWindow", "GAMS Output"))
        self.pushButton_clear_gams_output.setText(_translate("MainWindow", "Clear"))
        self.checkBox_debug.setToolTip(_translate("MainWindow", "<html><head/><body><p>Switch logging verbosity</p></body></html>"))
        self.checkBox_debug.setText(_translate("MainWindow", "Debug"))
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
        self.actionSettings.setText(_translate("MainWindow", "Settings..."))
        self.actionSettings.setToolTip(_translate("MainWindow", "<html><head/><body><p>Manage Sceleton Settings</p></body></html>"))
        self.actionSettings.setShortcut(_translate("MainWindow", "F2"))

