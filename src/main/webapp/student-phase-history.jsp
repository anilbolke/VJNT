<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true"%>
<%@ page import="com.vjnt.model.User,com.vjnt.util.DatabaseConnection,java.sql.*,java.util.*,java.text.SimpleDateFormat" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) { response.sendRedirect(request.getContextPath() + "/login"); return; }

    String userType  = user.getUserType().toString();
    String userUdise = user.getUdiseNo()      != null ? user.getUdiseNo().trim()       : "";
    String userDist  = user.getDistrictName() != null ? user.getDistrictName().trim()  : "";
    String userDiv   = user.getDivisionName() != null ? user.getDivisionName().trim()  : "";

    // ── Search params ──
    String searchPen  = request.getParameter("pen")  != null ? request.getParameter("pen").trim()  : "";
    String searchName = request.getParameter("name") != null ? request.getParameter("name").trim()  : "";
    boolean didSearch = !searchPen.isEmpty() || !searchName.isEmpty();

    // ── Result holders ──
    List<Map<String,Object>> historyRows  = new ArrayList<>();   // from student_phase_history
    Map<String,Object>       activeRow    = null;                 // current live data in students
    Map<String,Object>       graduatedRow = null;                 // from graduated_students
    String                   studentName  = "";
    String                   studentPen   = "";
    String                   studentUdise = "";
    String                   errMsg       = "";

    SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy");

    if (didSearch) {
        try (Connection conn = DatabaseConnection.getConnection()) {

            // ── 1. student_phase_history ──────────────────────────────────
            StringBuilder hSql = new StringBuilder(
                "SELECT sph.student_name, sph.student_pen, sph.udise_no, " +
                "       sph.division, sph.district, sph.class_before, sph.class_after, " +
                "       sph.phase1_marathi, sph.phase1_math, sph.phase1_english, " +
                "       sph.phase1_date, " +
                "       sph.phase2_marathi, sph.phase2_math, sph.phase2_english, " +
                "       sph.phase2_date, " +
                "       sph.phase3_marathi, sph.phase3_math, sph.phase3_english, " +
                "       sph.phase3_date, " +
                "       sph.phase4_marathi, sph.phase4_math, sph.phase4_english, " +
                "       sph.phase4_date, " +
                "       cpl.academic_year, cpl.promotion_date " +
                "FROM student_phase_history sph " +
                "JOIN class_promotion_log cpl ON sph.promotion_id = cpl.promotion_id " +
                "WHERE 1=1 ");

            List<String> hParams = new ArrayList<>();

            if (!searchPen.isEmpty()) {
                hSql.append("AND sph.student_pen = ? ");
                hParams.add(searchPen);
            } else {
                hSql.append("AND sph.student_name LIKE ? ");
                hParams.add("%" + searchName + "%");
            }

            // Scope restriction
            if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) {
                hSql.append("AND sph.udise_no = ? ");
                hParams.add(userUdise);
            } else if (userType.equals("DISTRICT_OFFICER")) {
                hSql.append("AND sph.district = ? ");
                hParams.add(userDist);
            } else if (userType.equals("DIVISION_OFFICER")) {
                hSql.append("AND sph.division = ? ");
                hParams.add(userDiv);
            }

            hSql.append("ORDER BY cpl.academic_year DESC");

            try (PreparedStatement ps = conn.prepareStatement(hSql.toString())) {
                for (int i = 0; i < hParams.size(); i++) ps.setString(i + 1, hParams.get(i));
                ResultSet rs = ps.executeQuery();
                while (rs.next()) {
                    Map<String,Object> r = new LinkedHashMap<>();
                    r.put("name",     rs.getString("student_name"));
                    r.put("pen",      rs.getString("student_pen"));
                    r.put("udise",    rs.getString("udise_no"));
                    r.put("division", rs.getString("division"));
                    r.put("district", rs.getString("district"));
                    r.put("before",   rs.getString("class_before"));
                    r.put("after",    rs.getString("class_after"));
                    // Phase 1
                    r.put("p1mar", rs.getObject("phase1_marathi")); r.put("p1mat", rs.getObject("phase1_math")); r.put("p1eng", rs.getObject("phase1_english"));
                    r.put("p1date", rs.getDate("phase1_date") != null ? sdf.format(rs.getDate("phase1_date")) : "—");
                    // Phase 2
                    r.put("p2mar", rs.getObject("phase2_marathi")); r.put("p2mat", rs.getObject("phase2_math")); r.put("p2eng", rs.getObject("phase2_english"));
                    r.put("p2date", rs.getDate("phase2_date") != null ? sdf.format(rs.getDate("phase2_date")) : "—");
                    // Phase 3
                    r.put("p3mar", rs.getObject("phase3_marathi")); r.put("p3mat", rs.getObject("phase3_math")); r.put("p3eng", rs.getObject("phase3_english"));
                    r.put("p3date", rs.getDate("phase3_date") != null ? sdf.format(rs.getDate("phase3_date")) : "—");
                    // Phase 4
                    r.put("p4mar", rs.getObject("phase4_marathi")); r.put("p4mat", rs.getObject("phase4_math")); r.put("p4eng", rs.getObject("phase4_english"));
                    r.put("p4date", rs.getDate("phase4_date") != null ? sdf.format(rs.getDate("phase4_date")) : "—");
                    // Meta
                    r.put("year",   rs.getString("academic_year"));
                    r.put("promDate", rs.getTimestamp("promotion_date") != null ? sdf.format(rs.getTimestamp("promotion_date")) : "—");
                    historyRows.add(r);
                    if (studentName.isEmpty() && rs.getString("student_name") != null) {
                        studentName  = rs.getString("student_name");
                        studentPen   = rs.getString("student_pen");
                        studentUdise = rs.getString("udise_no");
                    }
                }
            } catch (SQLException ex) {
                // phase1_date / phase2_date columns may not exist in older schema — retry without date columns
                StringBuilder hSql2 = new StringBuilder(
                    "SELECT sph.student_name, sph.student_pen, sph.udise_no, " +
                    "       sph.division, sph.district, sph.class_before, sph.class_after, " +
                    "       sph.phase1_marathi, sph.phase1_math, sph.phase1_english, " +
                    "       sph.phase2_marathi, sph.phase2_math, sph.phase2_english, " +
                    "       sph.phase3_marathi, sph.phase3_math, sph.phase3_english, " +
                    "       sph.phase4_marathi, sph.phase4_math, sph.phase4_english, " +
                    "       cpl.academic_year, cpl.promotion_date " +
                    "FROM student_phase_history sph " +
                    "JOIN class_promotion_log cpl ON sph.promotion_id = cpl.promotion_id " +
                    "WHERE 1=1 ");
                List<String> hParams2 = new ArrayList<>(hParams);
                // re-apply same conditions
                if (!searchPen.isEmpty()) { hSql2.append("AND sph.student_pen = ? "); }
                else                      { hSql2.append("AND sph.student_name LIKE ? "); }
                if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) hSql2.append("AND sph.udise_no = ? ");
                else if (userType.equals("DISTRICT_OFFICER")) hSql2.append("AND sph.district = ? ");
                else if (userType.equals("DIVISION_OFFICER")) hSql2.append("AND sph.division = ? ");
                hSql2.append("ORDER BY cpl.academic_year DESC");
                try (PreparedStatement ps2 = conn.prepareStatement(hSql2.toString())) {
                    for (int i = 0; i < hParams2.size(); i++) ps2.setString(i + 1, hParams2.get(i));
                    ResultSet rs = ps2.executeQuery();
                    while (rs.next()) {
                        Map<String,Object> r = new LinkedHashMap<>();
                        r.put("name", rs.getString("student_name")); r.put("pen", rs.getString("student_pen"));
                        r.put("udise", rs.getString("udise_no")); r.put("division", rs.getString("division")); r.put("district", rs.getString("district"));
                        r.put("before", rs.getString("class_before")); r.put("after", rs.getString("class_after"));
                        r.put("p1mar", rs.getObject("phase1_marathi")); r.put("p1mat", rs.getObject("phase1_math")); r.put("p1eng", rs.getObject("phase1_english")); r.put("p1date","—");
                        r.put("p2mar", rs.getObject("phase2_marathi")); r.put("p2mat", rs.getObject("phase2_math")); r.put("p2eng", rs.getObject("phase2_english")); r.put("p2date","—");
                        r.put("p3mar", rs.getObject("phase3_marathi")); r.put("p3mat", rs.getObject("phase3_math")); r.put("p3eng", rs.getObject("phase3_english")); r.put("p3date","—");
                        r.put("p4mar", rs.getObject("phase4_marathi")); r.put("p4mat", rs.getObject("phase4_math")); r.put("p4eng", rs.getObject("phase4_english")); r.put("p4date","—");
                        r.put("year", rs.getString("academic_year")); r.put("promDate", rs.getTimestamp("promotion_date") != null ? sdf.format(rs.getTimestamp("promotion_date")) : "—");
                        historyRows.add(r);
                        if (studentName.isEmpty()) { studentName = rs.getString("student_name"); studentPen = rs.getString("student_pen"); studentUdise = rs.getString("udise_no"); }
                    }
                } catch (Exception ex2) { errMsg = "टप्पा इतिहास तक्ता आढळला नाही: " + ex2.getMessage(); }
            }

            // ── 2. Active students table (current year) ───────────────────
            StringBuilder aSql = new StringBuilder(
                "SELECT st.student_name, st.student_pen, st.udise_no, st.class, " +
                "       st.phase1_marathi, st.phase1_math, st.phase1_english, st.phase1_date, " +
                "       st.phase2_marathi, st.phase2_math, st.phase2_english, st.phase2_date, " +
                "       st.phase3_marathi, st.phase3_math, st.phase3_english, st.phase3_date, " +
                "       st.phase4_marathi, st.phase4_math, st.phase4_english, st.phase4_date, " +
                "       st.fln_completed, " +
                "       MAX(sc.school_name) AS school_name " +
                "FROM students st " +
                "LEFT JOIN schools sc ON sc.udise_no COLLATE utf8mb4_unicode_ci = st.udise_no " +
                "WHERE st.is_active = 1 ");
            List<String> aParams = new ArrayList<>();
            if (!searchPen.isEmpty()) { aSql.append("AND st.student_pen = ? "); aParams.add(searchPen); }
            else                      { aSql.append("AND st.student_name LIKE ? "); aParams.add("%" + searchName + "%"); }
            if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) { aSql.append("AND st.udise_no = ? "); aParams.add(userUdise); }
            else if (userType.equals("DISTRICT_OFFICER")) { aSql.append("AND st.district = ? "); aParams.add(userDist); }
            else if (userType.equals("DIVISION_OFFICER")) { aSql.append("AND st.division = ? "); aParams.add(userDiv); }
            aSql.append("GROUP BY st.student_pen LIMIT 1");

            try (PreparedStatement ps = conn.prepareStatement(aSql.toString())) {
                for (int i = 0; i < aParams.size(); i++) ps.setString(i + 1, aParams.get(i));
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    activeRow = new LinkedHashMap<>();
                    activeRow.put("name",   rs.getString("student_name"));
                    activeRow.put("pen",    rs.getString("student_pen"));
                    activeRow.put("udise",  rs.getString("udise_no"));
                    activeRow.put("class",  rs.getString("class"));
                    activeRow.put("school", rs.getString("school_name"));
                    activeRow.put("p1mar",  rs.getObject("phase1_marathi"));  activeRow.put("p1mat",  rs.getObject("phase1_math"));  activeRow.put("p1eng",  rs.getObject("phase1_english"));
                    activeRow.put("p1date", rs.getDate("phase1_date") != null ? sdf.format(rs.getDate("phase1_date")) : "—");
                    activeRow.put("p2mar",  rs.getObject("phase2_marathi"));  activeRow.put("p2mat",  rs.getObject("phase2_math"));  activeRow.put("p2eng",  rs.getObject("phase2_english"));
                    activeRow.put("p2date", rs.getDate("phase2_date") != null ? sdf.format(rs.getDate("phase2_date")) : "—");
                    activeRow.put("p3mar",  rs.getObject("phase3_marathi"));  activeRow.put("p3mat",  rs.getObject("phase3_math"));  activeRow.put("p3eng",  rs.getObject("phase3_english"));
                    activeRow.put("p3date", rs.getDate("phase3_date") != null ? sdf.format(rs.getDate("phase3_date")) : "—");
                    activeRow.put("p4mar",  rs.getObject("phase4_marathi"));  activeRow.put("p4mat",  rs.getObject("phase4_math"));  activeRow.put("p4eng",  rs.getObject("phase4_english"));
                    activeRow.put("p4date", rs.getDate("phase4_date") != null ? sdf.format(rs.getDate("phase4_date")) : "—");
                    activeRow.put("fln",    rs.getInt("fln_completed") == 1);
                    if (studentName.isEmpty()) { studentName = rs.getString("student_name"); studentPen = rs.getString("student_pen"); studentUdise = rs.getString("udise_no"); }
                }
            } catch (Exception ex) { /* ignore — column may not have date */ }

            // ── 3. graduated_students ─────────────────────────────────────
            StringBuilder gSql = new StringBuilder(
                "SELECT student_name, student_pen, udise_no, division, district, section, " +
                "       academic_year, final_marathi_level, final_math_level, final_english_level, " +
                "       fln_completed, graduated_at FROM graduated_students WHERE 1=1 ");
            List<String> gParams = new ArrayList<>();
            if (!searchPen.isEmpty()) { gSql.append("AND student_pen = ? "); gParams.add(searchPen); }
            else                      { gSql.append("AND student_name LIKE ? "); gParams.add("%" + searchName + "%"); }
            if (userType.equals("SCHOOL_COORDINATOR") || userType.equals("HEAD_MASTER")) { gSql.append("AND udise_no = ? "); gParams.add(userUdise); }
            else if (userType.equals("DISTRICT_OFFICER")) { gSql.append("AND district = ? "); gParams.add(userDist); }
            else if (userType.equals("DIVISION_OFFICER")) { gSql.append("AND division = ? "); gParams.add(userDiv); }
            gSql.append("ORDER BY academic_year DESC LIMIT 1");

            try (PreparedStatement ps = conn.prepareStatement(gSql.toString())) {
                for (int i = 0; i < gParams.size(); i++) ps.setString(i + 1, gParams.get(i));
                ResultSet rs = ps.executeQuery();
                if (rs.next()) {
                    graduatedRow = new LinkedHashMap<>();
                    graduatedRow.put("name",  rs.getString("student_name"));
                    graduatedRow.put("pen",   rs.getString("student_pen"));
                    graduatedRow.put("udise", rs.getString("udise_no"));
                    graduatedRow.put("div",   rs.getString("division"));
                    graduatedRow.put("dist",  rs.getString("district"));
                    graduatedRow.put("sec",   rs.getString("section"));
                    graduatedRow.put("year",  rs.getString("academic_year"));
                    graduatedRow.put("mar",   rs.getObject("final_marathi_level"));
                    graduatedRow.put("math",  rs.getObject("final_math_level"));
                    graduatedRow.put("eng",   rs.getObject("final_english_level"));
                    graduatedRow.put("fln",   rs.getInt("fln_completed") == 1);
                    graduatedRow.put("date",  rs.getTimestamp("graduated_at") != null ? sdf.format(rs.getTimestamp("graduated_at")) : "—");
                    if (studentName.isEmpty()) { studentName = rs.getString("student_name"); studentPen = rs.getString("student_pen"); }
                }
            } catch (Exception ex) { /* ignore */ }

        } catch (Exception ex) { errMsg = "डेटाबेस त्रुटी: " + ex.getMessage(); }
    }

    boolean found = !historyRows.isEmpty() || activeRow != null || graduatedRow != null;

    // ── helper: level label ──
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>विद्यार्थी टप्पा इतिहास — GATEE पोर्टल</title>
<style>
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;min-height:100vh;}

