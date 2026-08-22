package com.vjnt.util;

/**
 * Keeps a template message inside WhatsApp's body-size limit.
 *
 * Meta caps the RENDERED template body at 1024 characters — the fixed text plus every substituted
 * parameter. Exceeding it fails at the gateway, per recipient, as an opaque error; on a bulk send
 * that is a wall of failures with no explanation, discovered only after the officer clicked. Nothing
 * checked this before: {@link CriteriaAlertMessages#sanitize} fixes whitespace but never measures.
 *
 * <p><b>Why the cap cannot be raised by changing the template.</b> The limit is on the whole rendered
 * body, not per parameter, so a template with seven placeholders holds exactly as much text as one
 * with three. Long content belongs in the attached PDF, not in more parameters.
 *
 * <p><b>Why Marathi runs out of room sooner than it looks.</b> Devanagari conjuncts are several
 * codepoints per visible glyph — {@code क्ष} is 3, {@code र्थी} is 4 — so a message that looks half
 * the length of an English one can cost the same. Eyeballing is not a check; this class is.
 *
 * Two entry points, deliberately different:
 * <ul>
 *   <li>{@link #enforce} — used on the send path. Never throws: it truncates and logs, because a
 *       slightly shortened alert reaching a district coordinator beats no alert at all.</li>
 *   <li>{@link #validateOrThrow} — used by the self-test. Throws, so a copy edit that would overflow
 *       fails the build rather than production.</li>
 * </ul>
 * (The plan called these "development" and "production" modes. This project has no such switch, so
 * they are two methods with two call sites instead of one method reading an environment flag.)
 */
public final class MessageBudget {

    /** Meta's cap on the rendered template body. */
    public static final int BODY_LIMIT = 1024;

    /**
     * Fixed text of {@link WhatsAppConfig#TPL_CRITERIA_ALERT} / {@code TPL_CRITERIA_ALERT_DOC},
     * i.e. everything the template contributes around {{1}} {{2}} {{3}}.
     *
     * Kept as the literal text rather than a hand-counted number so that correcting the template copy
     * here automatically corrects the budget — a number would silently go stale.
     */
    public static final String BODY_ALERT =
            "🚨🚨 GATEE Portal Alert 🚨🚨\n\n{{1}}\n{{2}}\n\n{{3}}\nइतर मागास बहुजन कल्याण विभाग";

    /** Body of {@link WhatsAppConfig#TPL_STATUS_REPORT_DOC} (the template named two_line_document). */
    public static final String BODY_STATUS_REPORT =
            "*स्तर निश्चितीकरण सद्यस्थिती अहवाल*\n\n{{1}} \n{{2}}\n{{3}}\n\nइतर मागास बहुजन कल्याण विभाग";

    /**
     * Body of {@link WhatsAppConfig#TPL_CRITERIA_ALERT_DOC} (gatee_performance_rpt) — the document
     * template messages 1-5 use. Note it declares only TWO parameters.
     */
    public static final String BODY_PERFORMANCE_RPT =
            "Performance Report from GATEE Portal\n\n{{1}}\n\n{{2}}\nइतर मागास बहुजन कल्याण विभाग";

    /**
     * Both bodies above are the EXACT text returned by getTemplateList() on 2026-08-19, kept verbatim
     * so the budget stays correct by construction. The placeholders are stripped at runtime rather
     * than hand-subtracted, because a hand-counted number would silently go stale the first time
     * anyone edited the copy.
     *
     * Footers are excluded on purpose: WhatsApp budgets the footer separately (60 chars of its own),
     * so counting it here would wrongly shrink the body allowance.
     */
    public static final String FIXED_ALERT = stripPlaceholders(BODY_ALERT);

    public static final String FIXED_STATUS_REPORT = stripPlaceholders(BODY_STATUS_REPORT);

    public static final String FIXED_PERFORMANCE_RPT = stripPlaceholders(BODY_PERFORMANCE_RPT);

    /** Remove {{1}}…{{9}} so what remains is the template's own contribution to the body. */
    private static String stripPlaceholders(String body) {
        return body.replaceAll("\\{\\{[0-9]+\\}\\}", "");
    }

    /**
     * Which slot carries the expendable detail, and is therefore the only one truncation may touch.
     *
     * On the three-parameter templates that is {{2}}, the figures. On the two-parameter document
     * template the heading has been folded into {{1}} alongside the figures, so {{1}} is the long
     * one and {{2}} is the action — truncating index 1 there would cut the instruction and leave the
     * numbers, which is exactly backwards.
     */
    private static int detailIndex(String[] params) {
        return params.length >= 3 ? 1 : 0;
    }

    /**
     * Appended when {{2}} has to be shortened. Names where the missing detail went, so a truncated
     * message still tells the officer what to do next.
     */
    public static final String TRUNCATION_SUFFIX = "… सविस्तर माहिती सोबतच्या यादीत आहे.";

    private MessageBudget() { }

    /**
     * Cost of a string, counted in UTF-16 units rather than codepoints.
     *
     * This deliberately OVER-counts: an emoji is 2 units but 1 codepoint. Meta does not document
     * which unit it counts, and over-counting only ever makes us send a slightly shorter message,
     * whereas under-counting sends one the gateway rejects. Wrong in the safe direction.
     */
    public static int cost(String value) {
        return value == null ? 0 : value.length();
    }

