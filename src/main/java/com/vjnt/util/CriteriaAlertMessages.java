package com.vjnt.util;

/**
 * Builds the three body params of the gatee_com_alert1 template for one school in one bucket.
 *
 *   🚨🚨 GATEE Portal Alert 🚨🚨 {{1}} {{2}} {{3}} इतर मागास बहुजन कल्याण विभाग
 *
 *   {{1}} heading — which bucket and which phase
 *   {{2}} the school's own situation, with its UDISE and real numbers
 *   {{3}} the action asked for, ending in the portal link
 *
 * The source drafts were addressed to a district officer about a district ("[XX] जिल्ह्यातील [XX]
 * शाळांनी..."). These are addressed to the school itself, because the only WhatsApp numbers on file
 * belong to school contacts — so each school is told about its own position rather than a total it
 * cannot act on.
 */
public final class CriteriaAlertMessages {

    private CriteriaAlertMessages() { }

    /**
     * @param criterion   which bucket the school is in
     * @param phase       1-4
     * @param udiseNo     school UDISE
     * @param schoolName  school name (may be blank; the UDISE still identifies it)
     * @param done        students saved in this phase
     * @param total       phase roster size
     * @return the three template params, already sanitized
     */
    public static String[] build(AlertCriterion criterion, int phase, String udiseNo,
                                 String schoolName, int done, int total) {

        String phaseLabel = "चरण " + phase;
        String school = (schoolName == null || schoolName.trim().isEmpty())
                ? "UDISE " + udiseNo
                : "UDISE " + udiseNo + " — " + schoolName;
        int pct = total > 0 ? (int) Math.round(done * 100.0 / total) : 0;
        int remaining = Math.max(total - done, 0);
        String portal = "पोर्टल: " + WhatsAppConfig.PORTAL_LOGIN_URL;

        // Parenthesised, not dash-joined: two of the headings already contain an em dash.
        String heading = criterion.getHeading() + " (" + phaseLabel + ")";
        String body;
        String action;

        switch (criterion) {
            case NOT_STARTED:
                body = school + " या शाळेने " + phaseLabel + " मध्ये अद्याप स्तर निश्चितीकरणाचे काम सुरू केलेले नाही."
                     + " शाळेतील एकूण विद्यार्थी: " + total + ".";
                action = "कृपया तात्काळ कार्यवाही करून विद्यार्थ्यांचे स्तर निश्चित करावेत. " + portal;
                break;

            case BELOW_25:
            case BELOW_50:
                body = school + " या शाळेची " + phaseLabel + " मधील स्तर निश्चितीकरणाची प्रगती " + pct + "% आहे"
                     + " (" + total + " पैकी " + done + " विद्यार्थी). ही प्रगती अपेक्षेपेक्षा कमी आहे.";
                action = "कृपया उर्वरित " + remaining + " विद्यार्थ्यांचे स्तर तातडीने निश्चित करावेत. " + portal;
                break;

            case PENDING_APPROVAL:
                // Phrased on the total alone: this bucket only fires when done == total, and saying
                // "158 पैकी 158" adds nothing while risking a nonsense sentence if it ever does not.
                body = school + " या शाळेची " + phaseLabel + " मधील स्तर निश्चितीची माहिती सर्व "
                     + total + " विद्यार्थ्यांसाठी 100% भरलेली आहे;"
                     + " मात्र मुख्याध्यापक स्तरावर तपासणी/Approval अद्याप प्रलंबित आहे.";
                action = "कृपया मुख्याध्यापकांनी पोर्टलवर माहिती तपासून Approval ची कार्यवाही तात्काळ करावी. " + portal;
                break;

            case REJECTED:
                body = school + " या शाळेची " + phaseLabel + " मधील स्तर निश्चितीची माहिती मुख्याध्यापकांनी"
                     + " दुरुस्तीसाठी Reject केली आहे. आवश्यक दुरुस्ती अद्याप झालेली नाही.";
                action = "कृपया शाळा समन्वयकांनी आवश्यक दुरुस्ती करून माहिती पुन्हा सादर करावी. " + portal;
                break;

            default:
                throw new IllegalStateException("Unhandled criterion: " + criterion);
        }

        return new String[] { sanitize(heading), sanitize(body), sanitize(action) };
    }

    /**
     * Collapse every whitespace run to a single space.
     *
     * Meta rejects template parameters containing newlines, tabs or 4+ consecutive spaces, and the
     * gateway reports it only as an opaque failure — so this is not cosmetic. Any line breaks in the
     * delivered message come from the approved template itself, between {{1}} {{2}} {{3}}.
     */
    public static String sanitize(String value) {
        if (value == null) return "";
        return value.replaceAll("\\s+", " ").trim();
    }
}
