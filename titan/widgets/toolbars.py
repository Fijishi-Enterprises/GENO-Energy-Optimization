"""
Functions to make and handle QToolBars.

:author: Pekka Savolainen <pekka.t.savolainen@vtt.fi>
:date:   22.6.2017
"""

from PyQt5.Qt import QIcon, QPixmap, QAction, QSize
from PyQt5.QtWidgets import QToolBar, QLabel, QComboBox
from PyQt5.QtCore import Qt
from config import ICON_TOOLBAR_STYLESHEET


# noinspection PyUnresolvedReferences
def make_view_toolbar(ui):
    """Initialize resize views toolbar. Action signals are connected in TitanUI.

    Args:
        ui (TitanUI): Application QMainWindow
    """
    tb = QToolBar("Resize Views Toolbar", ui)
    max_icon = QIcon()
    max_icon.addPixmap(QPixmap(":/toolButtons/down_arrow.png"), QIcon.Normal, QIcon.On)
    min_icon = QIcon()
    min_icon.addPixmap(QPixmap(":/toolButtons/up_arrow.png"), QIcon.Normal, QIcon.On)
    split_icon = QIcon()
    split_icon.addPixmap(QPixmap(":/toolButtons/restore_original.png"), QIcon.Normal, QIcon.On)
    # Make actions
    maximize_action = QAction(max_icon, "", ui)
    minimize_action = QAction(min_icon, "", ui)
    split_action = QAction(split_icon, "", ui)
    # Set objectNames to determine sender in the connected slot
    maximize_action.setObjectName("maximize_action")
    minimize_action.setObjectName("minimize_action")
    split_action.setObjectName("split_action")
    # Set tooltips
    maximize_action.setToolTip("Maximize Command Output View")
    minimize_action.setToolTip("Maximize Tool Output View")
    split_action.setToolTip("Split Command and Tool Output Views Evenly")
    # Add actions to toolbar
    tb.addAction(maximize_action)
    tb.addAction(minimize_action)
    tb.addAction(split_action)
    tb.setToolButtonStyle(Qt.ToolButtonIconOnly)
    tb.setIconSize(QSize(20, 20))
    # Connect signals
    maximize_action.triggered.connect(ui.handle_view_toolbar_actions)
    minimize_action.triggered.connect(ui.handle_view_toolbar_actions)
    split_action.triggered.connect(ui.handle_view_toolbar_actions)
    # Set stylesheet
    tb.setStyleSheet(ICON_TOOLBAR_STYLESHEET)
    tb.setObjectName("viewToolbar")
    return tb


# noinspection PyUnresolvedReferences
def make_execute_toolbar(ui):
    """Initialize Execute toolbar.

    Args:
        ui (TitanUI): Application QMainWindow
    """
    toolb = QToolBar("Execute Toolbar", ui)
    run_selected_icon = QIcon()
    run_selected_icon.addPixmap(QPixmap(":/toolButtons/run_selected.png"), QIcon.Normal, QIcon.On)
    run_project_icon = QIcon()
    run_project_icon.addPixmap(QPixmap(":/toolButtons/run_project.png"), QIcon.Normal, QIcon.On)
    stop_icon = QIcon()
    stop_icon.addPixmap(QPixmap(":/toolButtons/stop.png"), QIcon.Normal, QIcon.On)
    label = QLabel("Execute")
    combobox = QComboBox()  # Algorithms
    combobox.addItem("Breadth-first")
    combobox.addItem("Depth-first")
    exec_selected = QAction(run_selected_icon, "Selected", ui)
    exec_project = QAction(run_project_icon, "Project", ui)
    cancel = QAction(stop_icon, "Cancel", ui)
    cancel.setEnabled(False)
    # Set tooltips for toolbar actions
    combobox.setToolTip("Select Algorithm")
    exec_selected.setToolTip("Execute selected Setup (F6)")
    exec_project.setToolTip("Execute project (F7)")
    cancel.setToolTip("Cancel execution (Ctrl+C)")
    # Add actions to toolbar
    toolb.addWidget(label)
    toolb.addWidget(combobox)
    toolb.addAction(exec_selected)
    toolb.addAction(exec_project)
    toolb.addAction(cancel)
    toolb.setToolButtonStyle(Qt.ToolButtonIconOnly)
    toolb.setIconSize(QSize(20, 20))
    # Connect signals
    exec_selected.triggered.connect(ui.execute_selected)
    exec_project.triggered.connect(ui.execute_project)
    cancel.triggered.connect(ui.terminate_execution)
    # Set stylesheet
    toolb.setStyleSheet(ICON_TOOLBAR_STYLESHEET)
    toolb.setObjectName("executeToolbar")
    return toolb


