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
    
    // Phase-specific level storage
    private Integer phase1Marathi;
    private Integer phase1Math;
    private Integer phase1English;
    private Integer phase2Marathi;
    private Integer phase2Math;
    private Integer phase2English;
    private Integer phase3Marathi;
    private Integer phase3Math;
    private Integer phase3English;
    private Integer phase4Marathi;
    private Integer phase4Math;
    private Integer phase4English;
    
    // Phase save timestamps - to track if save button was clicked
    private Date phase1Date;
    private Date phase2Date;
    private Date phase3Date;
    private Date phase4Date;
    
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
    
    // Helper methods for phase data
    public String getFullName() {
        return studentName != null ? studentName : "";
    }
    
    // Phase 1 methods
    public Integer getPhase1Marathi() {
        return phase1Marathi;
    }
    
    public void setPhase1Marathi(Integer phase1Marathi) {
        this.phase1Marathi = phase1Marathi;
    }
    
    public Integer getPhase1Math() {
        return phase1Math;
    }
    
    public void setPhase1Math(Integer phase1Math) {
        this.phase1Math = phase1Math;
    }
    
    public Integer getPhase1English() {
        return phase1English;
    }
    
    public void setPhase1English(Integer phase1English) {
        this.phase1English = phase1English;
    }
    
    // Phase 2 methods
    public Integer getPhase2Marathi() {
        return phase2Marathi;
    }
    
    public void setPhase2Marathi(Integer phase2Marathi) {
        this.phase2Marathi = phase2Marathi;
    }
    
    public Integer getPhase2Math() {
        return phase2Math;
    }
    
    public void setPhase2Math(Integer phase2Math) {
        this.phase2Math = phase2Math;
    }
    
    public Integer getPhase2English() {
        return phase2English;
    }
    
    public void setPhase2English(Integer phase2English) {
        this.phase2English = phase2English;
    }
    
    // Phase 3 methods
    public Integer getPhase3Marathi() {
        return phase3Marathi;
    }
    
    public void setPhase3Marathi(Integer phase3Marathi) {
        this.phase3Marathi = phase3Marathi;
    }
    
    public Integer getPhase3Math() {
        return phase3Math;
    }
    
    public void setPhase3Math(Integer phase3Math) {
        this.phase3Math = phase3Math;
    }
    
    public Integer getPhase3English() {
        return phase3English;
    }
    
    public void setPhase3English(Integer phase3English) {
        this.phase3English = phase3English;
    }
    
    // Phase 4 methods
    public Integer getPhase4Marathi() {
        return phase4Marathi;
    }
    
    public void setPhase4Marathi(Integer phase4Marathi) {
        this.phase4Marathi = phase4Marathi;
    }
    
    public Integer getPhase4Math() {
        return phase4Math;
    }
    
    public void setPhase4Math(Integer phase4Math) {
        this.phase4Math = phase4Math;
    }
    
    public Integer getPhase4English() {
        return phase4English;
    }
    
    public void setPhase4English(Integer phase4English) {
        this.phase4English = phase4English;
    }
    
    // Phase date getters and setters
    public Date getPhase1Date() {
        return phase1Date;
    }
    
    public void setPhase1Date(Date phase1Date) {
        this.phase1Date = phase1Date;
    }
    
    public Date getPhase2Date() {
        return phase2Date;
    }
    
    public void setPhase2Date(Date phase2Date) {
        this.phase2Date = phase2Date;
    }
    
    public Date getPhase3Date() {
        return phase3Date;
    }
    
    public void setPhase3Date(Date phase3Date) {
        this.phase3Date = phase3Date;
    }
    
    public Date getPhase4Date() {
        return phase4Date;
    }
    
    public void setPhase4Date(Date phase4Date) {
        this.phase4Date = phase4Date;
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
