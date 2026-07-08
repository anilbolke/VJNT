<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.vjnt.model.User" %>
<%
    User user = (User) session.getAttribute("user");
    if (user == null) {
        response.sendRedirect(request.getContextPath() + "/login.jsp");
        return;
    }
    String userType = user.getUserType().toString();
    String userName = user.getFullName() != null ? user.getFullName() : user.getUsername();
%>
<!DOCTYPE html>
<html lang="mr">
<head>
<meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>मदत केंद्र — GATEE पोर्टल</title>
<style>
/* ───── Reset & Base ───── */
*{margin:0;padding:0;box-sizing:border-box;}
body{font-family:'Segoe UI',Tahoma,Geneva,Verdana,sans-serif;background:#f0f4f8;color:#1e293b;min-height:100vh;}

/* ───── Top Bar ───── */
.topbar{background:linear-gradient(90deg,#667eea,#764ba2);color:#fff;display:flex;
        align-items:center;justify-content:space-between;padding:0 24px;height:56px;
        position:sticky;top:0;z-index:100;box-shadow:0 2px 8px rgba(0,0,0,0.2);}
.topbar-left{display:flex;align-items:center;gap:14px;}
.topbar-logo{font-size:22px;font-weight:800;letter-spacing:-0.5px;}
.topbar-badge{background:rgba(255,255,255,0.2);border-radius:12px;padding:3px 10px;font-size:11px;font-weight:600;}
.topbar-right{display:flex;align-items:center;gap:12px;}
.back-btn{background:rgba(255,255,255,0.15);border:1px solid rgba(255,255,255,0.3);color:#fff;
          padding:6px 16px;border-radius:20px;font-size:13px;cursor:pointer;text-decoration:none;
          transition:background 0.2s;}
.back-btn:hover{background:rgba(255,255,255,0.25);}
.user-chip{font-size:13px;opacity:0.85;}

/* ───── Hero Search ───── */
.hero{background:linear-gradient(135deg,#1e293b,#0f172a);padding:48px 24px;text-align:center;}
.hero h1{font-size:32px;font-weight:800;color:#fff;margin-bottom:8px;}
.hero p{color:rgba(255,255,255,0.65);font-size:15px;margin-bottom:28px;}
.search-wrap{max-width:560px;margin:0 auto;position:relative;}
.search-wrap input{width:100%;padding:14px 52px 14px 20px;border-radius:30px;border:none;
                   font-size:15px;outline:none;box-shadow:0 4px 20px rgba(0,0,0,0.3);}
.search-wrap .s-icon{position:absolute;right:18px;top:50%;transform:translateY(-50%);
                     font-size:18px;color:#94a3b8;pointer-events:none;}
.hero-tags{display:flex;gap:10px;justify-content:center;margin-top:18px;flex-wrap:wrap;}
.hero-tag{background:rgba(255,255,255,0.1);border:1px solid rgba(255,255,255,0.2);color:#fff;
          border-radius:16px;padding:5px 14px;font-size:12px;cursor:pointer;transition:background 0.2s;}
.hero-tag:hover,.hero-tag.active{background:rgba(255,255,255,0.25);}

/* ───── Role Filter Bar ───── */
.role-bar{background:#fff;border-bottom:1px solid #e2e8f0;padding:0 24px;
          display:flex;align-items:center;gap:4px;overflow-x:auto;}
.role-tab{padding:14px 20px;font-size:13px;font-weight:600;cursor:pointer;color:#64748b;
          border-bottom:3px solid transparent;white-space:nowrap;transition:all 0.2s;}
.role-tab:hover{color:#667eea;}
.role-tab.active{color:#667eea;border-bottom-color:#667eea;}

/* ───── Main Layout ───── */
.main-layout{display:grid;grid-template-columns:260px 1fr;gap:0;max-width:1200px;
             margin:24px auto;padding:0 24px;}

/* ───── Sidebar ───── */
.sidebar{background:#fff;border-radius:12px;padding:8px;height:fit-content;
         position:sticky;top:76px;box-shadow:0 1px 4px rgba(0,0,0,0.08);}
.sb-section{margin-bottom:4px;}
.sb-head{font-size:10px;font-weight:700;letter-spacing:1.5px;text-transform:uppercase;
         color:#94a3b8;padding:12px 12px 6px;}
.sb-link{display:flex;align-items:center;gap:10px;padding:9px 12px;border-radius:8px;
         font-size:13px;font-weight:500;color:#475569;cursor:pointer;transition:all 0.15s;}
.sb-link:hover{background:#f1f5f9;color:#667eea;}
.sb-link.active{background:#ede9fe;color:#667eea;font-weight:600;}
.sb-link .sb-icon{font-size:16px;width:20px;text-align:center;}
.sb-divider{height:1px;background:#f1f5f9;margin:8px 0;}

/* ───── Content Area ───── */
.content{display:flex;flex-direction:column;gap:20px;}

/* ───── Quick Cards ───── */
.quick-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;}
.quick-card{background:#fff;border-radius:12px;padding:20px;cursor:pointer;
            border:2px solid transparent;transition:all 0.2s;box-shadow:0 1px 4px rgba(0,0,0,0.07);}
.quick-card:hover{border-color:#667eea;transform:translateY(-2px);box-shadow:0 6px 20px rgba(102,126,234,0.15);}
.quick-card .qc-icon{font-size:32px;margin-bottom:10px;}
.quick-card h4{font-size:14px;font-weight:700;color:#1e293b;margin-bottom:4px;}
.quick-card p{font-size:12px;color:#64748b;line-height:1.6;}

/* ───── Article Cards ───── */
.article{background:#fff;border-radius:12px;box-shadow:0 1px 4px rgba(0,0,0,0.07);overflow:hidden;}
.article-header{padding:20px 24px;border-bottom:1px solid #f1f5f9;display:flex;
                align-items:center;gap:12px;cursor:pointer;}
.article-header .a-icon{font-size:24px;}
.article-header h3{font-size:16px;font-weight:700;flex:1;}
.article-header .a-badge{font-size:11px;padding:3px 10px;border-radius:12px;font-weight:600;}
.article-body{padding:24px;display:none;}
.article-body.open{display:block;}

/* ───── Step List ───── */
.step-list{list-style:none;margin:12px 0;}
.step-list li{display:flex;gap:14px;padding:12px 0;border-bottom:1px solid #f8fafc;}
.step-list li:last-child{border-bottom:none;}
.step-num{width:28px;height:28px;border-radius:50%;background:linear-gradient(135deg,#667eea,#764ba2);
          color:#fff;font-size:12px;font-weight:700;display:flex;align-items:center;
          justify-content:center;flex-shrink:0;margin-top:1px;}
.step-text{font-size:14px;line-height:1.7;color:#374151;}
.step-text strong{color:#1e293b;}
.step-text .step-note{font-size:12px;color:#667eea;margin-top:3px;display:block;}

/* ───── Info Boxes ───── */
.info-box{border-radius:8px;padding:14px 16px;margin:12px 0;font-size:13px;line-height:1.7;}
.info-tip  {background:#eff6ff;border-left:4px solid #3b82f6;color:#1e40af;}
.info-warn {background:#fff7ed;border-left:4px solid #f97316;color:#9a3412;}
.info-ok   {background:#f0fdf4;border-left:4px solid #22c55e;color:#14532d;}
.info-box strong{display:block;margin-bottom:4px;font-size:13px;}

/* ───── Role Chips in content ───── */
.role-chip{display:inline-block;border-radius:10px;padding:2px 10px;font-size:11px;
           font-weight:700;margin:2px;}
.rc-admin  {background:#fee2e2;color:#991b1b;}
.rc-coord  {background:#dbeafe;color:#1e40af;}
.rc-hm     {background:#dcfce7;color:#14532d;}
.rc-dist   {background:#f3e8ff;color:#6b21a8;}
.rc-div    {background:#ffedd5;color:#9a3412;}
.rc-super  {background:#ccfbf1;color:#115e59;}

/* ───── FAQ ───── */
.faq-item{border:1px solid #e2e8f0;border-radius:10px;margin-bottom:8px;overflow:hidden;}
.faq-q{padding:14px 18px;cursor:pointer;display:flex;justify-content:space-between;
       align-items:center;font-size:14px;font-weight:600;color:#1e293b;
       background:#fff;transition:background 0.15s;}
.faq-q:hover{background:#f8fafc;}
.faq-q .faq-arrow{transition:transform 0.2s;color:#667eea;font-size:16px;}
.faq-q.open .faq-arrow{transform:rotate(180deg);}
.faq-a{padding:0 18px;max-height:0;overflow:hidden;transition:max-height 0.3s ease,padding 0.2s;
       font-size:13px;color:#475569;line-height:1.8;background:#fafafa;}
.faq-a.open{max-height:400px;padding:14px 18px;}

/* ───── Workflow Diagram ───── */
.workflow{display:flex;align-items:flex-start;gap:0;margin:16px 0;overflow-x:auto;padding-bottom:4px;}
.wf-step{background:#f8fafc;border:2px solid #e2e8f0;border-radius:10px;padding:14px;
         text-align:center;min-width:120px;flex:1;}
.wf-step.wf-active{border-color:#667eea;background:#ede9fe;}
.wf-step.wf-done{border-color:#22c55e;background:#f0fdf4;}
.wf-step .wf-icon{font-size:24px;margin-bottom:6px;}
.wf-step h5{font-size:12px;font-weight:700;color:#1e293b;margin-bottom:3px;}
.wf-step p{font-size:10px;color:#64748b;line-height:1.5;}
.wf-arrow{font-size:20px;color:#cbd5e1;padding:0 6px;margin-top:20px;flex-shrink:0;}

/* ───── Phase Boxes ───── */
.phase-row{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:12px 0;}
.phase-card{border-radius:8px;padding:14px;border:2px solid;}
.ph1{background:#eff6ff;border-color:#93c5fd;}
.ph2{background:#f0fdf4;border-color:#86efac;}
.ph3{background:#fff7ed;border-color:#fdba74;}
.ph4{background:#faf5ff;border-color:#c084fc;}
.phase-card h5{font-size:13px;font-weight:700;margin-bottom:6px;}
.phase-card p{font-size:12px;color:#475569;line-height:1.6;}

/* ───── Two Column ───── */
.two-col{display:grid;grid-template-columns:1fr 1fr;gap:16px;margin:12px 0;}
.col-card{background:#f8fafc;border-radius:8px;padding:14px;}
.col-card h5{font-size:13px;font-weight:700;color:#1e293b;margin-bottom:8px;}
.col-card ul{list-style:none;}
.col-card ul li{font-size:12px;color:#475569;padding:4px 0;display:flex;align-items:flex-start;gap:6px;}
.col-card ul li::before{content:"•";color:#667eea;font-weight:700;flex-shrink:0;}

/* ───── Contact Section ───── */
.contact-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:14px;}
.contact-card{background:#fff;border-radius:10px;padding:18px;text-align:center;
              box-shadow:0 1px 4px rgba(0,0,0,0.08);border:1px solid #e2e8f0;}
.contact-card .cc-icon{font-size:36px;margin-bottom:10px;}
.contact-card h4{font-size:14px;font-weight:700;margin-bottom:4px;}
.contact-card p{font-size:12px;color:#64748b;line-height:1.7;}

/* ───── Table ───── */
.help-table{width:100%;border-collapse:collapse;font-size:13px;margin:12px 0;}
.help-table th{background:#f1f5f9;padding:10px 14px;text-align:left;font-weight:700;
               color:#475569;font-size:12px;text-transform:uppercase;letter-spacing:0.5px;}
.help-table td{padding:10px 14px;border-bottom:1px solid #f1f5f9;color:#374151;}
.help-table tr:last-child td{border-bottom:none;}
.help-table tr:hover td{background:#f8fafc;}

/* ───── No results ───── */
.no-results{text-align:center;padding:60px 20px;color:#94a3b8;}
.no-results .nr-icon{font-size:48px;margin-bottom:12px;}

/* ───── Utilities ───── */
.section-title{font-size:18px;font-weight:800;color:#1e293b;margin-bottom:14px;
               display:flex;align-items:center;gap:8px;}
.section-title span{font-size:22px;}
.highlight{background:linear-gradient(90deg,#667eea20,#764ba220);border-radius:4px;
           padding:1px 6px;font-weight:600;}
.text-sm{font-size:12px;color:#64748b;}
.mt8{margin-top:8px;}

@media(max-width:768px){
  .main-layout{grid-template-columns:1fr;padding:0 12px;}
  .sidebar{position:static;display:flex;flex-wrap:wrap;gap:4px;padding:12px;}
  .sb-section{width:100%;}
  .quick-grid{grid-template-columns:1fr 1fr;}
  .phase-row{grid-template-columns:1fr 1fr;}
  .two-col{grid-template-columns:1fr;}
  .contact-grid{grid-template-columns:1fr;}
}
</style>
</head>
<body>

<!-- ══ Top Bar ══ -->
<div class="topbar">
  <div class="topbar-left">
    <div class="topbar-logo">🏫 GATEE</div>
    <div class="topbar-badge">मदत केंद्र / Help Desk</div>
  </div>
  <div class="topbar-right">
    <span class="user-chip">👤 <%= userName %></span>
    <a href="javascript:history.back()" class="back-btn">← मागे जा</a>
  </div>
</div>

<jsp:include page="academic-year-bar.jsp" />

<!-- ══ Hero Search ══ -->
<div class="hero">
  <h1>🙋 आपण कशाबद्दल जाणून घेऊ इच्छिता?</h1>
  <p>GATEE पोर्टलवरील कोणत्याही प्रश्नाचे उत्तर येथे शोधा</p>
  <div class="search-wrap">
    <input type="text" id="searchInput" placeholder="उदा. टप्पा मंजुरी, विद्यार्थी जोडणे, वर्ग पदोन्नती..."
           oninput="doSearch(this.value)" autocomplete="off"/>
    <span class="s-icon">🔍</span>
  </div>
  <div class="hero-tags">
    <span class="hero-tag" onclick="jumpTo('login-guide')">🔑 लॉगिन</span>
    <span class="hero-tag" onclick="jumpTo('fln-guide')">📊 FLN टप्पे</span>
    <span class="hero-tag" onclick="jumpTo('approval-guide')">✅ मंजुरी</span>
    <span class="hero-tag" onclick="jumpTo('student-guide')">👨‍🎓 विद्यार्थी</span>
    <span class="hero-tag" onclick="jumpTo('promote-guide')">🎓 पदोन्नती</span>
    <span class="hero-tag" onclick="jumpTo('analytics-guide')">📈 विश्लेषण</span>
    <span class="hero-tag" onclick="jumpTo('faq-section')">❓ FAQ</span>
  </div>
</div>

<!-- ══ Role Filter ══ -->
<div class="role-bar">
  <span style="font-size:12px;font-weight:700;color:#94a3b8;white-space:nowrap;padding:14px 12px 14px 0;">
    भूमिका निवडा:
  </span>
  <div class="role-tab active" onclick="filterRole('all',this)">सर्व</div>
  <div class="role-tab" onclick="filterRole('DATA_ADMIN',this)">👑 डेटा प्रशासक</div>
  <div class="role-tab" onclick="filterRole('SCHOOL_COORDINATOR',this)">📝 शाळा समन्वयक</div>
  <div class="role-tab" onclick="filterRole('HEAD_MASTER',this)">✅ मुख्याध्यापक</div>
  <div class="role-tab" onclick="filterRole('DISTRICT_OFFICER',this)">🏢 जिल्हा अधिकारी</div>
  <div class="role-tab" onclick="filterRole('DIVISION_OFFICER',this)">🗺️ विभाग अधिकारी</div>
</div>

<!-- ══ Main Layout ══ -->
<div class="main-layout">

  <!-- Sidebar -->
  <div class="sidebar">
    <div class="sb-section">
      <div class="sb-head">सुरुवात</div>
      <div class="sb-link active" onclick="showSection('getting-started')">
        <span class="sb-icon">🚀</span> सुरुवात कशी करावी
      </div>
      <div class="sb-link" onclick="showSection('login-guide')">
        <span class="sb-icon">🔑</span> लॉगिन / लॉगआउट
      </div>
      <div class="sb-link" onclick="showSection('dashboard-guide')">
        <span class="sb-icon">🏠</span> डॅशबोर्ड समजणे
      </div>
    </div>
    <div class="sb-divider"></div>
    <div class="sb-section">
      <div class="sb-head">मुख्य वैशिष्ट्ये</div>
      <div class="sb-link" onclick="showSection('student-guide')">
        <span class="sb-icon">👨‍🎓</span> विद्यार्थी व्यवस्थापन
      </div>
      <div class="sb-link" onclick="showSection('fln-guide')">
        <span class="sb-icon">📊</span> FLN टप्पे भरणे
      </div>
      <div class="sb-link" onclick="showSection('approval-guide')">
        <span class="sb-icon">✅</span> टप्पा मंजुरी
      </div>
      <div class="sb-link" onclick="showSection('promote-guide')">
        <span class="sb-icon">🎓</span> वर्ग पदोन्नती
      </div>
      <div class="sb-link" onclick="showSection('palak-guide')">
        <span class="sb-icon">👨‍👩‍👧</span> पालक मेळावा
      </div>
      <div class="sb-link" onclick="showSection('teacher-guide')">
        <span class="sb-icon">👨‍🏫</span> शिक्षक व्यवस्थापन
      </div>
    </div>
    <div class="sb-divider"></div>
    <div class="sb-section">
      <div class="sb-head">अहवाल व विश्लेषण</div>
      <div class="sb-link" onclick="showSection('analytics-guide')">
        <span class="sb-icon">📈</span> विश्लेषण डॅशबोर्ड
      </div>
      <div class="sb-link" onclick="showSection('report-guide')">
        <span class="sb-icon">📄</span> विद्यार्थी अहवाल
      </div>
    </div>
    <div class="sb-divider"></div>
    <div class="sb-section">
      <div class="sb-head">मदत</div>
      <div class="sb-link" onclick="showSection('faq-section')">
        <span class="sb-icon">❓</span> वारंवार विचारले प्रश्न
      </div>
      <div class="sb-link" onclick="showSection('glossary-section')">
        <span class="sb-icon">📖</span> शब्दकोश
      </div>
      <div class="sb-link" onclick="showSection('contact-section')">
        <span class="sb-icon">📞</span> संपर्क
      </div>
    </div>
  </div>

  <!-- Content -->
  <div class="content" id="mainContent">

    <!-- ══════ SECTION: Getting Started ══════ -->
    <div id="section-getting-started" class="help-section">
      <div class="section-title"><span>🚀</span> GATEE पोर्टलवर सुरुवात कशी करावी</div>

      <div class="quick-grid">
        <div class="quick-card" onclick="showSection('login-guide')">
          <div class="qc-icon">🔑</div>
          <h4>लॉगिन करा</h4>
          <p>वापरकर्तानाव व पासवर्डसह पोर्टलवर प्रवेश मिळवा</p>
        </div>
        <div class="quick-card" onclick="showSection('fln-guide')">
          <div class="qc-icon">📊</div>
          <h4>FLN डेटा भरा</h4>
          <p>विद्यार्थ्यांचे मराठी, गणित, इंग्रजी स्तर नोंदवा</p>
        </div>
        <div class="quick-card" onclick="showSection('approval-guide')">
          <div class="qc-icon">✅</div>
          <h4>टप्पा मंजूर करा</h4>
          <p>मुख्याध्यापक म्हणून सादर केलेला टप्पा तपासा व मंजूर करा</p>
        </div>
        <div class="quick-card" onclick="showSection('student-guide')">
          <div class="qc-icon">👨‍🎓</div>
          <h4>विद्यार्थी पाहा</h4>
          <p>शाळेतील सर्व विद्यार्थ्यांची माहिती व FLN प्रगती पाहा</p>
        </div>
        <div class="quick-card" onclick="showSection('analytics-guide')">
          <div class="qc-icon">📈</div>
          <h4>विश्लेषण पाहा</h4>
          <p>जिल्हा/विभागस्तरीय FLN प्रगती डॅशबोर्ड</p>
        </div>
        <div class="quick-card" onclick="showSection('faq-section')">
          <div class="qc-icon">❓</div>
          <h4>FAQ पाहा</h4>
          <p>वारंवार विचारले जाणारे प्रश्न व उत्तरे</p>
        </div>
      </div>

      <!-- Overall project flow -->
      <div class="article" style="margin-top:20px;">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">🔄</span>
          <h3>संपूर्ण प्रकल्प कार्यप्रवाह — एका नजरेत</h3>
          <span class="a-badge" style="background:#ede9fe;color:#6d28d9;">महत्त्वाचे</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <div class="workflow">
            <div class="wf-step wf-done">
              <div class="wf-icon">🏫</div>
              <h5>शाळा नोंदणी</h5>
              <p>Admin: शाळा UDISE नंबरसह अपलोड</p>
            </div>
            <div class="wf-arrow">→</div>
            <div class="wf-step wf-done">
              <div class="wf-icon">👤</div>
              <h5>वापरकर्ता तयार</h5>
              <p>Admin: समन्वयक / मुख्याध्यापक लॉगिन तयार</p>
            </div>
            <div class="wf-arrow">→</div>
            <div class="wf-step wf-done">
              <div class="wf-icon">👨‍🎓</div>
              <h5>विद्यार्थी अपलोड</h5>
              <p>Admin: Excel द्वारे विद्यार्थी</p>
            </div>
            <div class="wf-arrow">→</div>
            <div class="wf-step wf-active">
              <div class="wf-icon">📝</div>
              <h5>FLN डेटा</h5>
              <p>समन्वयक: ४ टप्पे भरतो</p>
            </div>
            <div class="wf-arrow">→</div>
            <div class="wf-step">
              <div class="wf-icon">✅</div>
              <h5>मंजुरी</h5>
              <p>मुख्याध्यापक: प्रत्येक टप्पा मंजूर</p>
            </div>
            <div class="wf-arrow">→</div>
            <div class="wf-step">
              <div class="wf-icon">🎓</div>
              <h5>पदोन्नती</h5>
              <p>Admin: वर्षांत वर्ग पुढे करतो</p>
            </div>
          </div>
          <div class="info-box info-tip">
            <strong>💡 मुख्य नियम:</strong>
            टप्पा N+१ तेव्हाच उघडतो जेव्हा टप्पा N मुख्याध्यापकांनी मंजूर केलेला असतो. त्यामुळे डेटा भरल्यानंतर त्वरित मंजुरीसाठी मुख्याध्यापकांशी संपर्क साधा.
          </div>
          <div class="phase-row">
            <div class="phase-card ph1">
              <h5>📘 टप्पा १ — जून/जुलै</h5>
              <p>आधारभूत FLN मूल्यमापन. मागील वर्षाच्या टप्पा ४ वरून आपोआप बीज केले जाते.</p>
            </div>
            <div class="phase-card ph2">
              <h5>📗 टप्पा २ — सप्टें/ऑक्टो</h5>
              <p>मध्यवर्ती मूल्यमापन. टप्पा १ मंजुरीनंतर उघडतो.</p>
            </div>
            <div class="phase-card ph3">
              <h5>📙 टप्पा ३ — डिसें/जाने</h5>
              <p>मध्यवर्ती मूल्यमापन २. प्रगती मोजली जाते.</p>
            </div>
            <div class="phase-card ph4">
              <h5>📕 टप्पा ४ — मार्च/एप्रिल</h5>
              <p>अंतिम वर्षांत मूल्यमापन. पदोन्नतीसाठी आधार.</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Login Guide ══════ -->
    <div id="section-login-guide" class="help-section" style="display:none;">
      <div class="section-title"><span>🔑</span> लॉगिन / लॉगआउट मार्गदर्शिका</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">🔐</span>
          <h3>पोर्टलवर लॉगिन कसे करावे</h3>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <ul class="step-list">
            <li>
              <div class="step-num">१</div>
              <div class="step-text"><strong>ब्राउझर उघडा</strong> — Google Chrome किंवा Mozilla Firefox वापरा (Internet Explorer नाही).<br/>
              <span class="step-note">पोर्टल URL: http://gateepor.com/VJNT_ClassManagement/login.jsp</span></div>
            </li>
            <li>
              <div class="step-num">२</div>
              <div class="step-text"><strong>वापरकर्तानाव (Username) भरा</strong> — तुम्हाला Admin ने दिलेले वापरकर्तानाव टाका. उदा. <span class="highlight">school_99722005436</span></div>
            </li>
            <li>
              <div class="step-num">३</div>
              <div class="step-text"><strong>पासवर्ड भरा</strong> — पहिल्यांदा लॉगिन करताना Admin ने दिलेला पासवर्ड वापरा.</div>
            </li>
            <li>
              <div class="step-num">४</div>
              <div class="step-text"><strong>लॉगिन बटण दाबा</strong> — यशस्वी लॉगिन झाल्यावर तुमच्या भूमिकेनुसार डॅशबोर्डवर जाल.</div>
            </li>
            <li>
              <div class="step-num">५</div>
              <div class="step-text"><strong>पासवर्ड बदला</strong> — पहिल्यांदा लॉगिन केल्यावर "पासवर्ड बदला" या पर्यायातून नवीन पासवर्ड ठेवा.<br/>
              <span class="step-note">पासवर्ड किमान ८ अक्षरे असावा.</span></div>
            </li>
          </ul>
          <div class="info-box info-warn">
            <strong>⚠️ सावधान:</strong>
            सलग ५ वेळा चुकीचा पासवर्ड टाकल्यास खाते तात्पुरते बंद होईल. Admin ला संपर्क करा.
          </div>
          <div class="info-box info-tip">
            <strong>💡 टीप:</strong>
            लॉगआउटसाठी उजव्या कोपर्‍यातील तुमच्या नावावर क्लिक करा आणि "लॉगआउट" निवडा. ब्राउझर बंद करण्यापूर्वी नेहमी लॉगआउट करा.
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Dashboard ══════ -->
    <div id="section-dashboard-guide" class="help-section" style="display:none;">
      <div class="section-title"><span>🏠</span> डॅशबोर्ड समजणे</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">📋</span>
          <h3>प्रत्येक भूमिकेचा डॅशबोर्ड</h3>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <table class="help-table">
            <tr>
              <th>भूमिका</th>
              <th>डॅशबोर्डवर काय दिसते</th>
              <th>मुख्य कार्ये</th>
            </tr>
            <tr>
              <td><span class="role-chip rc-admin">👑 डेटा प्रशासक</span></td>
              <td>सर्व शाळा, एकूण विद्यार्थी, टप्पा पूर्णता, अलीकडील नोंदी</td>
              <td>वर्ग पदोन्नती, वापरकर्ता व्यवस्थापन, Excel अपलोड</td>
            </tr>
            <tr>
              <td><span class="role-chip rc-coord">📝 शाळा समन्वयक</span></td>
              <td>स्वतःच्या शाळेचे विद्यार्थी, टप्पा स्थिती, त्वरित क्रिया</td>
              <td>FLN डेटा भरणे, टप्पा सादर करणे, पालक मेळावा</td>
            </tr>
            <tr>
              <td><span class="role-chip rc-hm">✅ मुख्याध्यापक</span></td>
              <td>प्रलंबित मंजुरी, शाळा प्रगती, अलीकडील क्रिया</td>
              <td>टप्पा मंजुरी/नकार, पालक मेळावा मंजुरी</td>
            </tr>
            <tr>
              <td><span class="role-chip rc-dist">🏢 जिल्हा अधिकारी</span></td>
              <td>जिल्ह्यातील सर्व शाळा, टप्पा पूर्णता टक्केवारी</td>
              <td>विश्लेषण पाहणे, शिक्षक अहवाल, पालक मेळावा</td>
            </tr>
            <tr>
              <td><span class="role-chip rc-div">🗺️ विभाग अधिकारी</span></td>
              <td>विभागातील जिल्हे, टप्पा तुलना, स्तर वितरण</td>
              <td>विभागस्तरीय विश्लेषण, शाळा संपर्क</td>
            </tr>
            <tr>
              <td><span class="role-chip rc-super">🔭 अति-विभाग अधिकारी</span></td>
              <td>सर्व विभागांचे दृश्य, राज्यस्तरीय आकडेवारी</td>
              <td>राज्यस्तरीय विश्लेषण, घोषणा</td>
            </tr>
          </table>
          <div class="info-box info-ok">
            <strong>✅ शैक्षणिक वर्ष बार:</strong>
            सर्व डॅशबोर्डच्या वर जांभळ्या रंगाची पट्टी दिसते — यात सध्याचे शैक्षणिक वर्ष दाखवले जाते. उदा. <strong>शैक्षणिक वर्ष / Academic Year : 2026-27</strong>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Student Management ══════ -->
    <div id="section-student-guide" class="help-section" style="display:none;" data-roles="DATA_ADMIN,SCHOOL_COORDINATOR,HEAD_MASTER">
      <div class="section-title"><span>👨‍🎓</span> विद्यार्थी व्यवस्थापन</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">👁️</span>
          <h3>विद्यार्थी यादी कशी पाहावी</h3>
          <span class="a-badge" style="background:#dbeafe;color:#1e40af;">समन्वयक</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <ul class="step-list">
            <li><div class="step-num">१</div><div class="step-text"><strong>डॅशबोर्डवरून "विद्यार्थी पाहा"</strong> या पर्यायावर क्लिक करा.</div></li>
            <li><div class="step-num">२</div><div class="step-text"><strong>इयत्ता निवडा</strong> — dropdown मधून इयत्ता निवडा (I ते IX). सर्व इयत्तांसाठी "सर्व" निवडा.</div></li>
            <li><div class="step-num">३</div><div class="step-text"><strong>विद्यार्थी यादी दिसेल</strong> — PEN क्रमांक, नाव, जन्मतारीख, लिंग, आणि प्रत्येक टप्प्याचे स्तर दिसतात.</div></li>
            <li><div class="step-num">४</div><div class="step-text"><strong>विद्यार्थ्यावर क्लिक करा</strong> — त्याची संपूर्ण FLN प्रगती पाहण्यासाठी.</div></li>
          </ul>
        </div>
      </div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">➕</span>
          <h3>विद्यार्थी जोडणे / संपादन</h3>
          <span class="a-badge" style="background:#fee2e2;color:#991b1b;">Admin</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body">
          <ul class="step-list">
            <li><div class="step-num">१</div><div class="step-text"><strong>"विद्यार्थी व्यवस्थापन"</strong> → <strong>"विद्यार्थी जोडा/संपादन"</strong> वर जा.</div></li>
            <li><div class="step-num">२</div><div class="step-text"><strong>UDISE क्रमांक भरा</strong> — शाळेचा १२ अंकी UDISE नंबर आवश्यक आहे.</div></li>
            <li><div class="step-num">३</div><div class="step-text"><strong>PEN क्रमांक भरा</strong> — विद्यार्थ्याचा अद्वितीय PEN नंबर. हा डुप्लिकेट असू शकत नाही.</div></li>
            <li><div class="step-num">४</div><div class="step-text"><strong>सर्व माहिती भरा</strong> — नाव, जन्मतारीख, लिंग, इयत्ता (I–IX).</div></li>
            <li><div class="step-num">५</div><div class="step-text"><strong>जतन करा</strong> — "Save" बटण दाबा. यशस्वी झाल्यावर हिरवा संदेश येईल.</div></li>
          </ul>
          <div class="info-box info-tip">
            <strong>💡 Excel अपलोड:</strong>
            एकाधिक विद्यार्थी एकत्र जोडायचे असल्यास "Excel अपलोड" वापरा. Admin dashboard → "विद्यार्थी Excel अपलोड" → नमुना Excel डाउनलोड करा, भरा, अपलोड करा.
          </div>
          <div class="info-box info-warn">
            <strong>⚠️ इयत्ता नोंद:</strong>
            इयत्ता नेहमी रोमन अंकांत (I, II, III, IV, V, VI, VII, VIII, IX) नोंदवली जाते. "1", "2" असे नाही.
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: FLN Guide ══════ -->
    <div id="section-fln-guide" class="help-section" style="display:none;" data-roles="SCHOOL_COORDINATOR,HEAD_MASTER">
      <div class="section-title"><span>📊</span> FLN टप्पे — डेटा भरणे</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">📝</span>
          <h3>FLN स्तर कसे भरावे (शाळा समन्वयक)</h3>
          <span class="a-badge" style="background:#dbeafe;color:#1e40af;">समन्वयक</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <ul class="step-list">
            <li>
              <div class="step-num">१</div>
              <div class="step-text"><strong>टप्पा स्थिती तपासा</strong> — डॅशबोर्डवर "टप्पा स्थिती" दाखवलेली असते. सध्या कोणता टप्पा खुला आहे ते पाहा.<br/>
              <span class="step-note">🟢 OPEN — भरता येतो | 🟡 PENDING — मंजुरीसाठी सादर केला | 🔴 APPROVED — पूर्ण झाला</span></div>
            </li>
            <li>
              <div class="step-num">२</div>
              <div class="step-text"><strong>"FLN डेटा भरा"</strong> वर क्लिक करा → इयत्ता निवडा.</div>
            </li>
            <li>
              <div class="step-num">३</div>
              <div class="step-text"><strong>प्रत्येक विद्यार्थ्यासाठी स्तर निवडा:</strong>
                <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:12px;margin-top:10px;">
                  <div class="col-card">
                    <h5>📖 मराठी स्तर (६)</h5>
                    <ul>
                      <li>स्तर १ — अक्षरे ओळखत नाही</li>
                      <li>स्तर २ — अक्षरे ओळखतो</li>
                      <li>स्तर ३ — शब्द वाचतो</li>
                      <li>स्तर ४ — वाक्य वाचतो</li>
                      <li>स्तर ५ — उतारा वाचतो</li>
                      <li>स्तर ६ — FLN पूर्ण</li>
                    </ul>
                  </div>
                  <div class="col-card">
                    <h5>🔢 गणित स्तर (८)</h5>
                    <ul>
                      <li>स्तर १ — अंक ओळखत नाही</li>
                      <li>स्तर २ — १-९ अंक</li>
                      <li>स्तर ३ — ११-९९ अंक</li>
                      <li>स्तर ४ — बेरीज</li>
                      <li>स्तर ५ — वजाबाकी</li>
                      <li>स्तर ६ — गुणाकार</li>
                      <li>स्तर ७ — भागाकार</li>
                      <li>स्तर ८ — FLN पूर्ण</li>
                    </ul>
                  </div>
                  <div class="col-card">
                    <h5>🔤 इंग्रजी स्तर (६)</h5>
                    <ul>
                      <li>स्तर १ — अक्षरे ओळखत नाही</li>
                      <li>स्तर २ — अक्षरे ओळखतो</li>
                      <li>स्तर ३ — शब्द वाचतो</li>
                      <li>स्तर ४ — वाक्य वाचतो</li>
                      <li>स्तर ५ — उतारा वाचतो</li>
                      <li>स्तर ६ — FLN पूर्ण</li>
                    </ul>
                  </div>
                </div>
              </div>
            </li>
            <li>
              <div class="step-num">४</div>
              <div class="step-text"><strong>मूल्यमापन तारीख भरा</strong> — प्रत्येक टप्प्यासाठी मूल्यमापन केल्याची तारीख आवश्यक आहे.</div>
            </li>
            <li>
              <div class="step-num">५</div>
              <div class="step-text"><strong>"जतन करा" दाबा</strong> — डेटा जतन होईल. सर्व इयत्तांचा डेटा भरल्यावर "मंजुरीसाठी सादर करा" बटण दाबा.</div>
            </li>
          </ul>
          <div class="info-box info-warn">
            <strong>⚠️ महत्त्वाचे:</strong>
            एकदा "मंजुरीसाठी सादर" केल्यावर मुख्याध्यापक मंजूर करेपर्यंत डेटा बदलता येत नाही. त्यामुळे सर्व माहिती बरोबर असल्याची खात्री करूनच सादर करा.
          </div>
        </div>
      </div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">📤</span>
          <h3>टप्पा मंजुरीसाठी सादर कसे करावे</h3>
          <span class="a-badge" style="background:#dbeafe;color:#1e40af;">समन्वयक</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body">
          <ul class="step-list">
            <li><div class="step-num">१</div><div class="step-text"><strong>सर्व इयत्तांचा डेटा भरल्याची खात्री करा</strong> — कोणताही विद्यार्थी सुटला नाही ना ते तपासा.</div></li>
            <li><div class="step-num">२</div><div class="step-text"><strong>"टप्पा स्थिती"</strong> पृष्ठावर जा → <strong>"मंजुरीसाठी सादर करा"</strong> बटण दाबा.</div></li>
            <li><div class="step-num">३</div><div class="step-text"><strong>पुष्टी करा</strong> — "होय, सादर करा" बटण दाबा. टप्पा PENDING स्थितीत जाईल.</div></li>
            <li><div class="step-num">४</div><div class="step-text"><strong>मुख्याध्यापकांना सांगा</strong> — मंजुरीसाठी मुख्याध्यापकांशी संपर्क साधा.</div></li>
          </ul>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Approval Guide ══════ -->
    <div id="section-approval-guide" class="help-section" style="display:none;" data-roles="HEAD_MASTER,DATA_ADMIN">
      <div class="section-title"><span>✅</span> टप्पा मंजुरी मार्गदर्शिका</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">🔍</span>
          <h3>टप्पा कसा मंजूर करावा (मुख्याध्यापक)</h3>
          <span class="a-badge" style="background:#dcfce7;color:#14532d;">मुख्याध्यापक</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <ul class="step-list">
            <li>
              <div class="step-num">१</div>
              <div class="step-text"><strong>डॅशबोर्डवर जा</strong> — "प्रलंबित मंजुरी" (Pending Approvals) कार्ड दिसेल. त्यावर क्लिक करा किंवा मेनूतून <strong>"टप्पा मंजुरी"</strong> निवडा.</div>
            </li>
            <li>
              <div class="step-num">२</div>
              <div class="step-text"><strong>प्रलंबित टप्पा पाहा</strong> — कोणत्या शाळेने कोणता टप्पा सादर केला आहे ते दिसेल (PENDING स्थिती).</div>
            </li>
            <li>
              <div class="step-num">३</div>
              <div class="step-text"><strong>डेटा तपासा</strong> — "विद्यार्थी पाहा" वर जाऊन भरलेला डेटा बरोबर आहे का तपासा.</div>
            </li>
            <li>
              <div class="step-num">४</div>
              <div class="step-text"><strong>मंजूर करा किंवा नाकारा:</strong><br/>
                ✅ <strong>मंजूर (APPROVE)</strong> — डेटा बरोबर असल्यास. पुढील टप्पा आपोआप उघडेल.<br/>
                ❌ <strong>नाकार (REJECT)</strong> — चुकीचा डेटा असल्यास. कारण लिहा. समन्वयक पुन्हा भरू शकेल.
              </div>
            </li>
            <li>
              <div class="step-num">५</div>
              <div class="step-text"><strong>शेरा लिहा</strong> — मंजूर करताना किंवा नाकारताना छोटी टिप्पणी लिहा (उदा. "सर्व इयत्तांचा डेटा बरोबर आहे").</div>
            </li>
          </ul>
          <div class="info-box info-ok">
            <strong>✅ मंजुरीनंतर काय होते?</strong><br/>
            टप्पा N मंजूर झाल्यावर टप्पा N+१ शाळा समन्वयकासाठी आपोआप उघडतो. त्यांना सूचना द्या.
          </div>
          <div class="info-box info-warn">
            <strong>⚠️ नाकार दिल्यास:</strong><br/>
            समन्वयकाला सूचना द्या की कोणता डेटा चुकीचा आहे. ते दुरुस्ती करून पुन्हा सादर करतील.
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Promote Guide ══════ -->
    <div id="section-promote-guide" class="help-section" style="display:none;" data-roles="DATA_ADMIN">
      <div class="section-title"><span>🎓</span> वर्ग पदोन्नती</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">🎓</span>
          <h3>वर्षांत वर्ग पदोन्नती कशी करावी</h3>
          <span class="a-badge" style="background:#fee2e2;color:#991b1b;">केवळ Admin</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <div class="info-box info-warn">
            <strong>⚠️ पूर्वतयारी:</strong>
            पदोन्नती करण्यापूर्वी शक्यतो सर्व शाळांचे टप्पा ४ पूर्ण होऊन मंजूर झालेले असावेत. अपूर्ण शाळांसाठी पोर्टल COALESCE (सर्वोत्तम उपलब्ध टप्पा) वापरतो.
          </div>
          <ul class="step-list">
            <li><div class="step-num">१</div><div class="step-text"><strong>Admin डॅशबोर्ड</strong> → <strong>"वर्ग पदोन्नती"</strong> वर जा.</div></li>
            <li><div class="step-num">२</div><div class="step-text"><strong>Preview तपासा</strong> — एकूण किती विद्यार्थी पदोन्नत होतील, किती इयत्ता नववीतून उत्तीर्ण होतील, किती शाळांचा डेटा अपूर्ण आहे — सर्व दिसेल.</div></li>
            <li>
              <div class="step-num">३</div>
              <div class="step-text"><strong>एकट्या शाळेसाठी चाचणी (शिफारसीय)</strong> — "Test Promote" वापरून एखाद्या शाळेसाठी आधी चाचणी करा.<br/>
              <span class="step-note">Admin डॅशबोर्ड → "Test Promote" → UDISE क्रमांक भरा → Preview पाहा → Confirm</span></div>
            </li>
            <li><div class="step-num">४</div><div class="step-text"><strong>पुष्टी करण्यासाठी "PROMOTE" टाइप करा</strong> — सुरक्षिततेसाठी PROMOTE शब्द टाइप करणे आवश्यक आहे.</div></li>
            <li><div class="step-num">५</div><div class="step-text"><strong>"सर्व शाळा पदोन्नत करा" बटण दाबा</strong> — ही प्रक्रिया काही मिनिटे घेऊ शकते. पूर्ण झाल्यावर यशाचा संदेश येईल.</div></li>
          </ul>
          <div class="two-col">
            <div class="col-card">
              <h5>✅ पदोन्नतीत काय होते</h5>
              <ul>
                <li>इयत्ता I → II, II → III... VIII → IX</li>
                <li>इयत्ता IX विद्यार्थी "उत्तीर्ण" म्हणून नोंदवले जातात</li>
                <li>टप्पा ४ डेटा → नव्या वर्षाचा टप्पा १</li>
                <li>सर्व मंजुरी नोंदी इतिहासात जतन</li>
                <li>पूर्ण लेखापरीक्षण नोंद तयार होते</li>
              </ul>
            </div>
            <div class="col-card">
              <h5>📋 पदोन्नतीनंतर</h5>
              <ul>
                <li>"Promotion Audit" मध्ये नोंद पाहा</li>
                <li>"Graduated Students" मध्ये उत्तीर्ण पाहा</li>
                <li>नव्या वर्षात टप्पा १ आपोआप बीज झालेला असेल</li>
                <li>समन्वयकांना सांगा की नवीन वर्ष सुरू झाले</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Palak Melava ══════ -->
    <div id="section-palak-guide" class="help-section" style="display:none;" data-roles="SCHOOL_COORDINATOR,HEAD_MASTER,DISTRICT_OFFICER">
      <div class="section-title"><span>👨‍👩‍👧</span> पालक मेळावा</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">📸</span>
          <h3>पालक मेळाव्याची नोंद कशी करावी</h3>
          <span class="a-badge" style="background:#dbeafe;color:#1e40af;">समन्वयक</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <ul class="step-list">
            <li><div class="step-num">१</div><div class="step-text"><strong>"पालक मेळावा"</strong> मेनूवर जा → <strong>"नोंद करा"</strong> निवडा.</div></li>
            <li><div class="step-num">२</div><div class="step-text"><strong>तारीख भरा</strong> — मेळावा झाल्याची तारीख निवडा.</div></li>
            <li><div class="step-num">३</div><div class="step-text"><strong>उपस्थित पालकांची संख्या</strong> — एकूण किती पालक उपस्थित होते ते भरा.</div></li>
            <li><div class="step-num">४</div><div class="step-text"><strong>फोटो अपलोड करा</strong> — मेळाव्याचे फोटो अपलोड करा (JPG/PNG, कमाल 5MB). फोटो सुरक्षितपणे CDN वर साठवले जातात.</div></li>
            <li><div class="step-num">५</div><div class="step-text"><strong>"जतन करा"</strong> दाबा → नोंद PENDING स्थितीत जाईल → मुख्याध्यापक मंजूर करतील.</div></li>
          </ul>
          <div class="info-box info-tip">
            <strong>💡 टीप:</strong>
            पालक मेळावा नोंद जिल्हा व विभाग अधिकाऱ्यांना त्यांच्या विश्लेषण डॅशबोर्डवर दिसते. नियमित मेळावे घेणे व नोंद करणे महत्त्वाचे आहे.
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Teacher Guide ══════ -->
    <div id="section-teacher-guide" class="help-section" style="display:none;" data-roles="DATA_ADMIN,SCHOOL_COORDINATOR">
      <div class="section-title"><span>👨‍🏫</span> शिक्षक व्यवस्थापन</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">➕</span>
          <h3>शिक्षक जोडणे व इयत्ता/विषय नियुक्ती</h3>
          <span class="a-badge" style="background:#dbeafe;color:#1e40af;">समन्वयक / Admin</span>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <ul class="step-list">
            <li><div class="step-num">१</div><div class="step-text"><strong>"शिक्षक व्यवस्थापन"</strong> → <strong>"शिक्षक जोडा"</strong> वर जा.</div></li>
            <li><div class="step-num">२</div><div class="step-text"><strong>शिक्षकाची माहिती भरा</strong> — पूर्ण नाव, मोबाइल, विषय.</div></li>
            <li><div class="step-num">३</div><div class="step-text"><strong>"शिक्षक नियुक्ती"</strong> वर जा → इयत्ता व विषय निवडा → शिक्षकाचे नाव निवडा → "नियुक्त करा".</div></li>
          </ul>
          <div class="info-box info-tip">
            <strong>💡 शिक्षक अहवाल:</strong>
            जिल्हा अधिकारी त्यांच्या डॅशबोर्डवरून जिल्ह्यातील सर्व शिक्षक नियुक्ती पाहू शकतात.
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Analytics Guide ══════ -->
    <div id="section-analytics-guide" class="help-section" style="display:none;" data-roles="DISTRICT_OFFICER,DIVISION_OFFICER,SUPER_DIVISION_OFFICER,DATA_ADMIN">
      <div class="section-title"><span>📈</span> विश्लेषण डॅशबोर्ड</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">📊</span>
          <h3>विश्लेषण डॅशबोर्ड कसे वाचावे</h3>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <table class="help-table">
            <tr>
              <th>विश्लेषण प्रकार</th>
              <th>काय दाखवते</th>
              <th>कोणासाठी</th>
            </tr>
            <tr>
              <td><strong>स्तर वितरण</strong></td>
              <td>किती विद्यार्थी कोणत्या स्तरावर आहेत (स्तर १ ते ६/८)</td>
              <td><span class="role-chip rc-dist">जिल्हा</span> <span class="role-chip rc-div">विभाग</span> <span class="role-chip rc-super">अति-विभाग</span></td>
            </tr>
            <tr>
              <td><strong>टप्पा तुलना</strong></td>
              <td>टप्पा १ ते ४ मधील स्तर बदल (प्रगती मोजमाप)</td>
              <td><span class="role-chip rc-dist">जिल्हा</span> <span class="role-chip rc-div">विभाग</span></td>
            </tr>
            <tr>
              <td><strong>स्तर उड्या</strong></td>
              <td>टप्पा सुरू ते शेवटात विद्यार्थ्याने किती स्तर सुधारले</td>
              <td><span class="role-chip rc-dist">जिल्हा</span> <span class="role-chip rc-div">विभाग</span></td>
            </tr>
            <tr>
              <td><strong>FLN पूर्णता %</strong></td>
              <td>तिन्ही विषयांत FLN पूर्ण केलेल्या विद्यार्थ्यांची टक्केवारी</td>
              <td>सर्व स्तर</td>
            </tr>
            <tr>
              <td><strong>टप्पा पूर्णता स्थिती</strong></td>
              <td>कोणत्या शाळांनी कोणते टप्पे पूर्ण केले</td>
              <td>सर्व स्तर</td>
            </tr>
            <tr>
              <td><strong>उपक्रम विश्लेषण</strong></td>
              <td>पालक मेळावे, शाळा संपर्क आकडेवारी</td>
              <td><span class="role-chip rc-div">विभाग</span> <span class="role-chip rc-super">अति-विभाग</span></td>
            </tr>
          </table>
          <div class="info-box info-tip">
            <strong>💡 जिल्हा अधिकारी:</strong>
            तुमच्या डॅशबोर्डवर dropdown मधून शाळा निवडून त्याचे विद्यार्थी स्तर पाहता येतात. "Phase-wise Subject Statistics" मध्ये मराठी, गणित, इंग्रजी — विषयनिहाय आकडेवारी मिळते.
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Report Guide ══════ -->
    <div id="section-report-guide" class="help-section" style="display:none;" data-roles="SCHOOL_COORDINATOR,HEAD_MASTER,DATA_ADMIN">
      <div class="section-title"><span>📄</span> विद्यार्थी अहवाल</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">📄</span>
          <h3>विद्यार्थी प्रगती पत्रिका (PDF) कशी मिळवावी</h3>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <ul class="step-list">
            <li><div class="step-num">१</div><div class="step-text"><strong>"विद्यार्थी अहवाल"</strong> मेनूवर जा → <strong>"अहवाल विनंती करा"</strong>.</div></li>
            <li><div class="step-num">२</div><div class="step-text"><strong>विद्यार्थी निवडा</strong> — PEN क्रमांकाने किंवा नावाने शोधा.</div></li>
            <li><div class="step-num">३</div><div class="step-text"><strong>विनंती पाठवा</strong> — अहवाल विनंती PENDING स्थितीत जाईल. Admin मंजुरीनंतर PDF उपलब्ध होईल.</div></li>
            <li><div class="step-num">४</div><div class="step-text"><strong>"माझ्या विनंत्या"</strong> (My Report Requests) मध्ये स्थिती पाहा. मंजूर झाल्यावर PDF डाउनलोड करा.</div></li>
          </ul>
          <div class="info-box info-ok">
            <strong>📋 अहवालात काय असते:</strong>
            विद्यार्थ्याचे नाव, PEN, शाळा, इयत्ता, सर्व ४ टप्प्यांचे मराठी/गणित/इंग्रजी स्तर, FLN पूर्णता स्थिती, आणि टप्पानिहाय मूल्यमापन तारखा.
          </div>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: FAQ ══════ -->
    <div id="section-faq-section" class="help-section" style="display:none;">
      <div class="section-title"><span>❓</span> वारंवार विचारले जाणारे प्रश्न (FAQ)</div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>माझा पासवर्ड विसरला. काय करावे?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          लॉगिन पृष्ठावर "पासवर्ड विसरलात?" पर्याय नसल्यास थेट तुमच्या <strong>Data Admin</strong> शी संपर्क साधा. ते तुमचा पासवर्ड रीसेट करतील. Admin: "वापरकर्ता व्यवस्थापन" → संबंधित वापरकर्ता शोधा → "पासवर्ड रीसेट" करा.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>पुढील टप्पा का उघडत नाही?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          पुढील टप्पा तेव्हाच उघडतो जेव्हा <strong>मागील टप्पा मुख्याध्यापकांनी APPROVED केलेला असतो</strong>. "टप्पा स्थिती" पृष्ठावर जाऊन पाहा — मागील टप्पा PENDING आहे का? PENDING असेल तर मुख्याध्यापकांशी संपर्क साधा आणि मंजुरी द्यायला सांगा.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>डेटा भरल्यानंतर बदलता येत नाही. काय करावे?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          एकदा "मंजुरीसाठी सादर" केल्यावर डेटा संपादन बंद होते. <strong>मुख्याध्यापकांनी टप्पा REJECT केल्यावरच</strong> समन्वयक पुन्हा डेटा दुरुस्त करू शकतो. त्यामुळे मुख्याध्यापकांना सांगा की चुकीचा टप्पा REJECT करावा, दुरुस्ती करा, आणि पुन्हा सादर करा.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>विद्यार्थी यादीत एखादा विद्यार्थी दिसत नाही. का?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          खालील कारणे असू शकतात: (१) विद्यार्थी is_active=0 (निष्क्रिय) असेल — Admin ला सांगा सक्रिय करायला. (२) विद्यार्थ्याचा UDISE वेगळा असेल. (३) विद्यार्थी चुकीच्या इयत्तेत नोंदला असेल. Admin ला PEN क्रमांक देऊन तपासायला सांगा.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>FLN_COMPLETED म्हणजे काय?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          जेव्हा विद्यार्थी <strong>मराठी स्तर ६</strong> + <strong>गणित स्तर ८</strong> + <strong>इंग्रजी स्तर ६</strong> — तिन्ही विषयांत सर्वोच्च स्तर गाठतो तेव्हा त्याची <strong>FLN पूर्णता (fln_completed=1)</strong> नोंदली जाते. हे आपोआप होते — वेगळे करण्याची गरज नाही.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>वर्ग पदोन्नतीनंतर टप्पा १ डेटा कुठून येतो?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          पदोन्नतीत नव्या वर्षाचा टप्पा १ मागील वर्षाच्या सर्वोत्तम उपलब्ध टप्प्यावरून (<strong>COALESCE: टप्पा४ → ३ → २ → १</strong>) आपोआप बीज (seed) केला जातो. त्यामुळे समन्वयकाला टप्पा १ शून्यापासून भरावा लागत नाही — फक्त सुधारणा/अद्ययावत करायच्या असतात.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>पालक मेळाव्याचे फोटो अपलोड होत नाहीत. काय करावे?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          (१) फोटो फाईल JPG किंवा PNG फॉरमॅटमध्ये असावी. (२) एका फोटोचा आकार ५ MB पेक्षा जास्त नसावा. (३) इंटरनेट कनेक्शन स्थिर असावे. (४) ब्राउझर refresh करून पुन्हा प्रयत्न करा. तरीही अडचण असल्यास Admin ला संपर्क करा.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>UDISE क्रमांक म्हणजे काय?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          <strong>UDISE (Unified District Information System for Education)</strong> हा प्रत्येक शाळेला शासनाकडून दिलेला अद्वितीय १२ अंकी ओळख क्रमांक आहे. हाच क्रमांक शाळेचा मुख्य ओळखकर्ता म्हणून GATEE पोर्टलमध्ये वापरला जातो.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>लॉगिन झाल्यावर "Unauthorized Access" येतो. का?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          तुम्ही चुकीच्या पृष्ठावर जात असाल. प्रत्येक पृष्ठ विशिष्ट भूमिकेसाठीच उघडते. उदा. "headmaster-approve-phase.jsp" फक्त मुख्याध्यापकांसाठी आहे. योग्य डॅशबोर्डमधून क्लिक करा. थेट URL टाकू नका.
        </div>
      </div>

      <div class="faq-item">
        <div class="faq-q" onclick="toggleFaq(this)">
          <span>शैक्षणिक वर्ष बार चुकीचे वर्ष दाखवत आहे. का?</span>
          <span class="faq-arrow">▼</span>
        </div>
        <div class="faq-a">
          शैक्षणिक वर्ष <strong>जून महिन्यापासून</strong> नवीन वर्ष सुरू होते असे मानले जाते. जून ते मे = एक शैक्षणिक वर्ष. उदा. जून २०२६ ते मे २०२७ = शैक्षणिक वर्ष <strong>२०२६-२७</strong>. जर तुम्हाला वेगळे वर्ष दिसत असेल तर Admin ला कळवा.
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Glossary ══════ -->
    <div id="section-glossary-section" class="help-section" style="display:none;">
      <div class="section-title"><span>📖</span> शब्दकोश — महत्त्वाच्या संज्ञा</div>

      <div class="article">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">📖</span>
          <h3>तांत्रिक व शैक्षणिक संज्ञांचा अर्थ</h3>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body open">
          <table class="help-table">
            <tr><th>संज्ञा</th><th>अर्थ</th></tr>
            <tr><td><strong>FLN</strong></td><td>Foundational Literacy and Numeracy — मूलभूत साक्षरता आणि अंकज्ञान. राष्ट्रीय शैक्षणिक धोरण २०२० नुसार इयत्ता तिसरीपर्यंत साध्य करायचे उद्दिष्ट.</td></tr>
            <tr><td><strong>UDISE</strong></td><td>Unified District Information System for Education — शाळेचा १२ अंकी शासकीय ओळख क्रमांक.</td></tr>
            <tr><td><strong>PEN</strong></td><td>Permanent Enrollment Number — विद्यार्थ्याचा अद्वितीय नोंदणी क्रमांक.</td></tr>
            <tr><td><strong>टप्पा (Phase)</strong></td><td>FLN मूल्यमापनाचा एक कालावधी. प्रत्येक शैक्षणिक वर्षात ४ टप्पे असतात.</td></tr>
            <tr><td><strong>PENDING</strong></td><td>टप्पा सादर केला आहे, मुख्याध्यापकांची मंजुरी प्रतीक्षेत आहे.</td></tr>
            <tr><td><strong>APPROVED</strong></td><td>मुख्याध्यापकांनी टप्पा मंजूर केला आहे. पुढील टप्पा उघडला आहे.</td></tr>
            <tr><td><strong>REJECTED</strong></td><td>मुख्याध्यापकांनी टप्पा नाकारला — समन्वयकाने दुरुस्ती करावी.</td></tr>
            <tr><td><strong>OPEN</strong></td><td>टप्पा डेटा भरण्यासाठी उघडा आहे.</td></tr>
            <tr><td><strong>COALESCE</strong></td><td>पदोन्नतीत उपलब्ध सर्वोत्तम टप्प्याचा डेटा नव्या वर्षाच्या टप्पा १ साठी वापरण्याची पद्धत.</td></tr>
            <tr><td><strong>FLN_COMPLETED</strong></td><td>विद्यार्थ्याने तिन्ही विषयांत (मराठी ६, गणित ८, इंग्रजी ६) सर्वोच्च FLN स्तर गाठला आहे.</td></tr>
            <tr><td><strong>उत्तीर्ण (Graduated)</strong></td><td>इयत्ता नववीतून पुढे गेलेला विद्यार्थी. पोर्टलमध्ये कायमस्वरूपी नोंदला जातो.</td></tr>
            <tr><td><strong>पालक मेळावा</strong></td><td>शाळेने आयोजित केलेली पालक-शिक्षक बैठक. तारीख, उपस्थिती, फोटो नोंदवले जातात.</td></tr>
            <tr><td><strong>लेखापरीक्षण (Audit)</strong></td><td>प्रत्येक कृतीची (पदोन्नती, मंजुरी) कायम नोंद — कोणी, केव्हा केले याचे पुरावे.</td></tr>
            <tr><td><strong>VJNT</strong></td><td>Vimukta Jatis and Nomadic Tribes — विमुक्त जाती व भटक्या जमाती. महाराष्ट्र शासनाचा कल्याण विभाग.</td></tr>
            <tr><td><strong>GATEE</strong></td><td>Government Attendance and Training Evaluation Engine — या पोर्टलचे पूर्ण नाव.</td></tr>
          </table>
        </div>
      </div>
    </div>

    <!-- ══════ SECTION: Contact ══════ -->
    <div id="section-contact-section" class="help-section" style="display:none;">
      <div class="section-title"><span>📞</span> संपर्क व समर्थन</div>

      <div class="contact-grid">
        <div class="contact-card">
          <div class="cc-icon">💻</div>
          <h4>तांत्रिक समस्या</h4>
          <p>लॉगिन अडचण, पृष्ठ न उघडणे, डेटा न जतन होणे यासाठी Data Admin ला संपर्क करा.</p>
          <div style="margin-top:12px;font-size:13px;color:#667eea;font-weight:600;">📧 anilbolke@gmail.com</div>
        </div>
        <div class="contact-card">
          <div class="cc-icon">📊</div>
          <h4>डेटा अडचण</h4>
          <p>विद्यार्थी डेटा चुकीचा, टप्पा उघडत नाही, मंजुरी मिळत नाही — Admin किंवा वरिष्ठ अधिकाऱ्यांशी संपर्क करा.</p>
          <div style="margin-top:12px;font-size:13px;color:#667eea;font-weight:600;">तुमचे Data Admin</div>
        </div>
        <div class="contact-card">
          <div class="cc-icon">📖</div>
          <h4>FLN मार्गदर्शन</h4>
          <p>FLN स्तर, मूल्यमापन पद्धत, शैक्षणिक मार्गदर्शनासाठी जिल्हा/विभाग अधिकाऱ्यांशी संपर्क करा.</p>
          <div style="margin-top:12px;font-size:13px;color:#667eea;font-weight:600;">जिल्हा/विभाग कार्यालय</div>
        </div>
      </div>

      <div class="article" style="margin-top:20px;">
        <div class="article-header" onclick="toggleArticle(this)">
          <span class="a-icon">🐛</span>
          <h3>समस्या नोंदवताना काय माहिती द्यावी</h3>
          <span style="margin-left:auto;color:#667eea;">▼</span>
        </div>
        <div class="article-body">
          <p style="font-size:14px;color:#374151;margin-bottom:12px;">समस्या नोंदवताना खालील माहिती द्या — यामुळे त्वरित समाधान मिळेल:</p>
          <ul class="step-list">
            <li><div class="step-num">✓</div><div class="step-text"><strong>तुमचे वापरकर्तानाव</strong> व भूमिका (समन्वयक / मुख्याध्यापक / इ.)</div></li>
            <li><div class="step-num">✓</div><div class="step-text"><strong>शाळेचा UDISE क्रमांक</strong> (शाळा समन्वयक / मुख्याध्यापकासाठी)</div></li>
            <li><div class="step-num">✓</div><div class="step-text"><strong>नक्की काय घडले</strong> — कोणती कृती केली, काय होणे अपेक्षित होते, काय झाले</div></li>
            <li><div class="step-num">✓</div><div class="step-text"><strong>स्क्रीनशॉट</strong> — त्रुटी संदेशाचा स्क्रीनशॉट असल्यास द्या</div></li>
            <li><div class="step-num">✓</div><div class="step-text"><strong>ब्राउझर</strong> — Chrome/Firefox आणि त्याची आवृत्ती</div></li>
          </ul>
        </div>
      </div>
    </div>

    <!-- No Results -->
    <div id="no-results" style="display:none;">
      <div class="no-results">
        <div class="nr-icon">🔍</div>
        <h3>कोणताही विषय सापडला नाही</h3>
        <p class="text-sm mt8">वेगळे शब्द वापरून शोधा किंवा डाव्या बाजूच्या मेनूतून विषय निवडा.</p>
      </div>
    </div>

  </div><!-- /content -->
</div><!-- /main-layout -->

<script>
// ── Section switching ──
function showSection(id) {
  document.querySelectorAll('.help-section').forEach(s => s.style.display = 'none');
  document.getElementById('no-results').style.display = 'none';
  const el = document.getElementById('section-' + id);
  if (el) el.style.display = 'block';

  document.querySelectorAll('.sb-link').forEach(l => l.classList.remove('active'));
  const links = document.querySelectorAll('.sb-link');
  links.forEach(l => {
    if (l.getAttribute('onclick') && l.getAttribute('onclick').includes(id)) l.classList.add('active');
  });
  el && el.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function jumpTo(id) {
  showSection(id);
}

// ── Article toggle ──
function toggleArticle(header) {
  const body = header.nextElementSibling;
  const arrow = header.querySelector('span:last-child');
  if (body.classList.contains('open')) {
    body.classList.remove('open');
    if (arrow && arrow.textContent === '▲') arrow.textContent = '▼';
  } else {
    body.classList.add('open');
    if (arrow && arrow.textContent === '▼') arrow.textContent = '▲';
  }
}

// ── FAQ toggle ──
function toggleFaq(qEl) {
  const answer = qEl.nextElementSibling;
  const arrow  = qEl.querySelector('.faq-arrow');
  const isOpen = answer.classList.contains('open');
  document.querySelectorAll('.faq-a.open').forEach(a => {
    a.classList.remove('open');
    const q = a.previousElementSibling;
    q.classList.remove('open');
    q.querySelector('.faq-arrow').textContent = '▼';
  });
  if (!isOpen) {
    answer.classList.add('open');
    qEl.classList.add('open');
    arrow.textContent = '▲';
  }
}

// ── Role filter ──
function filterRole(role, tab) {
  document.querySelectorAll('.role-tab').forEach(t => t.classList.remove('active'));
  tab.classList.add('active');
  if (role === 'all') {
    document.querySelectorAll('[data-roles]').forEach(s => s.style.opacity = '1');
    return;
  }
  document.querySelectorAll('[data-roles]').forEach(s => {
    const roles = s.getAttribute('data-roles') || '';
    s.style.opacity = roles.includes(role) ? '1' : '0.35';
  });
}

// ── Search ──
const searchIndex = [
  { term: ['लॉगिन','login','पासवर्ड','password','प्रवेश'], section: 'login-guide' },
  { term: ['डॅशबोर्ड','dashboard','होमपेज'], section: 'dashboard-guide' },
  { term: ['विद्यार्थी','student','जोडणे','संपादन','PEN','excel'], section: 'student-guide' },
  { term: ['fln','टप्पा','phase','स्तर','मराठी','गणित','इंग्रजी','भरणे','data'], section: 'fln-guide' },
  { term: ['मंजुरी','approval','मुख्याध्यापक','headmaster','pending','approve','reject'], section: 'approval-guide' },
  { term: ['पदोन्नती','promote','graduation','उत्तीर्ण','class promotion','नववी'], section: 'promote-guide' },
  { term: ['पालक','melava','मेळावा','palak','meeting','फोटो','photo'], section: 'palak-guide' },
  { term: ['शिक्षक','teacher','नियुक्ती','assignment'], section: 'teacher-guide' },
  { term: ['विश्लेषण','analytics','आलेख','chart','report','अहवाल','जिल्हा','district'], section: 'analytics-guide' },
  { term: ['अहवाल','report','pdf','प्रगती पत्रिका'], section: 'report-guide' },
  { term: ['faq','प्रश्न','question','उत्तर','समस्या','error'], section: 'faq-section' },
  { term: ['शब्दकोश','glossary','udise','coalesce','fln_completed'], section: 'glossary-section' },
  { term: ['संपर्क','contact','support','मदत','help','technical'], section: 'contact-section' },
];

function doSearch(val) {
  const q = val.trim().toLowerCase();
  if (!q) {
    showSection('getting-started');
    return;
  }
  for (const entry of searchIndex) {
    if (entry.term.some(t => q.includes(t) || t.includes(q))) {
      showSection(entry.section);
      return;
    }
  }
  document.querySelectorAll('.help-section').forEach(s => s.style.display = 'none');
  document.getElementById('no-results').style.display = 'block';
}

// ── On load: highlight current user's role tab ──
window.onload = function() {
  const myRole = '<%= userType %>';
  const tabs   = document.querySelectorAll('.role-tab');
  tabs.forEach(t => {
    if (t.getAttribute('onclick') && t.getAttribute('onclick').includes(myRole)) {
      t.style.fontWeight = '700';
      t.style.color = '#667eea';
    }
  });
};
</script>
</body>
</html>
