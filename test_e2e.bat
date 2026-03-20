@echo off
REM Generate timestamp in DDMMYYYY HHMMSS format
for /f "tokens=1-3 delims=/" %%a in ('date /t') do (
    set MM=%%a
    set DD=%%b
    set YYYY=%%c
)
for /f "tokens=1-3 delims=:." %%a in ('echo %time: =0%') do (
    set HH=%%a
    set MIN=%%b
    set SS=%%c
)

set FOLDER_NAME=Report %DD%%MM%%YYYY% %HH%%MIN%%SS%
set REPORT_DIR=%~dp0Reports\%FOLDER_NAME%

echo Creating report folder: %REPORT_DIR%
mkdir "%REPORT_DIR%"

robot --outputdir "%REPORT_DIR%" --variable REPORT_DIR:"%REPORT_DIR%" "%~dp0RobotFramework\tests\test_e2e.robot"

echo.
echo Report saved to: %REPORT_DIR%
echo Custom report: %REPORT_DIR%\ag_autoframe_report.html
echo.
echo Opening report...
start "" "%REPORT_DIR%\ag_autoframe_report.html"
pause
