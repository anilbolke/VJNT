package com.vjnt.servlet;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.JsonObject;
import com.vjnt.dao.SchoolDAO;
import com.vjnt.dao.SchoolContactDAO;
import com.vjnt.dao.PalakMelavaDAO;
import com.vjnt.dao.OtherSchoolActivityDAO;
import com.vjnt.model.School;
import com.vjnt.model.SchoolContact;
import com.vjnt.model.PalakMelava;
import com.vjnt.model.OtherSchoolActivity;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

/**
 * Public servlet to display school details by UDISE number
 * No authentication required - for public website display
 */
@WebServlet("/public-school-lookup")
public class PublicSchoolLookupServlet extends HttpServlet {
    
    private SchoolDAO schoolDAO = new SchoolDAO();
    private SchoolContactDAO contactDAO = new SchoolContactDAO();
    private PalakMelavaDAO melavaDAO = new PalakMelavaDAO();
    private OtherSchoolActivityDAO activityDAO = new OtherSchoolActivityDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String udiseNo = request.getParameter("udise");
        response.setContentType("text/html; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        // Validate UDISE parameter existence
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            out.println(returnErrorPage("Missing UDISE Parameter", 
                "❌ UDISE number is required to view school information.", 
                "Please provide a valid UDISE number in the URL parameter."));
            out.flush();
            return;
        }
        
        udiseNo = udiseNo.trim();
        
        // Validate UDISE format (should be numeric, typically 11 digits)
        if (!udiseNo.matches("^[0-9]+$")) {
            out.println(returnErrorPage("Invalid UDISE Format", 
                "❌ UDISE number must contain only digits.", 
                "Valid UDISE: 27150408704 (11 digits typically)"));
            out.flush();
            return;
        }
        
        if (udiseNo.length() < 10 || udiseNo.length() > 12) {
            out.println(returnErrorPage("Invalid UDISE Format", 
                "❌ UDISE number should be between 10-12 digits.", 
                "Provided UDISE: " + escapeHtml(udiseNo) + " (" + udiseNo.length() + " digits)"));
            out.flush();
            return;
        }
        
