package com.vjnt.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.text.SimpleDateFormat;
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
import com.vjnt.model.User.UserType;

/**
 * GATEE Portal Assistant Chatbot
 *
 * Rule-based helpdesk chatbot available to every logged-in user.
 * Answers are personalized using the session User object and the
 * user's role (UserType), and include direct links to portal pages.
 *
 * GET  /chatbot  -> welcome message + role-specific suggestions
 * POST /chatbot  -> param "message", returns JSON {reply, links[], suggestions[]}
 */
@WebServlet("/chatbot")
public class ChatbotServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getSessionUser(request, response);
        if (user == null) return;

        JSONObject json = new JSONObject();
        json.put("reply", "नमस्कार " + displayName(user) + "! 🙏\n"
                + "I am the GATEE Portal Assistant. I can help you use the portal, "
                + "find the right page, and answer common questions.\n"
                + "How can I help you today?");
        json.put("suggestions", new JSONArray(roleSuggestions(user.getUserType())));
        json.put("links", new JSONArray());
        writeJson(response, json);
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        User user = getSessionUser(request, response);
        if (user == null) return;

        String message = request.getParameter("message");
        if (message == null) message = "";
        message = message.trim().toLowerCase();

        String ctx = request.getContextPath();
        JSONObject json = buildReply(message, user, ctx);
        writeJson(response, json);
    }

    // ==================== Core reply logic ====================

    private JSONObject buildReply(String msg, User user, String ctx) {
        UserType type = user.getUserType();
        List<String[]> links = new ArrayList<String[]>();
        String reply;

        if (msg.isEmpty()) {
            reply = "Please type a question, or tap one of the suggestions below.";

        } else if (matches(msg, "hi", "hello", "hey", "namaskar", "namaste", "good morning", "good afternoon", "good evening")) {
            reply = "नमस्कार " + displayName(user) + "! 🙏 How can I help you with the GATEE Portal today?";

        } else if (matches(msg, "my info", "my profile", "who am i", "my details", "my account", "profile")) {
            reply = buildUserInfo(user);

        } else if (matches(msg, "password", "change password", "forgot password", "reset password")) {
            reply = "To change your password:\n"
                  + "1. Open the Change Password page.\n"
                  + "2. Enter your current password, then your new password twice.\n"
                  + "3. Click Save. You will use the new password from your next login.\n"
                  + "If your account is locked after failed attempts, please contact your coordinator or raise a support ticket.";
            links.add(new String[]{"🔑 Change Password", ctx + "/change-password"});

        } else if (matches(msg, "ticket", "support", "complaint", "issue", "problem", "not working", "error", "madat", "help desk", "helpdesk")) {
            reply = "If something is not working or you need help from the support team, "
                  + "please raise a support ticket. Describe the problem and the page where it happens — "
                  + "the team will respond on your registered contact details.";
            links.add(new String[]{"🎫 Raise a Ticket", ctx + "/raise-ticket.jsp"});
            links.add(new String[]{"📞 Helpdesk", ctx + "/helpdesk.jsp"});

        } else if (matches(msg, "logout", "sign out", "log out")) {
            reply = "Click the button below to safely log out of the GATEE Portal.";
            links.add(new String[]{"🚪 Logout", ctx + "/logout"});

        } else if (matches(msg, "about", "gatee", "what is this portal", "portal info")) {
            reply = "GATEE PORTAL is the class management system for the VJNT school program in Maharashtra. "
                  + "It is used by Division officers, District coordinators, School coordinators, Head Masters, "
                  + "Teachers and Data Admins to manage students, track learning levels and phases, "
                  + "approve reports, and view analytics.";

        } else if (matches(msg, "dashboard", "home", "main page")) {
            reply = "Your dashboard shows the summary and actions available for your role ("
                  + roleLabel(type) + "). Use the button below to go back to it.";
            links.add(new String[]{"🏠 My Dashboard", ctx + dashboardUrl(type)});

        } else {
            JSONObject roleAnswer = roleReply(msg, type, ctx, links);
            if (roleAnswer != null) {
                reply = roleAnswer.getString("reply");
            } else {
                reply = "Sorry, I don't have an answer for that yet. 🙏\n"
                      + "You can try one of the suggestions below, or raise a support ticket "
                      + "and the team will help you directly.";
                links.add(new String[]{"🎫 Raise a Ticket", ctx + "/raise-ticket.jsp"});
            }
        }

        JSONObject json = new JSONObject();
        json.put("reply", reply);
        json.put("links", toLinkArray(links));
        json.put("suggestions", new JSONArray(roleSuggestions(type)));
        return json;
    }

    /**
     * Role-specific FAQ answers. Returns null when no role intent matches.
     */
    private JSONObject roleReply(String msg, UserType type, String ctx, List<String[]> links) {
        String reply = null;

        switch (type) {
            case TEACHER:
                if (matches(msg, "activity", "mark activity", "student activity", "daily activity")) {
                    reply = "To record student activities, open the Student Activity page, "
                          + "select the class and subject assigned to you, then mark each student's activity for the day.";
                    links.add(new String[]{"📝 Student Activity", ctx + "/student-activity.jsp"});
                } else if (matches(msg, "level", "student level", "levels")) {
                    reply = "Student levels (1 to 4) show learning progress per subject. "
                          + "You can update a student's level from the Student Activity page while marking activities. "
                          + "Level changes are tracked and visible to your Head Master and coordinators.";
                    links.add(new String[]{"📝 Student Activity", ctx + "/student-activity.jsp"});
                } else if (matches(msg, "phase", "phase status")) {
                    reply = "Phases group the program into stages. Once you complete a phase for your class, "
                          + "it goes to the Head Master for approval. You can check the current status on the Phase Status page.";
                    links.add(new String[]{"📊 Phase Status", ctx + "/phase-status.jsp"});
                } else if (matches(msg, "report", "report card", "student report")) {
                    reply = "Student report cards are generated from recorded activities and levels. "
                          + "You can request and track reports from the My Report Requests page.";
                    links.add(new String[]{"📄 My Report Requests", ctx + "/my-report-requests.jsp"});
                }
                break;

            case HEAD_MASTER:
            case SCHOOL_COORDINATOR:
                if (matches(msg, "approve", "approval", "phase approval", "pending approval")) {
                    reply = "Pending phase completions from teachers appear on the Phase Approvals page. "
                          + "Review each phase and approve or send it back. Approved phases move the class to the next stage.";
                    links.add(new String[]{"✅ Phase Approvals", ctx + "/headmaster-approve-phase.jsp"});
                    links.add(new String[]{"📄 Report Approvals", ctx + "/pending-report-approvals.jsp"});
                } else if (matches(msg, "student", "add student", "manage student")) {
                    reply = "You can add new students, edit details, and view records from the Manage Students page. "
                          + "Make sure each student is placed in the correct class and section.";
                    links.add(new String[]{"👨‍🎓 Manage Students", ctx + "/manage-students.jsp"});
                } else if (matches(msg, "teacher", "add teacher", "assign teacher", "manage teacher")) {
                    reply = "Use Manage Teachers to add teachers and Assign Teacher to map them to classes and subjects. "
                          + "Teachers only see the students of the subjects assigned to them.";
                    links.add(new String[]{"👩‍🏫 Manage Teachers", ctx + "/manage-teachers.jsp"});
                    links.add(new String[]{"📋 Assign Teacher", ctx + "/assign-teacher.jsp"});
                } else if (matches(msg, "palak", "melava", "palak melava")) {
                    reply = "Palak Melava (parents' meet) details and photos are submitted from the Palak Melava page "
                          + "and reviewed by your district. You can check submission status any time.";
                    links.add(new String[]{"👪 Palak Melava", ctx + "/palak-melava.jsp"});
                    links.add(new String[]{"📷 Melava Status", ctx + "/palak-melava-status.jsp"});
                } else if (matches(msg, "promote", "promotion", "next class")) {
                    reply = "At the end of the academic year, use Promote Classes to move students to the next class. "
                          + "Please review the list carefully before confirming — promotions are audited.";
                    links.add(new String[]{"🎓 Promote Classes", ctx + "/promote-classes.jsp"});
                }
                break;

            case DISTRICT_COORDINATOR:
            case DISTRICT_2ND_COORDINATOR:
                if (matches(msg, "credential", "login", "school login", "user id")) {
                    reply = "School and teacher login credentials for your district are available on the "
                          + "District Credentials page. Share them securely with the schools.";
                    links.add(new String[]{"🔐 District Credentials", ctx + "/district-credentials.jsp"});
                } else if (matches(msg, "teacher", "assignment", "teacher assignment")) {
                    reply = "The Teacher Assignments page shows which teachers are mapped to which schools, "
                          + "classes and subjects across your district.";
                    links.add(new String[]{"📋 Teacher Assignments", ctx + "/district-teacher-assignments.jsp"});
                } else if (matches(msg, "report", "analysis", "analytics", "progress")) {
                    reply = "District-level activity analysis, teacher reports and student level jumps "
                          + "are available from your district dashboard pages.";
                    links.add(new String[]{"📊 Activity Analysis", ctx + "/district-activity-analysis.jsp"});
                    links.add(new String[]{"📈 Teacher Report", ctx + "/district-teacher-report.jsp"});
                } else if (matches(msg, "school", "contact", "school contact")) {
                    reply = "School contact details for your district are on the School Contacts page.";
                    links.add(new String[]{"🏫 School Contacts", ctx + "/school-contacts.jsp"});
                }
                break;

            case DIVISION:
            case SUPER_DIVISION_OFFICER:
                if (matches(msg, "analytics", "report", "statistics", "analysis", "progress")) {
                    reply = "Division-wide analytics — phase statistics, student level distribution and "
                          + "teacher progress — are available from your analytics dashboard.";
                    links.add(new String[]{"📊 Analytics Dashboard", ctx + "/division-analytics-dashboard.jsp"});
                    links.add(new String[]{"📈 Phase Statistics", ctx + "/division-phase-wise-statistics.jsp"});
                } else if (matches(msg, "ticket", "tickets")) {
                    reply = "Support tickets raised by schools and coordinators in your division "
                          + "are listed on the Division Tickets page.";
                    links.add(new String[]{"🎫 Division Tickets", ctx + "/division-tickets.jsp"});
                } else if (matches(msg, "district", "districts", "compare")) {
                    reply = "You can compare districts and view district-wise details from the "
                          + "division dashboard and phase comparison pages.";
                    links.add(new String[]{"🗺️ Phase Comparison", ctx + "/division-phase-comparison.jsp"});
                }
                break;

            case DATA_ADMIN:
                if (matches(msg, "upload", "excel", "school upload", "import")) {
                    reply = "Bulk school data can be imported from the Upload Schools page using the Excel template. "
                          + "Verify the file format before uploading.";
                    links.add(new String[]{"📤 Upload Schools", ctx + "/upload-schools.jsp"});
                } else if (matches(msg, "user", "manage user", "create user", "credential")) {
                    reply = "You can create and manage portal users from the Manage Users page, "
                          + "and view all credentials from All Users Credentials.";
                    links.add(new String[]{"👥 Manage Users", ctx + "/manage-users.jsp"});
                    links.add(new String[]{"🔐 All Credentials", ctx + "/all-users-credentials.jsp"});
                }
                break;

            default:
                break;
        }

        if (reply == null) return null;
        JSONObject o = new JSONObject();
        o.put("reply", reply);
        return o;
    }

    // ==================== Helpers ====================

    private String buildUserInfo(User user) {
        SimpleDateFormat fmt = new SimpleDateFormat("dd-MM-yyyy hh:mm a");
        StringBuilder sb = new StringBuilder();
        sb.append("Here are your account details:\n");
        sb.append("👤 Name: ").append(displayName(user)).append("\n");
        sb.append("🆔 Username: ").append(user.getUsername()).append("\n");
        sb.append("🏷️ Role: ").append(roleLabel(user.getUserType()));
        if (user.getDivisionName() != null && !user.getDivisionName().isEmpty()) {
            sb.append("\n🗺️ Division: ").append(user.getDivisionName());
        }
        if (user.getDistrictName() != null && !user.getDistrictName().isEmpty()) {
            sb.append("\n📍 District: ").append(user.getDistrictName());
        }
        if (user.getUdiseNo() != null && !user.getUdiseNo().isEmpty()) {
            sb.append("\n🏫 UDISE No: ").append(user.getUdiseNo());
        }
        if (user.getLastLoginDate() != null) {
            sb.append("\n🕒 Last Login: ").append(fmt.format(user.getLastLoginDate()));
        }
        return sb.toString();
    }

    private List<String> roleSuggestions(UserType type) {
        List<String> s = new ArrayList<String>();
        s.add("My info");
        switch (type) {
            case TEACHER:
                s.add("How to mark student activity?");
                s.add("How to update student levels?");
                s.add("Phase status");
                break;
            case HEAD_MASTER:
            case SCHOOL_COORDINATOR:
                s.add("Pending phase approvals");
                s.add("How to add students?");
                s.add("Palak Melava");
                break;
            case DISTRICT_COORDINATOR:
            case DISTRICT_2ND_COORDINATOR:
                s.add("School credentials");
                s.add("Teacher assignments");
                s.add("District reports");
                break;
            case DIVISION:
            case SUPER_DIVISION_OFFICER:
                s.add("Division analytics");
                s.add("View tickets");
                s.add("Compare districts");
                break;
            case DATA_ADMIN:
                s.add("Upload schools");
                s.add("Manage users");
                break;
            default:
                break;
        }
        s.add("Change password");
        s.add("Raise a ticket");
        return s;
    }

    private String dashboardUrl(UserType type) {
        switch (type) {
            case DIVISION:                 return "/division-dashboard.jsp";
            case SUPER_DIVISION_OFFICER:   return "/super-officer-dashboard.jsp";
            case DISTRICT_COORDINATOR:
            case DISTRICT_2ND_COORDINATOR: return "/district-dashboard.jsp";
            case SCHOOL_COORDINATOR:
            case HEAD_MASTER:              return "/school-dashboard-enhanced.jsp";
            case DATA_ADMIN:               return "/data-admin-dashboard.jsp";
            case TEACHER:                  return "/teacher-dashboard.jsp";
            default:                       return "/dashboard.jsp";
        }
    }

    private String roleLabel(UserType type) {
        return type.name().replace("_", " ");
    }

    private String displayName(User user) {
        return (user.getFullName() != null && !user.getFullName().isEmpty())
                ? user.getFullName() : user.getUsername();
    }

    private boolean matches(String msg, String... keywords) {
        for (String k : keywords) {
            if (msg.contains(k)) return true;
        }
        return false;
    }

    private JSONArray toLinkArray(List<String[]> links) {
        JSONArray arr = new JSONArray();
        for (String[] l : links) {
            JSONObject o = new JSONObject();
            o.put("label", l[0]);
            o.put("url", l[1]);
            arr.put(o);
        }
        return arr;
    }

    private User getSessionUser(HttpServletRequest request, HttpServletResponse response) throws IOException {
        HttpSession session = request.getSession(false);
        User user = (session != null) ? (User) session.getAttribute("user") : null;
        if (user == null) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            response.setContentType("application/json");
            response.setCharacterEncoding("UTF-8");
            response.getWriter().write("{\"error\":\"Not logged in\"}");
        }
        return user;
    }

    private void writeJson(HttpServletResponse response, JSONObject json) throws IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();
        out.write(json.toString());
        out.flush();
    }
}
