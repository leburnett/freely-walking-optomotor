@echo off
REM Activate the Python environment if needed, then run the monitor_and_copy script, logging to one file from within the script

REM Path to Python interpreter
set PYTHON_EXE=C:\Users\labadmin\AppData\Local\Programs\Python\Python313\python.exe

REM Path to your Python script
set SCRIPT_PATH=C:\Users\labadmin\Documents\GitHub\freely-walking-optomotor\monitor_and_copy_folder\monitor_and_copy.py

REM Set working directory to script folder
cd /d "%~dp0"

REM Run the script and write output/errors to log
"%PYTHON_EXE%" "%SCRIPT_PATH%"
