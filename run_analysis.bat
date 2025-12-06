@echo off
cd /d "C:\Users\Admin\V2Project\VJNT Class Managment"
python read_excel.py > duplicate_udise_report.txt 2>&1
if exist duplicate_udise_report.txt (
    type duplicate_udise_report.txt
) else (
    echo Failed to create report
)
pause
