<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="com.vjnt.util.DatabaseConnection" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%!
    // Simple HTML escaper for safe rendering of user/DB values
    private String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")
                .replace("\"", "&quot;");
    }

    // Destructive / high-risk keywords that require an explicit override to run.
    private static final String[] DANGEROUS_KEYWORDS = {
        "DROP", "TRUNCATE", "ALTER", "RENAME", "GRANT", "REVOKE",
        "SHUTDOWN", "CREATE USER", "DROP USER", "DROP DATABASE", "DROP SCHEMA"
    };

    /**
     * Returns a description of the dangerous keyword found in the statement,
     * or null if the statement is considered safe.
     * Also flags DELETE / UPDATE statements that have no WHERE clause.
     */
    private String dangerousHit(String sql) {
        String upper = sql.toUpperCase();
        // Strip anything after a quote to avoid matching keywords inside string literals (best-effort)
        for (String kw : DANGEROUS_KEYWORDS) {
            // word-boundary match so "DROPBOX_TABLE" doesn't trip "DROP"
            if (upper.matches("(?s).*\\b" + kw.replace(" ", "\\s+") + "\\b.*")) {
                return kw;
            }
        }
        // DELETE / UPDATE without WHERE affects every row
        if (upper.matches("(?s)^\\s*DELETE\\s+FROM\\b.*") && !upper.matches("(?s).*\\bWHERE\\b.*")) {
            return "DELETE without WHERE (affects all rows)";
        }
        if (upper.matches("(?s)^\\s*UPDATE\\b.*") && !upper.matches("(?s).*\\bWHERE\\b.*")) {
            return "UPDATE without WHERE (affects all rows)";
        }
        return null;
    }

    /** Create the audit table on first use if it does not already exist. */
    private void ensureAuditTable(Connection conn) throws SQLException {
        String ddl =
            "CREATE TABLE IF NOT EXISTS `sql_console_audit` (" +
            "  `audit_id` bigint NOT NULL AUTO_INCREMENT," +
            "  `username` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL," +
            "  `user_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL," +
            "  `client_ip` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL," +
            "  `executed_at` datetime NOT NULL," +
            "  `status` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL," +
            "  `sql_text` mediumtext COLLATE utf8mb4_unicode_ci," +
            "  `result_summary` text COLLATE utf8mb4_unicode_ci," +
            "  PRIMARY KEY (`audit_id`)" +
            ") ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        try (Statement st = conn.createStatement()) {
            st.executeUpdate(ddl);
        }
    }

    /** Write one audit row for a submission. Never throws to the caller. */
    private void logAudit(Connection conn, String username, String userType, String clientIp,
                          String status, String sqlText, String summary) {
        String ins = "INSERT INTO `sql_console_audit` " +
            "(username, user_type, client_ip, executed_at, status, sql_text, result_summary) " +
            "VALUES (?, ?, ?, NOW(), ?, ?, ?)";
        try (PreparedStatement ps = conn.prepareStatement(ins)) {
            ps.setString(1, username);
            ps.setString(2, userType);
            ps.setString(3, clientIp);
            ps.setString(4, status);
            ps.setString(5, sqlText);
            ps.setString(6, summary);
            ps.executeUpdate();
        } catch (Exception e) {
            // Auditing must not break the console; surface only to server logs.
            System.err.println("sql_console_audit logging failed: " + e.getMessage());
        }
    }
