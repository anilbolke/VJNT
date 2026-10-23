package com.vjnt.util;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;

/**
 * Builds the Marathi HTML that {@link PdfRenderer} turns into the attached school list.
 *
 * Two layouts from one method: an alert lists the schools in one bucket, while the status report
 * lists every school with a mark per bucket and a summary block above the table. They share the
 * header, the styling and the pagination rules, which is the reason they are not two classes.
 *
 * <p><b>Fonts.</b> The stack is "Nirmala UI" then "Noto Sans Devanagari": the first ships with
 * Windows, the second is what a Linux host would have. Both are named because the renderer embeds
 * whatever it finds, and a host with neither produces a PDF of empty boxes without erroring.
 */
public final class CoordinatorAlertReportHtml {

    private CoordinatorAlertReportHtml() { }

    /**
     * @param type    which of the six messages this document accompanies
     * @param summary the figures for the district or division it covers
     * @param rows    schools to list — the bucket's schools, or every school for a status report
     */
    public static String build(CoordinatorAlertType type, CoordinatorAlertSummary summary,
                               List<PhaseSchoolRow> rows) {
        StringBuilder h = new StringBuilder(16384);
        boolean rollUp = type.isRollUp();
        // Only a division report needs to say which district a school is in; within one district the
        // column would repeat the same value on every line.
        boolean showDistrict = summary.getScope() == AlertScope.DIVISION;

        h.append("<!DOCTYPE html><html lang=\"mr\"><head><meta charset=\"UTF-8\">");
        h.append("<title>").append(esc(type.getHeading())).append("</title>");
        appendStyles(h);
        h.append("</head><body>");

        appendHeader(h, type, summary);
        if (rollUp) {
            appendSummaryBlock(h, summary);
        }

        if (rows == null || rows.isEmpty()) {
            h.append("<p class=\"empty\">या निकषात कोणतीही शाळा आढळली नाही.</p>");
        } else {
            appendTable(h, summary, rows, rollUp, showDistrict);
        }

        appendFooter(h, rows == null ? 0 : rows.size());
        h.append("</body></html>");
        return h.toString();
    }

    private static void appendStyles(StringBuilder h) {
        h.append("<style>")
         .append("@page { size: A4 landscape; margin: 12mm 10mm; }")
         .append("* { box-sizing: border-box; }")
         .append("body { font-family: \"Nirmala UI\", \"Noto Sans Devanagari\", sans-serif;")
         .append(" font-size: 9.5pt; color: #1a1a1a; margin: 0; }")
         .append(".dept { font-size: 9pt; color: #555; letter-spacing: .2px; }")
         .append("h1 { font-size: 14pt; margin: 1mm 0 1mm; }")
         .append(".meta { font-size: 9pt; color: #333; margin-bottom: 4mm;")
         .append(" border-bottom: 1.5px solid #37474f; padding-bottom: 2mm; }")
         .append(".summary { margin: 0 0 4mm; border-collapse: collapse; }")
         .append(".summary td { border: 1px solid #b0bec5; padding: 2px 8px; font-size: 9pt; }")
         .append(".summary td.k { background: #eceff1; }")
         .append(".summary td.v { text-align: right; font-weight: 600; }")
         .append("table.list { border-collapse: collapse; width: 100%; }")
         .append("table.list th, table.list td { border: 1px solid #90a4ae; padding: 2.5px 5px; }")
         .append("table.list th { background: #eceff1; font-size: 9pt; text-align: center; }")
         .append("td.n { text-align: right; }")
         .append("td.c { text-align: center; }")
         // Repeat the header on every page: a 300-school district runs to several pages and a
         // headerless continuation page cannot be read.
         .append("thead { display: table-header-group; }")
         .append("tr { page-break-inside: avoid; }")
         .append(".empty { padding: 10mm 0; font-size: 11pt; }")
         .append(".foot { margin-top: 4mm; font-size: 8.5pt; color: #555; }")
         .append("</style>");
    }

