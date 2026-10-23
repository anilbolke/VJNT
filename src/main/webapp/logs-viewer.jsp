<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User" %>
<%@ page import="java.io.*" %>
<%@ page import="java.nio.charset.StandardCharsets" %>
<%@ page import="java.nio.file.*" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.*" %>
<%!
    // ── Server log viewer (DATA_ADMIN only) ─────────────────────────────
    // Shows the resolved log directory + path, lists the files in it, and
    // tails a selected file. `file` is canonical-path-checked to stay inside
    // the resolved log directory — there is no way to name an arbitrary
    // absolute path (VJNT-013: an earlier `path` parameter allowed exactly
    // that and has been removed).

    private static String esc(String s) {
        if (s == null) return "";
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }
    private static String humanSize(long b) {
        if (b < 1024) return b + " B";
        if (b < 1024 * 1024) return String.format("%.1f KB", b / 1024.0);
        if (b < 1024L * 1024 * 1024) return String.format("%.1f MB", b / (1024.0 * 1024));
        return String.format("%.2f GB", b / (1024.0 * 1024 * 1024));
    }

    /** Resolve the most likely server log directory. */
    private static File resolveLogDir(javax.servlet.ServletContext ctx) {
        String[] candidates = {
            System.getProperty("catalina.base"),
            System.getProperty("catalina.home"),
            System.getProperty("jetty.base"),
            System.getProperty("user.dir")
        };
        for (String base : candidates) {
            if (base == null) continue;
            File d = new File(base, "logs");
            if (d.isDirectory()) return d;
        }
        // Eclipse WTP sometimes keeps logs under the workspace metadata
        String tmp = System.getProperty("java.io.tmpdir");
        if (tmp != null) {
            File d = new File(tmp);
            if (d.isDirectory()) return d;
        }
        return null;
    }

    /** Read the last `maxBytes` bytes of a file as UTF-8 text. */
    private static String tail(File f, long maxBytes) throws IOException {
        long len = f.length();
        long start = Math.max(0, len - maxBytes);
        try (RandomAccessFile raf = new RandomAccessFile(f, "r")) {
            raf.seek(start);
            byte[] buf = new byte[(int) Math.min(maxBytes, len - start)];
            raf.readFully(buf);
            String s = new String(buf, StandardCharsets.UTF_8);
            if (start > 0) {
                int nl = s.indexOf('\n');
                if (nl >= 0 && nl < s.length() - 1) s = s.substring(nl + 1);
                s = "… (showing last " + humanSize(buf.length) + " of " + humanSize(len) + ")\n\n" + s;
            }
            return s;
        }
    }
%>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }
    if (!user.getUserType().equals(User.UserType.DATA_ADMIN)) {
        response.sendRedirect(request.getContextPath() + "/login"); return;
    }

    File logDir = resolveLogDir(application);

    String fileParam = request.getParameter("file");   // name within logDir
    String q         = request.getParameter("q");      // case-insensitive line filter
    boolean raw      = "1".equals(request.getParameter("raw"));
    long maxKb;
    try { maxKb = Long.parseLong(request.getParameter("kb")); } catch (Exception e) { maxKb = 200; }
    if (maxKb < 1) maxKb = 1;
    if (maxKb > 20000) maxKb = 20000;
    int refresh;
    try { refresh = Integer.parseInt(request.getParameter("refresh")); } catch (Exception e) { refresh = 0; }

    // ── Resolve the target file (with traversal guard on `file`) ──
    File target = null;
    String targetError = null;
    if (fileParam != null && !fileParam.trim().isEmpty()) {
        if (logDir == null) {
            targetError = "Log directory could not be resolved.";
        } else {
            File f = new File(logDir, fileParam.trim());
            String canonBase = logDir.getCanonicalPath();
            String canonFile = f.getCanonicalPath();
            if (!canonFile.startsWith(canonBase + File.separator) && !canonFile.equals(canonBase)) {
                targetError = "Blocked: path outside the log directory.";
            } else if (!f.isFile()) {
                targetError = "Not a file: " + fileParam;
            } else {
                target = f;
            }
        }
    }

    // ── raw text mode ──
    if (raw && target != null) {
        response.setContentType("text/plain; charset=UTF-8");
        response.getWriter().write(tail(target, maxKb * 1024L));
        return;
    }

    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<% if (refresh > 0 && target != null) { %><meta http-equiv="refresh" content="<%= refresh %>"/><% } %>
