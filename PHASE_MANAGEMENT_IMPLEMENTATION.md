# Phase Management System Implementation

## Overview
This system implements a 4-phase language level tracking system where:
- All students must complete Phase 1 before Phase 2 becomes available
- Previous phase data is shown as read-only in subsequent phases
- All changes are audited for tracking

## Database Schema

### Students Table - Added Columns
```sql
phase1_marathi INT - Marathi level for Phase 1
phase1_math INT - Math level for Phase 1  
phase1_english INT - English level for Phase 1
phase1_date TIMESTAMP - When Phase 1 was completed

phase2_marathi INT - Marathi level for Phase 2
phase2_math INT - Math level for Phase 2
phase2_english INT - English level for Phase 2
phase2_date TIMESTAMP - When Phase 2 was completed

phase3_marathi INT - Marathi level for Phase 3
phase3_math INT - Math level for Phase 3
phase3_english INT - English level for Phase 3
phase3_date TIMESTAMP - When Phase 3 was completed

phase4_marathi INT - Marathi level for Phase 4
phase4_math INT - Math level for Phase 4
phase4_english INT - English level for Phase 4
phase4_date TIMESTAMP - When Phase 4 was completed
```

### Audit Table
```sql
student_phase_audit:
- audit_id (PK)
- student_id (FK)
- phase (1,2,3,4)
- marathi_level
- math_level
- english_level
- changed_by
- changed_date
- action_type (INSERT/UPDATE)
```

##Logic Flow

### Phase Completion Check
A phase is considered complete for a school when:
- ALL students in that school have non-NULL values for that phase
- Example: Phase 1 complete when all students have phase1_marathi, phase1_math, phase1_english filled

### Phase Availability
- Phase 1: Always available initially
- Phase 2: Available only when Phase 1 is 100% complete
- Phase 3: Available only when Phase 2 is 100% complete  
- Phase 4: Available only when Phase 3 is 100% complete

### Data Display
When viewing Phase N:
- Show editable dropdowns for Phase N data
- Show read-only Phase N-1 data for reference
- Phase 1 data carries forward as baseline

## Implementation Steps

### 1. Add DAO Methods (StudentDAO.java)

```java
/**
 * Check if a phase is complete for a school
 */
public boolean isPhaseComplete(String udiseNo, int phase) {
    String columnPrefix = "phase" + phase + "_";
    String sql = "SELECT COUNT(*) as total, " +
                 "SUM(CASE WHEN " + columnPrefix + "marathi IS NOT NULL AND " +
                 columnPrefix + "math IS NOT NULL AND " +
                 columnPrefix + "english IS NOT NULL THEN 1 ELSE 0 END) as completed " +
                 "FROM students WHERE udise_no = ?";
    
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        pstmt.setString(1, udiseNo);
        ResultSet rs = pstmt.executeQuery();
        if (rs.next()) {
            int total = rs.getInt("total");
            int completed = rs.getInt("completed");
            return total > 0 && total == completed;
        }
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return false;
}

/**
 * Update language levels for a specific phase
 */
public boolean updatePhaseLanguageLevels(int studentId, int phase, 
                                        int marathiLevel, int mathLevel, int englishLevel,
                                        String updatedBy) {
    String columnPrefix = "phase" + phase + "_";
    String sql = "UPDATE students SET " +
                 columnPrefix + "marathi = ?, " +
                 columnPrefix + "math = ?, " +
                 columnPrefix + "english = ?, " +
                 columnPrefix + "date = NOW() " +
                 "WHERE student_id = ?";
    
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        pstmt.setInt(1, marathiLevel);
        pstmt.setInt(2, mathLevel);
        pstmt.setInt(3, englishLevel);
        pstmt.setInt(4, studentId);
        
        int rows = pstmt.executeUpdate();
        
        // Create audit entry
        if (rows > 0) {
            auditPhaseChange(studentId, phase, marathiLevel, mathLevel, englishLevel, updatedBy);
        }
        
        return rows > 0;
    } catch (SQLException e) {
        e.printStackTrace();
    }
    return false;
}

/**
 * Create audit entry for phase changes
 */
private void auditPhaseChange(int studentId, int phase, int marathiLevel, 
                             int mathLevel, int englishLevel, String changedBy) {
    String sql = "INSERT INTO student_phase_audit (student_id, phase, marathi_level, " +
                 "math_level, english_level, changed_by, action_type) " +
                 "VALUES (?, ?, ?, ?, ?, ?, 'UPDATE')";
    
    try (Connection conn = DatabaseConnection.getConnection();
         PreparedStatement pstmt = conn.prepareStatement(sql)) {
        pstmt.setInt(1, studentId);
        pstmt.setInt(2, phase);
        pstmt.setInt(3, marathiLevel);
        pstmt.setInt(4, mathLevel);
        pstmt.setInt(5, englishLevel);
        pstmt.setString(6, changedBy);
        pstmt.executeUpdate();
    } catch (SQLException e) {
        e.printStackTrace();
    }
}

/**
 * Get students with phase data
 */
public List<Student> getStudentsByUdiseWithPhaseData(String udiseNo, int phase, 
                                                     int currentPage, int pageSize) {
    String columnPrefix = "phase" + phase + "_";
    String sql = "SELECT *, " +
                 columnPrefix + "marathi as current_marathi, " +
                 columnPrefix + "math as current_math, " +
                 columnPrefix + "english as current_english, " +
                 columnPrefix + "date as current_date " +
                 "FROM students WHERE udise_no = ? " +
                 "ORDER BY student_class, section, student_name " +
                 "LIMIT ? OFFSET ?";
    // Implementation continues...
}
```

