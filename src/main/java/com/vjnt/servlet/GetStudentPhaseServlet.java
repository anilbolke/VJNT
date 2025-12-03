package com.vjnt.servlet;

import com.google.gson.Gson;
import com.vjnt.dao.StudentDAO;
import com.vjnt.model.Student;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

@WebServlet("/get-student-phase")
public class GetStudentPhaseServlet extends HttpServlet {
    
    private StudentDAO studentDAO = new StudentDAO();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String studentIdStr = request.getParameter("studentId");
        String subject = request.getParameter("subject");
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            if (studentIdStr == null || subject == null) {
                result.put("success", false);
                result.put("message", "Missing parameters");
                response.getWriter().write(new Gson().toJson(result));
                return;
            }
            
            int studentId = Integer.parseInt(studentIdStr);
            Student student = studentDAO.getStudentById(studentId);
            
            if (student == null) {
                result.put("success", false);
                result.put("message", "Student not found");
                response.getWriter().write(new Gson().toJson(result));
                return;
            }
            
            // Get the actual level description from database column values
            String levelDescription = getLevelDescription(student, subject);
            String currentPhase = getCurrentPhase(student, subject);
            
            result.put("success", true);
            result.put("phase", currentPhase);
            result.put("description", levelDescription);
            result.put("studentName", student.getStudentName());
            
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "Error: " + e.getMessage());
        }
        
        response.getWriter().write(new Gson().toJson(result));
    }
    
    private String getCurrentPhase(Student student, String subject) {
        // Check which phase the student is currently in based on non-null values
        switch (subject.toLowerCase()) {
            case "marathi":
                if (student.getPhase4Marathi() != null && student.getPhase4Marathi() > 0) {
                    return "Phase 4";
                } else if (student.getPhase3Marathi() != null && student.getPhase3Marathi() > 0) {
                    return "Phase 3";
                } else if (student.getPhase2Marathi() != null && student.getPhase2Marathi() > 0) {
                    return "Phase 2";
                } else if (student.getPhase1Marathi() != null && student.getPhase1Marathi() > 0) {
                    return "Phase 1";
                }
                break;
                
            case "math":
                if (student.getPhase4Math() != null && student.getPhase4Math() > 0) {
                    return "Phase 4";
                } else if (student.getPhase3Math() != null && student.getPhase3Math() > 0) {
                    return "Phase 3";
                } else if (student.getPhase2Math() != null && student.getPhase2Math() > 0) {
                    return "Phase 2";
                } else if (student.getPhase1Math() != null && student.getPhase1Math() > 0) {
                    return "Phase 1";
                }
                break;
                
            case "english":
                if (student.getPhase4English() != null && student.getPhase4English() > 0) {
                    return "Phase 4";
                } else if (student.getPhase3English() != null && student.getPhase3English() > 0) {
                    return "Phase 3";
                } else if (student.getPhase2English() != null && student.getPhase2English() > 0) {
                    return "Phase 2";
                } else if (student.getPhase1English() != null && student.getPhase1English() > 0) {
                    return "Phase 1";
                }
                break;
        }
        
        return "Phase 1"; // Default to Phase 1
    }
    
    private String getPhaseDescription(String phase, String subject) {
        // This method now returns the actual level description used in database columns
        // phase parameter is not used anymore, we get level directly from student object
        return phase; // Placeholder, actual description comes from getLevelDescription
    }
    
    private String getLevelDescription(Student student, String subject) {
        // Get the actual level value from the student's database columns
        int levelValue = 0;
        
        switch (subject.toLowerCase()) {
            case "marathi":
                levelValue = student.getMarathiAksharaLevel();
                return getMarathiLevelText(levelValue);
                
            case "math":
                levelValue = student.getMathAksharaLevel();
                return getMathLevelText(levelValue);
                
            case "english":
                levelValue = student.getEnglishAksharaLevel();
                return getEnglishLevelText(levelValue);
        }
        
        return "स्तर निश्चित केला नाही (Level Not Set)";
    }
    
    private String getMarathiLevelText(int level) {
        switch (level) {
            case 0:
                return "स्तर निश्चित केला नाही";
            case 1:
                return "अक्षर स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 2:
                return "शब्द स्तरावरील विद्यार्थी संख्या (वाचन व लेखन)";
            case 3:
                return "वाक्य स्तरावरील विद्यार्थी संख्या";
            case 4:
                return "समजपुर्वक उतार वाचन स्तरावरील विद्यार्थी संख्या";
            default:
                return "स्तर निश्चित केला नाही";
        }
    }
    
    private String getMathLevelText(int level) {
        switch (level) {
            case 0:
                return "स्तर निश्चित केला नाही";
            case 1:
                return "प्रारंभीक स्तरावरील विद्यार्थी संख्या";
            case 2:
                return "अंक स्तरावरील विद्यार्थी संख्या";
            case 3:
                return "संख्या वाचन स्तरावरील विद्यार्थी संख्या";
            case 4:
                return "बेरीज स्तरावरील विद्यार्थी संख्या";
            case 5:
                return "वजाबाकी स्तरावरील विद्यार्थी संख्या";
            case 6:
                return "गुणाकार स्तरावरील विद्यार्थी संख्या";
            case 7:
                return "भागाकर स्तरावरील विद्यार्थी संख्या";
            default:
                return "स्तर निश्चित केला नाही";
        }
    }
    
    private String getEnglishLevelText(int level) {
        switch (level) {
            case 0:
                return "स्तर निश्चित केला नाही";
            case 1:
                return "BEGINER LEVEL";
            case 2:
                return "ALPHABET LEVEL Reading and Writing";
            case 3:
                return "WORD LEVEL Reading and Writing";
            case 4:
                return "SENTENCE LEVEL";
            case 5:
                return "Paragraph Reading with Understanding";
            default:
                return "स्तर निश्चित केला नाही";
        }
    }
}
