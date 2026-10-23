package com.vjnt.util;

/**
 * WhatsApp CPaaS API settings for the GATEE Portal.
 * All values live here in Java — no properties file.
 *
 * Provider: CPaaS reseller gateway (see tests/GateePorta,.l.json Postman collection).
 * Endpoints/headers:
 *   POST https://cpaasreseller.notify24x7.com/REST/directApi/message          (send)
 *   POST https://cpaasreseller.notify24x7.com/REST/directApi/getTemplateList  (list approved templates)
 *   headers: wabaNumber, Key, Content-Type: application/json
 */
public class WhatsAppConfig {

    /** Default country code for 10-digit numbers. */
    public static final String COUNTRY_CODE = "91";

    // CPaaS WhatsApp API gateway. NOTE: the Postman collection says
    // cpaasreseller.notify24x7.com but that host is unreachable — the account's
    // working gateway host is rcs.mmtpro.in (verified via getTemplateList).
    public static final String API_BASE          = "https://rcs.mmtpro.in/REST/directApi";
    public static final String API_URL           = API_BASE + "/message";
    public static final String API_TEMPLATES_URL = API_BASE + "/getTemplateList";

    /** WABA number (with country code). */
    public static final String WABA_NUMBER = "918065917639";

    /** API key from the reseller panel (complete key, verified working). */
    public static final String API_KEY = "3725676074XX";

    // ── Templates (all Marathi) ──
    /** Common Marathi language code for all GATEE templates. */
    public static final String LANG_MR = "mr";

    // APPROVED (verified via getTemplateList):
    /** नमस्कार {{1}}, शाळा UDISE {{2}} — {{3}} कृपया GATEE Portal वर लॉग इन करून
     *  शाळा समन्वयक यांनी पोर्टल वर भरलेली माहिती तपासून पुढील कार्यवाही तात्काळ करावी. */
    public static final String TPL_HM_APPROVAL  = "hm_approval_alert";
    public static final String LANG_HM_APPROVAL = LANG_MR;

    // PENDING APPROVAL — submit from WHATSAPP_TEMPLATES_MARATHI.md, then verify
    // with getTemplateList before using:
    /** पालक मेळावा आयोजन: {{1}} name, {{2}} UDISE, {{3}} school, {{4}} date, {{5}} melava no */
    public static final String TPL_MELAVA_SCHEDULE = "palak_melava_schedule";
    /** पालक मेळावा माहिती प्रलंबित: {{1}} name, {{2}} UDISE, {{3}} school, {{4}} melava no */
    public static final String TPL_MELAVA_PENDING  = "palak_melava_pending";
    /** चरण सुरू: {{1}} name, {{2}} UDISE, {{3}} school, {{4}} phase, {{5}} start date */
    public static final String TPL_PHASE_START     = "phase_start_alert";
    /** चरण बंद होणार: {{1}} name, {{2}} UDISE, {{3}} school, {{4}} phase, {{5}} last date, {{6}} days left */
    public static final String TPL_PHASE_CLOSING   = "phase_closing_soon";
    /** चरण प्रलंबित: {{1}} name, {{2}} UDISE, {{3}} school, {{4}} phase, {{5}} pending student count */
    public static final String TPL_PHASE_PENDING   = "phase_pending_activity";

    /** 🚨🚨 GATEE Portal Alert 🚨🚨 {{1}} {{2}} {{3}} इतर मागास बहुजन कल्याण विभाग
     *
     *  Utility template, APPROVED. Three free-text body params, no header — so it can carry a
     *  link but never a document. {{1}} = heading, {{2}} = the school's situation, {{3}} = the
     *  action asked for. See CriteriaAlertMessages (schools) and CoordinatorAlertMessages
     *  (district/division coordinators). */
    public static final String TPL_CRITERIA_ALERT  = "gatee_com_alert1";
    public static final String LANG_CRITERIA_ALERT = LANG_MR;

    // ── Coordinator alerts: templates with a DOCUMENT header ──
    //
    // A WhatsApp template can only carry a file if Meta approved it WITH a document header; a body
    // param cannot hold one, and sendDocument() is not a way round it because free-form documents
    // only send inside the 24h customer-service window — which will not apply to a coordinator who
    // has never messaged this WABA.

