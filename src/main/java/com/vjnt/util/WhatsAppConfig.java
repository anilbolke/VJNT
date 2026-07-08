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

    /** true = log payloads instead of calling the API (for testing). */
    public static final boolean MOCK_MODE = false;

    private WhatsAppConfig() { }
}
