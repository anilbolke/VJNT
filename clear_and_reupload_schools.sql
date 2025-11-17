-- Clear existing schools and re-upload
-- Run this before re-uploading the Excel file

-- Show current count
SELECT COUNT(*) as current_school_count FROM schools;

-- Clear all existing schools
DELETE FROM schools;

-- Verify cleared
SELECT COUNT(*) as school_count_after_clear FROM schools;

-- Now re-upload the Excel file from upload-schools.jsp
-- Expected result: 186 schools (187 rows - 1 header row)

SELECT 'Ready to upload Excel file. Go to upload-schools.jsp' as next_step;
