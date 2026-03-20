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
import java.util.List;

/**
 * API servlet to get school data in JSON format
 * Supports public access without authentication
 */
@WebServlet("/api/school-lookup")
public class SchoolLookupApiServlet extends HttpServlet {
    
    private SchoolDAO schoolDAO = new SchoolDAO();
    private SchoolContactDAO contactDAO = new SchoolContactDAO();
    private PalakMelavaDAO melavaDAO = new PalakMelavaDAO();
    private OtherSchoolActivityDAO activityDAO = new OtherSchoolActivityDAO();
    private Gson gson = new Gson();
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        String udiseNo = request.getParameter("udise");
        
        response.setContentType("application/json; charset=UTF-8");
        PrintWriter out = response.getWriter();
        
        if (udiseNo == null || udiseNo.trim().isEmpty()) {
            JsonObject errorResponse = new JsonObject();
            errorResponse.addProperty("error", "UDISE number is required");
            out.println(errorResponse.toString());
            return;
        }
        
        try {
            School school = schoolDAO.getSchoolByUdise(udiseNo);
            
            if (school == null) {
                JsonObject errorResponse = new JsonObject();
                errorResponse.addProperty("error", "School not found");
                out.println(errorResponse.toString());
                return;
            }
            
            JsonObject response_data = new JsonObject();
            
            // Add school details
            JsonObject schoolObj = new JsonObject();
            schoolObj.addProperty("schoolId", school.getSchoolId());
            schoolObj.addProperty("schoolName", school.getSchoolName() != null ? school.getSchoolName() : "");
            schoolObj.addProperty("udiseNo", school.getUdiseNo() != null ? school.getUdiseNo() : "");
            schoolObj.addProperty("district", school.getDistrictName() != null ? school.getDistrictName() : "");
            response_data.add("school", schoolObj);
            
            // Add school contacts
            JsonArray contactsArray = new JsonArray();
            try {
                List<SchoolContact> contacts = contactDAO.getContactsByUdise(school.getUdiseNo());
                if (contacts != null) {
                    for (SchoolContact contact : contacts) {
                        JsonObject contactObj = new JsonObject();
                        contactObj.addProperty("name", contact.getFullName() != null ? contact.getFullName() : "");
                        contactObj.addProperty("contactType", contact.getContactType() != null ? contact.getContactType() : "");
                        contactObj.addProperty("mobileNo", contact.getMobile() != null ? contact.getMobile() : "");
                        contactObj.addProperty("whatsappNo", contact.getWhatsappNumber() != null ? contact.getWhatsappNumber() : "");
                        contactsArray.add(contactObj);
                    }
                }
            } catch (Exception e) {
                System.err.println("Error fetching contacts: " + e.getMessage());
            }
            response_data.add("contacts", contactsArray);
            
            // Add Palak Melava data
            JsonArray melavasArray = new JsonArray();
            try {
                List<PalakMelava> melavas = melavaDAO.getByUdise(school.getUdiseNo());
                if (melavas != null) {
                    for (PalakMelava melava : melavas) {
                        // Only show APPROVED melavas
                        if ("APPROVED".equals(melava.getStatus())) {
                            JsonObject melavaObj = new JsonObject();
                            melavaObj.addProperty("melavaId", melava.getMelavaId());
                            melavaObj.addProperty("meetingDate", melava.getMeetingDate() != null ? melava.getMeetingDate().toString() : "");
                            melavaObj.addProperty("chiefAttendeeInfo", melava.getChiefAttendeeInfo() != null ? melava.getChiefAttendeeInfo() : "");
                            melavaObj.addProperty("totalParentsAttended", melava.getTotalParentsAttended() != null ? melava.getTotalParentsAttended() : "");
                            melavaObj.addProperty("hasPhoto1", melava.getPhoto1Content() != null && melava.getPhoto1Content().length > 0);
                            melavaObj.addProperty("hasPhoto2", melava.getPhoto2Content() != null && melava.getPhoto2Content().length > 0);
                            melavasArray.add(melavaObj);
                        }
                    }
                }
            } catch (Exception e) {
                System.err.println("Error fetching Palak Melava: " + e.getMessage());
            }
            response_data.add("melavas", melavasArray);
            
            // Add activities data
            JsonArray activitiesArray = new JsonArray();
            try {
                List<OtherSchoolActivity> activities = activityDAO.getByUdise(school.getUdiseNo());
                if (activities != null) {
                    for (OtherSchoolActivity activity : activities) {
                        // Only show APPROVED activities
                        if ("APPROVED".equals(activity.getApprovalStatus())) {
                            JsonObject activityObj = new JsonObject();
                            activityObj.addProperty("activityId", activity.getActivityId());
                            activityObj.addProperty("activitySubject", activity.getActivitySubject() != null ? activity.getActivitySubject() : "");
                            activityObj.addProperty("activityDate", activity.getActivityDate() != null ? activity.getActivityDate().toString() : "");
                            activityObj.addProperty("description", activity.getDescription() != null ? activity.getDescription() : "");
                            activityObj.addProperty("guestsPresent", activity.getGuestsPresent() != null ? activity.getGuestsPresent() : "");
                            activityObj.addProperty("videoLink", activity.getVideoLink() != null ? activity.getVideoLink() : "");
                            activityObj.addProperty("hasPhoto1", activity.getPhoto1Content() != null && activity.getPhoto1Content().length > 0);
                            activityObj.addProperty("hasPhoto2", activity.getPhoto2Content() != null && activity.getPhoto2Content().length > 0);
                            activitiesArray.add(activityObj);
                        }
                    }
                }
            } catch (Exception e) {
                System.err.println("Error fetching activities: " + e.getMessage());
            }
            response_data.add("activities", activitiesArray);
            
            out.println(response_data.toString());
            
        } catch (Exception e) {
            System.err.println("Error fetching school data: " + e.getMessage());
            e.printStackTrace();
            
            JsonObject errorResponse = new JsonObject();
            errorResponse.addProperty("error", "Error fetching school data");
            out.println(errorResponse.toString());
        }
        
        out.flush();
    }
}
