# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/setup_popup.ui'
#
# Created by: PyQt5 UI code generator 5.4.1
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_Form(object):
    def setupUi(self, Form):
        Form.setObjectName("Form")
        Form.setWindowModality(QtCore.Qt.ApplicationModal)
        Form.resize(320, 180)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(Form.sizePolicy().hasHeightForWidth())
        Form.setSizePolicy(sizePolicy)
        self.gridLayout = QtWidgets.QGridLayout(Form)
        self.gridLayout.setObjectName("gridLayout")
        self.lineEdit_description = QtWidgets.QLineEdit(Form)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEdit_description.sizePolicy().hasHeightForWidth())
        self.lineEdit_description.setSizePolicy(sizePolicy)
        self.lineEdit_description.setMinimumSize(QtCore.QSize(220, 20))
        self.lineEdit_description.setMaximumSize(QtCore.QSize(5000, 20))
        self.lineEdit_description.setObjectName("lineEdit_description")
        self.gridLayout.addWidget(self.lineEdit_description, 1, 0, 1, 1)
        spacerItem = QtWidgets.QSpacerItem(20, 41, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.gridLayout.addItem(spacerItem, 2, 0, 1, 1)
        self.lineEdit_name = QtWidgets.QLineEdit(Form)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEdit_name.sizePolicy().hasHeightForWidth())
        self.lineEdit_name.setSizePolicy(sizePolicy)
        self.lineEdit_name.setMinimumSize(QtCore.QSize(220, 20))
        self.lineEdit_name.setMaximumSize(QtCore.QSize(5000, 20))
        self.lineEdit_name.setObjectName("lineEdit_name")
        self.gridLayout.addWidget(self.lineEdit_name, 0, 0, 1, 1)
        self.verticalLayout = QtWidgets.QVBoxLayout()
        self.verticalLayout.setObjectName("verticalLayout")
        self.label_setup_folder = QtWidgets.QLabel(Form)
        self.label_setup_folder.setEnabled(False)
        self.label_setup_folder.setContextMenuPolicy(QtCore.Qt.NoContextMenu)
        self.label_setup_folder.setIndent(-1)
        self.label_setup_folder.setObjectName("label_setup_folder")
        self.verticalLayout.addWidget(self.label_setup_folder)
        self.horizontalLayout_2 = QtWidgets.QHBoxLayout()
        self.horizontalLayout_2.setSpacing(6)
        self.horizontalLayout_2.setContentsMargins(0, 0, 0, 0)
        self.horizontalLayout_2.setObjectName("horizontalLayout_2")
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout_2.addItem(spacerItem1)
        self.pushButton_ok = QtWidgets.QPushButton(Form)
        self.pushButton_ok.setDefault(True)
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.horizontalLayout_2.addWidget(self.pushButton_ok)
        self.pushButton_cancel = QtWidgets.QPushButton(Form)
        self.pushButton_cancel.setDefault(True)
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.horizontalLayout_2.addWidget(self.pushButton_cancel)
        spacerItem2 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout_2.addItem(spacerItem2)
        self.verticalLayout.addLayout(self.horizontalLayout_2)
        self.gridLayout.addLayout(self.verticalLayout, 3, 0, 1, 1)

        self.retranslateUi(Form)
        QtCore.QMetaObject.connectSlotsByName(Form)
        Form.setTabOrder(self.lineEdit_name, self.lineEdit_description)
        Form.setTabOrder(self.lineEdit_description, self.pushButton_ok)
        Form.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, Form):
        _translate = QtCore.QCoreApplication.translate
        Form.setWindowTitle(_translate("Form", "Create Setup"))
        self.lineEdit_description.setToolTip(_translate("Form", "<html><head/><body><p>Setup description (Optional)</p></body></html>"))
        self.lineEdit_description.setPlaceholderText(_translate("Form", "Type Setup description here..."))
        self.lineEdit_name.setToolTip(_translate("Form", "<html><head/><body><p>Setup name (Required)</p></body></html>"))
        self.lineEdit_name.setPlaceholderText(_translate("Form", "Type Setup name here..."))
        self.label_setup_folder.setToolTip(_translate("Form", "<html><head/><body><p>Folder name that will be used for the given Setup name</p></body></html>"))
        self.label_setup_folder.setText(_translate("Form", "Setup folder:"))
        self.pushButton_ok.setText(_translate("Form", "Ok"))
        self.pushButton_cancel.setText(_translate("Form", "Cancel"))