%>
<%
    // ---------------------------------------------------------------
    // ADMIN ONLY: SQL / Database Script Console
    // Access restricted to DATA_ADMIN user type.
    // ---------------------------------------------------------------
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login");
        return;
    }

    // Holders for rendering results after processing
    String submittedSql = "";
    List<String> messages = new ArrayList<String>();   // per-statement outcome / errors
    boolean hasError = false;
    boolean blocked = false;                            // true when guard stopped execution
    List<String> dangerWarnings = new ArrayList<String>(); // detected risky statements
    // Each result-set is stored as: [0]=list of column names, [1]=list of row (String[])
    List<Object[]> resultSets = new ArrayList<Object[]>();

    String clientIp = request.getRemoteAddr();
    String userType = user.getUserType().name();

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        submittedSql = request.getParameter("sql");
        String confirm = request.getParameter("confirm");
        String allowDangerous = request.getParameter("allowDangerous");
        if (submittedSql == null) submittedSql = "";

        if (submittedSql.trim().isEmpty()) {
            messages.add("No SQL entered.");
            hasError = true;
        } else if (confirm == null || !"on".equals(confirm)) {
            messages.add("Please tick the confirmation checkbox before executing.");
            hasError = true;
        } else {
            // ---- Dangerous-keyword guard: scan every statement first ----
            String[] scanStatements = submittedSql.split(";");
            int scanNo = 0;
            for (String raw : scanStatements) {
                String sql = raw.trim();
                if (sql.isEmpty()) continue;
                scanNo++;
                String hit = dangerousHit(sql);
                if (hit != null) {
                    dangerWarnings.add("Statement " + scanNo + " is high-risk: " + hit);
                }
            }
            boolean hasDanger = !dangerWarnings.isEmpty();
            boolean overrideOn = "on".equals(allowDangerous);

            if (hasDanger && !overrideOn) {
                // Block the whole batch until the admin explicitly authorises it.
                blocked = true;
                hasError = true;
                messages.add("BLOCKED: This batch contains high-risk statement(s). "
                    + "Review the warnings below, then tick 'Allow destructive operations' to proceed.");
                // Audit the blocked attempt.
                Connection aconn = null;
                try {
                    aconn = DatabaseConnection.getConnection();
                    ensureAuditTable(aconn);
                    logAudit(aconn, user.getUsername(), userType, clientIp,
                             "BLOCKED", submittedSql, String.join(" | ", dangerWarnings));
                } catch (Exception e) {
                    System.err.println("Audit (blocked) failed: " + e.getMessage());
                } finally {
                    if (aconn != null) try { aconn.close(); } catch (Exception ignore) {}
                }
            } else {
                Connection conn = null;
                Statement stmt = null;
                try {
                    conn = DatabaseConnection.getConnection();
                    ensureAuditTable(conn);
                    stmt = conn.createStatement();

                    // Split into individual statements on semicolons.
                    // (Simple splitter - does not parse strings containing ';'. Run such
                    //  statements one at a time.)
                    String[] rawStatements = submittedSql.split(";");
                    int stmtNo = 0;
                    for (String raw : rawStatements) {
                        String sql = raw.trim();
                        if (sql.isEmpty()) continue;
                        stmtNo++;
                        try {
                            boolean isResultSet = stmt.execute(sql);
                            if (isResultSet) {
                                ResultSet rs = stmt.getResultSet();
                                ResultSetMetaData md = rs.getMetaData();
                                int colCount = md.getColumnCount();
                                List<String> cols = new ArrayList<String>();
                                for (int i = 1; i <= colCount; i++) {
                                    cols.add(md.getColumnLabel(i));
                                }
                                List<String[]> rows = new ArrayList<String[]>();
                                int rowCount = 0;
                                while (rs.next() && rowCount < 5000) { // cap to protect the page
                                    String[] row = new String[colCount];
                                    for (int i = 1; i <= colCount; i++) {
                                        Object val = rs.getObject(i);
                                        row[i - 1] = (val == null) ? "NULL" : val.toString();
                                    }
                                    rows.add(row);
                                    rowCount++;
                                }
                                rs.close();
                                resultSets.add(new Object[]{cols, rows});
                                messages.add("Statement " + stmtNo + ": returned " + rows.size()
                                    + " row(s)" + (rowCount >= 5000 ? " (truncated at 5000)" : "") + ".");
                            } else {
                                int updateCount = stmt.getUpdateCount();
                                messages.add("Statement " + stmtNo + ": OK, " + updateCount + " row(s) affected.");
                            }
                        } catch (SQLException se) {
                            hasError = true;
                            messages.add("Statement " + stmtNo + " FAILED: " + se.getMessage());
                        }
                    }
                } catch (Exception e) {
                    hasError = true;
                    messages.add("Connection/Execution error: " + e.getMessage());
                } finally {
                    // Audit the executed batch (uses a fresh connection so a broken
                    // 'conn' from the try block cannot suppress the log).
                    Connection aconn = null;
                    try {
                        aconn = DatabaseConnection.getConnection();
                        ensureAuditTable(aconn);
                        String status = hasError ? "PARTIAL/FAILED" : (overrideOn && hasDanger ? "SUCCESS (override)" : "SUCCESS");
                        String summary = String.join(" | ", messages);
                        if (summary.length() > 4000) summary = summary.substring(0, 4000) + " ...";
                        logAudit(aconn, user.getUsername(), userType, clientIp, status, submittedSql, summary);
                    } catch (Exception e) {
                        System.err.println("Audit (executed) failed: " + e.getMessage());
                    } finally {
                        if (aconn != null) try { aconn.close(); } catch (Exception ignore) {}
                    }
                    if (stmt != null) try { stmt.close(); } catch (Exception ignore) {}
                    if (conn != null) try { conn.close(); } catch (Exception ignore) {}
                }
            }
        }
    }

