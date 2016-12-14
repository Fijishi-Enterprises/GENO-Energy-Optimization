# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/settings.ui'
#
# Created by: PyQt5 UI code generator 5.6
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_SettingsForm(object):
    def setupUi(self, SettingsForm):
        SettingsForm.setObjectName("SettingsForm")
        SettingsForm.setWindowModality(QtCore.Qt.ApplicationModal)
        SettingsForm.resize(400, 300)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(SettingsForm.sizePolicy().hasHeightForWidth())
        SettingsForm.setSizePolicy(sizePolicy)
        SettingsForm.setMinimumSize(QtCore.QSize(400, 300))
        SettingsForm.setMaximumSize(QtCore.QSize(400, 300))
        SettingsForm.setMouseTracking(False)
        SettingsForm.setFocusPolicy(QtCore.Qt.StrongFocus)
        SettingsForm.setContextMenuPolicy(QtCore.Qt.NoContextMenu)
        SettingsForm.setAutoFillBackground(False)
        self.verticalLayout_2 = QtWidgets.QVBoxLayout(SettingsForm)
        self.verticalLayout_2.setObjectName("verticalLayout_2")
        self.groupBox_general = QtWidgets.QGroupBox(SettingsForm)
        self.groupBox_general.setObjectName("groupBox_general")
        self.verticalLayout = QtWidgets.QVBoxLayout(self.groupBox_general)
        self.verticalLayout.setObjectName("verticalLayout")
        self.checkBox_exit_dialog = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_exit_dialog.setTristate(False)
        self.checkBox_exit_dialog.setObjectName("checkBox_exit_dialog")
        self.verticalLayout.addWidget(self.checkBox_exit_dialog)
        self.checkBox_save_at_exit = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_save_at_exit.setTristate(True)
        self.checkBox_save_at_exit.setObjectName("checkBox_save_at_exit")
        self.verticalLayout.addWidget(self.checkBox_save_at_exit)
        self.checkBox_del_work_dirs = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_del_work_dirs.setTristate(True)
        self.checkBox_del_work_dirs.setObjectName("checkBox_del_work_dirs")
        self.verticalLayout.addWidget(self.checkBox_del_work_dirs)
        self.checkBox_debug = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_debug.setObjectName("checkBox_debug")
        self.verticalLayout.addWidget(self.checkBox_debug)
        spacerItem = QtWidgets.QSpacerItem(20, 40, QtWidgets.QSizePolicy.Minimum, QtWidgets.QSizePolicy.Expanding)
        self.verticalLayout.addItem(spacerItem)
        self.verticalLayout_2.addWidget(self.groupBox_general)
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem1)
        self.pushButton_ok = QtWidgets.QPushButton(SettingsForm)
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.horizontalLayout.addWidget(self.pushButton_ok)
        spacerItem2 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem2)
        self.pushButton_cancel = QtWidgets.QPushButton(SettingsForm)
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.horizontalLayout.addWidget(self.pushButton_cancel)
        spacerItem3 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem3)
        self.verticalLayout_2.addLayout(self.horizontalLayout)

        self.retranslateUi(SettingsForm)
        QtCore.QMetaObject.connectSlotsByName(SettingsForm)

    def retranslateUi(self, SettingsForm):
        _translate = QtCore.QCoreApplication.translate
        SettingsForm.setWindowTitle(_translate("SettingsForm", "Settings"))
        self.groupBox_general.setTitle(_translate("SettingsForm", "General"))
        self.checkBox_exit_dialog.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Not checked: Exit Sceleton without prompt</p><p>Checked: Show confirm exit prompt</p><p><br/></p></body></html>"))
        self.checkBox_exit_dialog.setText(_translate("SettingsForm", "Show confirm exit dialog at exit"))
        self.checkBox_save_at_exit.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Not checked: Does not save project &amp; does not show message box</p><p>Partially checked: Shows message box (default)</p><p>Checked: Saves project &amp; does not show message box</p><p><br/></p></body></html>"))
        self.checkBox_save_at_exit.setText(_translate("SettingsForm", "Save changes to project at exit"))
        self.checkBox_del_work_dirs.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Not checked: Does not delete work directories &amp; does not show message box</p><p>Partially checked: Shows message box (default)</p><p>Checked: Deletes work directories &amp; does not show message box</p><p><br/></p></body></html>"))
        self.checkBox_del_work_dirs.setText(_translate("SettingsForm", "Delete work directories at exit"))
        self.checkBox_debug.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Shows Sceleton debug messages in console. Error messages are shown anyway.</p></body></html>"))
        self.checkBox_debug.setText(_translate("SettingsForm", "Show Debug messages"))
        self.pushButton_ok.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Saves changes and closes the window</p></body></html>"))
        self.pushButton_ok.setText(_translate("SettingsForm", "Ok"))
        self.pushButton_cancel.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Closes the window without saving changes</p></body></html>"))
        self.pushButton_cancel.setText(_translate("SettingsForm", "Cancel"))

