package com.vjnt.util;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Utility for sending WhatsApp messages through the CPaaS reseller gateway
 * (cpaasreseller.notify24x7.com). All configuration comes from
 * {@link WhatsAppConfig} — no properties file.
 *
 * Request format follows the provider's Postman collection
 * (tests/GateePorta,.l.json): POST to /REST/directApi/message with
 * headers wabaNumber + Key and a JSON body.
 *
 * Usage:
 *   WhatsAppService wa = WhatsAppService.getInstance();
 *   wa.sendTextMessage("919876543210", "Hello from GATEE Portal");
 *   wa.sendTemplateMessage("919876543210", WhatsAppConfig.TPL_HM_APPROVAL,
 *                          WhatsAppConfig.LANG_HM_APPROVAL, new String[]{"Name", "UDISE", "School"});
 */
public class WhatsAppService {

    private static WhatsAppService instance;

    private WhatsAppService() {
    }

    public static synchronized WhatsAppService getInstance() {
        if (instance == null) {
            instance = new WhatsAppService();
        }
        return instance;
    }

    /** Send a plain text message (works inside the 24h customer-service window). */
    public WhatsAppResponse sendTextMessage(String toNumber, String message) {
        JSONObject payload = new JSONObject()
                .put("to", normalizeNumber(toNumber))
                .put("type", "text")
                .put("recipient_type", "individual")
                .put("text", new JSONObject().put("body", message));
        return post(payload);
    }

    /**
     * Send a Meta-approved template message (required for business-initiated
     * conversations outside the 24-hour window).
     *
     * @param bodyParams values for {{1}}, {{2}}, ... placeholders in the template body; may be null
     */
    public WhatsAppResponse sendTemplateMessage(String toNumber, String templateName,
                                                String languageCode, String[] bodyParams) {
        JSONObject template = new JSONObject()
                .put("language", new JSONObject()
                        .put("policy", "deterministic")
                        .put("code", languageCode))
                .put("name", templateName);

        JSONArray components = new JSONArray();
        if (bodyParams != null && bodyParams.length > 0) {
            JSONArray parameters = new JSONArray();
            for (String value : bodyParams) {
                parameters.put(new JSONObject().put("type", "text").put("text", value));
            }
            components.put(new JSONObject().put("type", "body").put("parameters", parameters));
        }
        template.put("components", components);

        JSONObject payload = new JSONObject()
                .put("to", normalizeNumber(toNumber))
                .put("type", "template")
                .put("template", template);
        return post(payload);
    }

    /** Send a document (e.g. report card PDF) by public URL. */
    public WhatsAppResponse sendDocument(String toNumber, String documentUrl,
                                         String filename, String caption) {
        JSONObject document = new JSONObject().put("link", documentUrl);
        if (filename != null) document.put("filename", filename);
        if (caption != null) document.put("caption", caption);

        JSONObject payload = new JSONObject()
                .put("to", normalizeNumber(toNumber))
                .put("type", "document")
                .put("document", document);
        return post(payload);
    }

    /** Send an image by public URL. */
    public WhatsAppResponse sendImage(String toNumber, String imageUrl, String caption) {
        JSONObject image = new JSONObject().put("link", imageUrl);
        if (caption != null) image.put("caption", caption);

        JSONObject payload = new JSONObject()
                .put("to", normalizeNumber(toNumber))
                .put("type", "image")
                .put("image", image);
        return post(payload);
    }

    /** Fetch the list of approved templates from the gateway (raw JSON response). */
    public WhatsAppResponse getTemplateList() {
        return send(WhatsAppConfig.API_TEMPLATES_URL, new JSONObject());
    }

    /** Ensures the number has the country code and no +, spaces or dashes. */
    public static String normalizeNumber(String number) {
        if (number == null) return "";
        String digits = number.replaceAll("[^0-9]", "");
        if (digits.length() == 10) {
            digits = WhatsAppConfig.COUNTRY_CODE + digits;
        }
        return digits;
    }

    private WhatsAppResponse post(JSONObject payload) {
        return send(WhatsAppConfig.API_URL, payload);
    }

    private WhatsAppResponse send(String apiUrl, JSONObject payload) {
        if (WhatsAppConfig.MOCK_MODE) {
            System.out.println("[WhatsAppService MOCK] URL: " + apiUrl);
            System.out.println("[WhatsAppService MOCK] Payload: " + payload.toString(2));
            return new WhatsAppResponse(200, "{\"mock\":true}", true);
        }

        HttpURLConnection conn = null;
        try {
            URL url = new URL(apiUrl);
            conn = (HttpURLConnection) url.openConnection();
            conn.setRequestMethod("POST");
            conn.setConnectTimeout(15000);
            conn.setReadTimeout(30000);
            conn.setDoOutput(true);
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("wabaNumber", WhatsAppConfig.WABA_NUMBER);
            conn.setRequestProperty("Key", WhatsAppConfig.API_KEY);

            byte[] body = payload.toString().getBytes(StandardCharsets.UTF_8);
            try (OutputStream os = conn.getOutputStream()) {
                os.write(body);
            }

            int status = conn.getResponseCode();
            String responseBody = readStream(
                    status >= 200 && status < 300 ? conn.getInputStream() : conn.getErrorStream());

            // The gateway can return HTTP 200 with a failure body, e.g.
            // {"code":100,"status":"failed","message":"Authentication Failed"}
            String lower = responseBody == null ? "" : responseBody.toLowerCase();
            boolean bodyFailed = lower.contains("\"status\":\"failed\"")
                    || lower.contains("\"status\" : \"failed\"")
                    || lower.contains("\"errorcode\"");
            boolean success = status >= 200 && status < 300 && !bodyFailed;

            if (!success) {
                System.err.println("[WhatsAppService] HTTP " + status + " - " + responseBody);
            }
            return new WhatsAppResponse(status, responseBody, success);

        } catch (IOException e) {
            System.err.println("[WhatsAppService] Error sending message: " + e.getMessage());
            return new WhatsAppResponse(-1, e.getMessage(), false);
        } finally {
            if (conn != null) conn.disconnect();
        }
    }

    private static String readStream(InputStream in) throws IOException {
        if (in == null) return "";
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(in, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        return sb.toString();
    }

    /** Simple response holder. */
    public static class WhatsAppResponse {
        private final int statusCode;
        private final String body;
        private final boolean success;

        public WhatsAppResponse(int statusCode, String body, boolean success) {
            this.statusCode = statusCode;
            this.body = body;
            this.success = success;
        }

        public int getStatusCode() { return statusCode; }
        public String getBody() { return body; }
        public boolean isSuccess() { return success; }

        /** Message id returned by the gateway, or null if not present. */
        public String getMessageId() {
            try {
                JSONObject json = new JSONObject(body);
                // Cloud-API style: {"messages":[{"id":"..."}]}
                JSONArray messages = json.optJSONArray("messages");
                if (messages != null && messages.length() > 0) {
                    String id = messages.getJSONObject(0).optString("id", null);
                    if (id != null) return id;
                }
                // Gateway style: {"messageId":"..."} / {"id":"..."}
                String id = json.optString("messageId", null);
                if (id == null || id.isEmpty()) id = json.optString("id", null);
                return (id == null || id.isEmpty()) ? null : id;
            } catch (Exception ignored) {
            }
            return null;
        }

        @Override
        public String toString() {
            return "WhatsAppResponse{status=" + statusCode + ", success=" + success
                    + ", body=" + body + "}";
        }
    }
}