<title>Server Logs — GATEE Portal</title>
<style>
  *{box-sizing:border-box;margin:0;padding:0;}
  body{font-family:'Segoe UI',Tahoma,sans-serif;background:#0f172a;color:#e2e8f0;font-size:13px;}
  .bar{background:#1e293b;padding:10px 16px;display:flex;flex-wrap:wrap;gap:10px;align-items:center;
       position:sticky;top:0;z-index:10;border-bottom:1px solid #334155;}
  .bar h1{font-size:15px;font-weight:700;margin-right:8px;}
  .bar a,.bar button{color:#e2e8f0;background:#334155;border:1px solid #475569;border-radius:6px;
       padding:5px 10px;font-size:12px;text-decoration:none;cursor:pointer;}
  .bar a:hover,.bar button:hover{background:#475569;}
  .wrap{padding:16px;}
  .panel{background:#1e293b;border:1px solid #334155;border-radius:8px;padding:14px;margin-bottom:16px;}
  .panel h2{font-size:13px;text-transform:uppercase;letter-spacing:.5px;color:#94a3b8;margin-bottom:10px;}
  .kv{display:grid;grid-template-columns:180px 1fr;gap:4px 14px;font-family:Consolas,monospace;font-size:12px;}
  .kv div:nth-child(odd){color:#7dd3fc;}
  .kv div:nth-child(even){color:#e2e8f0;word-break:break-all;}
  table{width:100%;border-collapse:collapse;font-family:Consolas,monospace;font-size:12px;}
  th,td{text-align:left;padding:6px 10px;border-bottom:1px solid #334155;}
  th{color:#94a3b8;font-weight:600;}
  tr:hover td{background:#334155;}
  td a{color:#7dd3fc;text-decoration:none;}
  td a:hover{text-decoration:underline;}
  form.inline{display:flex;gap:8px;flex-wrap:wrap;align-items:center;}
  input[type=text],input[type=number]{background:#0f172a;border:1px solid #475569;color:#e2e8f0;
       border-radius:6px;padding:5px 8px;font-size:12px;font-family:Consolas,monospace;}
  .logbox{background:#000;border:1px solid #334155;border-radius:8px;padding:12px;
       white-space:pre-wrap;word-break:break-word;font-family:Consolas,monospace;font-size:12px;
       line-height:1.5;max-height:72vh;overflow:auto;}
  .err{background:#7f1d1d;color:#fecaca;padding:10px 14px;border-radius:8px;margin-bottom:16px;}
  .hl{color:#fde047;}
  .muted{color:#64748b;}
</style>
</head>
<body>

<%
    // Base query string identifying the current target (for the toolbar links)
    String targetQs = "";
    if (fileParam != null && !fileParam.trim().isEmpty())
        targetQs = "file=" + java.net.URLEncoder.encode(fileParam.trim(), "UTF-8");
    String qQs = (q != null && !q.trim().isEmpty()) ? "&q=" + java.net.URLEncoder.encode(q, "UTF-8") : "";
%>
<div class="bar">
  <h1>🗒️ Server Logs</h1>
  <a href="<%= request.getContextPath() %>/logs-viewer.jsp">↻ File list</a>
  <% if (target != null) { %>
    <a href="?<%= targetQs %>&kb=<%= maxKb %>&raw=1" target="_blank">⤓ Raw text</a>
    <a href="?<%= targetQs %>&kb=<%= maxKb %>&refresh=<%= refresh > 0 ? 0 : 10 %><%= qQs %>"><%= refresh > 0 ? "⏸ Stop auto-refresh" : "▶ Auto-refresh 10s" %></a>
  <% } %>
  <a href="<%= request.getContextPath() %>/data-admin-dashboard.jsp">← Dashboard</a>
</div>

<div class="wrap">

  <% if (targetError != null) { %><div class="err"><%= esc(targetError) %></div><% } %>

  <div class="panel">
    <h2>Server paths</h2>
    <div class="kv">
      <div>Resolved log dir</div><div><%= logDir != null ? esc(logDir.getAbsolutePath()) : "<span class='muted'>not found</span>" %></div>
      <div>catalina.base</div><div><%= esc(System.getProperty("catalina.base")) %></div>
      <div>catalina.home</div><div><%= esc(System.getProperty("catalina.home")) %></div>
      <div>java.io.tmpdir</div><div><%= esc(System.getProperty("java.io.tmpdir")) %></div>
      <div>user.dir (CWD)</div><div><%= esc(System.getProperty("user.dir")) %></div>
      <div>webapp real path</div><div><%= esc(application.getRealPath("/")) %></div>
      <div>server</div><div><%= esc(application.getServerInfo()) %> · Java <%= esc(System.getProperty("java.version")) %> · <%= esc(System.getProperty("os.name")) %></div>
    </div>
  </div>

  <%
    if (target == null && logDir != null) {
      File[] files = logDir.listFiles(new FileFilter() {
        public boolean accept(File f) { return f.isFile(); }
      });
      if (files != null) {
        Arrays.sort(files, new Comparator<File>() {
          public int compare(File a, File b) { return Long.compare(b.lastModified(), a.lastModified()); }
        });
  %>
  <div class="panel">
    <h2>Files in <%= esc(logDir.getAbsolutePath()) %> (<%= files.length %>)</h2>
    <table>
      <tr><th>Name</th><th>Size</th><th>Modified</th><th></th></tr>
      <% for (File f : files) {
           String enc = java.net.URLEncoder.encode(f.getName(), "UTF-8"); %>
      <tr>
        <td><a href="?file=<%= enc %>&kb=<%= maxKb %>"><%= esc(f.getName()) %></a></td>
        <td><%= humanSize(f.length()) %></td>
        <td><%= sdf.format(new Date(f.lastModified())) %></td>
        <td><a href="?file=<%= enc %>&kb=<%= maxKb %>&raw=1" target="_blank">raw</a></td>
      </tr>
      <% } %>
      <% if (files.length == 0) { %><tr><td colspan="4" class="muted">No files.</td></tr><% } %>
    </table>
  </div>
  <%   }
     } %>

  <%
    if (target != null) {
      String content;
      try { content = tail(target, maxKb * 1024L); }
      catch (Exception ex) { content = "Error reading file: " + ex.getMessage(); }

      if (q != null && !q.trim().isEmpty()) {
        String needle = q.toLowerCase();
        StringBuilder filtered = new StringBuilder();
        for (String line : content.split("\n", -1)) {
          if (line.toLowerCase().contains(needle)) filtered.append(line).append('\n');
        }
        content = filtered.length() == 0 ? "(no lines match \"" + q + "\")" : filtered.toString();
      }
  %>
  <div class="panel">
    <h2>
      <%= esc(target.getAbsolutePath()) %>
      <span class="muted">· <%= humanSize(target.length()) %> · <%= sdf.format(new Date(target.lastModified())) %>
      <% if (refresh > 0) { %> · <span class="hl">auto-refresh <%= refresh %>s</span><% } %></span>
    </h2>
    <form class="inline" method="get" action="logs-viewer.jsp" style="margin-bottom:10px;">
      <input type="hidden" name="file" value="<%= esc(fileParam) %>"/>
      <input type="text" name="q" size="30" placeholder="filter lines (contains)…" value="<%= esc(q) %>"/>
      <label class="muted">tail KB <input type="number" name="kb" value="<%= maxKb %>" min="1" max="20000" style="width:90px;"/></label>
      <% if (refresh > 0) { %><input type="hidden" name="refresh" value="<%= refresh %>"/><% } %>
      <button type="submit">Apply</button>
    </form>
    <div class="logbox" id="logbox"><%= esc(content) %></div>
  </div>
  <script>
    var lb = document.getElementById('logbox');
    if (lb) lb.scrollTop = lb.scrollHeight;
  </script>
  <% } %>

</div>
</body>
</html>
