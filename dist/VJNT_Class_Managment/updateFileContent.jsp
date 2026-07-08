<%@ page import="java.sql.*, java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page buffer="8kb" autoFlush="true" %>
<html>
<head>
<title>FileContent Migration Tool</title>
<style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 900px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    h2 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
    label { font-weight: bold; display: inline-block; width: 100px; }
    input[type="date"] { padding: 6px; margin: 5px 0; }
    .btn { padding: 10px 25px; border: none; border-radius: 5px; cursor: pointer; font-size: 14px; margin: 5px; }
    .btn-preview { background: #007bff; color: white; }
    .btn-preview:hover { background: #0056b3; }
    .btn-preview:disabled { background: #ccc; cursor: not-allowed; }
    .btn-update { background: #dc3545; color: white; font-size: 16px; padding: 12px 30px; }
    .btn-update:hover { background: #a71d2a; }
    .btn-cancel { background: #6c757d; color: white; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th { background: #007bff; color: white; padding: 10px; text-align: left; }
    td { padding: 8px 10px; border-bottom: 1px solid #ddd; }
    tr:hover { background: #f0f0f0; }
    .info-box { background: #e7f3fe; border-left: 4px solid #007bff; padding: 12px; margin: 15px 0; }
    .warn-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 15px 0; }
    .success-box { background: #d4edda; border-left: 4px solid #28a745; padding: 12px; margin: 15px 0; }
    .error-box { background: #f8d7da; border-left: 4px solid #dc3545; padding: 12px; margin: 15px 0; }
    pre { background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; }
    .summary { font-size: 18px; font-weight: bold; }
    .toggle-section { margin: 15px 0; padding: 15px; background: #fff3cd; border-radius: 5px; }
    .status-box { padding: 12px 15px; margin: 8px 0; border-radius: 5px; font-weight: bold; }
    .status-ok { background: #d4edda; border-left: 4px solid #28a745; color: #155724; }
    .status-fail { background: #f8d7da; border-left: 4px solid #dc3545; color: #721c24; }
    .status-check { background: #fff3cd; border-left: 4px solid #ffc107; color: #856404; }
</style>
</head>
<body>
<div class="container">
<h2>FileContent Migration: SQL Server → Oracle</h2>

<%
    // === UPDATE THESE VALUES ===
    String sqlUrl   = "jdbc:sqlserver://10.5.7.149:1757;databaseName=Digiremit";
    String sqlUser  = "Digiremit";
    String sqlPass  = "Di$iReM!T2026";
    String sqlTable = "TXNSENDERRISKDOCUPLOADDETAILS";
    String sqlDateCol = "CREATEDDATE";

    String oraUrl   = "jdbc:oracle:thin:@10.5.27.112:1652:DIGIREMI";
    String oraUser  = "DIGIREMIT";
    String oraPass  = "Idfc$#Feb2026";
    String oraTable = "TXNSENDERRISKDOCUPLOADDETAILS";
    // ============================Idfc$#F

    // ========================================
    // CHECK DATABASE CONNECTIVITY ON PAGE LOAD
    // ========================================
    boolean sqlConnected = false;
    boolean oraConnected = false;
    String sqlError = "";
    String oraError = "";
    String sqlVersion = "";
    String oraVersion = "";

    // Test SQL Server
    try {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        Connection testSql = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);
        DatabaseMetaData sqlMeta = testSql.getMetaData();
        sqlVersion = sqlMeta.getDatabaseProductName() + " " + sqlMeta.getDatabaseProductVersion();
        testSql.close();
        sqlConnected = true;
    } catch (Exception e) {
        sqlError = e.getMessage();
    }

    // Test Oracle
    try {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        Connection testOra = DriverManager.getConnection(oraUrl, oraUser, oraPass);
        DatabaseMetaData oraMeta = testOra.getMetaData();
        oraVersion = oraMeta.getDatabaseProductName() + " " + oraMeta.getDatabaseProductVersion();
        testOra.close();
        oraConnected = true;
    } catch (Exception e) {
        oraError = e.getMessage();
    }
%>

    <!-- DATABASE STATUS PANEL -->
    <h3>Database Connectivity Status</h3>

    <% if (sqlConnected) { %>
        <div class="status-box status-ok">
            SQL Server: CONNECTED | <%= sqlVersion %>
        </div>
    <% } else { %>
        <div class="status-box status-fail">
            SQL Server: FAILED | <%= sqlError %>
        </div>
    <% } %>

    <% if (oraConnected) { %>
        <div class="status-box status-ok">
            Oracle: CONNECTED | <%= oraVersion %>
        </div>
    <% } else { %>
        <div class="status-box status-fail">
            Oracle: FAILED | <%= oraError %>
        </div>
    <% } %>

<%
    String fromDate  = request.getParameter("fromDate");
    String toDate    = request.getParameter("toDate");
    String action    = request.getParameter("action");

    boolean bothConnected = sqlConnected && oraConnected;

    // STEP 1: Show date form
    if (action == null) {

        if (!bothConnected) {
%>
            <div class="error-box">
                Fix the database connection(s) above before proceeding. Check credentials and server details.
            </div>
<%
        }
%>
        <hr/>
        <div class="info-box">
            <b>Step 1:</b> Select date range to preview data. No changes will be made.
        </div>
        <form method="post">
            <label>From Date:</label>
            <input type="date" name="fromDate" required /><br/><br/>
            <label>To Date:</label>
            <input type="date" name="toDate" required /><br/><br/>
            <input type="hidden" name="action" value="preview" />
            <button type="submit" class="btn btn-preview" <%= !bothConnected ? "disabled title='Fix DB connections first'" : "" %>>
                Preview Data
            </button>
        </form>
<%
    }

    // STEP 2: Preview - SELECT only
    else if ("preview".equals(action) && fromDate != null && toDate != null && bothConnected) {

        Connection sqlConn = null;
        PreparedStatement sqlPs = null;
        ResultSet rs = null;

        try {
            sqlConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);

            // Get total count
            String countQuery = "SELECT COUNT(*) FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN ? AND ?";
            sqlPs = sqlConn.prepareStatement(countQuery);
            sqlPs.setString(1, fromDate);
            sqlPs.setString(2, toDate);
            rs = sqlPs.executeQuery();
            rs.next();
            int totalRows = rs.getInt(1);
            rs.close();
            sqlPs.close();
%>
            <hr/>
            <div class="info-box">
                <b>Step 2:</b> Preview Results (SELECT only - no changes made)
            </div>

            <div class="summary">
                Date Range: <%= fromDate %> to <%= toDate %><br/>
                Total Rows Found: <span style="color: #007bff;"><%= totalRows %></span>
            </div>

            <h3>Sample Data (First 20 rows)</h3>
            <table>
                <tr>
                    <th>#</th>
                    <th>SRDUID</th>
                    <th>FILECONTENT Size</th>
                    <th><%= sqlDateCol %></th>
                </tr>
<%
                String sampleQuery = "SELECT TOP 20 SRDUID, LEN(FILECONTENT) AS CONTENT_SIZE, "
                    + sqlDateCol + " FROM " + sqlTable
                    + " WHERE FILECONTENT IS NOT NULL"
                    + " AND " + sqlDateCol + " BETWEEN ? AND ?"
                    + " ORDER BY " + sqlDateCol;

                sqlPs = sqlConn.prepareStatement(sampleQuery);
                sqlPs.setString(1, fromDate);
                sqlPs.setString(2, toDate);
                rs = sqlPs.executeQuery();

                int rowNum = 0;
                while (rs.next()) {
                    rowNum++;
                    long sizeKB = rs.getLong("CONTENT_SIZE") / 1024;
%>
                    <tr>
                        <td><%= rowNum %></td>
                        <td><%= rs.getString("SRDUID") %></td>
                        <td><%= sizeKB %> KB (<%= String.format("%.2f", sizeKB / 1024.0) %> MB)</td>
                        <td><%= rs.getString(sqlDateCol) %></td>
                    </tr>
<%
                }
                rs.close();
                sqlPs.close();
%>
            </table>

            <div class="toggle-section">
                <b>Step 3:</b> Ready to execute UPDATE on Oracle?<br/><br/>
                <span style="color: red;">WARNING: This will update <b><%= totalRows %></b> rows in Oracle table <b><%= oraTable %></b></span><br/><br/>

                <form method="post" onsubmit="return confirm('Are you sure you want to UPDATE <%= totalRows %> rows in Oracle?');">
                    <input type="hidden" name="fromDate" value="<%= fromDate %>" />
                    <input type="hidden" name="toDate" value="<%= toDate %>" />
                    <input type="hidden" name="totalRows" value="<%= totalRows %>" />
                    <input type="hidden" name="action" value="update" />
                    <button type="submit" class="btn btn-update">Execute UPDATE on Oracle</button>
                    <a href="?" class="btn btn-cancel" style="text-decoration:none;">Cancel - Go Back</a>
                </form>
            </div>
<%
        } catch (Exception e) {
%>
            <div class="error-box">ERROR: <%= e.getMessage() %></div>
<%
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (sqlPs != null) try { sqlPs.close(); } catch(Exception e) {}
            if (sqlConn != null) try { sqlConn.close(); } catch(Exception e) {}
        }
    }

    // STEP 3: Execute UPDATE
    else if ("update".equals(action) && fromDate != null && toDate != null && bothConnected) {

        Connection sqlConn = null;
        Connection oraConn = null;
        PreparedStatement sqlPs = null;
        PreparedStatement oraPs = null;
        ResultSet rs = null;

        try {
            int totalRows = Integer.parseInt(request.getParameter("totalRows"));

            sqlConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);
            oraConn = DriverManager.getConnection(oraUrl, oraUser, oraPass);
            oraConn.setAutoCommit(false);
%>
            <hr/>
            <div class="warn-box">
                <b>UPDATE IN PROGRESS</b> — Do not close this page!
            </div>
            <pre>
Connected to SQL Server ✓
Connected to Oracle ✓
Starting update of <%= totalRows %> rows...
========================================
<%
            out.flush();

            String sqlQuery = "SELECT SRDUID, FILECONTENT FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN ? AND ?";

            sqlPs = sqlConn.prepareStatement(sqlQuery,
                ResultSet.TYPE_FORWARD_ONLY,
                ResultSet.CONCUR_READ_ONLY);
            sqlPs.setFetchSize(1);
            sqlPs.setString(1, fromDate);
            sqlPs.setString(2, toDate);
            rs = sqlPs.executeQuery();

            oraPs = oraConn.prepareStatement(
                "UPDATE " + oraTable + " SET FILECONTENT = ? WHERE SRDUID = ?"
            );

            int count = 0;
            int success = 0;
            int failed = 0;
            int COMMIT_EVERY = 50;
            long startTime = System.currentTimeMillis();

            while (rs.next()) {
                String srduid = rs.getString("SRDUID");
                String fileContent = rs.getString("FILECONTENT");

                try {
                    if (fileContent != null && fileContent.length() > 0) {
                        oraPs.setClob(1, new StringReader(fileContent));
                        oraPs.setString(2, srduid);
                        int updated = oraPs.executeUpdate();
                        success += updated;
                    }
                } catch (Exception rowEx) {
                    failed++;
                    out.println("FAILED SRDUID: " + srduid + " | " + rowEx.getMessage());
                    out.flush();
                }

                count++;
                fileContent = null;

                if (count % COMMIT_EVERY == 0) {
                    oraConn.commit();

                    long elapsed = System.currentTimeMillis() - startTime;
                    long avgPerRow = elapsed / count;
                    long remaining = avgPerRow * (totalRows - count);
                    long remMinutes = remaining / 60000;
                    int percent = (int)((count * 100.0) / totalRows);

                    out.println("[" + percent + "%] " + count + "/" + totalRows
                        + " | Updated: " + success
                        + " | Failed: " + failed
                        + " | ETA: " + remMinutes + " min");
                    out.flush();
                }
            }

            oraConn.commit();
            long totalTime = (System.currentTimeMillis() - startTime) / 1000;
%>
========================================
COMPLETED!
Date Range : <%= fromDate %> to <%= toDate %>
Total Rows : <%= count %>
Updated    : <%= success %>
Failed     : <%= failed %>
Time Taken : <%= (totalTime / 60) %> min <%= (totalTime % 60) %> sec
            </pre>

            <div class="success-box">
                Update completed successfully! <b><%= success %></b> rows updated.
            </div>
            <br/>
            <a href="?" class="btn btn-preview" style="text-decoration:none;">Run Another Batch</a>
<%
        } catch (Exception e) {
%>
            <div class="error-box">ERROR: <%= e.getMessage() %></div>
<%
            e.printStackTrace(new java.io.PrintWriter(out));
            if (oraConn != null) {
                try { oraConn.rollback(); } catch(Exception ex) {}
            }
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (sqlPs != null) try { sqlPs.close(); } catch(Exception e) {}
            if (oraPs != null) try { oraPs.close(); } catch(Exception e) {}
            if (sqlConn != null) try { sqlConn.close(); } catch(Exception e) {}
            if (oraConn != null) try { oraConn.close(); } catch(Exception e) {}
        }
    }
%>
</div>
</body>
</html>
