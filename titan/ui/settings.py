# -*- coding: utf-8 -*-

# Form implementation generated from reading ui file '../titan/ui/settings.ui'
#
# Created by: PyQt5 UI code generator 5.7.1
#
# WARNING! All changes made in this file will be lost!

from PyQt5 import QtCore, QtGui, QtWidgets

class Ui_SettingsForm(object):
    def setupUi(self, SettingsForm):
        SettingsForm.setObjectName("SettingsForm")
        SettingsForm.setWindowModality(QtCore.Qt.ApplicationModal)
        SettingsForm.resize(500, 300)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Fixed, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(SettingsForm.sizePolicy().hasHeightForWidth())
        SettingsForm.setSizePolicy(sizePolicy)
        SettingsForm.setMinimumSize(QtCore.QSize(500, 300))
        SettingsForm.setMaximumSize(QtCore.QSize(500, 300))
        SettingsForm.setMouseTracking(False)
        SettingsForm.setFocusPolicy(QtCore.Qt.StrongFocus)
        SettingsForm.setContextMenuPolicy(QtCore.Qt.NoContextMenu)
        SettingsForm.setAutoFillBackground(False)
        self.verticalLayout = QtWidgets.QVBoxLayout(SettingsForm)
        self.verticalLayout.setObjectName("verticalLayout")
        self.groupBox_general = QtWidgets.QGroupBox(SettingsForm)
        sizePolicy = QtWidgets.QSizePolicy(QtWidgets.QSizePolicy.Preferred, QtWidgets.QSizePolicy.Fixed)
        sizePolicy.setHorizontalStretch(0)
        sizePolicy.setVerticalStretch(0)
        sizePolicy.setHeightForWidth(self.groupBox_general.sizePolicy().hasHeightForWidth())
        self.groupBox_general.setSizePolicy(sizePolicy)
        self.groupBox_general.setMinimumSize(QtCore.QSize(0, 121))
        self.groupBox_general.setObjectName("groupBox_general")
        self.gridLayout_2 = QtWidgets.QGridLayout(self.groupBox_general)
        self.gridLayout_2.setObjectName("gridLayout_2")
        self.checkBox_del_work_dirs = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_del_work_dirs.setTristate(True)
        self.checkBox_del_work_dirs.setObjectName("checkBox_del_work_dirs")
        self.gridLayout_2.addWidget(self.checkBox_del_work_dirs, 2, 0, 1, 1)
        self.checkBox_exit_dialog = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_exit_dialog.setTristate(False)
        self.checkBox_exit_dialog.setObjectName("checkBox_exit_dialog")
        self.gridLayout_2.addWidget(self.checkBox_exit_dialog, 0, 0, 1, 1)
        self.checkBox_save_at_exit = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_save_at_exit.setTristate(True)
        self.checkBox_save_at_exit.setObjectName("checkBox_save_at_exit")
        self.gridLayout_2.addWidget(self.checkBox_save_at_exit, 1, 0, 1, 1)
        self.checkBox_clear_flags = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_clear_flags.setObjectName("checkBox_clear_flags")
        self.gridLayout_2.addWidget(self.checkBox_clear_flags, 0, 1, 1, 1)
        self.checkBox_debug = QtWidgets.QCheckBox(self.groupBox_general)
        self.checkBox_debug.setObjectName("checkBox_debug")
        self.gridLayout_2.addWidget(self.checkBox_debug, 3, 0, 1, 1)
        self.verticalLayout.addWidget(self.groupBox_general)
        self.groupBox_gams = QtWidgets.QGroupBox(SettingsForm)
        self.groupBox_gams.setMinimumSize(QtCore.QSize(0, 56))
        self.groupBox_gams.setFlat(False)
        self.groupBox_gams.setCheckable(False)
        self.groupBox_gams.setObjectName("groupBox_gams")
        self.gridLayout = QtWidgets.QGridLayout(self.groupBox_gams)
        self.gridLayout.setObjectName("gridLayout")
        self.checkBox_logoption = QtWidgets.QCheckBox(self.groupBox_gams)
        self.checkBox_logoption.setObjectName("checkBox_logoption")
        self.gridLayout.addWidget(self.checkBox_logoption, 2, 0, 1, 1)
        self.lineEdit_gamside_path = QtWidgets.QLineEdit(self.groupBox_gams)
        self.lineEdit_gamside_path.setMinimumSize(QtCore.QSize(0, 20))
        self.lineEdit_gamside_path.setCursor(QtGui.QCursor(QtCore.Qt.ArrowCursor))
        self.lineEdit_gamside_path.setFocusPolicy(QtCore.Qt.NoFocus)
        self.lineEdit_gamside_path.setAutoFillBackground(False)
        self.lineEdit_gamside_path.setFrame(False)
        self.lineEdit_gamside_path.setReadOnly(False)
        self.lineEdit_gamside_path.setClearButtonEnabled(True)
        self.lineEdit_gamside_path.setObjectName("lineEdit_gamside_path")
        self.gridLayout.addWidget(self.lineEdit_gamside_path, 3, 0, 1, 1)
        self.pushButton_browse_gamside = QtWidgets.QPushButton(self.groupBox_gams)
        self.pushButton_browse_gamside.setMinimumSize(QtCore.QSize(0, 23))
        self.pushButton_browse_gamside.setObjectName("pushButton_browse_gamside")
        self.gridLayout.addWidget(self.pushButton_browse_gamside, 3, 1, 1, 1)
        self.label = QtWidgets.QLabel(self.groupBox_gams)
        self.label.setObjectName("label")
        self.gridLayout.addWidget(self.label, 0, 0, 1, 1)
        self.spinBox_cerr = QtWidgets.QSpinBox(self.groupBox_gams)
        self.spinBox_cerr.setMaximumSize(QtCore.QSize(40, 16777215))
        self.spinBox_cerr.setFrame(True)
        self.spinBox_cerr.setProperty("showGroupSeparator", False)
        self.spinBox_cerr.setProperty("value", 1)
        self.spinBox_cerr.setObjectName("spinBox_cerr")
        self.gridLayout.addWidget(self.spinBox_cerr, 0, 1, 1, 1)
        self.verticalLayout.addWidget(self.groupBox_gams)
        self.horizontalLayout = QtWidgets.QHBoxLayout()
        self.horizontalLayout.setObjectName("horizontalLayout")
        spacerItem = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem)
        self.pushButton_ok = QtWidgets.QPushButton(SettingsForm)
        self.pushButton_ok.setObjectName("pushButton_ok")
        self.horizontalLayout.addWidget(self.pushButton_ok)
        spacerItem1 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem1)
        self.pushButton_cancel = QtWidgets.QPushButton(SettingsForm)
        self.pushButton_cancel.setObjectName("pushButton_cancel")
        self.horizontalLayout.addWidget(self.pushButton_cancel)
        spacerItem2 = QtWidgets.QSpacerItem(40, 20, QtWidgets.QSizePolicy.Expanding, QtWidgets.QSizePolicy.Minimum)
        self.horizontalLayout.addItem(spacerItem2)
        self.verticalLayout.addLayout(self.horizontalLayout)

        self.retranslateUi(SettingsForm)
        QtCore.QMetaObject.connectSlotsByName(SettingsForm)
        SettingsForm.setTabOrder(self.checkBox_exit_dialog, self.checkBox_save_at_exit)
        SettingsForm.setTabOrder(self.checkBox_save_at_exit, self.checkBox_del_work_dirs)
        SettingsForm.setTabOrder(self.checkBox_del_work_dirs, self.checkBox_debug)
        SettingsForm.setTabOrder(self.checkBox_debug, self.spinBox_cerr)
        SettingsForm.setTabOrder(self.spinBox_cerr, self.checkBox_logoption)
        SettingsForm.setTabOrder(self.checkBox_logoption, self.pushButton_browse_gamside)
        SettingsForm.setTabOrder(self.pushButton_browse_gamside, self.pushButton_ok)
        SettingsForm.setTabOrder(self.pushButton_ok, self.pushButton_cancel)

    def retranslateUi(self, SettingsForm):
        _translate = QtCore.QCoreApplication.translate
        SettingsForm.setWindowTitle(_translate("SettingsForm", "Settings"))
        self.groupBox_general.setTitle(_translate("SettingsForm", "General"))
        self.checkBox_del_work_dirs.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Unchecked: Does not delete work directories &amp; does not show message box</p><p>Partially checked: Shows message box (default)</p><p>Checked: Deletes work directories &amp; does not show message box</p><p><br/></p></body></html>"))
        self.checkBox_del_work_dirs.setText(_translate("SettingsForm", "Delete work directories at exit"))
        self.checkBox_exit_dialog.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Unchecked: Exit Sceleton without prompt</p><p>Checked: Show confirm exit prompt</p><p><br/></p></body></html>"))
        self.checkBox_exit_dialog.setText(_translate("SettingsForm", "Show confirm exit dialog at exit"))
        self.checkBox_save_at_exit.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Unchecked: Does not save project &amp; does not show message box</p><p>Partially checked: Shows message box (default)</p><p>Checked: Saves project &amp; does not show message box</p><p><br/></p></body></html>"))
        self.checkBox_save_at_exit.setText(_translate("SettingsForm", "Save changes to project at exit"))
        self.checkBox_clear_flags.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Clear Setup <span style=\" font-weight:600;\">ready</span> and <span style=\" font-weight:600;\">failed</span> flags at startup and when a project is loaded</p></body></html>"))
        self.checkBox_clear_flags.setText(_translate("SettingsForm", "Clear setup flags at startup"))
        self.checkBox_debug.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Shows Sceleton debug messages in console. Error messages are always shown.</p></body></html>"))
        self.checkBox_debug.setText(_translate("SettingsForm", "Show Debug messages"))
        self.groupBox_gams.setTitle(_translate("SettingsForm", "GAMS"))
        self.checkBox_logoption.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Controls the GAMS <span style=\" font-weight:600;\">logoption</span> keyword value.</p><p>If unchecked (logoption=3). LOG output is written to standard output. </p><p>If checked (logoption=4). LOG output is written to standard output and to &lt;TOOLNAME&gt;.log file.</p></body></html>"))
        self.checkBox_logoption.setText(_translate("SettingsForm", "Write output to log file (logoption)"))
        self.lineEdit_gamside_path.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Enter directory where gams.exe and gamside.exe reside.</p><p>Note: Leave this empty to use GAMS defined in the system PATH variable.</p></body></html>"))
        self.lineEdit_gamside_path.setPlaceholderText(_translate("SettingsForm", "GAMS directory"))
        self.pushButton_browse_gamside.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Select GAMS directory</p></body></html>"))
        self.pushButton_browse_gamside.setText(_translate("SettingsForm", "Browse"))
        self.label.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Controls the compile time error limit (<span style=\" font-weight:600;\">cerr</span>). The compilation will be stopped after n errors have occurred.</p><p>0: No error limit (default)</p><p>n: Stop after n errors</p></body></html>"))
        self.label.setText(_translate("SettingsForm", "Compile error limit (cerr)"))
        self.spinBox_cerr.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Controls the compile time error limit (<span style=\" font-weight:600;\">cerr</span>). The compilation will be stopped after n errors have occurred.</p><p>0: No error limit (default)</p><p>n: Stop after n errors</p></body></html>"))
        self.pushButton_ok.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Saves changes and closes the window</p></body></html>"))
        self.pushButton_ok.setText(_translate("SettingsForm", "Ok"))
        self.pushButton_cancel.setToolTip(_translate("SettingsForm", "<html><head/><body><p>Closes the window without saving changes</p></body></html>"))
        self.pushButton_cancel.setText(_translate("SettingsForm", "Cancel"))

