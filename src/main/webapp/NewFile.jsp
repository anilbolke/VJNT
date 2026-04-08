<%@ page import="java.sql.*, java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page buffer="8kb" autoFlush="true" %>
<html>
<head>
<title>FileContent Migration Tool</title>
<style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 960px; margin: 0 auto; background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    h2 { color: #333; border-bottom: 2px solid #007bff; padding-bottom: 10px; }
    h3 { color: #555; margin-top: 20px; }
    .db-section { display: flex; gap: 20px; flex-wrap: wrap; }
    .db-box { flex: 1; min-width: 380px; border: 1px solid #ddd; border-radius: 8px; padding: 15px; background: #fafafa; }
    .db-box h3 { margin-top: 0; padding: 8px; border-radius: 5px; color: white; text-align: center; }
    .db-box.sql h3 { background: #0078d4; }
    .db-box.oracle h3 { background: #f80000; }
    .form-group { margin: 10px 0; }
    .form-group label { display: block; font-weight: bold; margin-bottom: 3px; font-size: 13px; color: #555; }
    .form-group input, .form-group select { width: 100%; padding: 8px; border: 1px solid #ccc; border-radius: 4px; box-sizing: border-box; font-size: 14px; }
    .form-group input:focus, .form-group select:focus { border-color: #007bff; outline: none; box-shadow: 0 0 3px rgba(0,123,255,0.3); }
    .btn { padding: 10px 25px; border: none; border-radius: 5px; cursor: pointer; font-size: 14px; margin: 5px; display: inline-block; }
    .btn-sql { background: #0078d4; color: white; width: 100%; padding: 10px; font-size: 14px; }
    .btn-sql:hover { background: #005a9e; }
    .btn-ora { background: #f80000; color: white; width: 100%; padding: 10px; font-size: 14px; }
    .btn-ora:hover { background: #c00000; }
    .btn-preview { background: #007bff; color: white; padding: 10px 20px; }
    .btn-preview:hover { background: #0056b3; }
    .btn-update { background: #dc3545; color: white; font-size: 16px; padding: 12px 30px; }
    .btn-update:hover { background: #a71d2a; }
    .btn-cancel { background: #6c757d; color: white; text-decoration: none; padding: 12px 25px; }
    .btn-cancel:hover { background: #545b62; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th { background: #007bff; color: white; padding: 10px; text-align: left; }
    td { padding: 8px 10px; border-bottom: 1px solid #ddd; }
    tr:hover { background: #f0f0f0; }
    .info-box { background: #e7f3fe; border-left: 4px solid #007bff; padding: 12px; margin: 15px 0; border-radius: 4px; }
    .warn-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 15px 0; border-radius: 4px; }
    .success-box { background: #d4edda; border-left: 4px solid #28a745; padding: 12px; margin: 15px 0; border-radius: 4px; }
    .error-box { background: #f8d7da; border-left: 4px solid #dc3545; padding: 12px; margin: 15px 0; border-radius: 4px; }
    pre { background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 13px; }
    .summary { font-size: 18px; font-weight: bold; margin: 15px 0; }
    .toggle-section { margin: 15px 0; padding: 15px; background: #fff3cd; border-radius: 5px; }
    .query-box { background: #1e1e1e; color: #d4d4d4; padding: 15px; border-radius: 5px; margin: 10px 0; font-family: 'Courier New', monospace; font-size: 13px; overflow-x: auto; white-space: pre-wrap; word-wrap: break-word; }
    .query-box .keyword { color: #569cd6; }
    .query-box .table-name { color: #4ec9b0; }
    .query-box .param { color: #ce9178; }
    .query-label { display: inline-block; background: #6c757d; color: white; padding: 3px 10px; border-radius: 3px; font-size: 12px; font-weight: bold; margin-bottom: 5px; }
    .query-label.select { background: #007bff; }
    .query-label.update { background: #dc3545; }
    .query-label.count { background: #28a745; }
    .query-section { margin: 15px 0; border: 1px solid #ddd; border-radius: 8px; padding: 15px; background: #f8f9fa; }
    .query-section h3 { margin-top: 0; }
    .status-box { padding: 10px 15px; margin: 8px 0; border-radius: 5px; font-weight: bold; font-size: 13px; }
    .status-ok { background: #d4edda; border-left: 4px solid #28a745; color: #155724; }
    .status-fail { background: #f8d7da; border-left: 4px solid #dc3545; color: #721c24; }
    .status-wait { background: #e2e3e5; border-left: 4px solid #6c757d; color: #383d41; }
    .date-section { display: flex; gap: 15px; align-items: end; flex-wrap: wrap; margin: 15px 0; }
    .date-section .form-group { margin: 0; }
    hr { border: none; border-top: 1px solid #eee; margin: 20px 0; }
</style>
<script>
    function doAction(act) {
        document.getElementById('actionField').value = act;
        document.getElementById('mainForm').submit();
    }
</script>
</head>
<body>
<div class="container">
<h2>FileContent Migration: SQL Server to Oracle</h2>

<%
    String action = request.getParameter("action");

    // SQL Server params
    String sqlServer   = request.getParameter("sqlServer");
    String sqlPort     = request.getParameter("sqlPort");
    String sqlDatabase = request.getParameter("sqlDatabase");
    String sqlUser     = request.getParameter("sqlUser");
    String sqlPass     = request.getParameter("sqlPass");
    String sqlTable    = request.getParameter("sqlTable");
    String sqlDateCol  = request.getParameter("sqlDateCol");
    String sqlDriver   = request.getParameter("sqlDriver");

    // Oracle params
    String oraHost     = request.getParameter("oraHost");
    String oraPort     = request.getParameter("oraPort");
    String oraConnType = request.getParameter("oraConnType");
    String oraSid      = request.getParameter("oraSid");
    String oraUser     = request.getParameter("oraUser");
    String oraPass     = request.getParameter("oraPass");
    String oraTable    = request.getParameter("oraTable");

    // Date range
    String fromDate = request.getParameter("fromDate");
    String toDate   = request.getParameter("toDate");

    // Defaults
    if (sqlServer == null) sqlServer = "10.5.7.149";
    if (sqlPort == null) sqlPort = "1757";
    if (sqlDatabase == null) sqlDatabase = "IDFCDigiRemit";
    if (sqlUser == null) sqlUser = "digiremit";
    if (sqlPass == null) sqlPass = "Di$iReM!T2026";
    if (sqlTable == null) sqlTable = "TXNSENDERRISKDOCUPLOADDETAILS";
    if (sqlDateCol == null) sqlDateCol = "CREATEDDATE";
    if (sqlDriver == null) sqlDriver = "jtds";
    if (oraHost == null) oraHost = "10.5.27.112";
    if (oraPort == null) oraPort = "1652";
    if (oraConnType == null) oraConnType = "service";
    if (oraSid == null) oraSid = "DIGIREMI";
    if (oraUser == null) oraUser = "DIGIREMIT";
    if (oraPass == null) oraPass = "IDfc$#Feb2026";
    if (oraTable == null) oraTable = "TXNSENDERRISKDOCUPLOADDETAILS";

    // Connection status tracking
    String sqlStatus = request.getParameter("sqlStatus");
    String oraStatus = request.getParameter("oraStatus");
    String sqlMsg    = request.getParameter("sqlMsg");
    String oraMsg    = request.getParameter("oraMsg");
    if (sqlStatus == null) sqlStatus = "";
    if (oraStatus == null) oraStatus = "";
    if (sqlMsg == null) sqlMsg = "";
    if (oraMsg == null) oraMsg = "";

    // Build SQL Server URL based on driver choice
    String sqlUrl = "";
    String sqlDriverClass = "";
    if (sqlServer != null && sqlServer.length() > 0) {
        if ("jtds".equals(sqlDriver)) {
            // JTDS driver - NO SSL issues
            sqlDriverClass = "net.sourceforge.jtds.jdbc.Driver";
            sqlUrl = "jdbc:jtds:sqlserver://" + sqlServer + ":" + sqlPort + "/" + sqlDatabase;
        } else {
            // Microsoft driver with SSL fix
            sqlDriverClass = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
            sqlUrl = "jdbc:sqlserver://" + sqlServer + ":" + sqlPort
                + ";databaseName=" + sqlDatabase
                + ";encrypt=false;trustServerCertificate=true";
        }
    }

    // Build Oracle URL based on connection type
    String oraUrl = "";
    if (oraHost != null && oraHost.length() > 0) {
        if ("service".equals(oraConnType)) {
            oraUrl = "jdbc:oracle:thin:@//" + oraHost + ":" + oraPort + "/" + oraSid;
        } else {
            oraUrl = "jdbc:oracle:thin:@" + oraHost + ":" + oraPort + ":" + oraSid;
        }
    }

    // =============================================
    // TEST SQL SERVER
    // =============================================
    if ("testSql".equals(action)) {
        try {
            Class.forName(sqlDriverClass);
            long start = System.currentTimeMillis();
            Connection testConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);
            long time = System.currentTimeMillis() - start;
            DatabaseMetaData meta = testConn.getMetaData();
            sqlMsg = "CONNECTED in " + time + "ms | " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion() + " | Driver: " + sqlDriver.toUpperCase() + " | URL: " + sqlUrl;
            testConn.close();
            sqlStatus = "ok";
        } catch (ClassNotFoundException e) {
            if ("jtds".equals(sqlDriver)) {
                sqlMsg = "DRIVER NOT FOUND | Place jtds-1.3.1.jar in WEB-INF/lib/ and restart Tomcat";
            } else {
                sqlMsg = "DRIVER NOT FOUND | Place mssql-jdbc-*.jar in WEB-INF/lib/ and restart Tomcat";
            }
            sqlStatus = "fail";
        } catch (Exception e) {
            sqlMsg = "FAILED | " + e.getMessage();
            sqlStatus = "fail";
        }
        action = "form";
    }

    // =============================================
    // TEST ORACLE
    // =============================================
    if ("testOra".equals(action)) {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            long start = System.currentTimeMillis();
            Connection testConn = DriverManager.getConnection(oraUrl, oraUser, oraPass);
            long time = System.currentTimeMillis() - start;
            DatabaseMetaData meta = testConn.getMetaData();
            oraMsg = "CONNECTED in " + time + "ms | " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion() + " | URL: " + oraUrl;
            testConn.close();
            oraStatus = "ok";
        } catch (ClassNotFoundException e) {
            oraMsg = "DRIVER NOT FOUND | Place ojdbc8.jar in WEB-INF/lib/ and restart Tomcat";
            oraStatus = "fail";
        } catch (Exception e) {
            oraMsg = "FAILED | " + e.getMessage();
            oraStatus = "fail";
        }
        action = "form";
    }

    boolean sqlConnected = "ok".equals(sqlStatus);
    boolean oraConnected = "ok".equals(oraStatus);
    boolean bothConnected = sqlConnected && oraConnected;

    // =============================================
    // STEP 1: CONNECTION FORM
    // =============================================
    if (action == null || "form".equals(action)) {
%>

    <form method="post" id="mainForm">
        <input type="hidden" id="actionField" name="action" value="" />
        <input type="hidden" name="sqlStatus" value="<%= sqlStatus %>" />
        <input type="hidden" name="oraStatus" value="<%= oraStatus %>" />
        <input type="hidden" name="sqlMsg" value="<%= sqlMsg != null ? sqlMsg.replace("\"", "&quot;") : "" %>" />
        <input type="hidden" name="oraMsg" value="<%= oraMsg != null ? oraMsg.replace("\"", "&quot;") : "" %>" />

        <div class="db-section">

            <!-- SQL SERVER -->
            <div class="db-box sql">
                <h3>SQL Server (Source)</h3>
                <div class="form-group">
                    <label>JDBC Driver</label>
                    <select name="sqlDriver">
                        <option value="jtds" <%= "jtds".equals(sqlDriver) ? "selected" : "" %>>JTDS (Recommended - No SSL Issues)</option>
                        <option value="mssql" <%= "mssql".equals(sqlDriver) ? "selected" : "" %>>Microsoft JDBC</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Server / IP</label>
                    <input type="text" name="sqlServer" value="<%= sqlServer != null ? sqlServer : "" %>" placeholder="e.g. 192.168.1.100" required />
                </div>
                <div class="form-group">
                    <label>Port</label>
                    <input type="text" name="sqlPort" value="<%= sqlPort %>" placeholder="1433" />
                </div>
                <div class="form-group">
                    <label>Database Name</label>
                    <input type="text" name="sqlDatabase" value="<%= sqlDatabase != null ? sqlDatabase : "" %>" placeholder="e.g. MyDatabase" required />
                </div>
                <div class="form-group">
                    <label>Username</label>
                    <input type="text" name="sqlUser" value="<%= sqlUser != null ? sqlUser : "" %>" required />
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" name="sqlPass" value="<%= sqlPass != null ? sqlPass : "" %>" required />
                </div>
                <div class="form-group">
                    <label>Table Name</label>
                    <input type="text" name="sqlTable" value="<%= sqlTable != null ? sqlTable : "" %>" placeholder="e.g. dbo.FileTable" required />
                </div>
                <div class="form-group">
                    <label>Date Column Name</label>
                    <input type="text" name="sqlDateCol" value="<%= sqlDateCol != null ? sqlDateCol : "" %>" placeholder="e.g. CREATED_DATE" required />
                </div>
                <br/>
                <button type="button" class="btn btn-sql" onclick="doAction('testSql')">Test SQL Server Connection</button>

                <% if ("ok".equals(sqlStatus)) { %>
                    <div class="status-box status-ok"><%= sqlMsg %></div>
                <% } else if ("fail".equals(sqlStatus)) { %>
                    <div class="status-box status-fail"><%= sqlMsg %></div>
                <% } else { %>
                    <div class="status-box status-wait">Not tested yet</div>
                <% } %>
            </div>

            <!-- ORACLE -->
            <div class="db-box oracle">
                <h3>Oracle (Destination)</h3>
                <div class="form-group">
                    <label>Host / IP</label>
                    <input type="text" name="oraHost" value="<%= oraHost != null ? oraHost : "" %>" placeholder="e.g. 192.168.1.200" required />
                </div>
                <div class="form-group">
                    <label>Port</label>
                    <input type="text" name="oraPort" value="<%= oraPort %>" placeholder="1521" />
                </div>
                <div class="form-group">
                    <label>Connection Type</label>
                    <select name="oraConnType">
                        <option value="service" <%= "service".equals(oraConnType) ? "selected" : "" %>>Service Name</option>
                        <option value="sid" <%= "sid".equals(oraConnType) ? "selected" : "" %>>SID</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>SID / Service Name</label>
                    <input type="text" name="oraSid" value="<%= oraSid != null ? oraSid : "" %>" placeholder="e.g. ORCL or orcl.domain.com" required />
                </div>
                <div class="form-group">
                    <label>Username</label>
                    <input type="text" name="oraUser" value="<%= oraUser != null ? oraUser : "" %>" required />
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" name="oraPass" value="<%= oraPass != null ? oraPass : "" %>" required />
                </div>
                <div class="form-group">
                    <label>Table Name</label>
                    <input type="text" name="oraTable" value="<%= oraTable != null ? oraTable : "" %>" placeholder="e.g. FILE_TABLE" required />
                </div>
                <br/>
                <button type="button" class="btn btn-ora" onclick="doAction('testOra')">Test Oracle Connection</button>

                <% if ("ok".equals(oraStatus)) { %>
                    <div class="status-box status-ok"><%= oraMsg %></div>
                <% } else if ("fail".equals(oraStatus)) { %>
                    <div class="status-box status-fail"><%= oraMsg %></div>
                <% } else { %>
                    <div class="status-box status-wait">Not tested yet</div>
                <% } %>
            </div>
        </div>

        <br/>
        <hr/>

        <% if (bothConnected) { %>
            <div class="success-box">Both databases connected successfully! Select date range to preview data.</div>
            <h3>Select Date Range</h3>
            <div class="date-section">
                <div class="form-group">
                    <label>From Date</label>
                    <input type="date" name="fromDate" required />
                </div>
                <div class="form-group">
                    <label>To Date</label>
                    <input type="date" name="toDate" required />
                </div>
                <div class="form-group">
                    <button type="button" class="btn btn-preview" style="margin-top: 18px;" onclick="doAction('preview')">Preview Data</button>
                </div>
            </div>
        <% } else if (sqlConnected && !oraConnected) { %>
            <div class="info-box">SQL Server connected. Now test <b>Oracle</b> connection to proceed.</div>
        <% } else if (!sqlConnected && oraConnected) { %>
            <div class="info-box">Oracle connected. Now test <b>SQL Server</b> connection to proceed.</div>
        <% } else { %>
            <div class="info-box">Test <b>both</b> database connections to proceed. You can test them in any order.</div>
        <% } %>

    </form>

<%
    }

    // =============================================
    // STEP 2: PREVIEW - SELECT ONLY
    // =============================================
    else if ("preview".equals(action) && sqlServer != null && oraHost != null) {

        Connection sqlConn = null;
        PreparedStatement sqlPs = null;
        ResultSet rs = null;

        try {
            Class.forName(sqlDriverClass);
            sqlConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);

            // Count rows
            String countQuery = "SELECT COUNT(*) AS CNT FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN '" + fromDate + "' AND '" + toDate + "'";
            sqlPs = sqlConn.prepareStatement("SELECT COUNT(*) AS CNT FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN ? AND ?");
            sqlPs.setString(1, fromDate);
            sqlPs.setString(2, toDate);
            rs = sqlPs.executeQuery();
            rs.next();
            int totalRows = rs.getInt("CNT");
            rs.close();
            sqlPs.close();

            // Total size
            String sizeQuery = "SELECT SUM(LEN(FILECONTENT)) AS TOTAL_SIZE FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN '" + fromDate + "' AND '" + toDate + "'";
            sqlPs = sqlConn.prepareStatement("SELECT SUM(LEN(FILECONTENT)) AS TOTAL_SIZE FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN ? AND ?");
            sqlPs.setString(1, fromDate);
            sqlPs.setString(2, toDate);
            rs = sqlPs.executeQuery();
            rs.next();
            long totalSizeMB = rs.getLong("TOTAL_SIZE") / (1024 * 1024);
            rs.close();
            sqlPs.close();

            // Sample query
            String sampleQuery = "SELECT TOP 20 SRDUID, LEN(FILECONTENT) AS CONTENT_SIZE, "
                + sqlDateCol + " FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN '" + fromDate + "' AND '" + toDate + "'"
                + " ORDER BY " + sqlDateCol;

            // SELECT query for update step
            String selectQuery = "SELECT SRDUID, FILECONTENT FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN '" + fromDate + "' AND '" + toDate + "'";

            // UPDATE query for Oracle
            String updateQuery = "UPDATE " + oraTable + " SET FILECONTENT = ? WHERE SRDUID = ?";
%>
            <div class="info-box">
                <b>Preview Results</b> — SELECT only, no changes made
            </div>

            <!-- QUERIES SECTION -->
            <div class="query-section">
                <h3>Queries Being Executed</h3>

                <span class="query-label count">COUNT QUERY</span>
                <span style="font-size:12px; color:#666;"> — SQL Server (executed)</span>
                <div class="query-box"><%= countQuery %></div>

                <span class="query-label count">SIZE QUERY</span>
                <span style="font-size:12px; color:#666;"> — SQL Server (executed)</span>
                <div class="query-box"><%= sizeQuery %></div>

                <span class="query-label select">SAMPLE QUERY</span>
                <span style="font-size:12px; color:#666;"> — SQL Server (executed)</span>
                <div class="query-box"><%= sampleQuery %></div>

                <hr/>

                <span class="query-label select">SELECT QUERY</span>
                <span style="font-size:12px; color:#666;"> — SQL Server (will execute on UPDATE)</span>
                <div class="query-box"><%= selectQuery %></div>

                <span class="query-label update">UPDATE QUERY</span>
                <span style="font-size:12px; color:#666;"> — Oracle (will execute on UPDATE)</span>
                <div class="query-box"><%= updateQuery %></div>
            </div>

            <div class="summary">
                Date Range: <%= fromDate %> to <%= toDate %><br/>
                Total Rows Found: <span style="color: #007bff;"><%= totalRows %></span><br/>
                Total Data Size: <span style="color: #007bff;"><%= totalSizeMB %> MB</span>
            </div>

            <% if (totalRows == 0) { %>
                <div class="warn-box">No rows found for this date range. Try a different range.</div>
                <br/>
                <a href="?" class="btn btn-preview" style="text-decoration:none;">Go Back</a>
            <% } else { %>

                <h3>Sample Data (First 20 rows)</h3>
                <table>
                    <tr>
                        <th>#</th>
                        <th>SRDUID</th>
                        <th>FILECONTENT Size</th>
                        <th><%= sqlDateCol %></th>
                    </tr>
<%
                    sqlPs = sqlConn.prepareStatement("SELECT TOP 20 SRDUID, LEN(FILECONTENT) AS CONTENT_SIZE, "
                        + sqlDateCol + " FROM " + sqlTable
                        + " WHERE FILECONTENT IS NOT NULL"
                        + " AND " + sqlDateCol + " BETWEEN ? AND ?"
                        + " ORDER BY " + sqlDateCol);
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

                <!-- UPDATE BUTTON -->
                <div class="toggle-section">
                    <b>Ready to execute UPDATE on Oracle?</b><br/><br/>
                    <span style="color: red;">
                        WARNING: This will update <b><%= totalRows %></b> rows (<b><%= totalSizeMB %> MB</b>)
                        in Oracle table <b><%= oraTable %></b>
                    </span><br/><br/>

                    <form method="post" onsubmit="return confirm('Are you sure you want to UPDATE <%= totalRows %> rows (<%= totalSizeMB %> MB) in Oracle?');">
                        <input type="hidden" name="sqlServer" value="<%= sqlServer %>" />
                        <input type="hidden" name="sqlPort" value="<%= sqlPort %>" />
                        <input type="hidden" name="sqlDatabase" value="<%= sqlDatabase %>" />
                        <input type="hidden" name="sqlUser" value="<%= sqlUser %>" />
                        <input type="hidden" name="sqlPass" value="<%= sqlPass %>" />
                        <input type="hidden" name="sqlTable" value="<%= sqlTable %>" />
                        <input type="hidden" name="sqlDateCol" value="<%= sqlDateCol %>" />
                        <input type="hidden" name="sqlDriver" value="<%= sqlDriver %>" />
                        <input type="hidden" name="oraHost" value="<%= oraHost %>" />
                        <input type="hidden" name="oraPort" value="<%= oraPort %>" />
                        <input type="hidden" name="oraConnType" value="<%= oraConnType %>" />
                        <input type="hidden" name="oraSid" value="<%= oraSid %>" />
                        <input type="hidden" name="oraUser" value="<%= oraUser %>" />
                        <input type="hidden" name="oraPass" value="<%= oraPass %>" />
                        <input type="hidden" name="oraTable" value="<%= oraTable %>" />
                        <input type="hidden" name="fromDate" value="<%= fromDate %>" />
                        <input type="hidden" name="toDate" value="<%= toDate %>" />
                        <input type="hidden" name="totalRows" value="<%= totalRows %>" />
                        <input type="hidden" name="action" value="update" />
                        <button type="submit" class="btn btn-update">Execute UPDATE on Oracle</button>
                        <a href="?" class="btn btn-cancel" style="text-decoration:none;">Cancel - Start Over</a>
                    </form>
                </div>

            <% } %>
<%
        } catch (Exception e) {
%>
            <div class="error-box">ERROR: <%= e.getMessage() %></div>
            <br/>
            <a href="?" class="btn btn-preview" style="text-decoration:none;">Go Back</a>
<%
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (sqlPs != null) try { sqlPs.close(); } catch(Exception e) {}
            if (sqlConn != null) try { sqlConn.close(); } catch(Exception e) {}
        }
    }

    // =============================================
    // STEP 3: EXECUTE UPDATE
    // =============================================
    else if ("update".equals(action) && sqlServer != null && oraHost != null) {

        Connection sqlConn = null;
        Connection oraConn = null;
        PreparedStatement sqlPs = null;
        PreparedStatement oraPs = null;
        ResultSet rs = null;

        try {
            int totalRows = Integer.parseInt(request.getParameter("totalRows"));

            Class.forName(sqlDriverClass);
            Class.forName("oracle.jdbc.driver.OracleDriver");

            sqlConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);
            oraConn = DriverManager.getConnection(oraUrl, oraUser, oraPass);
            oraConn.setAutoCommit(false);

            String sqlQuery = "SELECT SRDUID, FILECONTENT FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN '" + fromDate + "' AND '" + toDate + "'";
            String oraQuery = "UPDATE " + oraTable + " SET FILECONTENT = ? WHERE SRDUID = ?";
%>
            <div class="warn-box">
                <b>UPDATE IN PROGRESS</b> — Do not close this page!
            </div>

            <!-- SHOW QUERIES DURING UPDATE -->
            <div class="query-section">
                <h3>Executing Queries</h3>
                <span class="query-label select">SELECT</span>
                <span style="font-size:12px; color:#666;"> — SQL Server (reading data)</span>
                <div class="query-box"><%= sqlQuery %></div>

                <span class="query-label update">UPDATE</span>
                <span style="font-size:12px; color:#666;"> — Oracle (writing data, per row)</span>
                <div class="query-box"><%= oraQuery %></div>
            </div>

            <pre>
Connected to SQL Server (Driver: <%= sqlDriver.toUpperCase() %>)
Connected to Oracle
SQL Server URL: <%= sqlUrl %>
Oracle URL: <%= oraUrl %>
Date Range: <%= fromDate %> to <%= toDate %>
Starting update of <%= totalRows %> rows...
========================================
<%
            out.flush();

            sqlPs = sqlConn.prepareStatement("SELECT SRDUID, FILECONTENT FROM " + sqlTable
                + " WHERE FILECONTENT IS NOT NULL"
                + " AND " + sqlDateCol + " BETWEEN ? AND ?",
                ResultSet.TYPE_FORWARD_ONLY,
                ResultSet.CONCUR_READ_ONLY);
            sqlPs.setFetchSize(1);
            sqlPs.setString(1, fromDate);
            sqlPs.setString(2, toDate);
            rs = sqlPs.executeQuery();

            oraPs = oraConn.prepareStatement(oraQuery);

            int count = 0;
            int success = 0;
            int failed = 0;
            int notFound = 0;
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
                        if (updated > 0) {
                            success++;
                        } else {
                            notFound++;
                        }
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
                    long remSeconds = (remaining % 60000) / 1000;
                    int percent = (int)((count * 100.0) / totalRows);

                    out.println("[" + percent + "%] " + count + "/" + totalRows
                        + " | Updated: " + success
                        + " | Not Found: " + notFound
                        + " | Failed: " + failed
                        + " | ETA: " + remMinutes + "m " + remSeconds + "s");
                    out.flush();
                }
            }

            // Final commit
            oraConn.commit();
            long totalTime = (System.currentTimeMillis() - startTime) / 1000;
%>
========================================
COMPLETED!
Date Range  : <%= fromDate %> to <%= toDate %>
Total Rows  : <%= count %>
Updated     : <%= success %>
Not Found   : <%= notFound %> (SRDUID not in Oracle table)
Failed      : <%= failed %>
Time Taken  : <%= (totalTime / 60) %> min <%= (totalTime % 60) %> sec
            </pre>

            <% if (failed == 0 && notFound == 0) { %>
                <div class="success-box">Update completed successfully! <b><%= success %></b> rows updated.</div>
            <% } else if (failed == 0) { %>
                <div class="success-box">
                    Update completed! <b><%= success %></b> updated.
                    <b><%= notFound %></b> SRDUIDs not found in Oracle.
                </div>
            <% } else { %>
                <div class="warn-box">
                    Completed with errors. Updated: <b><%= success %></b> |
                    Not Found: <b><%= notFound %></b> | Failed: <b><%= failed %></b>
                </div>
            <% } %>

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
%>
            <br/>
            <a href="?" class="btn btn-preview" style="text-decoration:none;">Go Back</a>
<%
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