%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>SQL Console (Admin) - GATEE PORTAL</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f0f2f5;
            min-height: 100vh;
            padding: 20px;
            color: #1a202c;
        }
        .container { max-width: 1100px; margin: 0 auto; }
        .header {
            background: #fff;
            padding: 18px 22px;
            border-radius: 10px;
            margin-bottom: 18px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            box-shadow: 0 1px 4px rgba(0,0,0,0.08);
        }
        .header h1 { font-size: 20px; color: #2d3748; }
        .header .who { font-size: 13px; color: #718096; }
        .header a.back {
            text-decoration: none; color: #fff; background: #667eea;
            padding: 8px 14px; border-radius: 6px; font-size: 13px;
        }
        .card {
            background: #fff; padding: 20px; border-radius: 10px;
            margin-bottom: 18px; box-shadow: 0 1px 4px rgba(0,0,0,0.08);
        }
        .warn {
            background: #fff5f5; border: 1px solid #feb2b2; color: #c53030;
            padding: 12px 14px; border-radius: 8px; font-size: 13px; margin-bottom: 16px;
        }
        label.blk { display:block; font-weight:600; margin-bottom:8px; color:#2d3748; }
        textarea {
            width: 100%; min-height: 180px; font-family: 'Consolas','Courier New',monospace;
            font-size: 14px; padding: 12px; border: 1px solid #cbd5e0; border-radius: 8px;
            resize: vertical;
        }
        .row { display:flex; align-items:center; gap:14px; margin-top:14px; flex-wrap:wrap; }
        .confirm { font-size: 13px; color:#4a5568; display:flex; align-items:center; gap:6px; }
        button.run {
            background: #2f855a; color:#fff; border:none; padding:10px 22px;
            border-radius:6px; font-size:14px; cursor:pointer; font-weight:600;
        }
        button.run:hover { background:#276749; }
        button.clear {
            background:#e2e8f0; color:#2d3748; border:none; padding:10px 18px;
            border-radius:6px; font-size:14px; cursor:pointer;
        }
        .msg-box { margin-bottom: 14px; }
        .msg { padding:8px 12px; border-radius:6px; font-size:13px; margin-bottom:6px; }
        .msg.ok { background:#f0fff4; border:1px solid #9ae6b4; color:#22543d; }
        .msg.err { background:#fff5f5; border:1px solid #feb2b2; color:#c53030; }
        .msg.danger { background:#fffaf0; border:1px solid #f6ad55; color:#c05621; }
        .danger-opt { color:#c05621; font-weight:600; }
        table.result {
            width:100%; border-collapse:collapse; font-size:13px; margin-top:10px;
        }
        table.result th, table.result td {
            border:1px solid #e2e8f0; padding:6px 10px; text-align:left;
            white-space:nowrap; max-width:400px; overflow:hidden; text-overflow:ellipsis;
        }
        table.result th { background:#edf2f7; position:sticky; top:0; }
        .scroll { overflow-x:auto; max-height:520px; overflow-y:auto; border-radius:8px; }
        .rs-title { font-weight:600; margin:18px 0 4px; color:#2d3748; }
        .hint { font-size:12px; color:#718096; margin-top:8px; }
    </style>
</head>
<body>
<div class="container">
    <div class="header">
        <div>
            <h1>🛠️ SQL / Database Script Console</h1>
            <div class="who">Logged in as <b><%= esc(user.getUsername()) %></b> (DATA_ADMIN)</div>
        </div>
        <a class="back" href="<%= request.getContextPath() %>/data-admin-dashboard.jsp">&larr; Dashboard</a>
    </div>

    <div class="card">
        <div class="warn">
            ⚠️ <b>Caution:</b> Statements run directly against the LIVE database and cannot be undone.
            Separate multiple statements with a semicolon (<code>;</code>). Always back up before running
            DELETE / UPDATE / DDL.
        </div>

        <form method="post" action="<%= request.getContextPath() %>/admin-sql-console.jsp">
            <label class="blk" for="sql">SQL to execute</label>
            <textarea id="sql" name="sql" placeholder="e.g. SELECT * FROM users LIMIT 20;"><%= esc(submittedSql) %></textarea>
            <div class="row">
                <label class="confirm">
                    <input type="checkbox" name="confirm" /> I understand this runs on the live database
                </label>
                <label class="confirm danger-opt">
                    <input type="checkbox" name="allowDangerous" /> Allow destructive operations (DROP / TRUNCATE / ALTER / no-WHERE, etc.)
                </label>
                <button type="submit" class="run">▶ Execute</button>
                <button type="button" class="clear" onclick="document.getElementById('sql').value='';">Clear</button>
            </div>
            <div class="hint">SELECT results are capped at 5000 rows per statement. Every execution and blocked attempt is recorded in <code>sql_console_audit</code>.</div>
        </form>
    </div>

    <% if (!dangerWarnings.isEmpty()) { %>
    <div class="card">
        <div style="font-weight:600;color:#c05621;margin-bottom:8px;">⚠️ High-risk statements detected</div>
        <% for (String w : dangerWarnings) { %>
            <div class="msg danger"><%= esc(w) %></div>
        <% } %>
        <% if (blocked) { %>
            <div class="hint" style="margin-top:8px;">Nothing was executed. To run this anyway, tick <b>“Allow destructive operations”</b> above and press Execute again.</div>
        <% } %>
    </div>
    <% } %>

    <% if (!messages.isEmpty()) { %>
    <div class="card">
        <div class="msg-box">
            <% for (String m : messages) {
                   boolean isErr = m.contains("FAILED") || m.contains("error") || m.contains("No SQL") || m.contains("confirmation") || m.contains("BLOCKED");
            %>
                <div class="msg <%= isErr ? "err" : "ok" %>"><%= esc(m) %></div>
            <% } %>
        </div>

        <% int rsIdx = 0;
           for (Object[] rsData : resultSets) {
               rsIdx++;
               @SuppressWarnings("unchecked")
               List<String> cols = (List<String>) rsData[0];
               @SuppressWarnings("unchecked")
               List<String[]> rows = (List<String[]>) rsData[1];
        %>
            <div class="rs-title">Result set <%= rsIdx %> (<%= rows.size() %> row<%= rows.size()==1?"":"s" %>)</div>
            <div class="scroll">
                <table class="result">
                    <thead>
                        <tr>
                            <% for (String c : cols) { %><th><%= esc(c) %></th><% } %>
                        </tr>
                    </thead>
                    <tbody>
                        <% for (String[] row : rows) { %>
                            <tr>
                                <% for (String cell : row) { %><td><%= esc(cell) %></td><% } %>
                            </tr>
                        <% } %>
                    </tbody>
                </table>
            </div>
        <% } %>
    </div>
    <% } %>
</div>
</body>
</html>
