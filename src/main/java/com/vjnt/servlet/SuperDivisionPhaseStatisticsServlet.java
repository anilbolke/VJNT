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
 * Super Division Officer version of {@link DivisionPhaseStatisticsServlet}.
 *
 * The {@code division} parameter is OPTIONAL: missing/empty/"ALL" aggregates every
 * division's schools; a specific division scopes to that division. Existing division
 * servlets are left untouched.
 */
@WebServlet("/super-phase-statistics")
public class SuperDivisionPhaseStatisticsServlet extends HttpServlet {

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

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

        // Only Super Division Officer can access this endpoint
        if (!user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER)) {
            out.print("{\"success\": false, \"message\": \"Access denied.\"}");
            return;
        }

        try {
            String divisionParam = request.getParameter("division");
            boolean allDivisions = divisionParam == null || divisionParam.trim().isEmpty()
                    || "ALL".equalsIgnoreCase(divisionParam.trim());

            String filterDistrict = request.getParameter("district");
            String filterSchool = request.getParameter("school");
            String filterClass = request.getParameter("class");

            SchoolDAO schoolDAO = new SchoolDAO();
            StudentDAO studentDAO = new StudentDAO();

            // All divisions -> every school; otherwise the selected division's schools
            List<School> schools = allDivisions
                    ? schoolDAO.getAllSchools()
                    : schoolDAO.getSchoolsByDivision(divisionParam);

            Map<String, Map<String, Object>> districtData = new LinkedHashMap<>();
            Map<String, Map<String, Object>> schoolData = new LinkedHashMap<>();
            List<String> districts = new ArrayList<>();
            Map<String, Object> divisionSummary = initializeSummary();

            for (School school : schools) {
                String districtName = school.getDistrictName();
                String udiseNo = school.getUdiseNo();
                String schoolName = school.getSchoolName();

                if (filterDistrict != null && !filterDistrict.isEmpty() &&
                    (districtName == null || !districtName.equalsIgnoreCase(filterDistrict))) {
                    continue;
                }

                if (filterSchool != null && !filterSchool.isEmpty() &&
                    !udiseNo.equals(filterSchool)) {
                    continue;
                }

                if (districtName != null && !districts.contains(districtName)) {
                    districts.add(districtName);
                }

                Map<String, Object> schoolStats = studentDAO.getPhaseWiseSubjectCounts(udiseNo, filterClass);

                Map<String, Object> schoolInfo = new LinkedHashMap<>();
                schoolInfo.put("udiseNo", udiseNo);
                schoolInfo.put("schoolName", schoolName);
                schoolInfo.put("districtName", districtName);
                schoolInfo.put("statistics", schoolStats);

                schoolData.put(udiseNo, schoolInfo);

                if (districtName != null) {
                    if (!districtData.containsKey(districtName)) {
                        districtData.put(districtName, initializeSummary());
                    }
                    aggregateStats(districtData.get(districtName), schoolStats);
                }

                aggregateStats(divisionSummary, schoolStats);
            }

            Map<String, Object> responseData = new LinkedHashMap<>();
            responseData.put("success", true);
            responseData.put("divisionName", allDivisions ? "All Divisions" : divisionParam);
            responseData.put("scope", allDivisions ? "ALL" : divisionParam);
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

    private Map<String, Object> initializeSummary() {
        Map<String, Object> summary = new LinkedHashMap<>();
        summary.put("totalStudents", 0);

        for (int phase = 1; phase <= 4; phase++) {
            Map<Integer, Integer> marathiCounts = new LinkedHashMap<>();
            for (int i = 0; i <= 6; i++) { marathiCounts.put(i, 0); }
            summary.put("phase" + phase + "_marathi", marathiCounts);

            Map<Integer, Integer> mathCounts = new LinkedHashMap<>();
            for (int i = 0; i <= 8; i++) { mathCounts.put(i, 0); }
            summary.put("phase" + phase + "_math", mathCounts);

            Map<Integer, Integer> englishCounts = new LinkedHashMap<>();
            for (int i = 0; i <= 6; i++) { englishCounts.put(i, 0); }
            summary.put("phase" + phase + "_english", englishCounts);
        }

        return summary;
    }

    @SuppressWarnings("unchecked")
    private void aggregateStats(Map<String, Object> target, Map<String, Object> source) {
        int targetTotal = (int) target.get("totalStudents");
        int sourceTotal = source.containsKey("totalStudents") ?
            parseNumber(source.get("totalStudents")) : 0;
        target.put("totalStudents", targetTotal + sourceTotal);

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
