@ECHO OFF
@TITLE Build Sceleton Titan GUI

PAUSE
ECHO --- Building Sceleton Titan GUI ---

ECHO main.py
CALL pyuic5 ../titan/ui/main.ui -o ../titan/ui/main.py.o
findstr /V /C:"# Created:" /C:"#      by:" ..\titan\ui\main.py.o > ..\titan\ui\main.py
del ..\titan\ui\main.py.o

ECHO --- Build completed ---
PAUSE
