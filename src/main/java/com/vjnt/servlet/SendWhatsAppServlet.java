package com.vjnt.servlet;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONObject;

import com.vjnt.util.WhatsAppService;
import com.vjnt.util.WhatsAppService.WhatsAppResponse;

/**
 * Test endpoint for WhatsApp integration.
 *
 * Send a text message:
 *   POST /sendWhatsApp
 *     type=text&to=919876543210&message=Hello
 *
 * Send a template message:
 *   POST /sendWhatsApp
 *     type=template&to=919876543210&template=welcome_template&lang=en&params=Anil,ClassV
 *
 * Send a document:
 *   POST /sendWhatsApp
 *     type=document&to=919876543210&url=https://example.com/report.pdf&filename=report.pdf&caption=Report Card
 */
@WebServlet("/sendWhatsApp")
public class SendWhatsAppServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        JSONObject result = new JSONObject();

        String type = param(request, "type", "text");
        String to = request.getParameter("to");

        if (to == null || to.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            result.put("success", false).put("error", "Parameter 'to' is required");
            response.getWriter().write(result.toString());
            return;
        }

        try {
            WhatsAppService wa = WhatsAppService.getInstance();
            WhatsAppResponse waResponse;

            switch (type) {
                case "template": {
                    String template = request.getParameter("template");
                    String lang = param(request, "lang", "en");
                    String paramsCsv = request.getParameter("params");
                    String[] params = (paramsCsv == null || paramsCsv.trim().isEmpty())
                            ? null : paramsCsv.split(",");
                    if (template == null || template.trim().isEmpty()) {
                        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        result.put("success", false).put("error", "Parameter 'template' is required");
                        response.getWriter().write(result.toString());
                        return;
                    }
                    waResponse = wa.sendTemplateMessage(to, template.trim(), lang, params);
                    break;
                }
                case "document": {
                    waResponse = wa.sendDocument(to,
                            request.getParameter("url"),
                            request.getParameter("filename"),
                            request.getParameter("caption"));
                    break;
                }
                case "image": {
                    waResponse = wa.sendImage(to,
                            request.getParameter("url"),
                            request.getParameter("caption"));
                    break;
                }
                case "text":
                default: {
                    String message = request.getParameter("message");
                    if (message == null || message.trim().isEmpty()) {
                        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                        result.put("success", false).put("error", "Parameter 'message' is required");
                        response.getWriter().write(result.toString());
                        return;
                    }
                    waResponse = wa.sendTextMessage(to, message);
                    break;
                }
            }

            result.put("success", waResponse.isSuccess());
            result.put("statusCode", waResponse.getStatusCode());
            result.put("messageId", waResponse.getMessageId() == null
                    ? JSONObject.NULL : waResponse.getMessageId());
            result.put("providerResponse", waResponse.getBody());

            if (!waResponse.isSuccess()) {
                response.setStatus(HttpServletResponse.SC_BAD_GATEWAY);
            }

        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            result.put("success", false).put("error", e.getMessage());
        }

        response.getWriter().write(result.toString());
    }

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Allow quick browser testing with the same parameters
        doPost(request, response);
    }

    private static String param(HttpServletRequest request, String name, String defaultValue) {
        String value = request.getParameter(name);
        return (value == null || value.trim().isEmpty()) ? defaultValue : value.trim();
    }
}
