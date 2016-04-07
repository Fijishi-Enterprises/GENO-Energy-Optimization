@ECHO OFF
@TITLE Build Sceleton Titan GUI

PAUSE
ECHO --- Building Sceleton Titan GUI ---

ECHO main.py
CALL pyuic5 ../titan/ui/main.ui -o ../titan/ui/main.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\main.py.o > ..\titan\ui\main.py
del ..\titan\ui\main.py.o

ECHO setup_popup.py
CALL pyuic5 ../titan/ui/setup_popup.ui -o ../titan/ui/setup_popup.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\setup_popup.py.o > ..\titan\ui\setup_popup.py
del ..\titan\ui\setup_popup.py.o

ECHO --- Build completed ---
PAUSE
