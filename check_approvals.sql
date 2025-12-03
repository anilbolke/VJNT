-- Check report_approvals table structure and data
SELECT 
    approval_id,
    pen_number,
    student_name,
    approval_status,
    requested_by,
    approved_by,
    approval_date,
    approval_remarks,
    requested_date
FROM report_approvals
ORDER BY requested_date DESC
LIMIT 5;

-- Check column names
DESCRIBE report_approvals;
