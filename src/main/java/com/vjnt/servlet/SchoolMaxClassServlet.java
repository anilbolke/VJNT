package com.vjnt.servlet;

import com.vjnt.model.User;
import com.vjnt.util.DatabaseConnection;
import com.vjnt.util.PromotionClassRules;
import org.json.JSONArray;
import org.json.JSONObject;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;

/**
 * Manage schools.max_class — each school's terminal (last) class.
 *
 * This is what stops the terminal-class bug recurring. Promotion graduates whatever class a
 * school ends at; with max_class NULL that is derived from the highest class the school
 * currently has students in, which is right most of the time but wrong for a school that runs
 * to IX and happens to have no IX students this year. Setting max_class pins it down.
 *
 *   GET  /school-max-class?search=&onlyUnset=            -> list schools with stored vs derived
 *   POST /school-max-class  action=set    udise= maxClass=
 *   POST /school-max-class  action=clear  udise=
 *   POST /school-max-class  action=seedAll                -> fill every NULL from derived
 */
@WebServlet("/school-max-class")
public class SchoolMaxClassServlet extends HttpServlet {

    private static final int LIMIT = 500;

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!isDataAdmin(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(err("Access denied"));
            return;
        }

        String search    = trimOrNull(request.getParameter("search"));
        boolean onlyUnset = "1".equals(request.getParameter("onlyUnset"));

        try (Connection conn = DatabaseConnection.getConnection()) {

            if (!PromotionClassRules.hasMaxClassColumn(conn)) {
                JSONObject o = new JSONObject();
                o.put("success", true);
                o.put("columnPresent", false);
                o.put("message", "schools.max_class does not exist yet. Run " +
                                 "databse Scripts/ADD_SCHOOL_MAX_CLASS_2026-08-06.sql, then restart Tomcat. " +
                                 "Until then the terminal class is derived from each school's highest active class.");
                o.put("schools", new JSONArray());
                out.print(o.toString());
                return;
            }

            StringBuilder sql = new StringBuilder(
                "SELECT sc.udise_no, sc.school_name, sc.district_name, sc.max_class, " +
                "       d.tr AS derived_rank, d.cnt AS active_students " +
                "FROM schools sc " +
                "LEFT JOIN ( SELECT s.udise_no, " +
                "                   MAX(" + PromotionClassRules.rank("s.class") + ") AS tr, " +
                "                   COUNT(*) AS cnt " +
                "            FROM students s WHERE s.is_active=1 GROUP BY s.udise_no " +
                "          ) d ON sc.udise_no COLLATE utf8mb4_unicode_ci = d.udise_no " +
                "WHERE 1=1 ");
            if (onlyUnset) sql.append("AND sc.max_class IS NULL ");
            if (search != null) {
                sql.append("AND (sc.udise_no LIKE ? OR sc.school_name LIKE ? OR sc.district_name LIKE ?) ");
            }
            sql.append("ORDER BY (sc.max_class IS NULL) DESC, sc.district_name, sc.school_name LIMIT ")
               .append(LIMIT);

            JSONArray schools = new JSONArray();
            int unset = 0, mismatched = 0;

            try (PreparedStatement ps = conn.prepareStatement(sql.toString())) {
                if (search != null) {
                    String like = "%" + search + "%";
                    ps.setString(1, like);
                    ps.setString(2, like);
                    ps.setString(3, like);
                }
                try (ResultSet rs = ps.executeQuery()) {
                    while (rs.next()) {
                        String stored = rs.getString("max_class");
                        int derived   = rs.getInt("derived_rank");
                        int storedRank = PromotionClassRules.rankOf(stored);

                        JSONObject s = new JSONObject();
                        s.put("udise",          str(rs.getString("udise_no")));
                        s.put("schoolName",     str(rs.getString("school_name")));
                        s.put("district",       str(rs.getString("district_name")));
                        s.put("maxClass",       stored == null ? "" : stored);
                        s.put("derivedRank",    derived);
                        s.put("derivedClass",   derived > 0 ? PromotionClassRules.roman(derived) : "");
                        s.put("activeStudents", rs.getInt("active_students"));
                        s.put("differs",        storedRank > 0 && derived > 0 && storedRank != derived);
                        schools.put(s);

                        if (stored == null) unset++;
                        if (storedRank > 0 && derived > 0 && storedRank != derived) mismatched++;
                    }
                }
            }

            JSONObject o = new JSONObject();
            o.put("success",       true);
            o.put("columnPresent", true);
            o.put("schools",       schools);
            o.put("unset",         unset);
            o.put("mismatched",    mismatched);
            o.put("truncated",     schools.length() >= LIMIT);
            out.print(o.toString());

        } catch (SQLException e) {
            System.err.println("SchoolMaxClass GET error: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(err(e.getMessage()));
        }
    }

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        PrintWriter out = response.getWriter();

