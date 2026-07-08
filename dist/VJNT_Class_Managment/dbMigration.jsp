<%@ page import="java.sql.*, java.io.*, java.util.*" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page buffer="8kb" autoFlush="true" %>
<html>
<head>
<title>SQL Server to Oracle - Full Migration</title>
<style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1000px; margin: 0 auto; background: white; padding: 25px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
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
    .btn-create { background: #28a745; color: white; font-size: 15px; padding: 12px 30px; }
    .btn-create:hover { background: #218838; }
    .btn-migrate { background: #dc3545; color: white; font-size: 16px; padding: 12px 30px; }
    .btn-migrate:hover { background: #a71d2a; }
    .btn-cancel { background: #6c757d; color: white; text-decoration: none; padding: 12px 25px; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th { background: #007bff; color: white; padding: 10px; text-align: left; font-size: 13px; }
    td { padding: 8px 10px; border-bottom: 1px solid #ddd; font-size: 13px; }
    tr:hover { background: #f0f0f0; }
    .info-box { background: #e7f3fe; border-left: 4px solid #007bff; padding: 12px; margin: 15px 0; border-radius: 4px; }
    .warn-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 12px; margin: 15px 0; border-radius: 4px; }
    .success-box { background: #d4edda; border-left: 4px solid #28a745; padding: 12px; margin: 15px 0; border-radius: 4px; }
    .error-box { background: #f8d7da; border-left: 4px solid #dc3545; padding: 12px; margin: 15px 0; border-radius: 4px; }
    pre { background: #f8f9fa; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 13px; }
    .query-box { background: #1e1e1e; color: #d4d4d4; padding: 15px; border-radius: 5px; margin: 10px 0; font-family: 'Courier New', monospace; font-size: 13px; overflow-x: auto; white-space: pre-wrap; word-wrap: break-word; }
    .query-label { display: inline-block; background: #6c757d; color: white; padding: 3px 10px; border-radius: 3px; font-size: 12px; font-weight: bold; margin-bottom: 5px; }
    .query-label.ddl { background: #17a2b8; }
    .query-label.insert { background: #28a745; }
    .query-label.select { background: #007bff; }
    .query-section { margin: 15px 0; border: 1px solid #ddd; border-radius: 8px; padding: 15px; background: #f8f9fa; }
    .summary { font-size: 18px; font-weight: bold; margin: 15px 0; }
    .status-box { padding: 10px 15px; margin: 8px 0; border-radius: 5px; font-weight: bold; font-size: 13px; }
    .status-ok { background: #d4edda; border-left: 4px solid #28a745; color: #155724; }
    .status-fail { background: #f8d7da; border-left: 4px solid #dc3545; color: #721c24; }
    .status-wait { background: #e2e3e5; border-left: 4px solid #6c757d; color: #383d41; }
    .arrow { color: #007bff; font-weight: bold; }
    .type-sql { color: #0078d4; }
    .type-ora { color: #f80000; font-weight: bold; }
    hr { border: none; border-top: 1px solid #eee; margin: 20px 0; }
    .checkbox-group { margin: 10px 0; }
    .checkbox-group label { font-weight: normal; font-size: 14px; cursor: pointer; }
    .checkbox-group input[type="checkbox"] { width: auto; margin-right: 8px; }
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
<h2>Full Migration: SQL Server to Oracle (Structure + Data)</h2>

<%!
    // =============================================
    // SQL Server to Oracle DATA TYPE MAPPING
    // =============================================
    public static String mapDataType(String sqlType, int size, int precision, int scale) {
        if (sqlType == null) return "VARCHAR2(255)";
        sqlType = sqlType.toUpperCase().trim();

        // String types
        if (sqlType.equals("VARCHAR") || sqlType.equals("NVARCHAR")) {
            if (size <= 0 || size > 4000) return "CLOB";
            return "VARCHAR2(" + size + ")";
        }
        if (sqlType.equals("CHAR") || sqlType.equals("NCHAR")) {
            if (size <= 0 || size > 2000) return "CHAR(2000)";
            return "CHAR(" + size + ")";
        }
        if (sqlType.equals("TEXT") || sqlType.equals("NTEXT")) return "CLOB";
        if (sqlType.equals("VARCHAR(MAX)") || sqlType.equals("NVARCHAR(MAX)")) return "CLOB";

        // Numeric types
        if (sqlType.equals("INT") || sqlType.equals("INTEGER")) return "NUMBER(10)";
        if (sqlType.equals("BIGINT")) return "NUMBER(19)";
        if (sqlType.equals("SMALLINT")) return "NUMBER(5)";
        if (sqlType.equals("TINYINT")) return "NUMBER(3)";
        if (sqlType.equals("BIT")) return "NUMBER(1)";
        if (sqlType.equals("DECIMAL") || sqlType.equals("NUMERIC")) {
            return "NUMBER(" + precision + "," + scale + ")";
        }
        if (sqlType.equals("FLOAT")) return "FLOAT";
        if (sqlType.equals("REAL")) return "FLOAT(24)";
        if (sqlType.equals("MONEY")) return "NUMBER(19,4)";
        if (sqlType.equals("SMALLMONEY")) return "NUMBER(10,4)";

        // Date/Time types
        if (sqlType.equals("DATETIME") || sqlType.equals("DATETIME2")) return "TIMESTAMP";
        if (sqlType.equals("SMALLDATETIME")) return "DATE";
        if (sqlType.equals("DATE")) return "DATE";
        if (sqlType.equals("TIME")) return "TIMESTAMP";
        if (sqlType.equals("DATETIMEOFFSET")) return "TIMESTAMP WITH TIME ZONE";

        // Binary types
        if (sqlType.equals("VARBINARY") || sqlType.equals("VARBINARY(MAX)")) return "BLOB";
        if (sqlType.equals("BINARY")) return "RAW(" + (size > 0 ? size : 2000) + ")";
        if (sqlType.equals("IMAGE")) return "BLOB";

        // Other
        if (sqlType.equals("UNIQUEIDENTIFIER")) return "VARCHAR2(36)";
        if (sqlType.equals("XML")) return "XMLTYPE";

        // Default
        return "VARCHAR2(255)";
    }
%>

<%
    String action = request.getParameter("action");

    // SQL Server params
    String sqlServer   = request.getParameter("sqlServer");
    String sqlPort     = request.getParameter("sqlPort");
    String sqlDatabase = request.getParameter("sqlDatabase");
    String sqlUser     = request.getParameter("sqlUser");
    String sqlPass     = request.getParameter("sqlPass");
    String sqlTable    = request.getParameter("sqlTable");
    String sqlDriver   = request.getParameter("sqlDriver");

    // Oracle params
    String oraHost     = request.getParameter("oraHost");
    String oraPort     = request.getParameter("oraPort");
    String oraConnType = request.getParameter("oraConnType");
    String oraSid      = request.getParameter("oraSid");
    String oraUser     = request.getParameter("oraUser");
    String oraPass     = request.getParameter("oraPass");
    String oraTable    = request.getParameter("oraTable");

    // Defaults - SQL Server
    if (sqlServer == null) sqlServer = "10.5.7.149";
    if (sqlPort == null) sqlPort = "1757";
    if (sqlDatabase == null) sqlDatabase = "IDFCDigiRemit";
    if (sqlUser == null) sqlUser = "digiremit";
    if (sqlPass == null) sqlPass = "Di$iReM!T2026";
    if (sqlTable == null) sqlTable = "TXNSENDERRISKDOCUPLOADDETAILS";
    if (sqlDriver == null) sqlDriver = "jtds";

    // Defaults - Oracle
    if (oraHost == null) oraHost = "10.5.7.149";
    if (oraPort == null) oraPort = "1521";
    if (oraConnType == null) oraConnType = "service";
    if (oraSid == null) oraSid = "DIGIREMI";
    if (oraUser == null) oraUser = "DIGIREMIT";
    if (oraPass == null) oraPass = "IDfc$#Feb2026";
    if (oraTable == null) oraTable = "";

    // Connection status
    String sqlStatus = request.getParameter("sqlStatus");
    String oraStatus = request.getParameter("oraStatus");
    String sqlMsg    = request.getParameter("sqlMsg");
    String oraMsg    = request.getParameter("oraMsg");
    if (sqlStatus == null) sqlStatus = "";
    if (oraStatus == null) oraStatus = "";
    if (sqlMsg == null) sqlMsg = "";
    if (oraMsg == null) oraMsg = "";

    // Build URLs
    String sqlUrl = "";
    String sqlDriverClass = "";
    if (sqlServer != null && sqlServer.length() > 0) {
        if ("jtds".equals(sqlDriver)) {
            sqlDriverClass = "net.sourceforge.jtds.jdbc.Driver";
            sqlUrl = "jdbc:jtds:sqlserver://" + sqlServer + ":" + sqlPort + "/" + sqlDatabase;
        } else {
            sqlDriverClass = "com.microsoft.sqlserver.jdbc.SQLServerDriver";
            sqlUrl = "jdbc:sqlserver://" + sqlServer + ":" + sqlPort
                + ";databaseName=" + sqlDatabase
                + ";encrypt=false;trustServerCertificate=true";
        }
    }

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
            sqlMsg = "CONNECTED in " + time + "ms | " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion();
            testConn.close();
            sqlStatus = "ok";
        } catch (ClassNotFoundException e) {
            sqlMsg = "DRIVER NOT FOUND | Place jtds-1.3.1.jar in WEB-INF/lib/";
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
            oraMsg = "CONNECTED in " + time + "ms | " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion();
            testConn.close();
            oraStatus = "ok";
        } catch (ClassNotFoundException e) {
            oraMsg = "DRIVER NOT FOUND | Place ojdbc8.jar in WEB-INF/lib/";
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
                        <option value="jtds" <%= "jtds".equals(sqlDriver) ? "selected" : "" %>>JTDS (Recommended)</option>
                        <option value="mssql" <%= "mssql".equals(sqlDriver) ? "selected" : "" %>>Microsoft JDBC</option>
                    </select>
                </div>
                <div class="form-group">
                    <label>Server / IP</label>
                    <input type="text" name="sqlServer" value="<%= sqlServer %>" required />
                </div>
                <div class="form-group">
                    <label>Port</label>
                    <input type="text" name="sqlPort" value="<%= sqlPort %>" />
                </div>
                <div class="form-group">
                    <label>Database Name</label>
                    <input type="text" name="sqlDatabase" value="<%= sqlDatabase %>" required />
                </div>
                <div class="form-group">
                    <label>Username</label>
                    <input type="text" name="sqlUser" value="<%= sqlUser %>" required />
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" name="sqlPass" value="<%= sqlPass %>" required />
                </div>
                <div class="form-group">
                    <label>Source Table Name</label>
                    <input type="text" name="sqlTable" value="<%= sqlTable %>" placeholder="e.g. TXNSENDERRISKDOCUPLOADDETAILS" required />
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
                    <input type="text" name="oraHost" value="<%= oraHost %>" required />
                </div>
                <div class="form-group">
                    <label>Port</label>
                    <input type="text" name="oraPort" value="<%= oraPort %>" />
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
                    <input type="text" name="oraSid" value="<%= oraSid %>" required />
                </div>
                <div class="form-group">
                    <label>Username</label>
                    <input type="text" name="oraUser" value="<%= oraUser %>" required />
                </div>
                <div class="form-group">
                    <label>Password</label>
                    <input type="password" name="oraPass" value="<%= oraPass %>" required />
                </div>
                <div class="form-group">
                    <label>Destination Table Name (leave blank = same as source)</label>
                    <input type="text" name="oraTable" value="<%= oraTable %>" placeholder="Leave blank to use same name" />
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
            <div class="success-box">Both databases connected! Click below to preview table structure.</div>
            <br/>
            <button type="button" class="btn btn-preview" onclick="doAction('preview')">Preview Table Structure &amp; Data</button>
        <% } else { %>
            <div class="info-box">Test <b>both</b> connections to proceed.</div>
        <% } %>

    </form>

<%
    }

    // =============================================
    // STEP 2: PREVIEW STRUCTURE + DATA
    // =============================================
    else if ("preview".equals(action)) {

        // If oraTable is blank, use same name as source
        if (oraTable == null || oraTable.trim().length() == 0) {
            oraTable = sqlTable;
        }

        Connection sqlConn = null;
        Statement sqlStmt = null;
        ResultSet rs = null;

        try {
            Class.forName(sqlDriverClass);
            sqlConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);

            // Get table structure
            DatabaseMetaData meta = sqlConn.getMetaData();
            rs = meta.getColumns(null, null, sqlTable, null);

            // Store columns
            List<String> colNames = new ArrayList<String>();
            List<String> sqlTypes = new ArrayList<String>();
            List<String> oraTypes = new ArrayList<String>();
            List<String> nullables = new ArrayList<String>();
            List<Integer> colSizes = new ArrayList<Integer>();

            while (rs.next()) {
                String colName = rs.getString("COLUMN_NAME");
                String typeName = rs.getString("TYPE_NAME");
                int size = rs.getInt("COLUMN_SIZE");
                int precision = rs.getInt("COLUMN_SIZE");
                int scale = rs.getInt("DECIMAL_DIGITS");
                String nullable = rs.getInt("NULLABLE") == DatabaseMetaData.columnNullable ? "NULL" : "NOT NULL";

                String sqlTypeDisplay = typeName;
                if (typeName.equalsIgnoreCase("VARCHAR") || typeName.equalsIgnoreCase("NVARCHAR") ||
                    typeName.equalsIgnoreCase("CHAR") || typeName.equalsIgnoreCase("NCHAR")) {
                    sqlTypeDisplay = typeName + "(" + size + ")";
                } else if (typeName.equalsIgnoreCase("DECIMAL") || typeName.equalsIgnoreCase("NUMERIC")) {
                    sqlTypeDisplay = typeName + "(" + precision + "," + scale + ")";
                }

                String oracleType = mapDataType(typeName, size, precision, scale);

                colNames.add(colName);
                sqlTypes.add(sqlTypeDisplay);
                oraTypes.add(oracleType);
                nullables.add(nullable);
                colSizes.add(size);
            }
            rs.close();

            // Get primary keys
            rs = meta.getPrimaryKeys(null, null, sqlTable);
            List<String> pkColumns = new ArrayList<String>();
            while (rs.next()) {
                pkColumns.add(rs.getString("COLUMN_NAME"));
            }
            rs.close();

            // Get row count
            sqlStmt = sqlConn.createStatement();
            rs = sqlStmt.executeQuery("SELECT COUNT(*) AS CNT FROM " + sqlTable);
            rs.next();
            int totalRows = rs.getInt("CNT");
            rs.close();

            // Get table size
            rs = sqlStmt.executeQuery("EXEC sp_spaceused '" + sqlTable + "'");
            String tableSize = "N/A";
            if (rs.next()) {
                tableSize = rs.getString("data");
            }
            rs.close();
            sqlStmt.close();

            // Build CREATE TABLE DDL for Oracle
            StringBuilder createDDL = new StringBuilder();
            createDDL.append("CREATE TABLE " + oraTable + " (\n");
            for (int i = 0; i < colNames.size(); i++) {
                createDDL.append("    " + colNames.get(i) + " " + oraTypes.get(i));
                if ("NOT NULL".equals(nullables.get(i)) || pkColumns.contains(colNames.get(i))) {
                    createDDL.append(" NOT NULL");
                }
                if (i < colNames.size() - 1) createDDL.append(",");
                createDDL.append("\n");
            }
            if (!pkColumns.isEmpty()) {
                createDDL.append("    ,CONSTRAINT PK_" + oraTable + " PRIMARY KEY (");
                for (int i = 0; i < pkColumns.size(); i++) {
                    if (i > 0) createDDL.append(", ");
                    createDDL.append(pkColumns.get(i));
                }
                createDDL.append(")\n");
            }
            createDDL.append(")");

            // Build INSERT query
            StringBuilder insertCols = new StringBuilder();
            StringBuilder insertParams = new StringBuilder();
            for (int i = 0; i < colNames.size(); i++) {
                if (i > 0) { insertCols.append(", "); insertParams.append(", "); }
                insertCols.append(colNames.get(i));
                insertParams.append("?");
            }
            String insertDDL = "INSERT INTO " + oraTable + " (" + insertCols + ") VALUES (" + insertParams + ")";

            // Build SELECT query
            String selectQuery = "SELECT * FROM " + sqlTable;
%>
            <div class="info-box"><b>Preview</b> — Review structure and queries before migration</div>

            <div class="summary">
                Source Table: <span class="type-sql"><%= sqlTable %></span><br/>
                Destination Table: <span class="type-ora"><%= oraTable %></span><br/>
                Total Rows: <span style="color: #007bff;"><%= totalRows %></span><br/>
                Data Size: <span style="color: #007bff;"><%= tableSize %></span>
            </div>

            <!-- COLUMN MAPPING -->
            <h3>Column Mapping (SQL Server → Oracle)</h3>
            <table>
                <tr>
                    <th>#</th>
                    <th>Column Name</th>
                    <th>SQL Server Type</th>
                    <th></th>
                    <th>Oracle Type</th>
                    <th>Nullable</th>
                    <th>PK</th>
                </tr>
<%
                for (int i = 0; i < colNames.size(); i++) {
                    boolean isPK = pkColumns.contains(colNames.get(i));
%>
                    <tr>
                        <td><%= (i + 1) %></td>
                        <td><b><%= colNames.get(i) %></b></td>
                        <td class="type-sql"><%= sqlTypes.get(i) %></td>
                        <td class="arrow">→</td>
                        <td class="type-ora"><%= oraTypes.get(i) %></td>
                        <td><%= nullables.get(i) %></td>
                        <td><%= isPK ? "<b>PK</b>" : "" %></td>
                    </tr>
<%
                }
%>
            </table>

            <!-- QUERIES -->
            <div class="query-section">
                <h3>Queries to Execute</h3>

                <span class="query-label ddl">CREATE TABLE</span>
                <span style="font-size:12px; color:#666;"> — Oracle (Step 1: Create table)</span>
                <div class="query-box"><%= createDDL.toString() %></div>

                <span class="query-label select">SELECT</span>
                <span style="font-size:12px; color:#666;"> — SQL Server (Step 2: Read data)</span>
                <div class="query-box"><%= selectQuery %></div>

                <span class="query-label insert">INSERT</span>
                <span style="font-size:12px; color:#666;"> — Oracle (Step 2: Insert data, per row)</span>
                <div class="query-box"><%= insertDDL %></div>
            </div>

            <!-- MIGRATION OPTIONS -->
            <div class="toggle-section">
                <h3 style="margin-top:0;">Migration Options</h3>

                <form method="post" onsubmit="return confirm('Start migration of <%= totalRows %> rows to Oracle table <%= oraTable %>?');">
                    <input type="hidden" name="sqlServer" value="<%= sqlServer %>" />
                    <input type="hidden" name="sqlPort" value="<%= sqlPort %>" />
                    <input type="hidden" name="sqlDatabase" value="<%= sqlDatabase %>" />
                    <input type="hidden" name="sqlUser" value="<%= sqlUser %>" />
                    <input type="hidden" name="sqlPass" value="<%= sqlPass %>" />
                    <input type="hidden" name="sqlTable" value="<%= sqlTable %>" />
                    <input type="hidden" name="sqlDriver" value="<%= sqlDriver %>" />
                    <input type="hidden" name="oraHost" value="<%= oraHost %>" />
                    <input type="hidden" name="oraPort" value="<%= oraPort %>" />
                    <input type="hidden" name="oraConnType" value="<%= oraConnType %>" />
                    <input type="hidden" name="oraSid" value="<%= oraSid %>" />
                    <input type="hidden" name="oraUser" value="<%= oraUser %>" />
                    <input type="hidden" name="oraPass" value="<%= oraPass %>" />
                    <input type="hidden" name="oraTable" value="<%= oraTable %>" />
                    <input type="hidden" name="totalRows" value="<%= totalRows %>" />
                    <input type="hidden" name="createDDL" value="<%= createDDL.toString().replace("\"", "&quot;") %>" />
                    <input type="hidden" name="colCount" value="<%= colNames.size() %>" />
<%
                    for (int i = 0; i < colNames.size(); i++) {
%>
                        <input type="hidden" name="col_<%= i %>" value="<%= colNames.get(i) %>" />
                        <input type="hidden" name="oraType_<%= i %>" value="<%= oraTypes.get(i) %>" />
<%
                    }
%>

                    <div class="checkbox-group">
                        <label><input type="checkbox" name="createTable" value="yes" checked /> Create table in Oracle (uncheck if table already exists)</label>
                    </div>
                    <div class="checkbox-group">
                        <label><input type="checkbox" name="dropFirst" value="yes" /> Drop existing table first (if exists)</label>
                    </div>
                    <div class="checkbox-group">
                        <label><input type="checkbox" name="migrateData" value="yes" checked /> Migrate data</label>
                    </div>
                    <br/>

                    <input type="hidden" name="action" value="migrate" />
                    <button type="submit" class="btn btn-migrate">Start Migration</button>
                    <a href="?" class="btn btn-cancel" style="text-decoration:none;">Cancel</a>
                </form>
            </div>
<%
        } catch (Exception e) {
%>
            <div class="error-box">ERROR: <%= e.getMessage() %></div>
<%
            e.printStackTrace(new java.io.PrintWriter(out));
%>
            <br/>
            <a href="?" class="btn btn-preview" style="text-decoration:none;">Go Back</a>
<%
        } finally {
            if (rs != null) try { rs.close(); } catch(Exception e) {}
            if (sqlStmt != null) try { sqlStmt.close(); } catch(Exception e) {}
            if (sqlConn != null) try { sqlConn.close(); } catch(Exception e) {}
        }
    }

    // =============================================
    // STEP 3: EXECUTE MIGRATION
    // =============================================
    else if ("migrate".equals(action)) {

        if (oraTable == null || oraTable.trim().length() == 0) {
            oraTable = sqlTable;
        }

        Connection sqlConn = null;
        Connection oraConn = null;
        PreparedStatement sqlPs = null;
        PreparedStatement oraPs = null;
        Statement oraStmt = null;
        ResultSet rs = null;

        try {
            int totalRows = Integer.parseInt(request.getParameter("totalRows"));
            int colCount = Integer.parseInt(request.getParameter("colCount"));
            String createDDL = request.getParameter("createDDL");
            boolean createTable = "yes".equals(request.getParameter("createTable"));
            boolean dropFirst = "yes".equals(request.getParameter("dropFirst"));
            boolean migrateData = "yes".equals(request.getParameter("migrateData"));

            // Get column info
            String[] colNamesArr = new String[colCount];
            String[] oraTypesArr = new String[colCount];
            for (int i = 0; i < colCount; i++) {
                colNamesArr[i] = request.getParameter("col_" + i);
                oraTypesArr[i] = request.getParameter("oraType_" + i);
            }

            Class.forName(sqlDriverClass);
            Class.forName("oracle.jdbc.driver.OracleDriver");

            sqlConn = DriverManager.getConnection(sqlUrl, sqlUser, sqlPass);
            oraConn = DriverManager.getConnection(oraUrl, oraUser, oraPass);
            oraConn.setAutoCommit(false);
            oraStmt = oraConn.createStatement();
%>
            <div class="warn-box"><b>MIGRATION IN PROGRESS</b> — Do not close this page!</div>
            <pre>
Connected to SQL Server
Connected to Oracle
Source: <%= sqlTable %> (<%= totalRows %> rows)
Destination: <%= oraTable %>
========================================
<%
            out.flush();

            // STEP 1: Drop table if requested
            if (dropFirst) {
                try {
                    oraStmt.executeUpdate("DROP TABLE " + oraTable + " CASCADE CONSTRAINTS");
                    oraConn.commit();
                    out.println("Dropped existing table: " + oraTable);
                    out.flush();
                } catch (Exception dropEx) {
                    out.println("Table " + oraTable + " does not exist (OK to proceed)");
                    out.flush();
                }
            }

            // STEP 2: Create table if requested
            if (createTable) {
                try {
                    oraStmt.executeUpdate(createDDL);
                    oraConn.commit();
                    out.println("Created Oracle table: " + oraTable);
                    out.flush();
                } catch (Exception createEx) {
                    out.println("CREATE TABLE WARNING: " + createEx.getMessage());
                    out.println("Attempting to continue with data migration...");
                    out.flush();
                }
            }

            // STEP 3: Migrate data
            if (migrateData) {
                out.println("Starting data migration...");
                out.flush();

                // Build INSERT
                StringBuilder insertCols = new StringBuilder();
                StringBuilder insertParams = new StringBuilder();
                for (int i = 0; i < colCount; i++) {
                    if (i > 0) { insertCols.append(", "); insertParams.append(", "); }
                    insertCols.append(colNamesArr[i]);
                    insertParams.append("?");
                }
                String insertSQL = "INSERT INTO " + oraTable + " (" + insertCols + ") VALUES (" + insertParams + ")";

                oraPs = oraConn.prepareStatement(insertSQL);

                // Read from SQL Server
                sqlPs = sqlConn.prepareStatement("SELECT * FROM " + sqlTable,
                    ResultSet.TYPE_FORWARD_ONLY,
                    ResultSet.CONCUR_READ_ONLY);
                sqlPs.setFetchSize(100);
                rs = sqlPs.executeQuery();

                ResultSetMetaData rsMeta = rs.getMetaData();
                int count = 0;
                int success = 0;
                int failed = 0;
                int BATCH_SIZE = 100;
                int COMMIT_EVERY = 500;
                long startTime = System.currentTimeMillis();

                while (rs.next()) {
                    try {
                        for (int i = 1; i <= colCount; i++) {
                            String oraType = oraTypesArr[i - 1];
                            int sqlType = rsMeta.getColumnType(i);

                            if (rs.getObject(i) == null) {
                                oraPs.setNull(i, Types.NULL);
                            } else if (oraType.equals("CLOB")) {
                                String val = rs.getString(i);
                                if (val != null) {
                                    oraPs.setClob(i, new StringReader(val));
                                } else {
                                    oraPs.setNull(i, Types.CLOB);
                                }
                            } else if (oraType.equals("BLOB")) {
                                byte[] val = rs.getBytes(i);
                                if (val != null) {
                                    oraPs.setBytes(i, val);
                                } else {
                                    oraPs.setNull(i, Types.BLOB);
                                }
                            } else if (oraType.startsWith("TIMESTAMP")) {
                                Timestamp val = rs.getTimestamp(i);
                                oraPs.setTimestamp(i, val);
                            } else if (oraType.equals("DATE")) {
                                try {
                                    Timestamp val = rs.getTimestamp(i);
                                    oraPs.setTimestamp(i, val);
                                } catch (Exception de) {
                                    oraPs.setDate(i, rs.getDate(i));
                                }
                            } else if (oraType.startsWith("NUMBER") || oraType.startsWith("FLOAT")) {
                                oraPs.setBigDecimal(i, rs.getBigDecimal(i));
                            } else {
                                oraPs.setString(i, rs.getString(i));
                            }
                        }

                        oraPs.addBatch();
                        count++;

                        if (count % BATCH_SIZE == 0) {
                            oraPs.executeBatch();
                            success += BATCH_SIZE;
                        }

                        if (count % COMMIT_EVERY == 0) {
                            oraConn.commit();

                            long elapsed = System.currentTimeMillis() - startTime;
                            long avgPerRow = elapsed / count;
                            long remaining = avgPerRow * (totalRows - count);
                            long remMinutes = remaining / 60000;
                            long remSeconds = (remaining % 60000) / 1000;
                            int percent = (int)((count * 100.0) / totalRows);

                            out.println("[" + percent + "%] " + count + "/" + totalRows
                                + " | Inserted: " + success
                                + " | Failed: " + failed
                                + " | ETA: " + remMinutes + "m " + remSeconds + "s");
                            out.flush();
                        }

                    } catch (Exception rowEx) {
                        failed++;
                        if (failed <= 10) {
                            out.println("FAILED Row " + count + ": " + rowEx.getMessage());
                            out.flush();
                        }
                        // Clear batch on error
                        try { oraPs.clearBatch(); } catch(Exception ce) {}
                    }
                }

                // Final batch
                try {
                    oraPs.executeBatch();
                    success = count - failed;
                } catch (Exception batchEx) {
                    out.println("Final batch error: " + batchEx.getMessage());
                }
                oraConn.commit();

                long totalTime = (System.currentTimeMillis() - startTime) / 1000;
%>
========================================
MIGRATION COMPLETED!
Source Table      : <%= sqlTable %>
Destination Table : <%= oraTable %>
Total Rows        : <%= count %>
Inserted          : <%= success %>
Failed            : <%= failed %>
Time Taken        : <%= (totalTime / 60) %> min <%= (totalTime % 60) %> sec
                </pre>

                <% if (failed == 0) { %>
                    <div class="success-box">Migration completed successfully! <b><%= success %></b> rows inserted.</div>
                <% } else { %>
                    <div class="warn-box">
                        Migration completed with <b><%= failed %></b> failures.
                        <b><%= success %></b> rows inserted successfully.
                    </div>
                <% } %>

<%
            } else {
                // Structure only, no data
%>
========================================
STRUCTURE CREATED (No data migrated)
                </pre>
                <div class="success-box">Oracle table <b><%= oraTable %></b> created successfully.</div>
<%
            }
%>
            <br/>
            <a href="?" class="btn btn-preview" style="text-decoration:none;">Run Another Migration</a>
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
            if (oraStmt != null) try { oraStmt.close(); } catch(Exception e) {}
            if (sqlConn != null) try { sqlConn.close(); } catch(Exception e) {}
            if (oraConn != null) try { oraConn.close(); } catch(Exception e) {}
        }
    }
%>
</div>
</body>
</html>
