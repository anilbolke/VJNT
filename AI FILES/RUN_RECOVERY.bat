@echo off
setlocal enabledelayedexpansion
cd /d "C:\Users\Admin\V2Project\VJNT Class Managment\AI FILES"
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -h localhost -u root -proot vjnt_class_management < RESTORE_PHASE1_2_3_ALL_UDISE.sql
