package com.vjnt.util;

import java.text.SimpleDateFormat;
import java.util.Date;

/**
 * Builds the body params of a coordinator alert.
 *
 * THREE templates are in play, and they agree on neither the parameter count nor what {{1}} means.
 * {@link CoordinatorAlertType} decides which is used; this class shapes the text to fit it.
 *
 *   messages 1-5, WITH attachment — gatee_performance_rpt, TWO params
 *     Performance Report from GATEE Portal / {{1}} / {{2}} / इतर मागास बहुजन कल्याण विभाग
 *     {{1}} heading + phase, a colon, then the position and figures
 *     {{2}} the action asked for
 *
 *   messages 1-5, WITHOUT attachment — gatee_com_alert1, three params
 *     🚨🚨 GATEE Portal Alert 🚨🚨 / {{1}} {{2}} / {{3}} / इतर मागास बहुजन कल्याण विभाग
 *     {{1}} heading — which bucket and which phase   ({{1}} and {{2}} render on adjacent lines)
 *     {{2}} the district's/division's position, with real numbers
 *     {{3}} the action asked for
 *
 *   status report (message 6) — two_line_document, three params, has a document header
 *     *स्तर निश्चितीकरण सद्यस्थिती अहवाल* / {{1}} {{2}} {{3}} / इतर मागास बहुजन कल्याण विभाग
 *     {{1}} scope line — district/division, phase, as-of date
 *     {{2}} every bucket count and overall progress
 *     {{3}} the action asked for
 *
 * The report's heading is part of its template, so repeating it in {{1}} would print it twice; the
 * freed slot carries the as-of date instead, because a status report is a snapshot and one forwarded
 * a week later should not read as current. The five alerts do not carry a date — they name an action
 * to take now, not a position to record.
 *
 * The two-param shape is the one to watch: the heading has no slot of its own there, so it is folded
 * into {{1}} ahead of the figures. Send three params to that template and the gateway rejects the
 * message for every recipient.
 *
 * Where {@link CriteriaAlertMessages} tells one school about itself, this tells an officer about the
 * schools they supervise — which is what the source drafts were actually written for ("[XX]
 * जिल्ह्यातील [XX] शाळांनी...").
 */
public final class CoordinatorAlertMessages {

    private CoordinatorAlertMessages() { }

    /**
     * @param type    which of the six messages
     * @param summary the figures for one district or one division
     * @return the three template params, already sanitized
     */
    public static String[] build(CoordinatorAlertType type, CoordinatorAlertSummary summary) {
        return build(type, summary, type.carriesDocument());
    }

    /**
     * Build for a send whose document state is already known, so a district whose document failed
     * gets wording that matches what it actually receives — a portal link, not "यादी सोबत जोडली आहे".
     */
    public static String[] build(CoordinatorAlertType type, CoordinatorAlertSummary summary,
                                 boolean withDocument) {
        String phaseLabel = "चरण " + summary.getPhase();

        String param1;
        String body;
        String action;

        if (type.isRollUp()) {
            param1 = buildReportScopeLine(summary, phaseLabel);
            body   = buildRollUpBody(summary);
            action = "कृपया प्रलंबित व अपेक्षेपेक्षा कमी प्रगती असलेल्या शाळांबाबत आवश्यक कार्यवाही व पाठपुरावा करावा."
                   + " " + listReference(withDocument, "सविस्तर अहवाल", "जोडला");
        } else {
            // Parenthesised, not dash-joined: two of the headings already contain an em dash.
            param1 = type.getHeading() + " (" + phaseLabel + ")";
            body   = buildBucketBody(type, summary);
            action = buildBucketAction(type) + " " + listReference(withDocument, "शाळांची यादी", "जोडली");
        }

        String[] params = (type.getBodyParamCount(withDocument) == 2)
                ? new String[] {
                        // Two-parameter template (gatee_performance_rpt): the heading has nowhere of
                        // its own to go, so it leads {{1}} and introduces the figures with a colon.
                        // A colon rather than a dash because two of the headings already contain an
                        // em dash, and "प्रलंबित — लातूर जिल्ह्यातील" reads as a broken sentence.
                        CriteriaAlertMessages.sanitize(param1 + ": " + body),
                        CriteriaAlertMessages.sanitize(action)
                  }
                : new String[] {
                        CriteriaAlertMessages.sanitize(param1),
                        CriteriaAlertMessages.sanitize(body),
                        CriteriaAlertMessages.sanitize(action)
                  };

        // Last line of defence, after sanitizing so what is measured is what is sent. An over-budget
        // body is rejected by the gateway per recipient as an opaque error, so a bulk send would
        // fail wholesale with no clue why; shortening the figures and logging loudly is strictly
        // better. CoordinatorAlertMessagesTest proves none of the six messages actually reach this.
        return MessageBudget.enforce(type, params);
    }

    /**
     * {{1}} of the status report: which district/division, which phase, and as of when.
     *
     * When the document templates are not approved yet the report goes out on the ALERT template,
     * whose body does not contain the report heading — so it has to be restored here or the message
     * arrives with no title at all.
     */
    private static String buildReportScopeLine(CoordinatorAlertSummary summary, String phaseLabel) {
        String scopeName = summary.getScope() == AlertScope.DIVISION
                ? summary.getName() + " विभाग"
                : summary.getName() + " जिल्हा";
        String line = scopeName + " — " + phaseLabel
                    + " (दिनांक " + new SimpleDateFormat("dd/MM/yyyy").format(new Date()) + ")";

        if (!CoordinatorAlertType.STATUS_REPORT.carriesDocument()) {
            line = "स्तर निश्चितीकरण सद्यस्थिती अहवाल — " + line;
        }
        return line;
    }

