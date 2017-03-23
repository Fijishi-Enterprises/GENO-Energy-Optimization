@ECHO OFF
@TITLE Build Sceleton Titan GUI

PAUSE
ECHO --- Building Sceleton Titan GUI ---

ECHO main.py
CALL pyuic5 ../titan/ui/main.ui -o ../titan/ui/main.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\main.py.o > ..\titan\ui\main.py
del ..\titan\ui\main.py.o

ECHO setup_form.py
CALL pyuic5 ../titan/ui/setup_form.ui -o ../titan/ui/setup_form.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\setup_form.py.o > ..\titan\ui\setup_form.py
del ..\titan\ui\setup_form.py.o

ECHO project_form.py
CALL pyuic5 ../titan/ui/project_form.ui -o ../titan/ui/project_form.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\project_form.py.o > ..\titan\ui\project_form.py
del ..\titan\ui\project_form.py.o

ECHO edit_tool_form.py
CALL pyuic5 ../titan/ui/edit_tool_form.ui -o ../titan/ui/edit_tool_form.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\edit_tool_form.py.o > ..\titan\ui\edit_tool_form.py
del ..\titan\ui\edit_tool_form.py.o

ECHO settings.py
CALL pyuic5 ../titan/ui/settings.ui -o ../titan/ui/settings.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\settings.py.o > ..\titan\ui\settings.py
del ..\titan\ui\settings.py.o

ECHO input_verifier_form.py
CALL pyuic5 ../titan/ui/input_verifier_form.ui -o ../titan/ui/input_verifier_form.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\input_verifier_form.py.o > ..\titan\ui\input_verifier_form.py
del ..\titan\ui\input_verifier_form.py.o

ECHO input_explorer_form.py
CALL pyuic5 ../titan/ui/input_explorer_form.ui -o ../titan/ui/input_explorer_form.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\input_explorer_form.py.o > ..\titan\ui\input_explorer_form.py
del ..\titan\ui\input_explorer_form.py.o

ECHO output_explorer_form.py
CALL pyuic5 ../titan/ui/output_explorer_form.ui -o ../titan/ui/output_explorer_form.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\output_explorer_form.py.o > ..\titan\ui\output_explorer_form.py
del ..\titan\ui\output_explorer_form.py.o

ECHO about.py
CALL pyuic5 ../titan/ui/about.ui -o ../titan/ui/about.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\about.py.o > ..\titan\ui\about.py
del ..\titan\ui\about.py.o

ECHO resources_rc.py
CALL pyrcc5 -o ../titan/resources_rc.py ../titan/ui/resources/resources.qrc

ECHO --- Build completed ---
PAUSE