# noinspection PyUnresolvedReferences
def make_tool_toolbar(ui):
    """Initialize Tool toolbar.

    Args:
        ui (TitanUI): Application QMainWindow
    """
    toolb = QToolBar("Tool Toolbar", ui)
    add_tool_icon = QIcon()
    add_tool_icon.addPixmap(QPixmap(":/toolButtons/add_tool.png"), QIcon.Normal, QIcon.On)
    refresh_tools_icon = QIcon()
    refresh_tools_icon.addPixmap(QPixmap(":/toolButtons/refresh_tools.png"), QIcon.Normal, QIcon.On)
    remove_tool_icon = QIcon()
    remove_tool_icon.addPixmap(QPixmap(":/toolButtons/remove_tool.png"), QIcon.Normal, QIcon.On)
    label = QLabel("Tools")
    add_tool = QAction(add_tool_icon, "Add", ui)
    refresh_tools = QAction(refresh_tools_icon, "Refresh", ui)
    remove_tool = QAction(remove_tool_icon, "Remove", ui)
    # Set tooltips for toolbar actions
    add_tool.setToolTip("Add Tool (F8)")
    refresh_tools.setToolTip("Reload all Tools in the project (F9)")
    remove_tool.setToolTip("Remove selected Tool from project (F10)")
    # Add actions to toolbar
    toolb.addWidget(label)
    toolb.addAction(add_tool)
    toolb.addAction(refresh_tools)
    toolb.addAction(remove_tool)
    toolb.setToolButtonStyle(Qt.ToolButtonIconOnly)
    toolb.setIconSize(QSize(20, 20))
    # Connect signals
    add_tool.triggered.connect(ui.add_tool)
    refresh_tools.triggered.connect(ui.refresh_tools)
    remove_tool.triggered.connect(ui.remove_tool)
    # Set stylesheet
    toolb.setStyleSheet(ICON_TOOLBAR_STYLESHEET)
    toolb.setObjectName("toolToolbar")
    return toolb


# noinspection PyUnresolvedReferences
def make_delete_toolbar(ui):
    """Initialize Delete toolbar.

    Args:
        ui (TitanUI): Application QMainWindow
    """
    toolb = QToolBar("Delete Toolbar", ui)
    delete_all_icon = QIcon()
    delete_all_icon.addPixmap(QPixmap(":/toolButtons/delete_all.png"), QIcon.Normal, QIcon.On)
    delete_single_icon = QIcon()
    delete_single_icon.addPixmap(QPixmap(":/toolButtons/delete_single.png"), QIcon.Normal, QIcon.On)
    label = QLabel("Delete")
    delete_single = QAction(delete_single_icon, "Single", ui)
    delete_all = QAction(delete_all_icon, "All", ui)
    # Set shortcut for delete_single QAction
    delete_single.setShortcut("Del")
    # Set tooltips for toolbar actions
    delete_single.setToolTip("Delete selected Setup(s)")
    delete_all.setToolTip("Delete all Setups in the project")
    # Add actions to toolbar
    toolb.addWidget(label)
    toolb.addAction(delete_single)
    toolb.addAction(delete_all)
    toolb.setToolButtonStyle(Qt.ToolButtonIconOnly)
    toolb.setIconSize(QSize(20, 20))
    # Connect signals
    delete_single.triggered.connect(ui.delete_selected_setup)
    delete_all.triggered.connect(ui.delete_all)
    # Set stylesheet
    toolb.setStyleSheet(ICON_TOOLBAR_STYLESHEET)
    toolb.setObjectName("deleteToolbar")
    return toolb


