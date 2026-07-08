import org.apache.poi.xslf.usermodel.*;
import org.apache.poi.sl.usermodel.TextParagraph.TextAlign;
import org.apache.poi.util.Units;

import java.awt.*;
import java.awt.geom.Rectangle2D;
import java.io.*;

public class GeneratePPT {

    // Slide dimensions: 13.33 x 7.5 inches (widescreen 16:9)
    static final int W = (int)(13.33 * 914400); // EMU
    static final int H = (int)(7.5  * 914400);

    // Color palette
    static final Color BG_DARK    = new Color(15,  23,  42);
    static final Color BG_BLUE    = new Color(15,  30,  80);
    static final Color BG_GREEN   = new Color(5,   46,  22);
    static final Color BG_PURPLE  = new Color(30,  27,  75);
    static final Color BG_ORANGE  = new Color(67,  20,   7);
    static final Color BG_TEAL    = new Color(4,   47,  46);
    static final Color BG_ROSE    = new Color(76,   5,  25);
    static final Color BG_INDIGO  = new Color(30,  27,  75);
    static final Color BG_COVER   = new Color(15,  52,  96);

    static final Color ACCENT_BLUE   = new Color(96, 165, 250);
    static final Color ACCENT_GREEN  = new Color(74, 222, 128);
    static final Color ACCENT_PURPLE = new Color(192,132,252);
    static final Color ACCENT_ORANGE = new Color(251,146, 60);
    static final Color ACCENT_TEAL   = new Color(45, 212,191);
    static final Color ACCENT_ROSE   = new Color(251,113,133);
    static final Color ACCENT_YELLOW = new Color(250,204, 21);
    static final Color WHITE         = Color.WHITE;
    static final Color WHITE70       = new Color(255,255,255,180);
    static final Color WHITE50       = new Color(255,255,255,130);

