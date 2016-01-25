# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/main.ui'
#
# Created by: PyQt5 UI code generator 5.5.1
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_MainWindow(object):
    def setupUi(self, MainWindow):
        MainWindow.setObjectName("MainWindow")
        MainWindow.resize(864, 710)
        MainWindow.setMinimumSize(QtCore.QSize(800, 600))
        self.centralwidget = QtWidgets.QWidget(MainWindow)
        self.centralwidget.setObjectName("centralwidget")
        self.pushButton_start = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_start.setGeometry(QtCore.QRect(300, 60, 75, 23))
        self.pushButton_start.setObjectName("pushButton_start")
        self.checkBox_debug = QtWidgets.QCheckBox(self.centralwidget)
        self.checkBox_debug.setGeometry(QtCore.QRect(790, 10, 70, 17))
        self.checkBox_debug.setChecked(True)
        self.checkBox_debug.setObjectName("checkBox_debug")
        self.pushButton_test = QtWidgets.QPushButton(self.centralwidget)
        self.pushButton_test.setGeometry(QtCore.QRect(470, 60, 75, 23))
        self.pushButton_test.setObjectName("pushButton_test")
        self.verticalLayoutWidget = QtWidgets.QWidget(self.centralwidget)
        self.verticalLayoutWidget.setGeometry(QtCore.QRect(80, 119, 721, 531))
        self.verticalLayoutWidget.setObjectName("verticalLayoutWidget")
        self.verticalLayout = QtWidgets.QVBoxLayout(self.verticalLayoutWidget)
        self.verticalLayout.setObjectName("verticalLayout")
        self.label = QtWidgets.QLabel(self.verticalLayoutWidget)
        self.label.setAlignment(QtCore.Qt.AlignCenter)
        self.label.setObjectName("label")
        self.verticalLayout.addWidget(self.label)
        self.textBrowser_main = QtWidgets.QTextBrowser(self.verticalLayoutWidget)
        self.textBrowser_main.setObjectName("textBrowser_main")
        self.verticalLayout.addWidget(self.textBrowser_main)
        self.label_2 = QtWidgets.QLabel(self.verticalLayoutWidget)
        self.label_2.setAlignment(QtCore.Qt.AlignCenter)
        self.label_2.setObjectName("label_2")
        self.verticalLayout.addWidget(self.label_2)
        self.textBrowser_process_output = QtWidgets.QTextBrowser(self.verticalLayoutWidget)
        self.textBrowser_process_output.setObjectName("textBrowser_process_output")
        self.verticalLayout.addWidget(self.textBrowser_process_output)
        MainWindow.setCentralWidget(self.centralwidget)
        self.menubar = QtWidgets.QMenuBar(MainWindow)
        self.menubar.setGeometry(QtCore.QRect(0, 0, 864, 21))
        self.menubar.setObjectName("menubar")
        self.menuSceleton_Titan = QtWidgets.QMenu(self.menubar)
        self.menuSceleton_Titan.setObjectName("menuSceleton_Titan")
        MainWindow.setMenuBar(self.menubar)
        self.statusbar = QtWidgets.QStatusBar(MainWindow)
        self.statusbar.setObjectName("statusbar")
        MainWindow.setStatusBar(self.statusbar)
        self.action_quit = QtWidgets.QAction(MainWindow)
        self.action_quit.setObjectName("action_quit")
        self.menuSceleton_Titan.addAction(self.action_quit)
        self.menubar.addAction(self.menuSceleton_Titan.menuAction())

        self.retranslateUi(MainWindow)
        QtCore.QMetaObject.connectSlotsByName(MainWindow)

    def retranslateUi(self, MainWindow):
        _translate = QtCore.QCoreApplication.translate
        MainWindow.setWindowTitle(_translate("MainWindow", "Sceleton Titan"))
        self.pushButton_start.setText(_translate("MainWindow", "Start"))
        self.checkBox_debug.setText(_translate("MainWindow", "Debug"))
        self.pushButton_test.setText(_translate("MainWindow", "Test"))
        self.label.setText(_translate("MainWindow", "Titan Output"))
        self.label_2.setText(_translate("MainWindow", "GAMS Output"))
        self.menuSceleton_Titan.setTitle(_translate("MainWindow", "File"))
        self.action_quit.setText(_translate("MainWindow", "Exit"))

