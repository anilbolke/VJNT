@echo off
rem Opens the change-review page in the browser.
rem   review-changes.bat                 uncommitted work vs last commit
rem   review-changes.bat --base main     this branch vs main (PR view)
rem   review-changes.bat --commit HEAD   one commit
rem   review-changes.bat --help          all options
cd /d "%~dp0.."
python "%~dp0review-changes.py" %*
if errorlevel 1 pause