        if (!isDataAdmin(request)) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            out.print(err("Access denied"));
            return;
        }

        String action = str(request.getParameter("action"));
        String udise  = trimOrNull(request.getParameter("udise"));
        String maxCls = trimOrNull(request.getParameter("maxClass"));

        try (Connection conn = DatabaseConnection.getConnection()) {

            if (!PromotionClassRules.hasMaxClassColumn(conn)) {
                out.print(err("schools.max_class does not exist yet. Run " +
                              "ADD_SCHOOL_MAX_CLASS_2026-08-06.sql first."));
                return;
            }

            JSONObject o = new JSONObject();
            o.put("success", true);

            if ("set".equals(action)) {
                if (udise == null)  { out.print(err("UDISE is required")); return; }
                // Reject anything that is not a class label, so a typo cannot make a school
                // un-promotable by silently falling through to rank 0.
                if (maxCls == null || PromotionClassRules.rankOf(maxCls) == 0) {
                    out.print(err("Invalid class: " + maxCls + ". Use I..IX or 1..9."));
                    return;
                }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE schools SET max_class=? WHERE udise_no=?")) {
                    ps.setString(1, maxCls);
                    ps.setString(2, udise);
                    o.put("updated", ps.executeUpdate());
                }

            } else if ("clear".equals(action)) {
                if (udise == null) { out.print(err("UDISE is required")); return; }
                try (PreparedStatement ps = conn.prepareStatement(
                        "UPDATE schools SET max_class=NULL WHERE udise_no=?")) {
                    ps.setString(1, udise);
                    o.put("updated", ps.executeUpdate());
                }

            } else if ("seedAll".equals(action)) {
                // Fill only the NULLs, so a value an admin already corrected is never overwritten.
                String sql =
                    "UPDATE schools sc " +
                    "JOIN ( SELECT s.udise_no, " +
                    "              MAX(" + PromotionClassRules.rank("s.class") + ") AS tr " +
                    "       FROM students s WHERE s.is_active=1 GROUP BY s.udise_no " +
                    "     ) d ON sc.udise_no COLLATE utf8mb4_unicode_ci = d.udise_no " +
                    "SET sc.max_class = CASE d.tr " +
                    "  WHEN 1 THEN 'I'   WHEN 2 THEN 'II'   WHEN 3 THEN 'III' " +
                    "  WHEN 4 THEN 'IV'  WHEN 5 THEN 'V'    WHEN 6 THEN 'VI' " +
                    "  WHEN 7 THEN 'VII' WHEN 8 THEN 'VIII' WHEN 9 THEN 'IX' " +
                    "  ELSE NULL END " +
                    "WHERE sc.max_class IS NULL AND d.tr > 0";
                try (PreparedStatement ps = conn.prepareStatement(sql)) {
                    o.put("updated", ps.executeUpdate());
                }

            } else {
                out.print(err("Unknown action: " + action));
                return;
            }

            out.print(o.toString());

        } catch (SQLException e) {
            System.err.println("SchoolMaxClass POST error: " + e.getMessage());
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            out.print(err(e.getMessage()));
        }
    }

    private boolean isDataAdmin(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session == null) return false;
        User user = (User) session.getAttribute("user");
        return user != null && User.UserType.DATA_ADMIN.equals(user.getUserType());
    }

    private static String trimOrNull(String s) {
        if (s == null) return null;
        s = s.trim();
        return s.isEmpty() ? null : s;
    }

    private static String str(String s) { return s == null ? "" : s; }

    private static String err(String msg) {
        return new JSONObject().put("success", false).put("message", msg).toString();
    }
}
