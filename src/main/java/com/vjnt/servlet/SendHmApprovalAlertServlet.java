package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.WhatsAppService;
import com.vjnt.util.WhatsAppService.WhatsAppResponse;

/**
 * Sends the hm_approval_alert WhatsApp template to school contacts
 * (Head Master / School Coordinator) from the Division dashboard.
 *
 * Template (Marathi):
 *   नमस्कार {{1}}, शाळा UDISE {{2}} — {{3}} कृपया GATEE Portal वर लॉग इन करून
 *   शाळा समन्वयक यांनी पोर्टल वर भरलेली माहिती तपासून पुढील कार्यवाही तात्काळ करावी.
 *
 *   {{1}} = contact full name, {{2}} = UDISE number, {{3}} = school name
 *
 * POST parameters:
 *   contactId - send to one specific contact, OR
 *   udise     - send to all Head Master + School Coordinator contacts of the school
 */
@WebServlet("/send-hm-approval-alert")
public class SendHmApprovalAlertServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    private static final String TEMPLATE_NAME = com.vjnt.util.WhatsAppConfig.TPL_HM_APPROVAL;
    private static final String TEMPLATE_LANG = com.vjnt.util.WhatsAppConfig.LANG_HM_APPROVAL;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        HttpSession session = request.getSession(false);
        if (session == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Session expired\"}");
            return;
        }

        User user = (User) session.getAttribute("user");
        if (user == null || (!user.getUserType().equals(User.UserType.DIVISION)
                && !user.getUserType().equals(User.UserType.SUPER_DIVISION_OFFICER))) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            out.print("{\"error\": \"Unauthorized access\"}");
            return;
        }

        String contactIdParam = request.getParameter("contactId");
        String udise = request.getParameter("udise");

        if ((contactIdParam == null || contactIdParam.trim().isEmpty())
                && (udise == null || udise.trim().isEmpty())) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            out.print("{\"error\": \"Parameter 'contactId' or 'udise' is required\"}");
            return;
        }

        String divisionName = user.getUserType() == User.UserType.SUPER_DIVISION_OFFICER
                ? null : user.getDivisionName();

        JSONObject result = sendAlerts(divisionName, contactIdParam, udise);
        out.print(result.toString());
        out.flush();
    }

    private JSONObject sendAlerts(String divisionName, String contactIdParam, String udise) {
        JSONObject result = new JSONObject();
        List<JSONObject> contacts = new ArrayList<>();

        try (Connection conn = DatabaseConnection.getConnection()) {

            StringBuilder sql = new StringBuilder(
                    "SELECT contact_id, udise_no, school_name, district_name, contact_type, "
                    + "full_name, mobile, whatsapp_number FROM school_contacts WHERE ");
            if (contactIdParam != null && !contactIdParam.trim().isEmpty()) {
                sql.append("contact_id = ?");
            } else {
                sql.append("udise_no = ? AND contact_type IN ('Head Master', 'School Coordinator')");
            }

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                if (contactIdParam != null && !contactIdParam.trim().isEmpty()) {
                    ps.setInt(1, Integer.parseInt(contactIdParam.trim()));
                } else {
                    ps.setString(1, udise.trim());
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        JSONObject c = new JSONObject();
                        c.put("contactId", rs.getInt("contact_id"));
                        c.put("udiseNo", rs.getString("udise_no"));
                        c.put("schoolName", rs.getString("school_name"));
                        c.put("districtName", rs.getString("district_name"));
                        c.put("contactType", rs.getString("contact_type"));
                        c.put("fullName", rs.getString("full_name"));
                        c.put("mobile", rs.getString("mobile"));
                        c.put("whatsappNumber", rs.getString("whatsapp_number"));
                        contacts.add(c);
                    }
                }
            }

            if (contacts.isEmpty()) {
                result.put("error", "No matching school contact found");
                return result;
            }

            // Division users may only alert schools whose district belongs to their division
            if (divisionName != null) {
                String verifySQL = "SELECT COUNT(*) as count FROM users WHERE division_name = ? "
                        + "AND district_name = ? AND user_type IN ('DISTRICT_COORDINATOR', 'DISTRICT_2ND_COORDINATOR')";
                for (JSONObject c : contacts) {
                    try (PreparedStatement verifyPs = conn.prepareStatement(verifySQL)) {
                        verifyPs.setString(1, divisionName);
                        verifyPs.setString(2, c.optString("districtName", ""));
                        try (ResultSet verifyRs = verifyPs.executeQuery()) {
                            if (!verifyRs.next() || verifyRs.getInt("count") == 0) {
                                result.put("error", "School does not belong to this division");
                                return result;
                            }
                        }
                    }
                }
            }

        } catch (SQLException e) {
            e.printStackTrace();
            result.put("error", e.getMessage());
            return result;
        } catch (NumberFormatException e) {
            result.put("error", "Invalid contactId");
            return result;
        }

        // Send the template message to each contact
        WhatsAppService wa = WhatsAppService.getInstance();
        JSONArray results = new JSONArray();
        int sent = 0;
        int failed = 0;

        for (JSONObject c : contacts) {
            JSONObject r = new JSONObject();
            r.put("contactId", c.getInt("contactId"));
            r.put("fullName", c.optString("fullName", ""));
            r.put("contactType", c.optString("contactType", ""));

            String number = c.optString("whatsappNumber", "");
            if (number == null || number.trim().isEmpty() || "null".equals(number)) {
                number = c.optString("mobile", "");
            }
            if (number == null || number.trim().isEmpty() || "null".equals(number)) {
                r.put("success", false);
                r.put("error", "No WhatsApp/mobile number available");
                failed++;
                results.put(r);
                continue;
            }
            r.put("number", WhatsAppService.normalizeNumber(number));

            String[] params = new String[] {
                    c.optString("fullName", ""),   // {{1}} name
                    c.optString("udiseNo", ""),    // {{2}} UDISE
                    c.optString("schoolName", "")  // {{3}} school name
            };

            WhatsAppResponse waResponse = wa.sendTemplateMessage(number, TEMPLATE_NAME, TEMPLATE_LANG, params);
            r.put("success", waResponse.isSuccess());
            if (waResponse.isSuccess()) {
                sent++;
                String messageId = waResponse.getMessageId();
                r.put("messageId", messageId == null ? JSONObject.NULL : messageId);
            } else {
                failed++;
                r.put("error", waResponse.getBody());
            }
            results.put(r);
        }

        result.put("success", failed == 0);
        result.put("sent", sent);
        result.put("failed", failed);
        result.put("results", results);
        return result;
    }
}