# noinspection PyUnresolvedReferences
def make_data_toolbar(ui):
    """Initialize Data toolbar.

    Args:
        ui (TitanUI): Application QMainWindow
    """
    toolb = QToolBar("Data Toolbar", ui)
    import_icon = QIcon()
    import_icon.addPixmap(QPixmap(":/toolButtons/import_data.png"), QIcon.Normal, QIcon.On)
    verify_icon = QIcon()
    verify_icon.addPixmap(QPixmap(":/toolButtons/verify_data.png"), QIcon.Normal, QIcon.On)
    explore_icon = QIcon()
    explore_icon.addPixmap(QPixmap(":/toolButtons/explore_data.png"), QIcon.Normal, QIcon.On)
    results_icon = QIcon()
    results_icon.addPixmap(QPixmap(":/toolButtons/results_data.png"), QIcon.Normal, QIcon.On)
    label = QLabel("Data")
    import_data = QAction(import_icon, "Import", ui)
    verify_data = QAction(verify_icon, "Verify", ui)
    explore_data = QAction(explore_icon, "Explore", ui)
    results = QAction(results_icon, "Results", ui)
    # Set tooltips for toolbar actions
    import_data.setToolTip("Import data from MS Excel files (F2)")
    verify_data.setToolTip("Open input verifier window (F3)")
    explore_data.setToolTip("Open input explorer window (F4)")
    results.setToolTip("Open result explorer window (F5)")
    # Add actions to toolbar
    toolb.addWidget(label)
    toolb.addAction(import_data)
    toolb.addAction(verify_data)
    toolb.addAction(explore_data)
    toolb.addAction(results)
    toolb.setToolButtonStyle(Qt.ToolButtonIconOnly)
    toolb.setIconSize(QSize(20, 20))
    # Connect signals
    import_data.triggered.connect(ui.import_data)
    verify_data.triggered.connect(ui.open_verifier_form)
    explore_data.triggered.connect(ui.show_explorer_form)
    results.triggered.connect(ui.show_results_form)
    # Set stylesheet
    toolb.setStyleSheet(ICON_TOOLBAR_STYLESHEET)
    toolb.setObjectName("dataToolbar")
    return toolb


# noinspection PyUnresolvedReferences
def make_clear_toolbar(ui):
    """Initialize Clear Flags toolbar.

    Args:
        ui (TitanUI): Application QMainWindow
    """
    toolb = QToolBar("Clear Flags Toolbar", ui)
    label = QLabel("Flags")
    failed_icon = QIcon()
    failed_icon.addPixmap(QPixmap(":/toolButtons/clear_failed_flags.png"), QIcon.Normal, QIcon.On)
    ready_icon = QIcon()
    ready_icon.addPixmap(QPixmap(":/toolButtons/clear_ready_flags.png"), QIcon.Normal, QIcon.On)
    all_icon = QIcon()
    all_icon.addPixmap(QPixmap(":/toolButtons/clear_flags.png"), QIcon.Normal, QIcon.On)
    clear_failed = QAction(failed_icon, "Failed", ui)
    clear_ready = QAction(ready_icon, "Ready", ui)
    clear_all = QAction(all_icon, "All", ui)
    # Set tooltips for toolbar actions
    clear_failed.setToolTip("Clear Failed Flags")
    clear_ready.setToolTip("Clear Ready Flags")
    clear_all.setToolTip("Clear All Flags")
    # Add actions to toolbar
    toolb.addWidget(label)
    toolb.addAction(clear_failed)
    toolb.addAction(clear_ready)
    toolb.addAction(clear_all)
    toolb.setToolButtonStyle(Qt.ToolButtonIconOnly)
    toolb.setIconSize(QSize(20, 20))
    # Connect signals
    clear_failed.triggered.connect(ui.clear_failed_flags)
    clear_ready.triggered.connect(ui.clear_ready_flags)
    clear_all.triggered.connect(ui.clear_flags)
    # Set stylesheet
    toolb.setStyleSheet(ICON_TOOLBAR_STYLESHEET)
    toolb.setObjectName("clearToolbar")
    return toolb