    /**
     * Messages 1-5, WITH a document header. APPROVED and in use.
     *
     *   [HEADER/DOCUMENT]
     *   Performance Report from GATEE Portal
     *   {{1}}
     *   {{2}}
     *   इतर मागास बहुजन कल्याण विभाग
     *   [FOOTER] Download Performance Report
     *
     * Chosen deliberately over submitting a new gatee_com_alert_doc: this one is already approved, so
     * the five alerts attach their school list today instead of waiting on a Meta review that could
     * take days and could be rejected.
     *
     * Two consequences to be aware of, neither fatal:
     * <ul>
     *   <li><b>The heading is English</b> ("Performance Report from GATEE Portal") on an otherwise
     *       Marathi alert, and the footer reads "Download Performance Report". If officers object,
     *       the fix is to submit a Marathi document template and repoint this constant — nothing else
     *       changes.</li>
     *   <li><b>It takes TWO body params, not three.</b> {@link CoordinatorAlertType#getBodyParamCount}
     *       carries that, and CoordinatorAlertMessages folds the heading into {{1}} accordingly. Send
     *       three params to a two-param template and the gateway rejects every message.</li>
     * </ul>
     */
    public static final String TPL_CRITERIA_ALERT_DOC = "gatee_performance_rpt";

    /**
     * The status report (message 6), WITH a document header. APPROVED and in use.
     *
     *   [HEADER/DOCUMENT]
     *   *स्तर निश्चितीकरण सद्यस्थिती अहवाल*
     *   {{1}} {{2}} {{3}}
     *   इतर मागास बहुजन कल्याण विभाग
     *   [FOOTER] सद्यस्थिती अहवाल
     *
     * The unhelpful name is the provider's, not ours — confirmed via getTemplateList() on
     * 2026-08-19 to be exactly the status-report template, already carrying a DOCUMENT header. Do not
     * rename it here hoping to tidy it up; the name is the gateway's key.
     *
     * Its heading is part of the template, so {{1}} carries the scope line — district/division and
     * चरण — rather than repeating it.
     */
    public static final String TPL_STATUS_REPORT_DOC = "two_line_document";

    /**
     * Whether messages 1-5 may attach their school list. TRUE — {@link #TPL_CRITERIA_ALERT_DOC} is
     * approved and carries a document header, so the five alerts attach today.
     *
     * Set back to false to route them onto {@link #TPL_CRITERIA_ALERT} instead, which has no document
     * header, with the list offered as a portal link in {{3}} — the wording the source drafts
     * themselves fall back to ("अद्यावत यादी पाहण्यासाठी पोर्टल वर पहावे"). That is the fallback if
     * the English heading on the document template turns out to be unacceptable.
     */
    public static final boolean ALERT_DOC_TEMPLATE_APPROVED = true;

    /**
     * Whether the status report may attach its PDF. TRUE — {@link #TPL_STATUS_REPORT_DOC} is approved
     * and has the document header, so message 6 attaches today.
     *
     * Split from {@link #ALERT_DOC_TEMPLATE_APPROVED} deliberately: the two families sit on different
     * templates with different approval states, and one flag for both would have held the working
     * status report hostage to an alert template nobody has submitted yet.
     *
     * Note both are compiled constants — whatever is built here is what production runs.
     */
    public static final boolean STATUS_REPORT_DOC_TEMPLATE_APPROVED = true;

    /**
     * Test routing for alerts.
     *
     * TEST MODE since 2026-08-19: every alert goes to {@link #ALERT_TEST_NUMBER} instead of its real
     * recipient. Turned on for end-to-end testing of the Coordinator Alerts console, whose sends
     * reach district and division officers.
     *
     * <p><b>This switch is shared, and that is the point to be aware of.</b> Both consoles route
     * through {@code SchoolAlertSender.destinationFor}, so while this is true the LIVE per-school
     * Criteria Alerts console also stops reaching real Head Masters and School Coordinators. That is
     * intended during testing — but it means real school follow-up alerts are not being delivered,
     * so set it back to false once coordinator testing is signed off.
     *
     * The intended recipient is still resolved, shown in the UI and written to whatsapp_alert_log
     * either way, so the flow is exercised end to end and the log stays an honest record of what was
     * sent where — only the destination changes.
     *
     * Note this is a compiled constant, not a per-environment setting: whatever is built here is what
     * production runs, and it needs a rebuild plus a republish to take effect.
     */
    public static final boolean ALERT_TEST_MODE   = false;
    public static final String  ALERT_TEST_NUMBER = "9422887070";

    /**
     * Absolute portal URL used in the {{3}} call to action. A servlet send has no reliable request
     * host to build one from (and the alert must work behind the proxy), so it is configured here.
     *
     * Domain only, deliberately: the context path differs between deployments (gateepor serves
     * /VJNT_ClassManagement, the WAR folder is spelled VJNT_Class_Managment), and a 404 in a message
     * sent to every head master is worse than one extra click from the site root.
     */
    public static final String PORTAL_LOGIN_URL = "https://gwsonline.in";

    /** true = log payloads instead of calling the API (for testing). */
    public static final boolean MOCK_MODE = false;

    private WhatsAppConfig() { }
}
