package com.vjnt.servlet;

import com.vjnt.dao.UserDAO;
import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.TeacherLoginNotifier;
import org.json.JSONObject;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.util.concurrent.ConcurrentHashMap;

/**
 * "Forgot Password" for the Teacher login.
 *
 * The teacher types their username on login.jsp and asks for it to be sent to
 * WhatsApp. We look the account up, and if it is an active TEACHER with a mobile
 * on file we WhatsApp the current credentials to that number — same message and
 * template as {@link TeacherLoginNotifier} uses on login creation / password
 * change. Passwords are stored in plain text in this app (see PasswordUtil), so
 * the actual password is sent, not a reset link.
 *
 * Restricted to TEACHER on purpose: other roles (division / district / admin)
 * do not self-serve password recovery over WhatsApp.
 */
@WebServlet("/teacher-forgot-password")
public class TeacherForgotPasswordServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    /** Per-username cooldown so the same number cannot be spammed. */
    private static final long COOLDOWN_MS = 60_000L;
    private static final ConcurrentHashMap<String, Long> LAST_SENT = new ConcurrentHashMap<>();

    private final UserDAO userDAO = new UserDAO();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        JSONObject result = new JSONObject();

        String username = request.getParameter("username");
        username = username == null ? "" : username.trim();

        if (username.isEmpty()) {
            result.put("success", false);
            result.put("message", "कृपया तुमचे युजरनेम टाका.");
            out.print(result.toString());
            return;
        }

        try {
            User user = userDAO.findByUsername(username);

            boolean eligible = user != null
                    && user.getUserType() == User.UserType.TEACHER
                    && user.isActive();

            String mobile = user != null && user.getMobile() != null && !user.getMobile().trim().isEmpty()
                    ? user.getMobile().trim()
                    : (user != null ? user.getUsername() : null); // teacher username == mobile

            if (!eligible || mobile == null || mobile.trim().isEmpty()) {
                // Deliberately specific — this is an internal portal and a teacher
                // who mistyped needs to know, not be left guessing.
                result.put("success", false);
                result.put("message", "या युजरनेमसाठी सक्रिय शिक्षक खाते किंवा नोंदणीकृत मोबाईल क्रमांक सापडला नाही. कृपया शाळा समन्वयकाशी संपर्क साधा.");
                out.print(result.toString());
                return;
            }

            long now = System.currentTimeMillis();
            Long last = LAST_SENT.get(username.toLowerCase());
            if (last != null && now - last < COOLDOWN_MS) {
                result.put("success", false);
                result.put("message", "पासवर्ड नुकताच पाठवला आहे. कृपया एक मिनिटानंतर पुन्हा प्रयत्न करा.");
                out.print(result.toString());
                return;
            }

            try (Connection conn = DatabaseConnection.getConnection()) {
                TeacherLoginNotifier.sendCredentials(conn, mobile, user.getFullName(),
                        user.getUdiseNo(), user.getUsername(), user.getPassword());
            }
            LAST_SENT.put(username.toLowerCase(), now);

            String masked = maskMobile(mobile);
            result.put("success", true);
            result.put("message", "तुमचा पासवर्ड WhatsApp वर " + masked + " या क्रमांकावर पाठवला आहे.");
        } catch (Exception e) {
            e.printStackTrace();
            result.put("success", false);
            result.put("message", "विनंती प्रक्रिया करताना त्रुटी आली. कृपया पुन्हा प्रयत्न करा.");
        }

        out.print(result.toString());
    }

    private static String maskMobile(String m) {
        String d = m.replaceAll("[^0-9]", "");
        if (d.length() >= 10) {
            String last10 = d.substring(d.length() - 10);
            return "XXXXXX" + last10.substring(6);
        }
        return "XXXX";
    }
}
