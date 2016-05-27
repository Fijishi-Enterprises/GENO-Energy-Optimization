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

ECHO --- Build completed ---
PAUSE
