@echo off
REM Run daily_processing.py and write output to dated log file

REM Set path to Python interpreter
set "PYTHON_EXE=C:\Users\burnettl\AppData\Local\Programs\Python\Python313\python.exe"

REM Set path to Python script
set "SCRIPT_PATH=C:\Users\burnettl\Documents\GitHub\freely-walking-optomotor\daily_processing\daily_processing.py"

REM Set log folder and ensure it exists
set "LOG_DIR=C:\Users\burnettl\Documents\oakey-cokey\processing_logs"
if not exist "%LOG_DIR%" (
    mkdir "%LOG_DIR%"
)

REM Get today's date (YYYY-MM-DD) for the log file name
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set "DATE=%%a"

REM Set full log file path
set "LOG_FILE=%LOG_DIR%\run_daily_processing_%DATE%.txt"

REM Run the Python script and redirect output
echo ---------- Script started at %DATE% %TIME% ---------- > "%LOG_FILE%"
"%PYTHON_EXE%" "%SCRIPT_PATH%" >> "%LOG_FILE%" 2>&1
echo ---------- Script ended at %TIME% ---------- >> "%LOG_FILE%"
