@echo off
REM Activate the Python environment if needed, then run the script with daily log rotation

REM Path to Python interpreter
set PYTHON_EXE=C:\Users\burnettl\AppData\Local\Programs\Python\Python313\python.exe

REM Path to your Python script
set SCRIPT_PATH=C:\Users\burnettl\Documents\GitHub\freely-walking-optomotor\daily_processing\daily_processing.py

REM Set today's date for filename (YYYY-MM-DD format)
for /f %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd"') do set DATE=%%a

REM Path to daily log file
set LOG_FILE="C:\Users\burnettl\Documents\oakey-cokey\logs\run_daily_processing_%DATE%.txt"

REM Ensure log directory exists
if not exist "C:\Users\burnettl\Documents\oakey-cokey\logs" (
    mkdir "C:\Users\burnettl\Documents\oakey-cokey\logs"
)

REM Run the script and write output/errors to log
echo ---------- Script started at %DATE% %TIME% ---------- > %LOG_FILE%
%PYTHON_EXE% %SCRIPT_PATH% >> %LOG_FILE% 2>&1
echo ---------- Script ended at %TIME% ---------- >> %LOG_FILE%