    /** Fixed cost of the template a given alert type will actually be sent on. */
    public static int fixedCostFor(CoordinatorAlertType type) {
        if (!type.carriesDocument()) {
            return cost(FIXED_ALERT);               // gatee_com_alert1
        }
        return type.isRollUp()
                ? cost(FIXED_STATUS_REPORT)         // two_line_document
                : cost(FIXED_PERFORMANCE_RPT);      // gatee_performance_rpt
    }

    /** Characters left for parameters once the template's own text is accounted for. */
    public static int budgetFor(CoordinatorAlertType type) {
        return BODY_LIMIT - fixedCostFor(type);
    }

    /** Total cost of the substituted parameters. */
    public static int paramCost(String[] params) {
        int total = 0;
        if (params != null) {
            for (String p : params) {
                total += cost(p);
            }
        }
        return total;
    }

    /** Rendered body size this message will produce. */
    public static int renderedCost(CoordinatorAlertType type, String[] params) {
        return fixedCostFor(type) + paramCost(params);
    }

    /** True when the message fits without any shortening. */
    public static boolean fits(CoordinatorAlertType type, String[] params) {
        return renderedCost(type, params) <= BODY_LIMIT;
    }

    /**
     * Bring a message inside the limit, shortening {{2}} if it does not fit.
     *
     * <p>Only {{2}} is ever cut. {{1}} is the heading and {{3}} is the action — a message that has
     * lost either is not worth sending, whereas one that has lost some of its middle detail still
     * tells the officer what happened and what to do. The cut lands on a word boundary so Marathi is
     * not severed mid-conjunct.
     *
     * <p>Never throws. An over-long alert is a copy bug that {@link #validateOrThrow} should have
     * caught; at send time the useful behaviour is to deliver something and leave a loud log line.
     *
     * @return the same array instance when nothing needed changing, otherwise a shortened copy
     */
    public static String[] enforce(CoordinatorAlertType type, String[] params) {
        if (params == null || params.length < 2 || fits(type, params)) {
            return params;
        }

        int detail = detailIndex(params);
        int overBy = renderedCost(type, params) - BODY_LIMIT;
        int allowedForBody = cost(params[detail]) - overBy - cost(TRUNCATION_SUFFIX);

        System.err.println("[MessageBudget] " + type + " body is " + renderedCost(type, params)
                + " chars, over the " + BODY_LIMIT + " limit by " + overBy
                + " — truncating {{" + (detail + 1) + "}}."
                + " Fix the copy: see LARGE_MESSAGE_TEMPLATE_PLAN.html");

        String[] out = params.clone();
        if (allowedForBody <= 0) {
            // The other slots alone have consumed the budget. Dropping the detail still delivers the
            // action, which is the least-bad outcome; the counts are in the attached PDF anyway.
            System.err.println("[MessageBudget] the remaining slots alone exceed the limit for " + type
                    + " — {{" + (detail + 1) + "}} dropped entirely. This message needs rewriting.");
            out[detail] = TRUNCATION_SUFFIX.trim();
            return out;
        }

        out[detail] = truncateOnWordBoundary(params[detail], allowedForBody) + TRUNCATION_SUFFIX;
        return out;
    }

    /**
     * Same check as {@link #enforce}, but fails loudly. Call from the self-test so an over-budget
     * message is caught at build time.
     *
     * @throws IllegalStateException when the rendered body would exceed {@link #BODY_LIMIT}
     */
    public static void validateOrThrow(CoordinatorAlertType type, String[] params, String context) {
        if (params == null || params.length != type.getBodyParamCount()) {
            // A count mismatch is worse than a length overrun: the gateway rejects the message for
            // every recipient, so it must never reach a send.
            throw new IllegalStateException("Wrong parameter count for " + type + " (" + context
                  + "): template " + type.getTemplateName() + " declares " + type.getBodyParamCount()
                  + ", got " + (params == null ? "null" : String.valueOf(params.length)));
        }
        int rendered = renderedCost(type, params);
        if (rendered > BODY_LIMIT) {
            StringBuilder sizes = new StringBuilder();
            for (int i = 0; i < params.length; i++) {
                sizes.append(i == 0 ? "" : "/").append(cost(params[i]));
            }
            throw new IllegalStateException(
                    "Message too long for " + type + " (" + context + "): " + rendered
                  + " chars, limit " + BODY_LIMIT + ". Params: " + sizes);
        }
    }

    /**
     * Cut at or before {@code max}, backing up to the last space so a Devanagari word — and its
     * conjuncts and matras — is never split down the middle.
     */
    private static String truncateOnWordBoundary(String value, int max) {
        if (value == null) return "";
        if (value.length() <= max) return value;

        String cut = value.substring(0, max);
        int lastSpace = cut.lastIndexOf(' ');
        // Only honour the word boundary if it is not throwing away most of the text.
        if (lastSpace > max / 2) {
            cut = cut.substring(0, lastSpace);
        }
        return cut.trim() + " ";
    }
}
