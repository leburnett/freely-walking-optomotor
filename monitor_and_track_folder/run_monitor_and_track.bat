@echo off
REM Run monitor_and_track.py and write output to dated log file

REM Set path to Python interpreter
set "PYTHON_EXE=C:\Users\burnettl\AppData\Local\Programs\Python\Python313\python.exe"

REM Set path to Python script
set "SCRIPT_PATH=C:\Users\burnettl\Documents\GitHub\freely-walking-optomotor\monitor_and_track_folder\monitor_and_track.py"

REM Set log directory
set "LOG_DIR=C:\Users\burnettl\Documents\oakey-cokey\monitor_and_track_logs"

REM Create log directory if it doesn't exist
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

REM Get today's date (YYYY-MM-DD)
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "DATE=%%a"

REM Set full path to log file
set "LOG_FILE=%LOG_DIR%\run_monitor_and_track_%DATE%.txt"

REM Run the Python script and redirect output
echo ---------- Script started at %DATE% %TIME% ---------- > "%LOG_FILE%"
"%PYTHON_EXE%" "%SCRIPT_PATH%" >> "%LOG_FILE%" 2>&1
echo ---------- Script ended at %TIME% ---------- >> "%LOG_FILE%"