    private static void appendHeader(StringBuilder h, CoordinatorAlertType type,
                                     CoordinatorAlertSummary summary) {
        String scopeName = summary.getScope() == AlertScope.DIVISION
                ? summary.getName() + " विभाग"
                : summary.getName() + " जिल्हा";

        h.append("<div class=\"dept\">इतर मागास बहुजन कल्याण विभाग — GATEE Portal</div>");
        h.append("<h1>").append(esc(type.getHeading())).append("</h1>");
        h.append("<div class=\"meta\">").append(esc(scopeName))
         .append(" &nbsp;·&nbsp; चरण ").append(summary.getPhase())
         .append(" &nbsp;·&nbsp; दिनांक ")
         .append(new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date()))
         .append("</div>");
    }

    /**
     * The status report's summary block: every bucket count and overall progress.
     *
     * Labelled from {@link CoordinatorAlertType}, not {@link AlertCriterion}: the same officer also
     * receives the five alert messages, and the counts should be named there and here in identical
     * words. AlertCriterion's headings address a school about itself.
     */
    private static void appendSummaryBlock(StringBuilder h, CoordinatorAlertSummary summary) {
        h.append("<table class=\"summary\">");
        row(h, summary.getTotalLabel(), String.valueOf(summary.getTotalSchools()));
        for (CoordinatorAlertType t : CoordinatorAlertType.values()) {
            if (t.isRollUp()) continue;
            row(h, t.getHeading(), String.valueOf(summary.getCount(t)));
        }
        row(h, "एकूण प्रगती", summary.getProgressPercentage() + "%");
        row(h, "एकूण विद्यार्थी", summary.getRosterDone() + " / " + summary.getRosterTotal());
        h.append("</table>");
    }

    private static void row(StringBuilder h, String key, String value) {
        h.append("<tr><td class=\"k\">").append(esc(key))
         .append("</td><td class=\"v\">").append(esc(value)).append("</td></tr>");
    }

    private static void appendTable(StringBuilder h, CoordinatorAlertSummary summary,
                                    List<PhaseSchoolRow> rows, boolean rollUp, boolean showDistrict) {
        h.append("<table class=\"list\"><thead><tr>")
         .append("<th>अ.क्र.</th><th>UDISE</th><th>शाळेचे नाव</th>");
        if (showDistrict) h.append("<th>जिल्हा</th>");
        h.append("<th>एकूण<br>विद्यार्थी</th><th>पूर्ण</th><th>बाकी</th><th>प्रगती %</th>")
         .append("<th>Approval<br>स्थिती</th>");
        if (rollUp) {
            for (AlertCriterion c : AlertCriterion.values()) {
                h.append("<th>").append(esc(shortLabel(c))).append("</th>");
            }
        }
        h.append("</tr></thead><tbody>");

        int index = 0;
        for (PhaseSchoolRow r : rows) {
            index++;
            h.append("<tr><td class=\"n\">").append(index).append("</td>")
             .append("<td>").append(esc(r.getUdiseNo())).append("</td>")
             .append("<td>").append(esc(r.getDisplayName())).append("</td>");
            if (showDistrict) {
                h.append("<td>").append(esc(nullToDash(r.getDistrictName()))).append("</td>");
            }
            h.append("<td class=\"n\">").append(r.getTotal()).append("</td>")
             .append("<td class=\"n\">").append(r.getDone()).append("</td>")
             .append("<td class=\"n\">").append(r.getRemaining()).append("</td>")
             .append("<td class=\"n\">").append(r.getPercentage()).append("%</td>")
             .append("<td class=\"c\">").append(esc(r.getApprovalLabel())).append("</td>");
            if (rollUp) {
                for (AlertCriterion c : AlertCriterion.values()) {
                    h.append("<td class=\"c\">").append(r.isIn(c) ? "&#10004;" : "").append("</td>");
                }
            }
            h.append("</tr>");
        }
        h.append("</tbody></table>");
    }

    private static void appendFooter(StringBuilder h, int count) {
        h.append("<div class=\"foot\">एकूण नोंदी: ").append(count)
         .append(" &nbsp;·&nbsp; हा अहवाल GATEE Portal वरून स्वयंचलितपणे तयार करण्यात आला आहे.")
         .append(" अद्यावत माहितीसाठी पोर्टलवर पहावे: ").append(esc(WhatsAppConfig.PORTAL_LOGIN_URL))
         .append("</div>");
    }

    /** Column headings for the roll-up's bucket marks; the full headings are far too wide. */
    private static String shortLabel(AlertCriterion criterion) {
        switch (criterion) {
            case NOT_STARTED:      return "सुरू नाही";
            case BELOW_25:         return "<25%";
            case BELOW_50:         return "<50%";
            case PENDING_APPROVAL: return "Appr. बाकी";
            case REJECTED:         return "Reject";
            default:               return criterion.name();
        }
    }

    private static String nullToDash(String value) {
        return (value == null || value.trim().isEmpty()) ? "—" : value.trim();
    }

    /**
     * HTML-escape. School names come from an Excel import, so an ampersand or angle bracket in one is
     * entirely possible and would otherwise break the markup — and a broken document is silently
     * attached to a message sent to every coordinator.
     */
    private static String esc(String value) {
        if (value == null) return "";
        StringBuilder out = new StringBuilder(value.length() + 16);
        for (int i = 0; i < value.length(); i++) {
            char c = value.charAt(i);
            switch (c) {
                case '&':  out.append("&amp;");  break;
                case '<':  out.append("&lt;");   break;
                case '>':  out.append("&gt;");   break;
                case '"':  out.append("&quot;"); break;
                case '\'': out.append("&#39;");  break;
                default:   out.append(c);
            }
        }
        return out.toString();
    }
}