    public static void main(String[] args) throws Exception {
        XMLSlideShow ppt = new XMLSlideShow();
        ppt.setPageSize(new Dimension((int)(13.33*72), (int)(7.5*72))); // points

        // ── SLIDE 1: Cover ────────────────────────────────────────────────────
        XSLFSlide s1 = addSlide(ppt, BG_COVER);
        addRect(s1, 0, 0, W, H, new Color(10,30,70));
        addText(s1, "VJNT & OBC Welfare Department, Maharashtra",
                60, 60, 860, 30, 11, WHITE50, false, TextAlign.LEFT);
        addText(s1, "GATEE Portal",
                60, 100, 860, 120, 54, WHITE, true, TextAlign.LEFT);
        addText(s1, "Class Management & FLN Assessment System",
                60, 230, 860, 50, 22, ACCENT_BLUE, false, TextAlign.LEFT);
        addText(s1, "A digital platform to track Foundational Literacy & Numeracy (FLN)\nprogress of students across all VJNT schools in Maharashtra —\nfrom school-level data entry to state-level analytics.",
                60, 300, 760, 100, 14, WHITE70, false, TextAlign.LEFT);
        addAccentBar(s1, 60, 430, 300, 4, ACCENT_BLUE);
        String[] chips1 = {"Maharashtra, India","VJNT & OBC Schools","Classes I – IX","FLN Mission","Academic Year 2026-27"};
        addChips(s1, chips1, 60, 460, ACCENT_BLUE);
        addSlideNumber(s1, "01");

        // ── SLIDE 2: Problem Statement ────────────────────────────────────────
        XSLFSlide s2 = addSlide(ppt, BG_BLUE);
        addAccentBar(s2, 60, 55, 80, 4, ACCENT_BLUE);
        addText(s2, "WHY THIS SYSTEM", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s2, "Problem Statement", 60, 65, 800, 60, 34, WHITE, true, TextAlign.LEFT);
        String[] problems = {
            "❌  No centralised data — schools kept paper registers, making division-level review impossible",
            "❌  No phase tracking — unclear which schools had completed FLN assessments",
            "❌  No approval workflow — data had no verification or Head Master sign-off",
            "❌  No student reports — generating individual progress reports was fully manual",
            "❌  No year-end process — class promotion had no digital record or audit trail"
        };
        addBullets(s2, problems, 60, 145, 480, 14, new Color(248,113,113));

        addRoundRect(s2, 570, 130, 380, 360, new Color(30,60,120), ACCENT_BLUE);
        addText(s2, "GATEE Portal Solves", 580, 145, 360, 30, 14, ACCENT_BLUE, true, TextAlign.LEFT);
        String[] solutions = {
            "✅  Centralised, real-time student FLN data",
            "✅  4-phase structured assessment per year",
            "✅  Head Master approval workflow per phase",
            "✅  Auto-generated PDF student report cards",
            "✅  Automated class promotion with audit trail",
            "✅  Analytics at school / district / division level",
            "✅  Parent meeting (Palak Melava) tracking"
        };
        addBullets(s2, solutions, 580, 185, 360, 13, ACCENT_GREEN);
        addSlideNumber(s2, "02");

        // ── SLIDE 3: System Overview ──────────────────────────────────────────
        XSLFSlide s3 = addSlide(ppt, BG_DARK);
        addAccentBar(s3, 60, 55, 80, 4, new Color(99,102,241));
        addText(s3, "SYSTEM OVERVIEW", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s3, "What is GATEE Portal?", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);
        addText(s3, "A multi-role web application digitising the complete lifecycle of FLN assessment —\nfrom student data entry to year-end class promotion.",
                60, 125, 850, 45, 13, WHITE70, false, TextAlign.LEFT);

        // Stats row
        String[][] stats = {{"6","User Roles"},{"4","Phases/Year"},{"9","Classes I–IX"},{"3","Subjects"},{"80+","JSP Pages"},{"100+","Servlets"}};
        Color[] statColors = {ACCENT_BLUE,ACCENT_GREEN,new Color(244,114,182),ACCENT_ORANGE,ACCENT_PURPLE,ACCENT_TEAL};
        for (int i = 0; i < stats.length; i++) {
            int x = 60 + i * 158;
            addRoundRect(s3, x, 180, 140, 85, new Color(30,41,59), new Color(60,80,120));
            addText(s3, stats[i][0], x, 192, 140, 40, 30, statColors[i], true, TextAlign.CENTER);
            addText(s3, stats[i][1], x, 232, 140, 22, 10, WHITE50, false, TextAlign.CENTER);
        }

        // Three cards
        int[] cx = {60, 360, 660};
        String[] ch = {"📍 Subjects Assessed","📐 Geographic Hierarchy","🔄 Annual Cycle"};
        String[][] cb = {
            {"Marathi (मराठी) — 6 levels","Mathematics (गणित) — 8 levels","English (इंग्रजी) — 6 levels","FLN completion per student"},
            {"State → Division (विभाग)","Division → District (जिल्हा)","District → School (UDISE)","School → Student (PEN)"},
            {"Phase 1 — Term start baseline","Phase 2 & 3 — Mid-year","Phase 4 — Year-end assessment","Year-end — Promote / Graduate"}
        };
        for (int i = 0; i < 3; i++) {
            addRoundRect(s3, cx[i], 285, 268, 185, new Color(20,30,50), new Color(40,60,100));
            addText(s3, ch[i], cx[i]+10, 298, 248, 28, 13, ACCENT_BLUE, true, TextAlign.LEFT);
            addBullets(s3, cb[i], cx[i]+10, 335, 248, 12, WHITE70);
        }
        addSlideNumber(s3, "03");

        // ── SLIDE 4: User Roles ───────────────────────────────────────────────
        XSLFSlide s4 = addSlide(ppt, BG_PURPLE);
        addAccentBar(s4, 60, 55, 80, 4, ACCENT_PURPLE);
        addText(s4, "ACCESS CONTROL", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s4, "User Roles & Permissions", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);
        addText(s4, "Six distinct roles with separate dashboards — each sees only what is relevant to their level.",
                60, 125, 850, 30, 13, WHITE70, false, TextAlign.LEFT);

        String[][] roles = {
            {"👑","Data Admin","Full system access. Manages schools, uploads students, runs promotions, top-level authority."},
            {"📝","School Coordinator","Enters FLN phase data for their school. Submits phases for Head Master approval."},
            {"✅","Head Master","Reviews and approves or rejects phase submissions. Data quality gate-keeper."},
            {"🏢","District Officer","Views all schools' phase completion, student levels, teacher assignments in district."},
            {"🗺️","Division Officer","Monitors division-level analytics, phase comparisons across all districts."},
            {"🔭","Super Division Officer","State-level view across all divisions. Highest analytics access."}
        };
        Color[] roleColors = {new Color(239,68,68,80), new Color(59,130,246,80), new Color(34,197,94,80),
                              new Color(168,85,247,80), new Color(249,115,22,80), new Color(20,184,166,80)};
        Color[] roleBorder = {new Color(239,68,68), new Color(59,130,246), new Color(34,197,94),
                              new Color(168,85,247), new Color(249,115,22), new Color(20,184,166)};
        for (int i = 0; i < 6; i++) {
            int col = i % 3, row = i / 3;
            int x = 60  + col * 310;
            int y = 175 + row * 165;
            addRoundRect(s4, x, y, 285, 145, roleColors[i], roleBorder[i]);
            addText(s4, roles[i][0] + "  " + roles[i][1], x+12, y+10, 261, 30, 14, WHITE, true, TextAlign.LEFT);
            addText(s4, roles[i][2], x+12, y+46, 261, 90, 11, WHITE70, false, TextAlign.LEFT);
        }
        addSlideNumber(s4, "04");

        // ── SLIDE 5: FLN Phase Workflow ───────────────────────────────────────
        XSLFSlide s5 = addSlide(ppt, BG_GREEN);
        addAccentBar(s5, 60, 55, 80, 4, ACCENT_GREEN);
        addText(s5, "CORE WORKFLOW", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s5, "FLN Phase Assessment Workflow", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);
        addText(s5, "Every academic year has 4 phases. Each phase must be completed and approved before the next unlocks.",
                60, 125, 850, 30, 13, WHITE70, false, TextAlign.LEFT);

        // 4 Phase boxes
        String[][] phases = {
            {"📘 Phase 1","Baseline assessment. Seeded from last year's Phase 4 data after promotion. Coordinator enters Marathi, Math, English levels for every student."},
            {"📗 Phase 2","Mid-year assessment 1. Unlocks ONLY after Phase 1 is approved by Head Master. Coordinator updates student levels."},
            {"📙 Phase 3","Mid-year assessment 2. Unlocks after Phase 2 approval. Level jumps tracked vs Phase 1 baseline."},
            {"📕 Phase 4","Year-end final assessment. After approval, data becomes seed for next year's Phase 1 via class promotion."}
        };
        Color[] phaseColors = {new Color(59,130,246,60), new Color(34,197,94,60), new Color(249,115,22,60), new Color(168,85,247,60)};
        Color[] phaseBorder = {new Color(59,130,246), new Color(34,197,94), new Color(249,115,22), new Color(168,85,247)};
        for (int i = 0; i < 4; i++) {
            int x = 60 + i * 235;
            addRoundRect(s5, x, 175, 215, 155, phaseColors[i], phaseBorder[i]);
            addText(s5, phases[i][0], x+10, 185, 195, 28, 13, WHITE, true, TextAlign.LEFT);
            addText(s5, phases[i][1], x+10, 218, 195, 105, 11, WHITE70, false, TextAlign.LEFT);
        }

        // Approval flow
        addText(s5, "Approval Flow (per Phase)", 60, 355, 800, 30, 14, WHITE, true, TextAlign.LEFT);
        String[] flowSteps = {"📝 Coordinator\nEnters Data","📤 Submit for\nApproval","🔍 Head Master\nReviews","✅ APPROVED","🔓 Next Phase\nUnlocks"};
        for (int i = 0; i < flowSteps.length; i++) {
            int x = 60 + i * 185;
            addRoundRect(s5, x, 393, 155, 65, new Color(20,80,40), new Color(50,180,80));
            addText(s5, flowSteps[i], x, 400, 155, 55, 11, WHITE, false, TextAlign.CENTER);
            if (i < flowSteps.length - 1) {
                addText(s5, "→", x + 162, 415, 25, 30, 18, WHITE50, false, TextAlign.LEFT);
            }
        }
        addSlideNumber(s5, "05");

        // ── SLIDE 6: Modules ──────────────────────────────────────────────────
        XSLFSlide s6 = addSlide(ppt, BG_DARK);
        addAccentBar(s6, 60, 55, 80, 4, ACCENT_TEAL);
        addText(s6, "FUNCTIONAL MODULES", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s6, "System Modules", 60, 65, 800, 50, 34, WHITE, true, TextAlign.LEFT);

        String[][] mods = {
            {"🔐","Authentication","Login, logout, BCrypt passwords, account lockout, session management"},
            {"👨‍🎓","Student Management","Add/edit/view students, Excel upload, FLN entry, PEN tracking"},
            {"📊","Phase Assessment","4-phase data entry, phase locking, submit for approval, status view"},
            {"✅","Approval Workflow","Head Master phase approval, Palak Melava approval, audit trail"},
            {"📈","Analytics Dashboards","Level distribution, phase comparison, level jumps, subject stats"},
            {"👨‍👩‍👧","Palak Melava","Record parent meetings, upload photos, district meeting statistics"},
            {"👨‍🏫","Teacher Management","Add/edit teachers, assign to classes, track teacher progress"},
            {"📄","Student Reports","Generate PDF report cards, request/approve reports workflow"},
            {"🎓","Class Promotion","Year-end promotion, Class IX graduation, 4-table audit trail"},
            {"🎬","Video Management","Student learning videos, YouTube integration, BunnyCDN storage"},
            {"🏫","School Management","Upload schools via Excel, school contacts, profiles"},
            {"🔔","Notifications","Admin announcements, other school activities submission & approval"}
        };
        for (int i = 0; i < mods.length; i++) {
            int col = i % 4, row = i / 4;
            int x = 60  + col * 235;
            int y = 120 + row * 135;
            addRoundRect(s6, x, y, 215, 120, new Color(15,25,45), new Color(40,60,100));
            addText(s6, mods[i][0] + " " + mods[i][1], x+8, y+8, 199, 30, 12, WHITE, true, TextAlign.LEFT);
            addText(s6, mods[i][2], x+8, y+40, 199, 72, 10, WHITE70, false, TextAlign.LEFT);
        }
        addSlideNumber(s6, "06");

        // ── SLIDE 7: Class Promotion ──────────────────────────────────────────
        XSLFSlide s7 = addSlide(ppt, BG_ORANGE);
        addAccentBar(s7, 60, 55, 80, 4, ACCENT_ORANGE);
        addText(s7, "KEY FEATURE", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s7, "Year-End Class Promotion System", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);
        addText(s7, "Fully atomic, audited 6-step transaction — Classes I–VIII promoted, Class IX graduates permanently.",
                60, 125, 850, 30, 13, WHITE70, false, TextAlign.LEFT);

        // 6 steps left column
        String[][] steps = {
            {"1","Create Promotion Log","Records who promoted, when, and for which academic year."},
            {"2","Archive Phase Data","All student phase data saved to student_phase_history table."},
            {"3","Archive Approvals","Approval records saved to history, then cleared for new year."},
            {"4","Graduate Class IX","Moved to graduated_students table permanently, marked inactive."},
            {"5","Promote Classes I–VIII","Advance class, seed Phase 1 from last completed phase (COALESCE)."},
            {"6","Update Log Counts","Records total promoted and graduated for audit reference."}
        };
        for (int i = 0; i < steps.length; i++) {
            int y = 170 + i * 65;
            addRoundRect(s7, 60, y, 28, 28, ACCENT_ORANGE, ACCENT_ORANGE);
            addText(s7, steps[i][0], 60, y+2, 28, 24, 13, new Color(20,10,5), true, TextAlign.CENTER);
            addText(s7, steps[i][1], 98, y+2, 200, 18, 12, WHITE, true, TextAlign.LEFT);
            addText(s7, steps[i][2], 98, y+20, 430, 18, 10, WHITE70, false, TextAlign.LEFT);
        }

        // Right side cards
        addRoundRect(s7, 580, 165, 370, 155, new Color(80,30,10), new Color(180,80,20));
        addText(s7, "🔒 Smart Phase Seeding (COALESCE)", 590, 175, 350, 25, 13, ACCENT_ORANGE, true, TextAlign.LEFT);
        addText(s7, "Phase 1 for new year seeded from best available phase:\n\nPhase 4 → Phase 3 → Phase 2 → Phase 1\n\nSchools that didn't complete all 4 phases still get\na meaningful baseline for the new year.",
                590, 205, 350, 108, 11, WHITE70, false, TextAlign.LEFT);

        addRoundRect(s7, 580, 335, 370, 145, new Color(10,50,20), new Color(20,150,50));
        addText(s7, "📋 4 Audit Tables Created", 590, 345, 350, 25, 13, ACCENT_GREEN, true, TextAlign.LEFT);
        String[] auditTables = {
            "class_promotion_log — one row per promotion run",
            "student_phase_history — all student phase data archived",
            "graduated_students — permanent IX graduate record",
            "phase_approvals_history — approval decisions archive"
        };
        addBullets(s7, auditTables, 590, 378, 350, 11, WHITE70);
        addSlideNumber(s7, "07");

        // ── SLIDE 8: Analytics ────────────────────────────────────────────────
        XSLFSlide s8 = addSlide(ppt, BG_TEAL);
        addAccentBar(s8, 60, 55, 80, 4, ACCENT_TEAL);
        addText(s8, "DATA INTELLIGENCE", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s8, "Analytics & Reporting", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);
        addText(s8, "Real-time analytics at every level of the hierarchy — school, district, division, and state.",
                60, 125, 850, 30, 13, WHITE70, false, TextAlign.LEFT);

        String[] analCols = {"🏫 School Level","🏢 District Level","🗺️ Division / State Level"};
        String[][] analItems = {
            {"Phase-wise student level summary","Individual student progress tracking","FLN completion percentage","Phase submission status","PDF student report card generation"},
            {"All schools' phase completion status","District-wide level distribution","Teacher assignment progress","Palak Melava statistics","Student level jump tracking"},
            {"Division-wide phase comparison","Subject-wise statistics across districts","Phase-wise level percentage charts","Activity analysis dashboards","School contact coverage analytics"}
        };
        for (int i = 0; i < 3; i++) {
            int x = 60 + i * 315;
            addRoundRect(s8, x, 170, 295, 185, new Color(10,60,60), new Color(20,140,130));
            addText(s8, analCols[i], x+10, 178, 275, 28, 13, ACCENT_TEAL, true, TextAlign.LEFT);
            addBullets(s8, analItems[i], x+10, 212, 275, 11, WHITE70);
        }

        addText(s8, "Key Metrics Tracked", 60, 375, 800, 30, 14, WHITE, true, TextAlign.LEFT);
        String[][] metrics = {
            {"📉→📈","Level Jumps","Student improvement from Phase 1 to Phase 4"},
            {"🎯","FLN Completion","Students achieving 100% in all 3 subjects"},
            {"📊","Phase Comparison","Side-by-side level distributions across all 4 phases"},
            {"🏆","School Ranking","Schools sorted by FLN achievement in district/division"}
        };
        for (int i = 0; i < metrics.length; i++) {
            int x = 60 + i * 240;
            addRoundRect(s8, x, 408, 220, 80, new Color(10,50,50), new Color(20,120,110));
            addText(s8, metrics[i][0] + " " + metrics[i][1], x+8, 415, 204, 25, 12, WHITE, true, TextAlign.LEFT);
            addText(s8, metrics[i][2], x+8, 440, 204, 42, 10, WHITE70, false, TextAlign.LEFT);
        }
        addSlideNumber(s8, "08");

        // ── SLIDE 9: Tech Stack ───────────────────────────────────────────────
        XSLFSlide s9 = addSlide(ppt, BG_DARK);
        addAccentBar(s9, 60, 55, 80, 4, ACCENT_BLUE);
        addText(s9, "TECHNOLOGY", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s9, "Technical Architecture", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);

        addText(s9, "Tech Stack", 60, 130, 400, 30, 16, WHITE, true, TextAlign.LEFT);
        String[][] techItems = {
            {"☕","Java EE Servlets","@WebServlet annotation-based"},
            {"📄","JSP Pages","Server-side rendering"},
            {"🐬","MySQL 8.0","utf8mb4_unicode_ci"},
            {"🐈","Apache Tomcat 9","Servlet container"},
            {"📦","Apache POI","Excel import/export"},
            {"🔣","org.json","JSON API responses"},
            {"🎬","YouTube Data API v3","Video upload integration"},
            {"🐰","BunnyCDN","Video CDN storage"},
            {"🔐","BCrypt","Password hashing"},
            {"📑","iText PDF","Report card generation"}
        };
        for (int i = 0; i < techItems.length; i++) {
            int col = i % 2, row = i / 2;
            int x = 60 + col * 240;
            int y = 165 + row * 50;
            addRoundRect(s9, x, y, 220, 40, new Color(20,30,55), new Color(40,60,100));
            addText(s9, techItems[i][0] + "  " + techItems[i][1], x+8, y+4, 204, 20, 12, WHITE, true, TextAlign.LEFT);
            addText(s9, techItems[i][2], x+8, y+22, 204, 14, 10, WHITE50, false, TextAlign.LEFT);
        }

        // Architecture flow right side
        addText(s9, "Architecture", 580, 130, 360, 30, 16, WHITE, true, TextAlign.LEFT);
        String[] archLayers = {
            "🖥️  Browser (JSP + JavaScript + Fetch API)",
            "↕  HTTP / JSON",
            "⚙️  Java Servlets  (@WebServlet REST APIs)",
            "↕  JDBC / PreparedStatement",
            "🐬  MySQL  (vjnt_class_management)",
            "↕",
            "📦  BunnyCDN  (Videos)  |  YouTube API"
        };
        Color[] archColors = {ACCENT_BLUE, WHITE50, ACCENT_GREEN, WHITE50, ACCENT_ORANGE, WHITE50, ACCENT_PURPLE};
        boolean[] arcBold = {true,false,true,false,true,false,true};
        for (int i = 0; i < archLayers.length; i++) {
            int y = 168 + i * 50;
            if (i % 2 == 0) {
                addRoundRect(s9, 575, y, 365, 40, new Color(20,30,55), new Color(40,60,100));
                addText(s9, archLayers[i], 583, y+10, 349, 22, 12, archColors[i], arcBold[i], TextAlign.LEFT);
            } else {
                addText(s9, archLayers[i], 575, y+10, 365, 22, 14, archColors[i], false, TextAlign.CENTER);
            }
        }
        addSlideNumber(s9, "09");

        // ── SLIDE 10: Security ────────────────────────────────────────────────
        XSLFSlide s10 = addSlide(ppt, BG_ROSE);
        addAccentBar(s10, 60, 55, 80, 4, ACCENT_ROSE);
        addText(s10, "SECURITY & ACCESS", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s10, "Security Features", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);

        String[] secTitles = {"🔐 Authentication","🛡️ Authorisation","🖼️ Media Security","📋 Data Integrity"};
        String[][] secItems = {
            {"BCrypt password hashing","Account lockout after failed attempts","Session-based login management","Secure logout — session invalidation","Change password with verification"},
            {"Every JSP checks session + role","Every servlet validates user type","DATA_ADMIN-only pages redirect on access","School coordinators limited to own UDISE","Officers limited to their geography"},
            {"Palak Melava photos encrypted at rest","Images served via SecureImageServlet","Videos stored on BunnyCDN (private)","YouTube upload with OAuth 2.0","No direct file-path exposure"},
            {"Phase locking — next phase disabled until previous approved","Promotion is atomic DB transaction (rollback on error)","Full audit trail — nothing deleted, everything archived","Graduated students permanently preserved","SQL injection prevention via PreparedStatement"}
        };
        for (int i = 0; i < 4; i++) {
            int col = i % 2, row = i / 2;
            int x = 60 + col * 475;
            int y = 155 + row * 210;
            addRoundRect(s10, x, y, 450, 190, new Color(60,5,20), new Color(180,30,60));
            addText(s10, secTitles[i], x+12, y+10, 426, 28, 14, WHITE, true, TextAlign.LEFT);
            addBullets(s10, secItems[i], x+12, y+45, 426, 11, WHITE70);
        }
        addSlideNumber(s10, "10");

        // ── SLIDE 11: Roadmap ─────────────────────────────────────────────────
        XSLFSlide s11 = addSlide(ppt, BG_INDIGO);
        addAccentBar(s11, 60, 55, 80, 4, new Color(99,102,241));
        addText(s11, "ROADMAP", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s11, "Upcoming Features", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);
        addText(s11, "Features planned for the next development phase.",
                60, 125, 850, 30, 13, WHITE70, false, TextAlign.LEFT);

        String[] rmPhases = {"PHASE A — IN PLAN","PHASE B","PHASE C","PHASE D"};
        String[] rmTitles = {"💬 WhatsApp Notifications","📱 Mobile Responsive UI","📊 Advanced Reports","🤖 AI Insights"};
        String[][] rmItems = {
            {"Phase approval alerts to coordinators","Phase submission alerts to Head Master","Promotion completion notifications","Weekly reminders for incomplete phases","Provider: MSG91 (Indian BSP)"},
            {"Touch-friendly data entry","Coordinators enter data from phones","Responsive dashboards for all screens","Offline-capable form entry"},
            {"Excel export for all analytics","State-level summary PDF generation","Comparative year-on-year reports","School progress certificates"},
            {"Predict at-risk students early","Recommended teaching interventions","Anomaly detection in data entry","Automated progress summaries"}
        };
        Color[] rmColors = {new Color(34,197,94,60), new Color(59,130,246,60), new Color(168,85,247,60), new Color(249,115,22,60)};
        Color[] rmBorder = {ACCENT_GREEN, ACCENT_BLUE, ACCENT_PURPLE, ACCENT_ORANGE};
        for (int i = 0; i < 4; i++) {
            int x = 60 + i * 238;
            addRoundRect(s11, x, 170, 220, 310, rmColors[i], rmBorder[i]);
            addText(s11, rmPhases[i], x+10, 178, 200, 20, 9, rmBorder[i], true, TextAlign.LEFT);
            addText(s11, rmTitles[i], x+10, 200, 200, 28, 13, WHITE, true, TextAlign.LEFT);
            addBullets(s11, rmItems[i], x+10, 234, 200, 11, WHITE70);
        }
        addText(s11, "Total estimated effort: 6–9 days (including MSG91 template approval turnaround)",
                60, 500, 850, 25, 12, WHITE50, false, TextAlign.LEFT);
        addSlideNumber(s11, "11");

        // ── SLIDE 12: Impact ──────────────────────────────────────────────────
        XSLFSlide s12 = addSlide(ppt, BG_GREEN);
        addAccentBar(s12, 60, 55, 80, 4, ACCENT_GREEN);
        addText(s12, "IMPACT", 60, 40, 800, 25, 10, WHITE50, false, TextAlign.LEFT);
        addText(s12, "Expected Impact", 60, 65, 800, 55, 34, WHITE, true, TextAlign.LEFT);
        addText(s12, "GATEE Portal transforms how VJNT welfare schools track and improve student learning outcomes.",
                60, 125, 850, 30, 13, WHITE70, false, TextAlign.LEFT);

        String[][] impacts = {
            {"🎯","Data Accuracy","Structured digital entry with phase locking eliminates incomplete or inconsistent FLN data."},
            {"⚡","Speed of Insight","Division officers and state administrators see real-time progress — no waiting for manual reports."},
            {"📣","Accountability","Every submission, approval, and promotion tracked with who did it and when — full governance trail."},
            {"🔄","Continuous Improvement","Phase-wise level jump tracking shows whether students actually improve — enabling interventions."},
            {"🗂️","Permanent Records","Graduated students, phase data, and promotion logs preserved permanently for multi-year analysis."},
            {"🤝","Parent Engagement","Palak Melava module ensures community involvement is recorded and tracked at every school."}
        };
        for (int i = 0; i < impacts.length; i++) {
            int col = i % 3, row = i / 3;
            int x = 60 + col * 315;
            int y = 175 + row * 160;
            addRoundRect(s12, x, y, 295, 140, new Color(5,40,15), new Color(20,140,60));
            addText(s12, impacts[i][0] + "  " + impacts[i][1], x+12, y+12, 271, 28, 14, WHITE, true, TextAlign.LEFT);
            addText(s12, impacts[i][2], x+12, y+45, 271, 88, 11, WHITE70, false, TextAlign.LEFT);
        }
        addSlideNumber(s12, "12");

        // ── SLIDE 13: Thank You ───────────────────────────────────────────────
        XSLFSlide s13 = addSlide(ppt, BG_COVER);
        addRect(s13, 0, 0, W, H, new Color(10,30,70));
        addText(s13, "🏫", 0, 110, 960, 80, 60, WHITE, false, TextAlign.CENTER);
        addAccentBar(s13, 380, 215, 200, 4, ACCENT_BLUE);
        addText(s13, "Thank You", 0, 230, 960, 100, 54, WHITE, true, TextAlign.CENTER);
        addText(s13, "GATEE Portal — Digitising FLN Assessment for VJNT Welfare Schools across Maharashtra",
                100, 345, 760, 50, 15, WHITE70, false, TextAlign.CENTER);
        addAccentBar(s13, 380, 415, 200, 2, WHITE50);
        addText(s13, "anilbolke@gmail.com  |  GATEE Portal — VJNT Class Management  |  2026-27",
                100, 430, 760, 30, 12, WHITE50, false, TextAlign.CENTER);
        addText(s13, "शिक्षण हे सर्वांसाठी  —  Education for All",
                100, 490, 760, 30, 13, ACCENT_BLUE, false, TextAlign.CENTER);
        addSlideNumber(s13, "13");

        // ── SAVE ──────────────────────────────────────────────────────────────
        String outPath = "D:/VBJNT_UAT/VJNT Class Managment/src/main/webapp/AI FIles/GATEE-Portal-Presentation.pptx";
        try (FileOutputStream fos = new FileOutputStream(outPath)) {
            ppt.write(fos);
        }
        ppt.close();
        System.out.println("✅ PPTX saved: " + outPath);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    static XSLFSlide addSlide(XMLSlideShow ppt, Color bg) {
        XSLFSlideMaster master = ppt.getSlideMasters().get(0);
        XSLFSlideLayout layout = master.getSlideLayouts()[6]; // blank
        XSLFSlide slide = ppt.createSlide(layout);
        // Background
        XSLFTextBox bgBox = slide.createTextBox();
        bgBox.setAnchor(new Rectangle(0, 0, (int)(13.33*72), (int)(7.5*72)));
        bgBox.getFillColor();
        bgBox.clearText();
        // Use a filled shape for background
        org.apache.poi.sl.usermodel.FillStyle fill = null;
        slide.getBackground().getFillColor();
        slide.getBackground().setFillColor(bg);
        return slide;
    }

    static void addRect(XSLFSlide slide, int xPt, int yPt, int wEmu, int hEmu, Color color) {
        // convert EMU to points for anchor
        XSLFTextBox box = slide.createTextBox();
        box.setAnchor(new Rectangle(xPt, yPt, (int)(wEmu/914400.0*72), (int)(hEmu/914400.0*72)));
        box.setFillColor(color);
        box.clearText();
        box.setLineWidth(0);
    }

    static void addRoundRect(XSLFSlide slide, int xPt, int yPt, int wPt, int hPt, Color fill, Color border) {
        XSLFTextBox box = slide.createTextBox();
        box.setAnchor(new Rectangle(xPt, yPt, wPt, hPt));
        box.setFillColor(fill);
        box.clearText();
        box.setLineColor(border);
        box.setLineWidth(1.0);
    }

    static XSLFTextBox addText(XSLFSlide slide, String text, int x, int y, int w, int h,
                                double fontSize, Color color, boolean bold, TextAlign align) {
        XSLFTextBox tb = slide.createTextBox();
        tb.setAnchor(new Rectangle(x, y, w, h));
        tb.clearText();
        tb.setFillColor(null);
        tb.setLineWidth(0);
        tb.setLineColor(null);
        for (String line : text.split("\n")) {
            XSLFTextParagraph p = tb.addNewTextParagraph();
            p.setTextAlign(align);
            p.setSpaceBefore(0.0);
            p.setSpaceAfter(0.0);
            XSLFTextRun r = p.addNewTextRun();
            r.setText(line.isEmpty() ? " " : line);
            r.setFontColor(color);
            r.setFontSize(fontSize);
            r.setBold(bold);
        }
        return tb;
    }

    static void addBullets(XSLFSlide slide, String[] items, int x, int y, int w, double fontSize, Color color) {
        XSLFTextBox tb = slide.createTextBox();
        tb.setAnchor(new Rectangle(x, y, w, 400));
        tb.clearText();
        tb.setFillColor(null);
        tb.setLineWidth(0);
        for (String item : items) {
            XSLFTextParagraph p = tb.addNewTextParagraph();
            p.setTextAlign(TextAlign.LEFT);
            p.setSpaceBefore(0.0);
            p.setSpaceAfter(2.0);
            XSLFTextRun r = p.addNewTextRun();
            r.setText((item.startsWith("✅") || item.startsWith("❌") || item.startsWith("→")) ? item : "→  " + item);
            r.setFontColor(color);
            r.setFontSize(fontSize);
        }
    }

    static void addAccentBar(XSLFSlide slide, int x, int y, int w, int h, Color color) {
        XSLFTextBox box = slide.createTextBox();
        box.setAnchor(new Rectangle(x, y, w, h));
        box.setFillColor(color);
        box.clearText();
        box.setLineWidth(0);
    }

    static void addChips(XSLFSlide slide, String[] labels, int x, int y, Color color) {
        int cx = x;
        for (String label : labels) {
            int w = label.length() * 7 + 24;
            addRoundRect(slide, cx, y, w, 26, new Color(color.getRed(),color.getGreen(),color.getBlue(),40),
                    new Color(color.getRed(),color.getGreen(),color.getBlue(),120));
            addText(slide, label, cx+2, y+4, w-4, 18, 10, color, false, TextAlign.CENTER);
            cx += w + 10;
        }
    }

    static void addSlideNumber(XSLFSlide slide, String num) {
        addText(slide, "SLIDE " + num, 870, 520, 60, 20, 9, WHITE50, false, TextAlign.RIGHT);
    }
}