/* ── Top bar ── */
.topbar{background:linear-gradient(90deg,#667eea,#764ba2);color:#fff;display:flex;
        align-items:center;justify-content:space-between;padding:0 24px;height:56px;
        position:sticky;top:0;z-index:100;box-shadow:0 2px 8px rgba(0,0,0,.2);}
.topbar-title{font-size:17px;font-weight:800;letter-spacing:-.3px;}
.topbar-right{display:flex;align-items:center;gap:10px;}
.back-btn{background:rgba(255,255,255,.15);border:1px solid rgba(255,255,255,.3);color:#fff;
          padding:6px 16px;border-radius:20px;font-size:13px;cursor:pointer;text-decoration:none;transition:.2s;}
.back-btn:hover{background:rgba(255,255,255,.25);}

/* ── Page wrap ── */
.page{max-width:980px;margin:30px auto;padding:0 20px 60px;}

/* ── Search card ── */
.search-card{background:#fff;border-radius:14px;padding:28px 32px;
             box-shadow:0 2px 12px rgba(0,0,0,.08);margin-bottom:28px;}
.search-card h2{font-size:20px;font-weight:800;margin-bottom:6px;}
.search-card p{font-size:13px;color:#64748b;margin-bottom:20px;}
.search-row{display:flex;gap:12px;flex-wrap:wrap;}
.search-row input{flex:1;min-width:200px;padding:11px 16px;border:2px solid #e2e8f0;border-radius:10px;
                  font-size:14px;outline:none;transition:.2s;}
.search-row input:focus{border-color:#667eea;}
.search-row .sep{display:flex;align-items:center;font-size:13px;color:#94a3b8;font-weight:600;}
.btn-search{background:linear-gradient(135deg,#667eea,#764ba2);color:#fff;border:none;
            padding:11px 28px;border-radius:10px;font-size:14px;font-weight:700;cursor:pointer;transition:.2s;}
.btn-search:hover{opacity:.9;}

/* ── Student header card ── */
.stu-header{background:linear-gradient(135deg,#1e293b,#0f172a);border-radius:14px;padding:24px 28px;
            color:#fff;margin-bottom:20px;display:flex;align-items:center;gap:20px;}
.stu-avatar{width:56px;height:56px;border-radius:50%;background:linear-gradient(135deg,#667eea,#764ba2);
            display:flex;align-items:center;justify-content:center;font-size:26px;flex-shrink:0;}
.stu-meta h3{font-size:20px;font-weight:800;}
.stu-meta p{font-size:13px;opacity:.7;margin-top:4px;}
.stu-chips{margin-left:auto;display:flex;gap:8px;flex-wrap:wrap;}
.stu-chip{background:rgba(255,255,255,.12);border:1px solid rgba(255,255,255,.2);
          border-radius:14px;padding:4px 14px;font-size:12px;font-weight:600;}
.grad-chip{background:rgba(34,197,94,.2);border-color:rgba(34,197,94,.5);color:#4ade80;}
.active-chip{background:rgba(59,130,246,.2);border-color:rgba(59,130,246,.5);color:#93c5fd;}

/* ── Year section ── */
.year-block{background:#fff;border-radius:14px;box-shadow:0 2px 10px rgba(0,0,0,.07);
            margin-bottom:20px;overflow:hidden;}
.year-head{background:linear-gradient(90deg,#667eea,#764ba2);color:#fff;
           padding:14px 22px;display:flex;align-items:center;gap:14px;}
.year-head .yr-badge{font-size:18px;font-weight:800;}
.year-head .yr-meta{font-size:12px;opacity:.8;}
.year-head .yr-class{margin-left:auto;background:rgba(255,255,255,.2);
                     border-radius:20px;padding:4px 14px;font-size:13px;font-weight:700;}

/* ── Active year (current) special style ── */
.year-block.current .year-head{background:linear-gradient(90deg,#059669,#047857);}
.year-block.graduated .year-head{background:linear-gradient(90deg,#d97706,#b45309);}

/* ── Phase grid inside year block ── */
.phase-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:0;border-top:1px solid #f1f5f9;}
.phase-col{padding:18px 16px;border-right:1px solid #f1f5f9;}
.phase-col:last-child{border-right:none;}
.phase-col .ph-label{font-size:11px;font-weight:700;letter-spacing:1px;text-transform:uppercase;
                     margin-bottom:12px;padding-bottom:8px;border-bottom:2px solid;}
.ph1 .ph-label{color:#3b82f6;border-color:#93c5fd;}
.ph2 .ph-label{color:#16a34a;border-color:#86efac;}
.ph3 .ph-label{color:#ea580c;border-color:#fdba74;}
.ph4 .ph-label{color:#7c3aed;border-color:#c084fc;}

.subj-row{display:flex;justify-content:space-between;align-items:center;
          padding:5px 0;border-bottom:1px solid #f8fafc;font-size:13px;}
.subj-row:last-of-type{border-bottom:none;}
.subj-name{color:#64748b;font-size:12px;}
.level-badge{font-weight:700;font-size:13px;border-radius:6px;padding:2px 8px;}
.lv-null{color:#94a3b8;font-style:italic;font-size:11px;}
.lv-low {background:#fee2e2;color:#991b1b;}   /* level 1-2 */
.lv-mid {background:#fef9c3;color:#854d0e;}   /* level 3-4 */
.lv-hi  {background:#dcfce7;color:#14532d;}   /* level 5+ */
.lv-fln {background:linear-gradient(90deg,#667eea,#764ba2);color:#fff;font-size:11px;}

.ph-date{font-size:11px;color:#94a3b8;margin-top:10px;padding-top:8px;
         border-top:1px dashed #e2e8f0;}

/* ── Progress bar per phase ── */
.progress-row{padding:12px 22px;background:#f8fafc;border-top:1px solid #f1f5f9;
              display:flex;align-items:center;gap:16px;flex-wrap:wrap;}
.prog-label{font-size:12px;font-weight:700;color:#475569;min-width:60px;}
.prog-bar-wrap{flex:1;min-width:200px;background:#e2e8f0;border-radius:4px;height:8px;overflow:hidden;}
.prog-bar{height:8px;border-radius:4px;background:linear-gradient(90deg,#667eea,#764ba2);}
.prog-pct{font-size:12px;font-weight:700;color:#667eea;min-width:38px;text-align:right;}

/* ── Graduated card ── */
.grad-card{background:linear-gradient(135deg,#fef3c7,#fde68a);border:2px solid #f59e0b;
           border-radius:14px;padding:22px 26px;margin-bottom:20px;}
.grad-card h3{font-size:16px;font-weight:800;color:#92400e;margin-bottom:12px;}
.grad-facts{display:flex;gap:16px;flex-wrap:wrap;}
.grad-fact{background:rgba(255,255,255,.6);border-radius:8px;padding:10px 16px;text-align:center;}
.grad-fact .gf-num{font-size:20px;font-weight:800;color:#92400e;}
.grad-fact .gf-lbl{font-size:11px;color:#b45309;}

/* ── No results ── */
.empty{text-align:center;padding:60px 20px;background:#fff;border-radius:14px;
       box-shadow:0 2px 10px rgba(0,0,0,.07);}
.empty .ei{font-size:56px;margin-bottom:14px;}

/* ── Error ── */
.err-box{background:#fee2e2;border:1px solid #fca5a5;border-radius:10px;
         padding:14px 18px;color:#991b1b;font-size:13px;margin-bottom:16px;}

/* ── Print btn ── */
.print-btn{background:#fff;border:2px solid #667eea;color:#667eea;padding:8px 20px;
           border-radius:20px;font-size:13px;font-weight:700;cursor:pointer;float:right;margin-top:-4px;}
.print-btn:hover{background:#667eea;color:#fff;}

@media print{.topbar,.back-btn,.search-card,.print-btn{display:none;} .page{margin:0;padding:0;}}
@media(max-width:700px){.phase-grid{grid-template-columns:1fr 1fr;} .phase-col{border-bottom:1px solid #f1f5f9;}}
</style>
</head>
<body>

<div class="topbar">
  <div class="topbar-title">📋 विद्यार्थी टप्पा इतिहास</div>
  <div class="topbar-right">
    <a href="javascript:history.back()" class="back-btn">← मागे जा</a>
  </div>
</div>

<jsp:include page="academic-year-bar.jsp" />

<div class="page">

  <!-- Search -->
  <div class="search-card">
    <h2>🔍 विद्यार्थी टप्पा इतिहास शोधा</h2>
    <p>पदोन्नतीनंतर विद्यार्थ्याचे मागील सर्व वर्षांचे FLN टप्पा तपशील येथे पाहा. PEN क्रमांकाने शोधणे अधिक अचूक आहे.</p>
    <form method="GET" action="">
      <div class="search-row">
        <input type="text" name="pen"  value="<%=searchPen%>"
               placeholder="PEN क्रमांक (उदा. MH2024001234)" autocomplete="off"/>
        <div class="sep">— किंवा —</div>
        <input type="text" name="name" value="<%=searchName%>"
               placeholder="विद्यार्थ्याचे नाव (किमान ३ अक्षरे)" autocomplete="off"/>
        <button type="submit" class="btn-search">🔍 शोधा</button>
      </div>
    </form>
  </div>

  <% if (!errMsg.isEmpty()) { %><div class="err-box">⚠️ <%= errMsg %></div><% } %>
  <% if (didSearch) { %>
    <% if (!found) { %>
      <div class="empty">
        <div class="ei">🙁</div>
        <h3 style="font-size:18px;margin-bottom:8px;">विद्यार्थी आढळला नाही</h3>
        <p style="color:#64748b;font-size:14px;">
          "<strong><%= searchPen.isEmpty() ? searchName : searchPen %></strong>" या PEN / नावाचा विद्यार्थी तुमच्या शाळेत / क्षेत्रात सापडला नाही.<br/>
          PEN क्रमांक बरोबर आहे का तपासा किंवा नावाचे पूर्ण शब्दलेखन तपासा.
        </p>
      </div>
    <% } else { %>

      <!-- Student Header -->
      <div class="stu-header">
        <div class="stu-avatar">👤</div>
        <div class="stu-meta">
          <h3><%= studentName.isEmpty() ? "—" : studentName %></h3>
          <p>PEN: <%= studentPen.isEmpty() ? "—" : studentPen %> &nbsp;|&nbsp; UDISE: <%= studentUdise.isEmpty() ? "—" : studentUdise %></p>
        </div>
        <div class="stu-chips">
          <% if (activeRow != null) { %><div class="stu-chip active-chip">🟢 सध्या सक्रिय — इयत्ता <%= activeRow.get("class") %></div><% } %>
          <% if (graduatedRow != null) { %><div class="stu-chip grad-chip">🎓 उत्तीर्ण <%= graduatedRow.get("year") %></div><% } %>
          <% if (!historyRows.isEmpty()) { %><div class="stu-chip">📚 <%= historyRows.size() %> वर्षांचा इतिहास</div><% } %>
        </div>
        <button class="print-btn" onclick="window.print()">🖨️ Print</button>
      </div>

      <!-- ── Graduated badge ── -->
      <% if (graduatedRow != null) { %>
      <div class="grad-card">
        <h3>🎓 उत्तीर्ण विद्यार्थी — शैक्षणिक वर्ष <%= graduatedRow.get("year") %></h3>
        <div class="grad-facts">
          <div class="grad-fact">
            <div class="gf-num">📖 <%= graduatedRow.get("mar") != null ? graduatedRow.get("mar") : "—" %></div>
            <div class="gf-lbl">अंतिम मराठी स्तर</div>
          </div>
          <div class="grad-fact">
            <div class="gf-num">🔢 <%= graduatedRow.get("math") != null ? graduatedRow.get("math") : "—" %></div>
            <div class="gf-lbl">अंतिम गणित स्तर</div>
          </div>
          <div class="grad-fact">
            <div class="gf-num">🔤 <%= graduatedRow.get("eng") != null ? graduatedRow.get("eng") : "—" %></div>
            <div class="gf-lbl">अंतिम इंग्रजी स्तर</div>
          </div>
          <div class="grad-fact">
            <div class="gf-num"><%= Boolean.TRUE.equals(graduatedRow.get("fln")) ? "✅" : "❌" %></div>
            <div class="gf-lbl">FLN पूर्ण</div>
          </div>
          <div class="grad-fact">
            <div class="gf-num" style="font-size:14px;"><%= graduatedRow.get("date") %></div>
            <div class="gf-lbl">उत्तीर्णता तारीख</div>
          </div>
        </div>
      </div>
      <% } %>

      <!-- ── Current active year ── -->
      <% if (activeRow != null) { %>
      <div class="year-block current">
        <div class="year-head">
          <span style="font-size:20px;">🟢</span>
          <div>
            <div class="yr-badge">चालू वर्ष — सध्याचा डेटा</div>
            <div class="yr-meta">live students तक्त्यातून</div>
          </div>
          <div class="yr-class">इयत्ता <%= activeRow.get("class") %> &nbsp;|&nbsp; <%= activeRow.get("school") != null ? activeRow.get("school") : activeRow.get("udise") %></div>
        </div>
        <div class="phase-grid">
          <%
            String[][] activePh = {
              {String.valueOf(activeRow.get("p1mar")), String.valueOf(activeRow.get("p1mat")), String.valueOf(activeRow.get("p1eng")), String.valueOf(activeRow.get("p1date"))},
              {String.valueOf(activeRow.get("p2mar")), String.valueOf(activeRow.get("p2mat")), String.valueOf(activeRow.get("p2eng")), String.valueOf(activeRow.get("p2date"))},
              {String.valueOf(activeRow.get("p3mar")), String.valueOf(activeRow.get("p3mat")), String.valueOf(activeRow.get("p3eng")), String.valueOf(activeRow.get("p3date"))},
              {String.valueOf(activeRow.get("p4mar")), String.valueOf(activeRow.get("p4mat")), String.valueOf(activeRow.get("p4eng")), String.valueOf(activeRow.get("p4date"))}
            };
            String[] phLabels = {"📘 टप्पा १","📗 टप्पा २","📙 टप्पा ३","📕 टप्पा ४"};
            String[] phCls    = {"ph1","ph2","ph3","ph4"};
            for (int i = 0; i < 4; i++) {
              String mar = activePh[i][0], mat = activePh[i][1], eng = activePh[i][2], dt = activePh[i][3];
          %>
          <div class="phase-col <%= phCls[i] %>">
            <div class="ph-label"><%= phLabels[i] %></div>
            <div class="subj-row"><span class="subj-name">📖 मराठी</span><span class="level-badge <%= levelClass(mar) %>"><%= levelLabel(mar) %></span></div>
            <div class="subj-row"><span class="subj-name">🔢 गणित</span><span class="level-badge <%= levelClass(mat) %>"><%= levelLabel(mat) %></span></div>
            <div class="subj-row"><span class="subj-name">🔤 इंग्रजी</span><span class="level-badge <%= levelClass(eng) %>"><%= levelLabel(eng) %></span></div>
            <div class="ph-date">📅 <%= dt.equals("null") ? "—" : dt %></div>
          </div>
          <% } %>
        </div>
        <div class="progress-row">
          <span class="prog-label">FLN प्रगती</span>
          <div class="prog-bar-wrap"><div class="prog-bar" style="width:<%= flnProgress(activeRow) %>%"></div></div>
          <span class="prog-pct"><%= flnProgress(activeRow) %>%</span>
          <% if (Boolean.TRUE.equals(activeRow.get("fln"))) { %><span style="font-size:12px;font-weight:700;color:#059669;">✅ FLN पूर्ण!</span><% } %>
        </div>
      </div>
      <% } %>

      <!-- ── History years (from student_phase_history) ── -->
      <% for (Map<String,Object> hr : historyRows) {
            String[][] ph = {
              {String.valueOf(hr.get("p1mar")), String.valueOf(hr.get("p1mat")), String.valueOf(hr.get("p1eng")), String.valueOf(hr.get("p1date"))},
              {String.valueOf(hr.get("p2mar")), String.valueOf(hr.get("p2mat")), String.valueOf(hr.get("p2eng")), String.valueOf(hr.get("p2date"))},
              {String.valueOf(hr.get("p3mar")), String.valueOf(hr.get("p3mat")), String.valueOf(hr.get("p3eng")), String.valueOf(hr.get("p3date"))},
              {String.valueOf(hr.get("p4mar")), String.valueOf(hr.get("p4mat")), String.valueOf(hr.get("p4eng")), String.valueOf(hr.get("p4date"))}
            };
            String[] phLbl = {"📘 टप्पा १","📗 टप्पा २","📙 टप्पा ३","📕 टप्पा ४"};
            String[] phC   = {"ph1","ph2","ph3","ph4"};
      %>
      <div class="year-block">
        <div class="year-head">
          <span style="font-size:20px;">📅</span>
          <div>
            <div class="yr-badge">शैक्षणिक वर्ष <%= hr.get("year") %></div>
            <div class="yr-meta">पदोन्नती दिनांक: <%= hr.get("promDate") %></div>
          </div>
          <div class="yr-class">
            इयत्ता <%= hr.get("before") %> → <%= hr.get("after") %>
            &nbsp;|&nbsp; <%= hr.get("district") %>, <%= hr.get("division") %>
          </div>
        </div>
        <div class="phase-grid">
          <% for (int i = 0; i < 4; i++) {
               String mar=ph[i][0], mat=ph[i][1], eng=ph[i][2], dt=ph[i][3];
          %>
          <div class="phase-col <%= phC[i] %>">
            <div class="ph-label"><%= phLbl[i] %></div>
            <div class="subj-row"><span class="subj-name">📖 मराठी</span><span class="level-badge <%= levelClass(mar) %>"><%= levelLabel(mar) %></span></div>
            <div class="subj-row"><span class="subj-name">🔢 गणित</span><span class="level-badge <%= levelClass(mat) %>"><%= levelLabel(mat) %></span></div>
            <div class="subj-row"><span class="subj-name">🔤 इंग्रजी</span><span class="level-badge <%= levelClass(eng) %>"><%= levelLabel(eng) %></span></div>
            <div class="ph-date">📅 <%= dt.equals("null") ? "—" : dt %></div>
          </div>
          <% } %>
        </div>
        <div class="progress-row">
          <span class="prog-label">टप्पा ४ प्रगती</span>
          <div class="prog-bar-wrap"><div class="prog-bar" style="width:<%= phaseProgress(ph[3]) %>%"></div></div>
          <span class="prog-pct"><%= phaseProgress(ph[3]) %>%</span>
          <span style="font-size:12px;color:#475569;">
            (मराठी:<%= ph[3][0].equals("null")?"—":ph[3][0] %> &nbsp;|&nbsp; गणित:<%= ph[3][1].equals("null")?"—":ph[3][1] %> &nbsp;|&nbsp; इंग्रजी:<%= ph[3][2].equals("null")?"—":ph[3][2] %>)
          </span>
        </div>
      </div>
      <% } %>

    <% } %>
  <% } else { %>
    <!-- Initial state -->
    <div class="empty">
      <div class="ei">📋</div>
      <h3 style="font-size:18px;margin-bottom:8px;">PEN क्रमांक किंवा नाव टाका</h3>
      <p style="color:#64748b;font-size:14px;">वरील शोध बॉक्समध्ये विद्यार्थ्याचा PEN क्रमांक किंवा नाव टाकल्यावर<br/>त्याचा संपूर्ण FLN टप्पा इतिहास दिसेल — सर्व वर्षांसह.</p>
    </div>
  <% } %>

</div><!-- /page -->

</body>
</html>

<%!
/* ── Helper methods ── */
private String levelClass(String v) {
    if (v == null || v.equals("null") || v.isEmpty()) return "lv-null";
    try {
        int n = Integer.parseInt(v.trim());
        if (n <= 2) return "lv-low";
        if (n <= 4) return "lv-mid";
        return "lv-hi";
    } catch (NumberFormatException e) { return "lv-null"; }
}

private String levelLabel(String v) {
    if (v == null || v.equals("null") || v.isEmpty()) return "—";
    try {
        int n = Integer.parseInt(v.trim());
        return "स्तर " + n;
    } catch (NumberFormatException e) { return v; }
}

private int flnProgress(java.util.Map<String,Object> row) {
    int total = 0, filled = 0;
    String[] keys = {"p1mar","p1mat","p1eng","p2mar","p2mat","p2eng","p3mar","p3mat","p3eng","p4mar","p4mat","p4eng"};
    int[]    max  = {6,8,6, 6,8,6, 6,8,6, 6,8,6};
    int[]    sum  = new int[12];
    for (int i = 0; i < keys.length; i++) {
        Object o = row.get(keys[i]);
        if (o != null && !o.toString().equals("null") && !o.toString().isEmpty()) {
            try { sum[i] = Integer.parseInt(o.toString()); filled++; } catch (Exception e) {}
        }
        total += max[i];
    }
    if (filled == 0) return 0;
    int sumAll = 0; for (int s : sum) sumAll += s;
    return (int) Math.round(sumAll * 100.0 / total);
}

private int phaseProgress(String[] ph) {
    // ph = [mar, mat, eng, date]
    int[] max = {6, 8, 6};
    int sumAll = 0, totalMax = 20;
    for (int i = 0; i < 3; i++) {
        if (ph[i] != null && !ph[i].equals("null") && !ph[i].isEmpty()) {
            try { sumAll += Integer.parseInt(ph[i]); } catch (Exception e) {}
        }
    }
    return (int) Math.round(sumAll * 100.0 / totalMax);
}
%>
