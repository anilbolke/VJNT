<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head><title>Database Connection Test</title>
<style>
    body { font-family: Arial; margin: 30px; background: #f5f5f5; }
    .box { background: white; padding: 20px; border-radius: 8px; max-width: 700px; margin: 0 auto; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    h2 { color: #333; }
    .ok { background: #d4edda; border-left: 4px solid #28a745; padding: 12px; margin: 10px 0; border-radius: 4px; color: #155724; }
    .fail { background: #f8d7da; border-left: 4px solid #dc3545; padding: 12px; margin: 10px 0; border-radius: 4px; color: #721c24; }
    .info { background: #e7f3fe; border-left: 4px solid #007bff; padding: 12px; margin: 10px 0; border-radius: 4px; }
    pre { background: #f8f9fa; padding: 10px; border-radius: 4px; font-size: 12px; overflow-x: auto; }
</style>
</head>
<body>
<div class="box">
<h2>Database Connection Test</h2>

<%-- ========== TEST 1: Check JDBC Drivers ========== --%>
<h3>Step 1: JDBC Drivers</h3>
<%
    boolean sqlDriverOk = false;
    boolean oraDriverOk = false;

    try {
        Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
        sqlDriverOk = true;
%>
        <div class="ok">SQL Server JDBC Driver: FOUND</div>
<%
    } catch (ClassNotFoundException e) {
%>
        <div class="fail">
            SQL Server JDBC Driver: NOT FOUND<br/>
            <b>Fix:</b> Download <code>mssql-jdbc-*.jar</code> and place it in <code>WEB-INF/lib/</code>
        </div>
<%
    }

    try {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        oraDriverOk = true;
%>
        <div class="ok">Oracle JDBC Driver: FOUND</div>
<%
    } catch (ClassNotFoundException e) {
%>
        <div class="fail">
            Oracle JDBC Driver: NOT FOUND<br/>
            <b>Fix:</b> Download <code>ojdbc8.jar</code> and place it in <code>WEB-INF/lib/</code>
        </div>
<%
    }
%>

<%-- ========== TEST 2: SQL Server Connection ========== --%>
<h3>Step 2: SQL Server Connection</h3>
<%
    if (sqlDriverOk) {
        // === CHANGE THESE VALUES ===
        String sqlUrl  = "jdbc:sqlserver://YOUR_SERVER:1433;databaseName=YOUR_DB";
        String sqlUser = "YOUR_USER";
        String sqlPass = "YOUR_PASS";
        // ===========================

        Connection sqlConn = null;
        try {
            long start = System.currentTimeMillis();
            sqlConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);
            long time = System.currentTimeMillis() - start;

            DatabaseMetaData meta = sqlConn.getMetaData();
%>
            <div class="ok">
                SQL Server: CONNECTED in <%= time %>ms<br/>
                Product: <%= meta.getDatabaseProductName() %> <%= meta.getDatabaseProductVersion() %><br/>
                URL: <%= sqlUrl %>
            </div>
<%
            // Test table access
            try {
                Statement stmt = sqlConn.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS CNT FROM YOUR_SQL_TABLE WHERE FILECONTENT IS NOT NULL");
                rs.next();
                int cnt = rs.getInt("CNT");
                rs.close();
                stmt.close();
%>
                <div class="ok">Table Access: OK | Rows with FILECONTENT: <%= cnt %></div>
<%
            } catch (Exception tableEx) {
%>
                <div class="fail">Table Access: FAILED | <%= tableEx.getMessage() %></div>
<%
            }

        } catch (Exception e) {
%>
            <div class="fail">
                SQL Server: FAILED<br/>
                URL: <%= sqlUrl %><br/>
                Error: <%= e.getMessage() %>
            </div>
            <div class="info">
                <b>Common causes:</b><br/>
                - Wrong server IP or port<br/>
                - SQL Authentication not enabled (only Windows Auth)<br/>
                - Firewall blocking port 1433<br/>
                - Wrong username/password<br/>
                - Database name incorrect
            </div>
<%
        } finally {
            if (sqlConn != null) try { sqlConn.close(); } catch(Exception e) {}
        }
    }
%>

<%-- ========== TEST 3: Oracle Connection ========== --%>
<h3>Step 3: Oracle Connection</h3>
<%
    if (oraDriverOk) {
        // === CHANGE THESE VALUES ===
        // For Service Name:
        String oraUrl  = "jdbc:oracle:thin:@//YOUR_HOST:1521/YOUR_SERVICE_NAME";
        // For SID use:
        // String oraUrl  = "jdbc:oracle:thin:@YOUR_HOST:1521:YOUR_SID";
        String oraUser = "YOUR_USER";
        String oraPass = "YOUR_PASS";
        // ===========================

        Connection oraConn = null;
        try {
            long start = System.currentTimeMillis();
            oraConn = DriverManager.getConnection(oraUrl, oraUser, oraPass);
            long time = System.currentTimeMillis() - start;

            DatabaseMetaData meta = oraConn.getMetaData();
%>
            <div class="ok">
                Oracle: CONNECTED in <%= time %>ms<br/>
                Product: <%= meta.getDatabaseProductName() %> <%= meta.getDatabaseProductVersion() %><br/>
                URL: <%= oraUrl %>
            </div>
<%
            // Test table access + update permission
            try {
                Statement stmt = oraConn.createStatement();
                ResultSet rs = stmt.executeQuery("SELECT COUNT(*) AS CNT FROM YOUR_ORACLE_TABLE");
                rs.next();
                int cnt = rs.getInt("CNT");
                rs.close();
                stmt.close();
%>
                <div class="ok">Table Access: OK | Total Rows: <%= cnt %></div>
<%
            } catch (Exception tableEx) {
%>
                <div class="fail">Table Access: FAILED | <%= tableEx.getMessage() %></div>
<%
            }

            // Test UPDATE permission
            try {
                oraConn.setAutoCommit(false);
                PreparedStatement ps = oraConn.prepareStatement(
                    "UPDATE YOUR_ORACLE_TABLE SET FILECONTENT = FILECONTENT WHERE 1=0"
                );
                ps.executeUpdate();
                oraConn.rollback();
                ps.close();
%>
                <div class="ok">UPDATE Permission: OK</div>
<%
            } catch (Exception permEx) {
%>
                <div class="fail">UPDATE Permission: DENIED | <%= permEx.getMessage() %></div>
<%
            }

        } catch (Exception e) {
%>
            <div class="fail">
                Oracle: FAILED<br/>
                URL: <%= oraUrl %><br/>
                Error: <%= e.getMessage() %>
            </div>
            <div class="info">
                <b>Common causes:</b><br/>
                - ORA-12541: TNS no listener (wrong host/port)<br/>
                - ORA-12514: TNS listener does not know service (wrong service name)<br/>
                - ORA-01017: Invalid username/password<br/>
                - ORA-28000: Account locked<br/>
                - Firewall blocking port 1521
            </div>
<%
        } finally {
            if (oraConn != null) try { oraConn.close(); } catch(Exception e) {}
        }
    }
%>

<hr/>
<h3>Summary</h3>
<div class="info">
    If both show <b>CONNECTED</b> + <b>Table Access OK</b> + <b>UPDATE Permission OK</b>,
    then the migration JSP will work perfectly.
</div>

</div>
</body>
</html>
