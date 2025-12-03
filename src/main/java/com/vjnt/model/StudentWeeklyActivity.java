package com.vjnt.model;

import java.sql.Timestamp;

public class StudentWeeklyActivity {
    private int id;
    private int studentId;
    private String studentPen;
    private String udiseNo;
    private String studentClass;
    private String section;
    private String studentName;
    private String language;
    private int weekNumber;
    private int dayNumber;
    private String activityText;
    private String activityIdentifier;
    private int activityCount;
    private boolean completed;
    private Timestamp completedDate;
    private String assignedBy;
    private Timestamp assignedDate;
    private Timestamp updatedAt;

    public StudentWeeklyActivity() {}

    public StudentWeeklyActivity(int studentId, String studentPen, String udiseNo, String studentClass, 
                                String section, String studentName, String language, int weekNumber, 
                                int dayNumber, String activityText) {
        this.studentId = studentId;
        this.studentPen = studentPen;
        this.udiseNo = udiseNo;
        this.studentClass = studentClass;
        this.section = section;
        this.studentName = studentName;
        this.language = language;
        this.weekNumber = weekNumber;
        this.dayNumber = dayNumber;
        this.activityText = activityText;
        this.activityCount = 1;
        this.completed = false;
    }

    // Getters and Setters
    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getStudentId() {
        return studentId;
    }

    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }

    public String getStudentPen() {
        return studentPen;
    }

    public void setStudentPen(String studentPen) {
        this.studentPen = studentPen;
    }

    public String getUdiseNo() {
        return udiseNo;
    }

    public void setUdiseNo(String udiseNo) {
        this.udiseNo = udiseNo;
    }

    public String getStudentClass() {
        return studentClass;
    }

    public void setStudentClass(String studentClass) {
        this.studentClass = studentClass;
    }

    public String getSection() {
        return section;
    }

    public void setSection(String section) {
        this.section = section;
    }

    public String getStudentName() {
        return studentName;
    }

    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }

    public int getWeekNumber() {
        return weekNumber;
    }

    public void setWeekNumber(int weekNumber) {
        this.weekNumber = weekNumber;
    }

    public int getDayNumber() {
        return dayNumber;
    }

    public void setDayNumber(int dayNumber) {
        this.dayNumber = dayNumber;
    }

    public String getActivityText() {
        return activityText;
    }

    public void setActivityText(String activityText) {
        this.activityText = activityText;
    }

    public String getActivityIdentifier() {
        return activityIdentifier;
    }

    public void setActivityIdentifier(String activityIdentifier) {
        this.activityIdentifier = activityIdentifier;
    }

    public int getActivityCount() {
        return activityCount;
    }

    public void setActivityCount(int activityCount) {
        this.activityCount = activityCount;
    }

    public boolean isCompleted() {
        return completed;
    }

    public void setCompleted(boolean completed) {
        this.completed = completed;
    }

    public Timestamp getCompletedDate() {
        return completedDate;
    }

    public void setCompletedDate(Timestamp completedDate) {
        this.completedDate = completedDate;
    }

    public String getAssignedBy() {
        return assignedBy;
    }

    public void setAssignedBy(String assignedBy) {
        this.assignedBy = assignedBy;
    }

    public Timestamp getAssignedDate() {
        return assignedDate;
    }

    public void setAssignedDate(Timestamp assignedDate) {
        this.assignedDate = assignedDate;
    }

    public Timestamp getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    /**
     * Generate activity identifier from mandatory fields
     * Format: studentId_language_week_day
     */
    public String generateActivityIdentifier() {
        return String.format("%d_%s_%d_%d", 
            this.studentId, 
            this.language, 
            this.weekNumber, 
            this.dayNumber
        );
    }
    
    /**
     * Auto-generate and set activity identifier
     */
    public void setActivityIdentifierFromFields() {
        this.activityIdentifier = generateActivityIdentifier();
    }
}
