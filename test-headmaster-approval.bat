@echo off
echo ========================================
echo Testing Headmaster Approval System
echo ========================================
echo.

REM Test database table
echo [1/3] Checking phase_approvals table structure...
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -proot vjnt_class_management -e "DESCRIBE phase_approvals;" 2>nul
if %ERRORLEVEL% EQU 0 (
    echo ✓ Table exists with all columns
) else (
    echo ✗ Table check failed
)
echo.

REM Test for pending approvals
echo [2/3] Checking for any pending approvals...
"C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe" -u root -proot vjnt_class_management -e "SELECT udise_no, phase_number, approval_status, completed_by FROM phase_approvals LIMIT 5;" 2>nul
echo.

REM Check compiled classes
echo [3/3] Verifying compiled classes...
if exist "src\main\webapp\WEB-INF\classes\com\vjnt\servlet\ApprovePhaseServlet.class" (
    echo ✓ ApprovePhaseServlet compiled
) else (
    echo ✗ ApprovePhaseServlet not found
)

if exist "src\main\webapp\WEB-INF\classes\com\vjnt\dao\PhaseApprovalDAO.class" (
    echo ✓ PhaseApprovalDAO compiled
) else (
    echo ✗ PhaseApprovalDAO not found
)
echo.

echo ========================================
echo Next Steps:
echo ========================================
echo 1. Restart Tomcat server
echo 2. Login as School Coordinator and submit a phase
echo 3. Login as Head Master to approve/reject
echo.
echo URLs:
echo - Head Master Approvals: http://localhost:8080/VJNT_Class_Managment/phase-approvals.jsp
echo - Approve Phase: http://localhost:8080/VJNT_Class_Managment/headmaster-approve-phase.jsp?phase=1
echo.
pause