### 2. Update Servlet (UpdateLanguageLevelsServlet.java)

```java
@Override
protected void doPost(HttpServletRequest request, HttpServletResponse response) 
        throws ServletException, IOException {
    
    // ... authentication checks ...
    
    try {
        int studentId = Integer.parseInt(request.getParameter("studentId"));
        int phase = Integer.parseInt(request.getParameter("phase"));
        int marathiLevel = Integer.parseInt(request.getParameter("marathi_akshara"));
        int mathLevel = Integer.parseInt(request.getParameter("math_akshara"));
        int englishLevel = Integer.parseInt(request.getParameter("english_akshara"));
        
        StudentDAO studentDAO = new StudentDAO();
        String username = user.getUsername();
        
        boolean success = studentDAO.updatePhaseLanguageLevels(
            studentId, phase, marathiLevel, mathLevel, englishLevel, username
        );
        
        if (success) {
            out.print("{\"success\": true, \"message\": \"Phase " + phase + " data saved successfully\"}");
        } else {
            out.print("{\"success\": false, \"message\": \"Failed to save data\"}");
        }
    } catch (Exception e) {
        out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
    }
}
```

## UI Features

### Phase Dropdown
- Displays Phase 1, 2, 3, 4
- Disabled phases show "✓ Completed" or "🔒 Locked"
- Only one active phase at a time

### Status Indicators
- Green: Phase completed
- Orange: Phase in progress
- Gray: Phase locked

### Table Display
- Shows dropdown values for current phase
- Shows previous phase data as read-only reference
- Save button updates only current phase

## Testing Checklist

1. ☐ Phase 1 can be selected initially
2. ☐ Assign values to all students in Phase 1
3. ☐ Verify Phase 1 gets disabled after completion
4. ☐ Verify Phase 2 becomes enabled
5. ☐ In Phase 2, verify Phase 1 data is visible
6. ☐ Complete Phase 2, verify Phase 3 unlocks
7. ☐ Check audit table has all changes recorded
8. ☐ Verify phase completion percentage updates

## Benefits

1. **Progressive Tracking**: Track student progress over time
2. **Data Integrity**: Cannot skip phases
3. **Audit Trail**: Complete history of all changes
4. **Read-Only History**: Previous phase data visible for comparison
5. **School-Level Control**: Phase completion at school level, not individual

## Queries for Reporting

```sql
-- Check phase completion status for a school
SELECT 
    phase1_marathi IS NOT NULL AND phase1_math IS NOT NULL AND phase1_english IS NOT NULL as p1_complete,
    phase2_marathi IS NOT NULL AND phase2_math IS NOT NULL AND phase2_english IS NOT NULL as p2_complete,
    phase3_marathi IS NOT NULL AND phase3_math IS NOT NULL AND phase3_english IS NOT NULL as p3_complete,
    phase4_marathi IS NOT NULL AND phase4_math IS NOT NULL AND phase4_english IS NOT NULL as p4_complete
FROM students
WHERE udise_no = '10001';

-- Get audit history for a student
SELECT * FROM student_phase_audit
WHERE student_id = 427
ORDER BY changed_date DESC;

-- Phase completion percentage for a school
SELECT 
    COUNT(*) as total_students,
    SUM(CASE WHEN phase1_marathi IS NOT NULL THEN 1 ELSE 0 END) as phase1_complete,
    SUM(CASE WHEN phase2_marathi IS NOT NULL THEN 1 ELSE 0 END) as phase2_complete,
    SUM(CASE WHEN phase3_marathi IS NOT NULL THEN 1 ELSE 0 END) as phase3_complete,
    SUM(CASE WHEN phase4_marathi IS NOT NULL THEN 1 ELSE 0 END) as phase4_complete
FROM students
WHERE udise_no = '10001';
```
