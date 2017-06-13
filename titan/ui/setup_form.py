# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/setup_form.ui'
#
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_Form(object):
    def setupUi(self, Form):
        Form.setObjectName("Form")
        Form.setWindowModality(QtCore.Qt.ApplicationModal)
        Form.resize(320, 278)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(Form.sizePolicy().hasHeightForWidth())
        Form.setSizePolicy(sizePolicy)
        self.verticalLayout_2 = QtWidgets.QVBoxLayout(Form)
        self.verticalLayout_2.setSpacing(0)
        self.verticalLayout_2.setContentsMargins(0, 0, 0, 0)
        self.verticalLayout_2.setObjectName("verticalLayout_2")
        self.verticalLayout = QtWidgets.QVBoxLayout()
        self.verticalLayout.setSpacing(6)
        self.verticalLayout.setContentsMargins(9, 9, 9, 0)
        self.verticalLayout.setObjectName("verticalLayout")
        self.lineEdit_name = QtWidgets.QLineEdit(Form)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEdit_name.sizePolicy().hasHeightForWidth())
        self.lineEdit_name.setSizePolicy(sizePolicy)
        self.lineEdit_name.setMinimumSize(QtCore.QSize(220, 20))
        self.lineEdit_name.setMaximumSize(QtCore.QSize(5000, 20))
        self.lineEdit_name.setClearButtonEnabled(True)
        self.lineEdit_name.setObjectName("lineEdit_name")
        self.verticalLayout.addWidget(self.lineEdit_name)
        self.lineEdit_description = QtWidgets.QLineEdit(Form)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.lineEdit_description.sizePolicy().hasHeightForWidth())
        self.lineEdit_description.setSizePolicy(sizePolicy)
        self.lineEdit_description.setMinimumSize(QtCore.QSize(220, 20))
        self.lineEdit_description.setMaximumSize(QtCore.QSize(5000, 20))
        self.lineEdit_description.setClearButtonEnabled(True)
        self.lineEdit_description.setObjectName("lineEdit_description")
        self.verticalLayout.addWidget(self.lineEdit_description)
        spacerItem = QtWidgets.QSpacerItem(20, 41, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.verticalLayout.addItem(spacerItem)
        self.comboBox_tool = QtWidgets.QComboBox(Form)
        self.comboBox_tool.setObjectName("comboBox_tool")
        self.verticalLayout.addWidget(self.comboBox_tool)
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        self.label = QtWidgets.QLabel(Form)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Preferred, QtWidgets.QSizePolicy.Preferred)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.label.sizePolicy().hasHeightForWidth())
        self.label.setSizePolicy(sizePolicy)
        self.label.setMaximumSize(QtCore.QSize(16777215, 20))
        self.label.setBaseSize(QtCore.QSize(0, 0))
        self.label.setFrameShape(QtWidgets.QFrame.Panel)
        self.label.setFrameShadow(QtWidgets.QFrame.Raised)
        self.label.setLineWidth(1)
        self.label.setObjectName("label")
        self.horizontalLayout.addWidget(self.label)
        self.lineEdit_tool_args = QtWidgets.QLineEdit(Form)
        self.lineEdit_tool_args.setEnabled(False)
        self.lineEdit_tool_args.setReadOnly(True)
        self.lineEdit_tool_args.setObjectName("lineEdit_tool_args")
        self.horizontalLayout.addWidget(self.lineEdit_tool_args)
        self.verticalLayout.addLayout(self.horizontalLayout)
        self.lineEdit_cmdline_params = QtWidgets.QLineEdit(Form)
        self.lineEdit_cmdline_params.setClearButtonEnabled(True)
        self.lineEdit_cmdline_params.setObjectName("lineEdit_cmdline_params")
        self.verticalLayout.addWidget(self.lineEdit_cmdline_params)
        self.label_setup_folder = QtWidgets.QLabel(Form)
        self.label_setup_folder.setEnabled(False)
        self.label_setup_folder.setContextMenuPolicy(QtCore.Qt.NoContextMenu)
        self.label_setup_folder.setIndent(-1)
        self.label_setup_folder.setObjectName("label_setup_folder")
        self.verticalLayout.addWidget(self.label_setup_folder)
        self.horizontalLayout_2 = QtWidgets.QHBoxLayout()
        self.horizontalLayout_2.setSpacing(0)
        self.horizontalLayout_2.setContentsMargins(0, 6, 0, 6)
        self.horizontalLayout_2.setObjectName("horizontalLayout_2")
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout_2.addItem(spacerItem1)
        self.pushButton_ok = QtWidgets.QPushButton(Form)
        self.pushButton_ok.setDefault(True)
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.horizontalLayout_2.addWidget(self.pushButton_ok)
        spacerItem2 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout_2.addItem(spacerItem2)
        self.pushButton_cancel = QtWidgets.QPushButton(Form)
        self.pushButton_cancel.setDefault(True)
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.horizontalLayout_2.addWidget(self.pushButton_cancel)
        spacerItem3 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout_2.addItem(spacerItem3)
        self.verticalLayout.addLayout(self.horizontalLayout_2)
        self.verticalLayout_2.addLayout(self.verticalLayout)
        self.horizontalLayout_statusbar_placeholder = QtWidgets.QHBoxLayout()
        self.horizontalLayout_statusbar_placeholder.setContentsMargins(-1, -1, -1, 0)
        self.horizontalLayout_statusbar_placeholder.setObjectName("horizontalLayout_statusbar_placeholder")
        self.widget_invisible_dummy = QtWidgets.QWidget(Form)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.widget_invisible_dummy.sizePolicy().hasHeightForWidth())
        self.widget_invisible_dummy.setSizePolicy(sizePolicy)
        self.widget_invisible_dummy.setMinimumSize(QtCore.QSize(0, 20))
        self.widget_invisible_dummy.setMaximumSize(QtCore.QSize(0, 20))
        self.widget_invisible_dummy.setObjectName("widget_invisible_dummy")
        self.horizontalLayout_statusbar_placeholder.addWidget(self.widget_invisible_dummy)
        self.verticalLayout_2.addLayout(self.horizontalLayout_statusbar_placeholder)

        self.retranslateUi(Form)
        QtCore.QMetaObject.connectSlotsByName(Form)
        Form.setTabOrder(self.lineEdit_name, self.lineEdit_description)
        Form.setTabOrder(self.lineEdit_description, self.comboBox_tool)
        Form.setTabOrder(self.comboBox_tool, self.lineEdit_tool_args)
        Form.setTabOrder(self.lineEdit_tool_args, self.lineEdit_cmdline_params)
        Form.setTabOrder(self.lineEdit_cmdline_params, self.pushButton_ok)
        Form.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, Form):
        _translate = QtCore.QCoreApplication.translate
        Form.setWindowTitle(_translate("Form", "Create Setup"))
        self.lineEdit_name.setToolTip(_translate("Form", "<html><head/><body><p>Setup name (Required)</p></body></html>"))
        self.lineEdit_name.setPlaceholderText(_translate("Form", "Type Setup name here..."))
        self.lineEdit_description.setToolTip(_translate("Form", "<html><head/><body><p>Setup description (Optional)</p></body></html>"))
        self.lineEdit_description.setPlaceholderText(_translate("Form", "Type Setup description here..."))
        self.comboBox_tool.setToolTip(_translate("Form", "<html><head/><body><p>Select tool</p></body></html>"))
        self.label.setToolTip(_translate("Form", "<html><head/><body><p>You can change Tool command line arguments by changing the Tool definition file</p></body></html>"))
        self.label.setText(_translate("Form", "Tool args"))
        self.lineEdit_tool_args.setToolTip(_translate("Form", "<html><head/><body><p>You can change Tool command line arguments by changing the Tool definition file</p></body></html>"))
        self.lineEdit_cmdline_params.setPlaceholderText(_translate("Form", "Type additional setup command line arguments here..."))
        self.label_setup_folder.setToolTip(_translate("Form", "<html><head/><body><p>Folder name that will be used for the given Setup name</p></body></html>"))
        self.label_setup_folder.setText(_translate("Form", "Setup folder:"))
        self.pushButton_ok.setText(_translate("Form", "Ok"))
        self.pushButton_cancel.setText(_translate("Form", "Cancel"))

