package com.vjnt.util;

/**
 * The six messages a coordinator can be sent, for one phase.
 *
 * Five of them are the {@link AlertCriterion} follow-up buckets, reported at district or division
 * grain instead of per school. The sixth, {@link #STATUS_REPORT}, is a roll-up of all five and
 * belongs to no bucket — which is exactly why it is not a sixth AlertCriterion value: that enum's
 * values must each yield a {@code sqlCondition()} selecting the schools in the bucket, and a roll-up
 * has nothing sensible to return there.
 *
 * Each value also carries its own template, because the status report was approved with different
 * body copy from the alerts (its heading is baked into the template, so {{1}} carries the scope line
 * instead). Keeping that here means the sender never decides which template to use.
 */
public enum CoordinatorAlertType {

    NOT_STARTED(AlertCriterion.NOT_STARTED, "काम सुरू न केलेल्या शाळांची यादी"),
    BELOW_25(AlertCriterion.BELOW_25, "25% पेक्षा कमी प्रगती असलेल्या शाळा"),
    BELOW_50(AlertCriterion.BELOW_50, "50% पेक्षा कमी प्रगती असलेल्या शाळा"),
    PENDING_APPROVAL(AlertCriterion.PENDING_APPROVAL,
            "100% माहिती भरलेली — मुख्याध्यापकांची कार्यवाही प्रलंबित"),
    REJECTED(AlertCriterion.REJECTED, "माहिती Reject झालेल्या शाळा — दुरुस्ती प्रलंबित"),

    /**
     * Whole-district (or whole-division) position: every bucket count plus overall progress.
     * Uses its own template, whose body already reads "स्तर निश्चितीकरण सद्यस्थिती अहवाल".
     */
    STATUS_REPORT(null, "स्तर निश्चितीकरण सद्यस्थिती अहवाल");

    private final AlertCriterion criterion;
    private final String heading;

    CoordinatorAlertType(AlertCriterion criterion, String heading) {
        this.criterion = criterion;
        this.heading = heading;
    }

    /**
     * The bucket this type reports on, or null for {@link #STATUS_REPORT}.
     *
     * A null here is the single branch that separates "count one bucket" from "count them all", so
     * callers should ask {@link #isRollUp()} rather than null-checking by hand.
     */
    public AlertCriterion getCriterion() {
        return criterion;
    }

    /** True for {@link #STATUS_REPORT}: reports every bucket, and lists every school. */
    public boolean isRollUp() {
        return criterion == null;
    }

    /**
     * Marathi heading, taken from the source drafts. Used as {{1}} of the message, as the PDF title,
     * and in the console.
     *
     * Deliberately NOT {@link AlertCriterion#getHeading()}: those are written to a single school
     * about itself ("काम सुरू न केलेली शाळा"), while these address an officer about the many schools
     * they supervise ("काम सुरू न केलेल्या शाळांची यादी"). Same buckets, different reader.
     *
     * The status report's heading is already inside its own template, so there this titles the
     * document only — see CoordinatorAlertMessages.
     */
    public String getHeading() {
        return heading;
    }

    /**
     * Meta template to send this type with.
     *
     * Which one depends on whether the document-header templates are approved yet — see
     * {@link WhatsAppConfig#COORDINATOR_DOC_TEMPLATES_APPROVED}. Until they are, everything goes out
     * on the already-approved no-header template and the school list is offered as a portal link
     * instead of an attachment.
     */
    public String getTemplateName() {
        return getTemplateName(carriesDocument());
    }

    /**
     * Template for a send whose document state is already known.
     *
     * Needed because a document can fail to build for one district after {@link #carriesDocument()}
     * has already said yes. That send has to drop to the no-header template, and the document
     * template would be rejected outright for lacking a header.
     */
    public String getTemplateName(boolean withDocument) {
        if (!withDocument) {
            return WhatsAppConfig.TPL_CRITERIA_ALERT;
        }
        return isRollUp()
                ? WhatsAppConfig.TPL_STATUS_REPORT_DOC
                : WhatsAppConfig.TPL_CRITERIA_ALERT_DOC;
    }

    /** All GATEE templates are Marathi; kept explicit so a future English one has a place to go. */
    public String getLanguageCode() {
        return WhatsAppConfig.LANG_MR;
    }

    /**
     * How many body parameters the template this type sends on actually declares.
     *
     * Not a constant 3: the document template the five alerts use (gatee_performance_rpt) declares
     * only TWO. Sending three parameters to a two-parameter template is rejected by the gateway for
     * every recipient, so this drives how CoordinatorAlertMessages shapes its output rather than
     * being left for the caller to remember.
     */
    public int getBodyParamCount() {
        return getBodyParamCount(carriesDocument());
    }

    /** Param count for a send whose document state is already known — see {@link #getTemplateName(boolean)}. */
    public int getBodyParamCount(boolean withDocument) {
        if (!isRollUp() && withDocument) {
            return 2;   // gatee_performance_rpt
        }
        return 3;       // gatee_com_alert1 and two_line_document
    }

    /**
     * True when the message this type sends carries the school list as an attached PDF.
     *
     * Decided per family, because the two sit on different templates with different approval states:
     * the status report's template (two_line_document) is approved WITH a document header and
     * attaches today, while messages 1-5 have no approved document template yet and fall back to a
     * portal link.
     *
     * False also forces {@link #STATUS_REPORT} onto the alert template, whose body does not contain
     * the report heading — so the heading has to move back into {{1}}. See CoordinatorAlertMessages.
     */
    public boolean carriesDocument() {
        boolean approved = isRollUp()
                ? WhatsAppConfig.STATUS_REPORT_DOC_TEMPLATE_APPROVED
                : WhatsAppConfig.ALERT_DOC_TEMPLATE_APPROVED;

        // A server with no Chromium cannot produce the PDF, so promising one would mean sending
        // "शाळांची यादी सोबत जोडली आहे" with nothing attached — or, worse, failing the send outright
        // and delivering nothing at all. Falling back here makes the whole message consistent in one
        // place: link wording, the no-header template, and its three parameters all follow.
        // No browser check. Java2DReportRenderer depends on nothing but the bundled font, so a
        // document can always be produced; whether a browser exists only decides which renderer
        // draws it. The old gate turned a missing browser into "no attachment for anyone", which is
        // exactly the behaviour this replaced.
        //
        // A render that fails anyway is handled at the send site, per scope, rather than here: the
        // failure is specific to one district's document and must not silently reword every message.
        return approved && Java2DReportRenderer.isAvailable();
    }

    /** Parse a key from the request, or null when it is missing/unknown. */
    public static CoordinatorAlertType from(String key) {
        if (key == null) return null;
        try {
            return valueOf(key.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }
}
