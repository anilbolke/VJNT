package com.vjnt.model;

import java.util.Date;

/**
 * Student Model
 * Represents a student record from Excel
 */
public class Student {
    
    private int studentId;
    private String division;
    private String district;
    private String udiseNo;
    private String studentClass;
    private String section;
    private String classCategory;
    private String studentName;
    private String gender;
    private String studentPen;
    private String marathiLevel;
    private String mathLevel;
    private String englishLevel;
    
    // Detailed language proficiency levels
    // Marathi (मराठी भाषा स्तर)
    private int marathiAksharaLevel;    // अक्षर स्तरावरील (वाचन व लेखन)
    private int marathiShabdaLevel;     // शब्द स्तरावरील (वाचन व लेखन)
    private int marathiVakyaLevel;      // वाक्य स्तरावरील
    private int marathiSamajpurvakLevel;// समजपुर्वक उतार वाचन स्तरावरील
    
    // Math (गणित स्तर)
    private int mathAksharaLevel;
    private int mathShabdaLevel;
    private int mathVakyaLevel;
    private int mathSamajpurvakLevel;
    
    // English (इंग्रजी स्तर)
    private int englishAksharaLevel;
    private int englishShabdaLevel;
    private int englishVakyaLevel;
    private int englishSamajpurvakLevel;
    
    private Date createdDate;
    private String createdBy;
    private Date updatedDate;
    private String updatedBy;
    
    // Constructors
    public Student() {
    }
    
    // Getters and Setters
    public int getStudentId() {
        return studentId;
    }
    
    public void setStudentId(int studentId) {
        this.studentId = studentId;
    }
    
    public String getDivision() {
        return division;
    }
    
    public void setDivision(String division) {
        this.division = division;
    }
    
    public String getDistrict() {
        return district;
    }
    
    public void setDistrict(String district) {
        this.district = district;
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
    
    public String getClassCategory() {
        return classCategory;
    }
    
    public void setClassCategory(String classCategory) {
        this.classCategory = classCategory;
    }
    
    public String getStudentName() {
        return studentName;
    }
    
    public void setStudentName(String studentName) {
        this.studentName = studentName;
    }
    
    public String getGender() {
        return gender;
    }
    
    public void setGender(String gender) {
        this.gender = gender;
    }
    
    public String getStudentPen() {
        return studentPen;
    }
    
    public void setStudentPen(String studentPen) {
        this.studentPen = studentPen;
    }
    
    public String getMarathiLevel() {
        return marathiLevel;
    }
    
    public void setMarathiLevel(String marathiLevel) {
        this.marathiLevel = marathiLevel;
    }
    
    public String getMathLevel() {
        return mathLevel;
    }
    
    public void setMathLevel(String mathLevel) {
        this.mathLevel = mathLevel;
    }
    
    public String getEnglishLevel() {
        return englishLevel;
    }
    
    public void setEnglishLevel(String englishLevel) {
        this.englishLevel = englishLevel;
    }
    
    public Date getCreatedDate() {
        return createdDate;
    }
    
    public void setCreatedDate(Date createdDate) {
        this.createdDate = createdDate;
    }
    
    public String getCreatedBy() {
        return createdBy;
    }
    
    public void setCreatedBy(String createdBy) {
        this.createdBy = createdBy;
    }
    
    public Date getUpdatedDate() {
        return updatedDate;
    }
    
    public void setUpdatedDate(Date updatedDate) {
        this.updatedDate = updatedDate;
    }
    
    public String getUpdatedBy() {
        return updatedBy;
    }
    
    public void setUpdatedBy(String updatedBy) {
        this.updatedBy = updatedBy;
    }
    
    // Marathi Level Getters and Setters
    public int getMarathiAksharaLevel() {
        return marathiAksharaLevel;
    }
    
    public void setMarathiAksharaLevel(int marathiAksharaLevel) {
        this.marathiAksharaLevel = marathiAksharaLevel;
    }
    
    public int getMarathiShabdaLevel() {
        return marathiShabdaLevel;
    }
    
    public void setMarathiShabdaLevel(int marathiShabdaLevel) {
        this.marathiShabdaLevel = marathiShabdaLevel;
    }
    
    public int getMarathiVakyaLevel() {
        return marathiVakyaLevel;
    }
    
    public void setMarathiVakyaLevel(int marathiVakyaLevel) {
        this.marathiVakyaLevel = marathiVakyaLevel;
    }
    
    public int getMarathiSamajpurvakLevel() {
        return marathiSamajpurvakLevel;
    }
    
    public void setMarathiSamajpurvakLevel(int marathiSamajpurvakLevel) {
        this.marathiSamajpurvakLevel = marathiSamajpurvakLevel;
    }
    
    // Math Level Getters and Setters
    public int getMathAksharaLevel() {
        return mathAksharaLevel;
    }
    
    public void setMathAksharaLevel(int mathAksharaLevel) {
        this.mathAksharaLevel = mathAksharaLevel;
    }
    
    public int getMathShabdaLevel() {
        return mathShabdaLevel;
    }
    
    public void setMathShabdaLevel(int mathShabdaLevel) {
        this.mathShabdaLevel = mathShabdaLevel;
    }
    
    public int getMathVakyaLevel() {
        return mathVakyaLevel;
    }
    
    public void setMathVakyaLevel(int mathVakyaLevel) {
        this.mathVakyaLevel = mathVakyaLevel;
    }
    
    public int getMathSamajpurvakLevel() {
        return mathSamajpurvakLevel;
    }
    
    public void setMathSamajpurvakLevel(int mathSamajpurvakLevel) {
        this.mathSamajpurvakLevel = mathSamajpurvakLevel;
    }
    
    // English Level Getters and Setters
    public int getEnglishAksharaLevel() {
        return englishAksharaLevel;
    }
    
    public void setEnglishAksharaLevel(int englishAksharaLevel) {
        this.englishAksharaLevel = englishAksharaLevel;
    }
    
    public int getEnglishShabdaLevel() {
        return englishShabdaLevel;
    }
    
    public void setEnglishShabdaLevel(int englishShabdaLevel) {
        this.englishShabdaLevel = englishShabdaLevel;
    }
    
    public int getEnglishVakyaLevel() {
        return englishVakyaLevel;
    }
    
    public void setEnglishVakyaLevel(int englishVakyaLevel) {
        this.englishVakyaLevel = englishVakyaLevel;
    }
    
    public int getEnglishSamajpurvakLevel() {
        return englishSamajpurvakLevel;
    }
    
    public void setEnglishSamajpurvakLevel(int englishSamajpurvakLevel) {
        this.englishSamajpurvakLevel = englishSamajpurvakLevel;
    }
    
    @Override
    public String toString() {
        return "Student{" +
                "studentId=" + studentId +
                ", division='" + division + '\'' +
                ", district='" + district + '\'' +
                ", udiseNo='" + udiseNo + '\'' +
                ", studentClass='" + studentClass + '\'' +
                ", section='" + section + '\'' +
                ", studentName='" + studentName + '\'' +
                ", studentPen='" + studentPen + '\'' +
                '}';
    }
}
