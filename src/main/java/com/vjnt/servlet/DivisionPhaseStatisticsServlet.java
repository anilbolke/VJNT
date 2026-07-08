package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.StudentDAO;
import com.vjnt.dao.SchoolDAO;
import com.vjnt.model.User;
import com.vjnt.model.School;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.util.*;

/**
 * Servlet to provide division-wide phase-wise subject statistics
 * Shows data grouped by district and school
 */
@WebServlet("/division-phase-statistics")
public class DivisionPhaseStatisticsServlet extends HttpServlet {
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Set UTF-8 encoding
        request.setCharacterEncoding("UTF-8");
        response.setContentType("application/json; charset=UTF-8");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("user") == null) {
            out.print("{\"success\": false, \"message\": \"Not authenticated\"}");
            return;
        }
        
        User user = (User) session.getAttribute("user");
        
        // Only Division users (or Super Division Officer) can access this
        if (!user.getUserType().equals(User.UserType.DIVISION) && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
            out.print("{\"success\": false, \"message\": \"Access denied. Only Division users can view this data.\"}");
            return;
        }
        
        try {
            String divisionName = user.getDivisionName();
            
            // Get filter parameters
            String filterDistrict = request.getParameter("district");
            String filterSchool = request.getParameter("school");
            String filterClass = request.getParameter("class");
            
            
            SchoolDAO schoolDAO = new SchoolDAO();
            StudentDAO studentDAO = new StudentDAO();
            
            // Get all schools in the division
            List<School> schools = schoolDAO.getSchoolsByDivision(divisionName);
            
            // Prepare data structures
            Map<String, Map<String, Object>> districtData = new LinkedHashMap<>();
            Map<String, Map<String, Object>> schoolData = new LinkedHashMap<>();
            List<String> districts = new ArrayList<>();
            Map<String, Object> divisionSummary = initializeSummary();
            
            // Process each school
            for (School school : schools) {
                String districtName = school.getDistrictName();
                String udiseNo = school.getUdiseNo();
                String schoolName = school.getSchoolName();
                
                // Apply filters if provided
                if (filterDistrict != null && !filterDistrict.isEmpty() && 
                    !districtName.equalsIgnoreCase(filterDistrict)) {
                    continue;
                }
                
                if (filterSchool != null && !filterSchool.isEmpty() && 
                    !udiseNo.equals(filterSchool)) {
                    continue;
                }
                
                // Track unique districts
                if (!districts.contains(districtName)) {
                    districts.add(districtName);
                }
                
                // Get phase-wise statistics for this school
                Map<String, Object> schoolStats = studentDAO.getPhaseWiseSubjectCounts(udiseNo, filterClass);
                
                // Add school metadata
                Map<String, Object> schoolInfo = new LinkedHashMap<>();
                schoolInfo.put("udiseNo", udiseNo);
                schoolInfo.put("schoolName", schoolName);
                schoolInfo.put("districtName", districtName);
                schoolInfo.put("statistics", schoolStats);
                
                // Store school data
                schoolData.put(udiseNo, schoolInfo);
                
                // Aggregate at district level
                if (!districtData.containsKey(districtName)) {
                    districtData.put(districtName, initializeSummary());
                }
                aggregateStats(districtData.get(districtName), schoolStats);
                
                // Aggregate at division level
                aggregateStats(divisionSummary, schoolStats);
            }
            
            // Prepare response
            Map<String, Object> responseData = new LinkedHashMap<>();
            responseData.put("success", true);
            responseData.put("divisionName", divisionName);
            responseData.put("totalSchools", schools.size());
            responseData.put("filteredSchools", schoolData.size());
            responseData.put("districts", districts);
            responseData.put("districtData", districtData);
            responseData.put("schoolData", schoolData);
            responseData.put("divisionSummary", divisionSummary);
            
            
            Gson gson = new Gson();
            out.print(gson.toJson(responseData));
            
        } catch (Exception e) {
            e.printStackTrace();
            out.print("{\"success\": false, \"message\": \"Error: " + e.getMessage() + "\"}");
        }
    }
    
    /**
     * Initialize summary structure with all level counts
     */
    private Map<String, Object> initializeSummary() {
        Map<String, Object> summary = new LinkedHashMap<>();
        
        // Total students
        summary.put("totalStudents", 0);
        
        // Initialize counts for all phases and subjects
        for (int phase = 1; phase <= 4; phase++) {
            // Marathi (0-6)
            Map<Integer, Integer> marathiCounts = new LinkedHashMap<>();
            for (int i = 0; i <= 6; i++) {
                marathiCounts.put(i, 0);
            }
            summary.put("phase" + phase + "_marathi", marathiCounts);
            
            // Math (0-8)
            Map<Integer, Integer> mathCounts = new LinkedHashMap<>();
            for (int i = 0; i <= 8; i++) {
                mathCounts.put(i, 0);
            }
            summary.put("phase" + phase + "_math", mathCounts);
            
            // English (0-6)
            Map<Integer, Integer> englishCounts = new LinkedHashMap<>();
            for (int i = 0; i <= 6; i++) {
                englishCounts.put(i, 0);
            }
            summary.put("phase" + phase + "_english", englishCounts);
        }
        
        return summary;
    }
    
    /**
     * Aggregate statistics from school to district/division level
     */
    @SuppressWarnings("unchecked")
    private void aggregateStats(Map<String, Object> target, Map<String, Object> source) {
        // Aggregate total students
        int targetTotal = (int) target.get("totalStudents");
        int sourceTotal = source.containsKey("totalStudents") ? 
            parseNumber(source.get("totalStudents")) : 0;
        target.put("totalStudents", targetTotal + sourceTotal);
        
        // Aggregate all phase counts
        for (int phase = 1; phase <= 4; phase++) {
            String[] subjects = {"marathi", "math", "english"};
            
            for (String subject : subjects) {
                String key = "phase" + phase + "_" + subject;
                
                Map<Integer, Integer> targetCounts = (Map<Integer, Integer>) target.get(key);
                Object sourceCounts = source.get(key);
                
                if (sourceCounts instanceof Map) {
                    Map<?, ?> sourceMap = (Map<?, ?>) sourceCounts;
                    for (Map.Entry<?, ?> entry : sourceMap.entrySet()) {
                        int level = parseNumber(entry.getKey());
                        int count = parseNumber(entry.getValue());
                        targetCounts.put(level, targetCounts.getOrDefault(level, 0) + count);
                    }
                }
            }
        }
    }
    
    /**
     * Parse object to integer (handles both Number and String)
     */
    private int parseNumber(Object obj) {
        if (obj == null) return 0;
        if (obj instanceof Number) {
            return ((Number) obj).intValue();
        }
        if (obj instanceof String) {
            try {
                return Integer.parseInt((String) obj);
            } catch (NumberFormatException e) {
                return 0;
            }
        }
        return 0;
    }
}