        try {
            // Fetch data server-side
            School school = schoolDAO.getSchoolByUdise(udiseNo);
            
            // Check if school exists
            if (school == null) {
                out.println(returnErrorPage("School Not Found", 
                    "❌ No school found with UDISE number: " + escapeHtml(udiseNo), 
                    "Please verify the UDISE number and try again."));
                out.flush();
                return;
            }
            
            List<SchoolContact> contacts = new ArrayList<>();
            List<PalakMelava> melavas = new ArrayList<>();
            List<OtherSchoolActivity> activities = new ArrayList<>();
            
            try {
                contacts = contactDAO.getContactsByUdise(udiseNo);
                if (contacts == null) contacts = new ArrayList<>();
            } catch (Exception e) {
                System.err.println("Error fetching contacts: " + e.getMessage());
            }
            
            try {
                melavas = melavaDAO.getByUdise(udiseNo);
                if (melavas == null) melavas = new ArrayList<>();
            } catch (Exception e) {
                System.err.println("Error fetching melavas: " + e.getMessage());
            }
            
            try {
                activities = activityDAO.getByUdise(udiseNo);
                if (activities == null) activities = new ArrayList<>();
            } catch (Exception e) {
                System.err.println("Error fetching activities: " + e.getMessage());
            }
            
            out.println(returnHtmlPage(school, contacts, melavas, activities));
            out.flush();
            
        } catch (Exception e) {
            System.err.println("Database error while fetching school data: " + e.getMessage());
            e.printStackTrace();
            out.println(returnErrorPage("Database Error", 
                "❌ An error occurred while retrieving school information.", 
                "Please try again later or contact the administrator."));
            out.flush();
        }
    }
    
    private String returnHtmlPage(School school, List<SchoolContact> contacts, List<PalakMelava> melavas, List<OtherSchoolActivity> activities) {
        StringBuilder html = new StringBuilder();
        
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"en\">\n");
        html.append("<head>\n");
        html.append("    <meta charset=\"UTF-8\">\n");
        html.append("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        html.append("    <title>School Information - VJNT Class Management</title>\n");
        html.append("    <style>\n");
        html.append("        * { margin: 0; padding: 0; box-sizing: border-box; }\n");
        html.append("        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; color: #333; }\n");
        html.append("        header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 1rem 0; position: sticky; top: 0; box-shadow: 0 2px 10px rgba(0,0,0,0.1); z-index: 100; }\n");
        html.append("        .header-content { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }\n");
        html.append("        .logo { font-size: 1.5rem; font-weight: bold; }\n");
        html.append("        nav a { color: white; margin-left: 2rem; text-decoration: none; transition: opacity 0.3s; }\n");
        html.append("        nav a:hover { opacity: 0.8; }\n");
        html.append("        .hero { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 3rem 20px; text-align: center; }\n");
        html.append("        .hero h1 { font-size: 2.5rem; margin-bottom: 1rem; }\n");
        html.append("        .hero p { font-size: 1.1rem; opacity: 0.9; }\n");
        html.append("        .container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }\n");
        html.append("        .section { background: white; margin: 2rem 0; padding: 2rem; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); }\n");
        html.append("        .section-title { font-size: 1.8rem; margin-bottom: 1rem; color: #667eea; }\n");
        html.append("        .section-subtitle { color: #666; margin-bottom: 1.5rem; }\n");
        html.append("        .info-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin-bottom: 2rem; }\n");
        html.append("        .info-card { background: #f9f9f9; padding: 1.5rem; border-left: 4px solid #667eea; border-radius: 5px; }\n");
        html.append("        .info-card label { font-weight: 600; color: #667eea; display: block; margin-bottom: 0.5rem; }\n");
        html.append("        .info-card p { color: #555; line-height: 1.6; }\n");
        html.append("        .contact-card { background: white; border: 1px solid #e0e0e0; padding: 1.5rem; border-radius: 8px; margin-bottom: 1rem; }\n");
        html.append("        .contact-info { display: flex; flex-wrap: wrap; gap: 2rem; margin-top: 1rem; }\n");
        html.append("        .contact-item { display: flex; align-items: center; gap: 0.5rem; }\n");
        html.append("        .activity-card { background: white; border: 1px solid #e0e0e0; padding: 1.5rem; border-radius: 8px; margin-bottom: 1rem; }\n");
        html.append("        .activity-images { display: grid; grid-template-columns: repeat(auto-fit, minmax(150px, 1fr)); gap: 10px; margin-bottom: 1rem; }\n");
        html.append("        .activity-image { width: 100%; height: 150px; object-fit: cover; border-radius: 5px; cursor: pointer; border: 1px solid #ddd; transition: transform 0.3s; }\n");
        html.append("        .activity-image:hover { transform: scale(1.05); }\n");
        html.append("        .activity-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem; padding-bottom: 1rem; border-bottom: 1px solid #e0e0e0; }\n");
        html.append("        .activity-title { font-size: 1.2rem; font-weight: 600; color: #333; }\n");
        html.append("        .activity-date { color: #666; font-size: 0.9rem; }\n");
        html.append("        .activity-info { margin-bottom: 1rem; }\n");
        html.append("        .activity-info label { font-weight: 600; color: #667eea; display: block; margin-bottom: 0.3rem; }\n");
        html.append("        .activity-info p { color: #555; }\n");
        html.append("        .activity-link { display: inline-block; margin-top: 0.5rem; padding: 0.5rem 1rem; background: #667eea; color: white; text-decoration: none; border-radius: 5px; font-size: 0.9rem; }\n");
        html.append("        .activity-link:hover { background: #764ba2; }\n");
        html.append("        footer { background: #333; color: white; text-align: center; padding: 2rem; margin-top: 3rem; }\n");
        html.append("        .error-message { background: #fee; color: #c33; padding: 1rem; border-radius: 5px; margin: 1rem 0; }\n");
        html.append("        @media (max-width: 768px) { .hero h1 { font-size: 1.8rem; } nav a { margin-left: 1rem; } }\n");
        html.append("    </style>\n");
        html.append("</head>\n");
        html.append("<body>\n");
        html.append("    <header>\n");
        html.append("        <div class=\"header-content\">\n");
        html.append("            <div class=\"logo\">🏫 School Info</div>\n");
        html.append("            <nav>\n");
        html.append("                <a href=\"#home\">Home</a>\n");
        html.append("                <a href=\"#details\">Details</a>\n");
        html.append("                <a href=\"#contacts\">Contacts</a>\n");
        html.append("            </nav>\n");
        html.append("        </div>\n");
        html.append("    </header>\n");
        html.append("    <div class=\"hero\">\n");
        if (school != null && school.getSchoolName() != null) {
            html.append("        <h1>").append(escapeHtml(school.getSchoolName())).append("</h1>\n");
        } else {
            html.append("        <h1>School Information Portal</h1>\n");
        }
        html.append("    </div>\n");
        html.append("    <div class=\"container\">\n");
        
        if (school != null) {
            html.append("        <div class=\"section\" id=\"details\">\n");
            html.append("            <h2 class=\"section-title\">📍 School Details</h2>\n");
            html.append("            <div class=\"info-grid\">\n");
            html.append("                <div class=\"info-card\"><label>School Name</label><p>").append(escapeHtml(school.getSchoolName() != null ? school.getSchoolName() : "N/A")).append("</p></div>\n");
            html.append("                <div class=\"info-card\"><label>UDISE Number</label><p>").append(escapeHtml(school.getUdiseNo() != null ? school.getUdiseNo() : "N/A")).append("</p></div>\n");
            html.append("                <div class=\"info-card\"><label>District</label><p>").append(escapeHtml(school.getDistrictName() != null ? school.getDistrictName() : "N/A")).append("</p></div>\n");
            html.append("            </div>\n");
            html.append("        </div>\n");
            
            // School Contacts
            if (contacts != null && contacts.size() > 0) {
                html.append("        <div class=\"section\" id=\"contacts\">\n");
                html.append("            <h2 class=\"section-title\">📞 Contact Information</h2>\n");
                html.append("            <p class=\"section-subtitle\">Get in touch with school administration</p>\n");
                for (SchoolContact contact : contacts) {
                    html.append("            <div class=\"contact-card\">\n");
                    html.append("                <div style=\"font-weight: 600; color: #333;\">").append(escapeHtml(contact.getFullName() != null ? contact.getFullName() : "Contact")).append("</div>\n");
                    html.append("                <div style=\"font-size: 0.9rem; color: #666; margin: 0.5rem 0;\">").append(escapeHtml(contact.getContactType() != null ? contact.getContactType() : "Staff")).append("</div>\n");
                    html.append("                <div class=\"contact-info\">\n");
                    if (contact.getMobile() != null && !contact.getMobile().isEmpty()) {
                        html.append("                    <div class=\"contact-item\">📱 ").append(escapeHtml(contact.getMobile())).append("</div>\n");
                    }
                    if (contact.getWhatsappNumber() != null && !contact.getWhatsappNumber().isEmpty()) {
                        html.append("                    <div class=\"contact-item\">💬 ").append(escapeHtml(contact.getWhatsappNumber())).append("</div>\n");
                    }
                    html.append("                </div>\n");
                    html.append("            </div>\n");
                }
                html.append("        </div>\n");
            }
            
            // Palak Melavas
            if (melavas != null && melavas.size() > 0) {
                html.append("        <div class=\"section\">\n");
                html.append("            <h2 class=\"section-title\">👨‍👩‍👧 Parent-Teacher Meetings</h2>\n");
                html.append("            <p class=\"section-subtitle\">Recent Palak Melava meetings</p>\n");
                for (PalakMelava melava : melavas) {
                    if ("APPROVED".equals(melava.getStatus())) {
                        html.append("            <div class=\"activity-card\">\n");
                        html.append("                <div class=\"activity-header\">\n");
                        html.append("                    <div class=\"activity-title\">Parent-Teacher Meeting</div>\n");
                        html.append("                    <div class=\"activity-date\">📅 ").append(escapeHtml(melava.getMeetingDate() != null ? melava.getMeetingDate().toString() : "TBD")).append("</div>\n");
                        html.append("                </div>\n");
                        
                        if ((melava.getPhoto1Content() != null && melava.getPhoto1Content().length > 0) || 
                            (melava.getPhoto2Content() != null && melava.getPhoto2Content().length > 0)) {
                            html.append("                <div class=\"activity-images\">\n");
                            if (melava.getPhoto1Content() != null && melava.getPhoto1Content().length > 0) {
                                html.append("                    <img src=\"/VJNT_Class_Managment/palak-melava-image-db?id=").append(melava.getMelavaId()).append("&photo=1\" alt=\"Meeting Photo\" class=\"activity-image\" onclick=\"viewImageFullScreen(this.src)\" style=\"cursor: pointer;\">\n");
                            }
                            if (melava.getPhoto2Content() != null && melava.getPhoto2Content().length > 0) {
                                html.append("                    <img src=\"/VJNT_Class_Managment/palak-melava-image-db?id=").append(melava.getMelavaId()).append("&photo=2\" alt=\"Meeting Photo\" class=\"activity-image\" onclick=\"viewImageFullScreen(this.src)\" style=\"cursor: pointer;\">\n");
                            }
                            html.append("                </div>\n");
                        }
                        
                        if (melava.getChiefAttendeeInfo() != null && !melava.getChiefAttendeeInfo().isEmpty()) {
                            html.append("                <div class=\"activity-info\"><label>Chief Guest</label><p>").append(escapeHtml(melava.getChiefAttendeeInfo())).append("</p></div>\n");
                        }
                        if (melava.getTotalParentsAttended() != null && !melava.getTotalParentsAttended().isEmpty()) {
                            html.append("                <div class=\"activity-info\"><label>Parents Attended</label><p>👥 ").append(escapeHtml(melava.getTotalParentsAttended())).append("</p></div>\n");
                        }
                        html.append("            </div>\n");
                    }
                }
                html.append("        </div>\n");
            }
            
            // Activities
            if (activities != null && activities.size() > 0) {
                html.append("        <div class=\"section\">\n");
                html.append("            <h2 class=\"section-title\">🎓 School Activities</h2>\n");
                html.append("            <p class=\"section-subtitle\">Various school programs and events</p>\n");
                for (OtherSchoolActivity activity : activities) {
                    if ("APPROVED".equals(activity.getApprovalStatus())) {
                        html.append("            <div class=\"activity-card\">\n");
                        html.append("                <div class=\"activity-header\">\n");
                        html.append("                    <div class=\"activity-title\">").append(escapeHtml(activity.getActivitySubject() != null ? activity.getActivitySubject() : "Activity")).append("</div>\n");
                        html.append("                    <div class=\"activity-date\">📅 ").append(escapeHtml(activity.getActivityDate() != null ? activity.getActivityDate().toString() : "TBD")).append("</div>\n");
                        html.append("                </div>\n");
                        
                        if ((activity.getPhoto1Content() != null && activity.getPhoto1Content().length > 0) || 
                            (activity.getPhoto2Content() != null && activity.getPhoto2Content().length > 0)) {
                            html.append("                <div class=\"activity-images\">\n");
                            if (activity.getPhoto1Content() != null && activity.getPhoto1Content().length > 0) {
                                html.append("                    <img src=\"/VJNT_Class_Managment/other-activity-image-db?id=").append(activity.getActivityId()).append("&photo=1\" alt=\"Activity Photo\" class=\"activity-image\" onclick=\"viewImageFullScreen(this.src)\" style=\"cursor: pointer;\">\n");
                            }
                            if (activity.getPhoto2Content() != null && activity.getPhoto2Content().length > 0) {
                                html.append("                    <img src=\"/VJNT_Class_Managment/other-activity-image-db?id=").append(activity.getActivityId()).append("&photo=2\" alt=\"Activity Photo\" class=\"activity-image\" onclick=\"viewImageFullScreen(this.src)\" style=\"cursor: pointer;\">\n");
                            }
                            html.append("                </div>\n");
                        }
                        
                        if (activity.getDescription() != null && !activity.getDescription().isEmpty()) {
                            html.append("                <div class=\"activity-info\"><label>Description</label><p>").append(escapeHtml(activity.getDescription())).append("</p></div>\n");
                        }
                        if (activity.getGuestsPresent() != null && !activity.getGuestsPresent().isEmpty()) {
                            html.append("                <div class=\"activity-info\"><label>Guests/Visitors</label><p>👥 ").append(escapeHtml(activity.getGuestsPresent())).append("</p></div>\n");
                        }
                        if (activity.getVideoLink() != null && !activity.getVideoLink().isEmpty()) {
                            html.append("                <div class=\"activity-info\"><a href=\"").append(escapeHtml(activity.getVideoLink())).append("\" target=\"_blank\" class=\"activity-link\">▶ Watch Video</a></div>\n");
                        }
                        html.append("            </div>\n");
                    }
                }
                html.append("        </div>\n");
            }
        } else {
            html.append("        <div class=\"section\" style=\"text-align: center; color: #999;\">\n");
            html.append("            <p>❌ School not found. Please check the UDISE number.</p>\n");
            html.append("        </div>\n");
        }
        
        html.append("    </div>\n");
        html.append("    <footer>\n");
        html.append("        <p>&copy; 2026 VJNT Class Management System. All rights reserved.</p>\n");
        html.append("    </footer>\n");
        html.append("    <script>\n");
        html.append("        function viewImageFullScreen(src) {\n");
        html.append("            const modal = document.createElement('div');\n");
        html.append("            modal.style.cssText = 'position:fixed;top:0;left:0;right:0;bottom:0;background:rgba(0,0,0,0.95);display:flex;align-items:center;justify-content:center;z-index:1000;cursor:pointer;';\n");
        html.append("            const img = document.createElement('img');\n");
        html.append("            img.src = src;\n");
        html.append("            img.style.cssText = 'max-width:90vw;max-height:90vh;object-fit:contain;';\n");
        html.append("            modal.appendChild(img);\n");
        html.append("            modal.onclick = () => modal.remove();\n");
        html.append("            document.body.appendChild(modal);\n");
        html.append("        }\n");
        html.append("    </script>\n");
        html.append("</body>\n");
        html.append("</html>\n");
        
        return html.toString();
    }
    
    private String returnErrorPage(String errorTitle, String errorMessage, String errorDetails) {
        StringBuilder html = new StringBuilder();
        
        html.append("<!DOCTYPE html>\n");
        html.append("<html lang=\"en\">\n");
        html.append("<head>\n");
        html.append("    <meta charset=\"UTF-8\">\n");
        html.append("    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n");
        html.append("    <title>Error - School Information Portal</title>\n");
        html.append("    <style>\n");
        html.append("        * { margin: 0; padding: 0; box-sizing: border-box; }\n");
        html.append("        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: #f5f5f5; color: #333; }\n");
        html.append("        header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 1rem 0; position: sticky; top: 0; box-shadow: 0 2px 10px rgba(0,0,0,0.1); z-index: 100; }\n");
        html.append("        .header-content { max-width: 1200px; margin: 0 auto; padding: 0 20px; display: flex; justify-content: space-between; align-items: center; }\n");
        html.append("        .logo { font-size: 1.5rem; font-weight: bold; }\n");
        html.append("        nav a { color: white; margin-left: 2rem; text-decoration: none; transition: opacity 0.3s; }\n");
        html.append("        nav a:hover { opacity: 0.8; }\n");
        html.append("        .hero { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 3rem 20px; text-align: center; }\n");
        html.append("        .hero h1 { font-size: 2.5rem; margin-bottom: 1rem; }\n");
        html.append("        .hero p { font-size: 1.1rem; opacity: 0.9; }\n");
        html.append("        .container { max-width: 1200px; margin: 0 auto; padding: 0 20px; }\n");
        html.append("        .error-container { background: white; margin: 3rem 0; padding: 3rem; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.05); text-align: center; }\n");
        html.append("        .error-icon { font-size: 4rem; margin-bottom: 1rem; }\n");
        html.append("        .error-title { font-size: 2rem; color: #d32f2f; margin-bottom: 1rem; font-weight: bold; }\n");
        html.append("        .error-message { font-size: 1.1rem; color: #666; margin-bottom: 1rem; line-height: 1.6; }\n");
        html.append("        .error-details { font-size: 0.95rem; color: #999; margin-bottom: 2rem; line-height: 1.6; padding: 1.5rem; background: #f9f9f9; border-left: 4px solid #d32f2f; border-radius: 5px; text-align: left; display: inline-block; }\n");
        html.append("        .error-actions { margin-top: 2rem; }\n");
        html.append("        .btn { display: inline-block; margin: 0.5rem; padding: 0.75rem 1.5rem; background: #667eea; color: white; text-decoration: none; border-radius: 5px; transition: background 0.3s; }\n");
        html.append("        .btn:hover { background: #764ba2; }\n");
        html.append("        .btn-secondary { background: #666; }\n");
        html.append("        .btn-secondary:hover { background: #555; }\n");
        html.append("        footer { background: #333; color: white; text-align: center; padding: 2rem; margin-top: 3rem; }\n");
        html.append("    </style>\n");
        html.append("</head>\n");
        html.append("<body>\n");
        html.append("    <header>\n");
        html.append("        <div class=\"header-content\">\n");
        html.append("            <div class=\"logo\">🏫 School Info</div>\n");
        html.append("            <nav>\n");
        html.append("                <a href=\"/VJNT_Class_Managment/\">Home</a>\n");
        html.append("            </nav>\n");
        html.append("        </div>\n");
        html.append("    </header>\n");
        html.append("    <div class=\"hero\">\n");
        html.append("        <h1>School Information Portal</h1>\n");
        html.append("        <p>Find details about your school</p>\n");
        html.append("    </div>\n");
        html.append("    <div class=\"container\">\n");
        html.append("        <div class=\"error-container\">\n");
        html.append("            <div class=\"error-icon\">⚠️</div>\n");
        html.append("            <div class=\"error-title\">").append(escapeHtml(errorTitle)).append("</div>\n");
        html.append("            <div class=\"error-message\">").append(escapeHtml(errorMessage)).append("</div>\n");
        html.append("            <div class=\"error-details\">").append(escapeHtml(errorDetails)).append("</div>\n");
        html.append("            <div class=\"error-actions\">\n");
        html.append("                <button class=\"btn\" onclick=\"window.history.back()\">← Go Back</button>\n");
        html.append("                <a href=\"/VJNT_Class_Managment/\" class=\"btn btn-secondary\">🏠 Home</a>\n");
        html.append("            </div>\n");
        html.append("        </div>\n");
        html.append("    </div>\n");
        html.append("    <footer>\n");
        html.append("        <p>&copy; 2026 VJNT Class Management System. All rights reserved.</p>\n");
        html.append("    </footer>\n");
        html.append("</body>\n");
        html.append("</html>\n");
        
        return html.toString();
    }
    
    private String escapeJavaScript(String text) {
        if (text == null) return "";
        return text.replace("\\", "\\\\").replace("'", "\\'").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
    
    private String escapeHtml(String text) {
        if (text == null) return "";
        return text.replace("&", "&amp;")
                   .replace("<", "&lt;")
                   .replace(">", "&gt;")
                   .replace("\"", "&quot;")
                   .replace("'", "&#39;");
    }
}
