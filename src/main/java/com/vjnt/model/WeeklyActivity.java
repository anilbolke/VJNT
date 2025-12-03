package com.vjnt.model;

import java.sql.Timestamp;

public class WeeklyActivity {
    private int id;
    private String udiseNo;
    private String studentClass;
    private String section;
    private String subject; // Marathi, English, Math
    private int weekNumber; // 1-52
    private String day; // Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
    private String activity;
    private boolean completed;
    private Timestamp completedDate;
    private String completedBy;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    
    // Constructors
    public WeeklyActivity() {
    }
    
    public WeeklyActivity(String udiseNo, String studentClass, String section, String subject, 
                         int weekNumber, String day, String activity) {
        this.udiseNo = udiseNo;
        this.studentClass = studentClass;
        this.section = section;
        this.subject = subject;
        this.weekNumber = weekNumber;
        this.day = day;
        this.activity = activity;
        this.completed = false;
    }
    
    // Getters and Setters
    public int getId() {
        return id;
    }
    
    public void setId(int id) {
        this.id = id;
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
    
    public String getSubject() {
        return subject;
    }
    
    public void setSubject(String subject) {
        this.subject = subject;
    }
    
    public int getWeekNumber() {
        return weekNumber;
    }
    
    public void setWeekNumber(int weekNumber) {
        this.weekNumber = weekNumber;
    }
    
    public String getDay() {
        return day;
    }
    
    public void setDay(String day) {
        this.day = day;
    }
    
    public String getActivity() {
        return activity;
    }
    
    public void setActivity(String activity) {
        this.activity = activity;
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
    
    public String getCompletedBy() {
        return completedBy;
    }
    
    public void setCompletedBy(String completedBy) {
        this.completedBy = completedBy;
    }
    
    public Timestamp getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Timestamp createdAt) {
        this.createdAt = createdAt;
    }
    
    public Timestamp getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(Timestamp updatedAt) {
        this.updatedAt = updatedAt;
    }
}
