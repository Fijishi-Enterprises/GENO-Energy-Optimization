# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/project_form.ui'
#
# Created by: PyQt5 UI code generator 5.6
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_Form(object):
    def setupUi(self, Form):
        Form.setObjectName("Form")
        Form.setWindowModality(QtCore.Qt.ApplicationModal)
        Form.resize(466, 369)
        self.gridLayout = QtWidgets.QGridLayout(Form)
        self.gridLayout.setObjectName("gridLayout")
        self.lineEdit_project_name = QtWidgets.QLineEdit(Form)
        self.lineEdit_project_name.setObjectName("lineEdit_project_name")
        self.gridLayout.addWidget(self.lineEdit_project_name, 0, 0, 1, 1)
        self.textEdit_description = QtWidgets.QTextEdit(Form)
        self.textEdit_description.setTabChangesFocus(True)
        self.textEdit_description.setAcceptRichText(False)
        self.textEdit_description.setObjectName("textEdit_description")
        self.gridLayout.addWidget(self.textEdit_description, 1, 0, 1, 1)
        self.verticalLayout_2 = QtWidgets.QVBoxLayout()
        self.verticalLayout_2.setObjectName("verticalLayout_2")
        self.label_folder = QtWidgets.QLabel(Form)
        self.label_folder.setEnabled(False)
        self.label_folder.setContextMenuPolicy(QtCore.Qt.NoContextMenu)
        self.label_folder.setFrameShape(QtWidgets.QFrame.NoFrame)
        self.label_folder.setFrameShadow(QtWidgets.QFrame.Plain)
        self.label_folder.setTextFormat(QtCore.Qt.PlainText)
        self.label_folder.setIndent(-1)
        self.label_folder.setObjectName("label_folder")
        self.verticalLayout_2.addWidget(self.label_folder)
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        spacerItem = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem)
        self.pushButton_ok = QtWidgets.QPushButton(Form)
        self.pushButton_ok.setDefault(True)
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.horizontalLayout.addWidget(self.pushButton_ok)
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem1)
        self.pushButton_cancel = QtWidgets.QPushButton(Form)
        self.pushButton_cancel.setDefault(True)
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.horizontalLayout.addWidget(self.pushButton_cancel)
        spacerItem2 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem2)
        self.verticalLayout_2.addLayout(self.horizontalLayout)
        self.gridLayout.addLayout(self.verticalLayout_2, 2, 0, 1, 1)

        self.retranslateUi(Form)
        QtCore.QMetaObject.connectSlotsByName(Form)
        Form.setTabOrder(self.lineEdit_project_name, self.textEdit_description)
        Form.setTabOrder(self.textEdit_description, self.pushButton_ok)
        Form.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, Form):
        _translate = QtCore.QCoreApplication.translate
        Form.setWindowTitle(_translate("Form", "New Project"))
        self.lineEdit_project_name.setToolTip(_translate("Form", "<html><head/><body><p>Project name (Required)</p></body></html>"))
        self.lineEdit_project_name.setPlaceholderText(_translate("Form", "Type project name here..."))
        self.textEdit_description.setToolTip(_translate("Form", "<html><head/><body><p>Project description (Optional)</p></body></html>"))
        self.textEdit_description.setPlaceholderText(_translate("Form", "Type project description here..."))
        self.label_folder.setToolTip(_translate("Form", "<html><head/><body><p>Folder name that will be used with the given project name</p></body></html>"))
        self.label_folder.setText(_translate("Form", "Project folder:"))
        self.pushButton_ok.setText(_translate("Form", "Ok"))
        self.pushButton_cancel.setText(_translate("Form", "Cancel"))