    /** {{2}} of the status report: all five buckets and overall progress, in one sentence. */
    private static String buildRollUpBody(CoordinatorAlertSummary summary) {
        return summary.getScopePhrase() + " एकूण " + summary.getTotalSchools() + " शाळांपैकी:"
             + " काम सुरू नाही " + summary.getCount(AlertCriterion.NOT_STARTED) + ","
             + " 25% पेक्षा कमी " + summary.getCount(AlertCriterion.BELOW_25) + ","
             + " 50% पेक्षा कमी " + summary.getCount(AlertCriterion.BELOW_50) + ","
             + " Approval प्रलंबित " + summary.getCount(AlertCriterion.PENDING_APPROVAL) + ","
             + " Reject " + summary.getCount(AlertCriterion.REJECTED) + "."
             + " एकूण प्रगती " + summary.getProgressPercentage() + "%.";
    }

    /**
     * {{2}} of an alert: how many schools are in this bucket, out of how many.
     *
     * The phase is deliberately absent — {{1}} already names it, and the source drafts do not repeat
     * it here either. Saying "चरण 1" twice in a four-line message reads like a template fault.
     */
    private static String buildBucketBody(CoordinatorAlertType type, CoordinatorAlertSummary summary) {
        int count = summary.getCount(type);
        String scope = summary.getScopePhrase();
        String totalClause = " " + summary.getTotalLabel() + ": " + summary.getTotalSchools() + ".";

        switch (type) {
            case NOT_STARTED:
                return scope + " " + count
                     + " शाळांनी अद्याप स्तर निश्चितीकरणाचे काम सुरू केलेले नाही." + totalClause;

            case BELOW_25:
            case BELOW_50:
                // Threshold derived from the type rather than written into the sentence twice, so the
                // wording cannot drift from the bucket actually being counted.
                int threshold = (type == CoordinatorAlertType.BELOW_25) ? 25 : 50;
                return scope + " " + count + " शाळांमध्ये स्तर निश्चितीकरणाची प्रगती "
                     + threshold + "% पेक्षा कमी आहे."
                     + " अशा शाळांची प्रगती अपेक्षेपेक्षा कमी असून संबंधित शाळांकडे लक्ष देणे आवश्यक आहे."
                     + " 📊 " + summary.getTotalLabel() + ": " + summary.getTotalSchools()
                     + " ⚠️ " + threshold + "% पेक्षा कमी: " + count;

            case PENDING_APPROVAL:
                // No total here: the drafts phrase this one on the pending count alone, and the
                // figure that matters to the officer is how many are waiting on a head master.
                return scope + " " + count + " शाळांमध्ये स्तर निश्चितीची माहिती 100% भरलेली आहे;"
                     + " मात्र मुख्याध्यापक स्तरावर तपासणी/Approval अद्याप प्रलंबित आहे."
                     + " 📋 प्रलंबित शाळा: " + count;

            case REJECTED:
                return scope + " " + count
                     + " शाळांची स्तर निश्चितीची माहिती मुख्याध्यापकांनी दुरुस्तीसाठी Reject केली आहे."
                     + " संबंधित शाळा समन्वयकांनी अद्याप आवश्यक दुरुस्ती केलेली नाही.";

            default:
                throw new IllegalStateException("Unhandled alert type: " + type);
        }
    }

    /** {{3}} of an alert, minus the closing reference to the list. */
    private static String buildBucketAction(CoordinatorAlertType type) {
        switch (type) {
            case NOT_STARTED:
                return "कृपया संबंधित शाळांना कार्यवाही करण्याबाबत निर्देश द्यावेत.";
            case BELOW_25:
            case BELOW_50:
                return "कृपया संबंधित शाळांच्या प्रगतीचा आढावा घेऊन आवश्यक सूचना द्याव्यात.";
            case PENDING_APPROVAL:
                return "कृपया संबंधित शाळांना आवश्यक सूचना द्याव्यात.";
            case REJECTED:
                return "कृपया संबंधित शाळांचा पाठपुरावा करावा.";
            default:
                throw new IllegalStateException("Unhandled alert type: " + type);
        }
    }

    /**
     * How the message refers to the school list: attached, or a portal link.
     *
     * The drafts promise "शाळांची यादी सोबत जोडली आहे", which is only honest once a
     * document-header template is approved. Until then the message uses the fallback the drafts
     * themselves offer — "अद्यावत यादी पाहण्यासाठी पोर्टल वर पहावे" — rather than claiming an
     * attachment that is not there.
     *
     * The participle has to be supplied with the noun because Marathi inflects it for gender:
     * "यादी" is feminine and takes जोडली, "अहवाल" is masculine and takes जोडला. A single hardcoded
     * form produces "सविस्तर अहवाल सोबत जोडली आहे", which is wrong and visible to every officer who
     * reads it. The link wording needs no such agreement, so it is shared.
     *
     * @param noun     "शाळांची यादी" for an alert, "सविस्तर अहवाल" for the status report
     * @param attached the matching participle — "जोडली" (f.) or "जोडला" (m.)
     */
    private static String listReference(boolean withDocument, String noun, String attached) {
        if (withDocument) {
            return noun + " सोबत " + attached + " आहे.";
        }
        return "अद्यावत " + noun + " पाहण्यासाठी पोर्टलवर पहावे: " + WhatsAppConfig.PORTAL_LOGIN_URL;
    }
}
