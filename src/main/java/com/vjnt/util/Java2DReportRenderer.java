package com.vjnt.util;

import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Font;
import java.awt.FontFormatException;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.font.FontRenderContext;
import java.awt.geom.Rectangle2D;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * Renders the coordinator school-list report to PDF using only Java2D, for hosts with no browser.
 *
 * <p>{@link PdfRenderer} drives headless Chromium, which produces the better-looking document and
 * stays the first choice. This exists because the production host has no browser and cannot have one
 * installed, which would otherwise mean every alert goes out with a portal link instead of the list.
 *
 * <p><b>Devanagari.</b> Java2D shapes complex scripts correctly — the JVM hands the run to HarfBuzz,
 * so matra reordering, conjuncts and the reph all come out right. That is the whole reason this is
 * viable without a browser. The font is bundled at {@code /fonts/NotoSansDevanagari-Regular.ttf}
 * rather than taken from the host, because a Linux server without a Devanagari font would silently
 * render every Marathi string as empty boxes. Bundling means the output does not depend on what
 * happens to be installed.
 *
 * <p>Pages are rasterised and embedded by {@link SimplePdfWriter}; see the trade-off documented
 * there. Layout mirrors {@link CoordinatorAlertReportHtml} closely enough that a coordinator
 * receiving one then the other sees the same document, not two different reports.
 */
public final class Java2DReportRenderer {

    /** A4 landscape in PostScript points, matching the HTML's {@code @page size: A4 landscape}. */
    private static final float PAGE_W_PT = 842f;
    private static final float PAGE_H_PT = 595f;

    /** Raster resolution. 150dpi keeps 9pt Devanagari legible; 300 quadrupled size for no real gain. */
    private static final int DPI = 150;

    private static final float PX_PER_PT = DPI / 72f;
    private static final int PAGE_W = Math.round(PAGE_W_PT * PX_PER_PT);   // 1754
    private static final int PAGE_H = Math.round(PAGE_H_PT * PX_PER_PT);   // 1240

    private static final int MARGIN_X = mm(10);
    private static final int MARGIN_Y = mm(12);

    private static final Color INK        = new Color(0x1a1a1a);
    private static final Color MUTED      = new Color(0x555555);
    private static final Color RULE       = new Color(0xb0bec5);
    private static final Color HEAD_BG    = new Color(0xeceff1);
    private static final Color STRIPE_BG  = new Color(0xf7f9fa);

    private static final String FONT_RESOURCE = "/fonts/NotoSansDevanagari-Regular.ttf";

    /** Loaded once: Font.createFont parses the whole file, and it is called per page otherwise. */
    private static volatile Font baseFont;
    private static volatile String fontError;

    private Java2DReportRenderer() { }

    private static int mm(double millis) {
        return (int) Math.round(millis * DPI / 25.4);
    }

    private static int pt(double points) {
        return (int) Math.round(points * PX_PER_PT);
    }

    /**
     * True when this renderer can actually produce a document — i.e. the bundled font loaded.
     * Unlike a browser this has no external dependency, so the only failure mode is a build that
     * shipped without the font resource.
     */
    public static boolean isAvailable() {
        return font() != null;
    }

    /** Human-readable state for the console's diagnostics panel. */
    public static String describeAvailability() {
        if (font() != null) {
            return "OK: Java2D renderer, bundled font " + baseFont.getFamily();
        }
        return "Bundled font " + FONT_RESOURCE + " could not be loaded: " + fontError;
    }

    private static Font font() {
        Font local = baseFont;
        if (local != null) {
            return local;
        }
        synchronized (Java2DReportRenderer.class) {
            if (baseFont == null && fontError == null) {
                try (InputStream in = Java2DReportRenderer.class.getResourceAsStream(FONT_RESOURCE)) {
                    if (in == null) {
                        fontError = "resource not on the classpath";
                    } else {
                        baseFont = Font.createFont(Font.TRUETYPE_FONT, in);
                    }
                } catch (FontFormatException | IOException e) {
                    fontError = e.getClass().getSimpleName() + ": " + e.getMessage();
                }
            }
            return baseFont;
        }
    }

    /**
     * Render the report and return a temp PDF. Caller owns the file and must delete it.
     *
     * @param baseName file name stem, as {@link PdfRenderer#renderToPdf} uses
     */
    public static File renderToPdf(CoordinatorAlertType type, CoordinatorAlertSummary summary,
                                   List<PhaseSchoolRow> rows, String baseName) throws IOException {
        Font f = font();
        if (f == null) {
            throw new IOException("Java2D renderer unavailable: " + describeAvailability());
        }

        List<BufferedImage> pages = paint(type, summary, rows, f);
        File pdf = Files.createTempFile(baseName + "-", ".pdf").toFile();
        try {
            SimplePdfWriter.write(pages, PAGE_W_PT, PAGE_H_PT, pdf);
        } catch (IOException e) {
            if (!pdf.delete()) {
                pdf.deleteOnExit();
            }
            throw e;
        }
        return pdf;
    }

    // ------------------------------------------------------------------
    // Painting
    // ------------------------------------------------------------------

    private static List<BufferedImage> paint(CoordinatorAlertType type,
                                             CoordinatorAlertSummary summary,
                                             List<PhaseSchoolRow> rows, Font base) {
        boolean rollUp = type.isRollUp();
        boolean showDistrict = summary.getScope() == AlertScope.DIVISION;

        Font fDept  = base.deriveFont(Font.PLAIN, pt(9));
        Font fTitle = base.deriveFont(Font.BOLD,  pt(14));
        Font fMeta  = base.deriveFont(Font.PLAIN, pt(9));
        Font fHead  = base.deriveFont(Font.BOLD,  pt(8.5));
        Font fBody  = base.deriveFont(Font.PLAIN, pt(8.5));
        Font fFoot  = base.deriveFont(Font.PLAIN, pt(7.5));

        List<String> headers = headers(rollUp, showDistrict);
        int[] widths = columnWidths(headers, rollUp, showDistrict);

        List<BufferedImage> pages = new ArrayList<>();
        int rowCount = rows == null ? 0 : rows.size();
        int index = 0;
        int pageNo = 0;

        do {
            pageNo++;
            BufferedImage page = blankPage();
            Graphics2D g = page.createGraphics();
            quality(g);

            int y = MARGIN_Y;
            y = drawHeader(g, type, summary, fDept, fTitle, fMeta, y);

            // The summary block belongs to the roll-up and only to its first page; repeating it
            // would push the list down on every page for no benefit.
            if (rollUp && pageNo == 1) {
                y = drawSummaryBlock(g, summary, fHead, fBody, y);
            }

            if (rowCount == 0) {
                g.setFont(base.deriveFont(Font.PLAIN, pt(11)));
                g.setColor(INK);
                g.drawString("या निकषात कोणतीही शाळा आढळली नाही.", MARGIN_X, y + pt(14));
                y += pt(30);
            } else {
                int rowH = pt(8.5) + mm(2.2);
                int footReserve = pt(7.5) * 3;
                int bottom = PAGE_H - MARGIN_Y - footReserve;

                y = drawTableHeader(g, headers, widths, fHead, y, rowH);
                while (index < rowCount && y + rowH <= bottom) {
                    drawRow(g, rows.get(index), index + 1, widths, fBody, y, rowH,
                            rollUp, showDistrict);
                    y += rowH;
                    index++;
                }
            }

            drawFooter(g, fFoot, rowCount, pageNo);
            g.dispose();
            pages.add(page);
        } while (index < rowCount);

        // Page N of M is only knowable once every page exists, so it is stamped afterwards.
        stampPageNumbers(pages, base);
        return pages;
    }

    private static BufferedImage blankPage() {
        BufferedImage page = new BufferedImage(PAGE_W, PAGE_H, BufferedImage.TYPE_INT_RGB);
        Graphics2D g = page.createGraphics();
        g.setColor(Color.WHITE);
        g.fillRect(0, 0, PAGE_W, PAGE_H);
        g.dispose();
        return page;
    }

    private static void quality(Graphics2D g) {
        g.setRenderingHint(RenderingHints.KEY_TEXT_ANTIALIASING,
                           RenderingHints.VALUE_TEXT_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_ANTIALIASING,
                           RenderingHints.VALUE_ANTIALIAS_ON);
        g.setRenderingHint(RenderingHints.KEY_FRACTIONALMETRICS,
                           RenderingHints.VALUE_FRACTIONALMETRICS_ON);
        g.setRenderingHint(RenderingHints.KEY_STROKE_CONTROL,
                           RenderingHints.VALUE_STROKE_PURE);
    }

    private static int drawHeader(Graphics2D g, CoordinatorAlertType type,
                                  CoordinatorAlertSummary summary,
                                  Font fDept, Font fTitle, Font fMeta, int y) {
        String scopeName = summary.getScope() == AlertScope.DIVISION
                ? summary.getName() + " विभाग"
                : summary.getName() + " जिल्हा";

        g.setFont(fDept);
        g.setColor(MUTED);
        y += fDept.getSize();
        g.drawString("इतर मागास बहुजन कल्याण विभाग — GATEE Portal", MARGIN_X, y);

        g.setFont(fTitle);
        g.setColor(INK);
        y += fTitle.getSize() + mm(1.5);
        g.drawString(type.getHeading(), MARGIN_X, y);

        g.setFont(fMeta);
        g.setColor(new Color(0x333333));
        y += fMeta.getSize() + mm(2);
        g.drawString(scopeName + "  ·  चरण " + summary.getPhase() + "  ·  दिनांक "
                     + new SimpleDateFormat("dd/MM/yyyy HH:mm").format(new Date()),
                     MARGIN_X, y);

        y += mm(3);
        g.setColor(RULE);
        g.setStroke(new BasicStroke(1.5f));
        g.drawLine(MARGIN_X, y, PAGE_W - MARGIN_X, y);
        return y + mm(3);
    }

    private static int drawSummaryBlock(Graphics2D g, CoordinatorAlertSummary summary,
                                        Font fHead, Font fBody, int y) {
        List<String[]> entries = new ArrayList<>();
        entries.add(new String[]{ summary.getTotalLabel(), String.valueOf(summary.getTotalSchools()) });
        for (CoordinatorAlertType t : CoordinatorAlertType.values()) {
            if (t.isRollUp()) continue;
            entries.add(new String[]{ t.getHeading(), String.valueOf(summary.getCount(t)) });
        }
        entries.add(new String[]{ "एकूण प्रगती", summary.getProgressPercentage() + "%" });
        entries.add(new String[]{ "एकूण विद्यार्थी",
                                  summary.getRosterDone() + " / " + summary.getRosterTotal() });

        // Two columns of key/value pairs: the block is short and wide, and a single column would
        // waste most of a landscape page.
        int perColumn = (entries.size() + 1) / 2;
        int cellW = (PAGE_W - 2 * MARGIN_X) / 2;
        int keyW = cellW - pt(60);
        int rowH = pt(8.5) + mm(1.8);

        g.setStroke(new BasicStroke(1f));
        for (int i = 0; i < entries.size(); i++) {
            int col = i / perColumn;
            int rowInCol = i % perColumn;
            int x = MARGIN_X + col * cellW;
            int rowY = y + rowInCol * rowH;

            g.setColor(RULE);
            g.drawRect(x, rowY, keyW, rowH);
            g.drawRect(x + keyW, rowY, cellW - keyW - mm(4), rowH);

            g.setFont(fBody);
            g.setColor(INK);
            drawClipped(g, entries.get(i)[0], x + mm(2), rowY + rowH - mm(1.6), keyW - mm(4));
            g.setFont(fHead);
            drawRight(g, entries.get(i)[1], x + cellW - mm(6), rowY + rowH - mm(1.6));
        }
        return y + perColumn * rowH + mm(4);
    }

    private static List<String> headers(boolean rollUp, boolean showDistrict) {
        List<String> h = new ArrayList<>();
        h.add("अ.क्र.");
        h.add("UDISE");
        h.add("शाळेचे नाव");
        if (showDistrict) h.add("जिल्हा");
        // "|" marks the same break the HTML version writes as <br>; a single line does not fit.
        h.add("एकूण|विद्यार्थी");
        h.add("पूर्ण");
        h.add("बाकी");
        h.add("प्रगती %");
        h.add("Approval|स्थिती");
        if (rollUp) {
            for (AlertCriterion c : AlertCriterion.values()) {
                h.add(shortLabel(c));
            }
        }
        return h;
    }

    /**
     * Fixed weights rather than measured content: the school-name column must absorb the slack, and
     * measuring 2000 names to size it would make one long name shrink every other column.
     */
    private static int[] columnWidths(List<String> headers, boolean rollUp, boolean showDistrict) {
        int n = headers.size();
        int[] w = new int[n];
        int i = 0;
        w[i++] = pt(28);                    // अ.क्र.
        w[i++] = pt(72);                    // UDISE
        int nameIdx = i;
        w[i++] = 0;                         // school name - filled from the slack below
        if (showDistrict) w[i++] = pt(74);
        w[i++] = pt(46);                    // एकूण
        w[i++] = pt(38);                    // पूर्ण
        w[i++] = pt(38);                    // बाकी
        w[i++] = pt(46);                    // प्रगती %
        w[i++] = pt(72);                    // Approval
        if (rollUp) {
            for (int c = 0; c < AlertCriterion.values().length; c++) {
                w[i++] = pt(52);
            }
        }
        int used = 0;
        for (int k = 0; k < n; k++) used += w[k];
        int slack = (PAGE_W - 2 * MARGIN_X) - used;
        w[nameIdx] = Math.max(pt(110), slack);
        return w;
    }

    private static int drawTableHeader(Graphics2D g, List<String> headers, int[] widths,
                                       Font fHead, int y, int rowH) {
        int lineH = fHead.getSize() + mm(0.8);
        int maxLines = 1;
        for (String h : headers) {
            maxLines = Math.max(maxLines, splitLines(h).length);
        }
        int headH = maxLines * lineH + mm(1.6);

        int x = MARGIN_X;
        g.setColor(HEAD_BG);
        g.fillRect(MARGIN_X, y, tableWidth(widths), headH);
        g.setFont(fHead);
        g.setStroke(new BasicStroke(1f));
        for (int i = 0; i < headers.size(); i++) {
            g.setColor(RULE);
            g.drawRect(x, y, widths[i], headH);
            g.setColor(INK);
            String[] lines = splitLines(headers.get(i));
            // Vertically centre however many lines this heading has within the shared height.
            int top = y + (headH - lines.length * lineH) / 2;
            for (int l = 0; l < lines.length; l++) {
                drawCentred(g, lines[l], x, widths[i], top + (l + 1) * lineH - mm(0.6));
            }
            x += widths[i];
        }
        return y + headH;
    }

    private static void drawRow(Graphics2D g, PhaseSchoolRow r, int index, int[] widths,
                                Font fBody, int y, int rowH, boolean rollUp, boolean showDistrict) {
        if (index % 2 == 0) {
            g.setColor(STRIPE_BG);
            g.fillRect(MARGIN_X, y, tableWidth(widths), rowH);
        }
        g.setFont(fBody);
        int baseline = y + rowH - mm(1.6);
        int x = MARGIN_X;
        int i = 0;

        x = cell(g, String.valueOf(index), x, widths[i++], y, rowH, baseline, Align.CENTRE);
        x = cell(g, r.getUdiseNo(), x, widths[i++], y, rowH, baseline, Align.LEFT);
        x = cell(g, r.getDisplayName(), x, widths[i++], y, rowH, baseline, Align.LEFT);
        if (showDistrict) {
            x = cell(g, nullToDash(r.getDistrictName()), x, widths[i++], y, rowH, baseline, Align.LEFT);
        }
        x = cell(g, String.valueOf(r.getTotal()), x, widths[i++], y, rowH, baseline, Align.RIGHT);
        x = cell(g, String.valueOf(r.getDone()), x, widths[i++], y, rowH, baseline, Align.RIGHT);
        x = cell(g, String.valueOf(r.getRemaining()), x, widths[i++], y, rowH, baseline, Align.RIGHT);
        x = cell(g, r.getPercentage() + "%", x, widths[i++], y, rowH, baseline, Align.RIGHT);
        x = cell(g, r.getApprovalLabel(), x, widths[i++], y, rowH, baseline, Align.CENTRE);
        if (rollUp) {
            for (AlertCriterion c : AlertCriterion.values()) {
                x = cell(g, "", x, widths[i], y, rowH, baseline, Align.CENTRE);
                if (r.isIn(c)) {
                    drawTick(g, x - widths[i] / 2, y + rowH / 2);
                }
                i++;
            }
        }
    }

    /**
     * A tick as two strokes rather than a glyph. Noto Sans Devanagari has no U+2714, and a missing
     * glyph renders as an empty box — which in a bucket column reads as "marked" just as much as a
     * tick does. Drawing it removes the dependency on what the font happens to cover.
     */
    private static void drawTick(Graphics2D g, int cx, int cy) {
        int r = mm(1.4);
        g.setColor(new Color(0x2e7d32));
        g.setStroke(new BasicStroke(Math.max(2f, r / 3f),
                                    BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND));
        g.drawLine(cx - r, cy, cx - r / 3, cy + r);
        g.drawLine(cx - r / 3, cy + r, cx + r, cy - r);
        g.setStroke(new BasicStroke(1f));
        g.setColor(INK);
    }

    /** Column headings break on "|", the same place the HTML version emits a &lt;br&gt;. */
    private static String[] splitLines(String heading) {
        return heading.split("\\|", -1);
    }

    private enum Align { LEFT, CENTRE, RIGHT }

    private static int cell(Graphics2D g, String text, int x, int w, int y, int rowH,
                            int baseline, Align align) {
        g.setColor(RULE);
        g.drawRect(x, y, w, rowH);
        g.setColor(INK);
        String value = text == null ? "" : text;
        switch (align) {
            case CENTRE: drawCentred(g, value, x, w, baseline); break;
            case RIGHT:  drawRight(g, value, x + w - mm(2), baseline); break;
            default:     drawClipped(g, value, x + mm(1.5), baseline, w - mm(3));
        }
        return x + w;
    }

    private static int tableWidth(int[] widths) {
        int total = 0;
        for (int w : widths) total += w;
        return total;
    }

    /** Truncate with an ellipsis rather than overflowing into the next column. */
    private static void drawClipped(Graphics2D g, String text, int x, int baseline, int maxWidth) {
        if (text == null || text.isEmpty()) return;
        FontRenderContext frc = g.getFontRenderContext();
        if (width(g, text, frc) <= maxWidth) {
            g.drawString(text, x, baseline);
            return;
        }
        String ellipsis = "…";
        int end = text.length();
        while (end > 0 && width(g, text.substring(0, end) + ellipsis, frc) > maxWidth) {
            end--;
        }
        g.drawString(end > 0 ? text.substring(0, end) + ellipsis : ellipsis, x, baseline);
    }

    private static void drawCentred(Graphics2D g, String text, int x, int w, int baseline) {
        if (text == null || text.isEmpty()) return;
        double tw = width(g, text, g.getFontRenderContext());
        if (tw > w - mm(2)) {
            drawClipped(g, text, x + mm(1), baseline, w - mm(2));
            return;
        }
        g.drawString(text, (int) Math.round(x + (w - tw) / 2), baseline);
    }

    private static void drawRight(Graphics2D g, String text, int right, int baseline) {
        if (text == null || text.isEmpty()) return;
        double tw = width(g, text, g.getFontRenderContext());
        g.drawString(text, (int) Math.round(right - tw), baseline);
    }

    private static double width(Graphics2D g, String text, FontRenderContext frc) {
        Rectangle2D b = g.getFont().getStringBounds(text, frc);
        return b.getWidth();
    }

    private static void drawFooter(Graphics2D g, Font fFoot, int count, int pageNo) {
        g.setFont(fFoot);
        g.setColor(MUTED);
        int y = PAGE_H - MARGIN_Y;
        g.drawString("एकूण नोंदी: " + count
                     + "  ·  हा अहवाल GATEE Portal वरून स्वयंचलितपणे तयार करण्यात आला आहे."
                     + "  अद्यावत माहितीसाठी पोर्टलवर पहावे: " + WhatsAppConfig.PORTAL_LOGIN_URL,
                     MARGIN_X, y);
    }

    private static void stampPageNumbers(List<BufferedImage> pages, Font base) {
        Font f = base.deriveFont(Font.PLAIN, pt(7.5));
        for (int i = 0; i < pages.size(); i++) {
            Graphics2D g = pages.get(i).createGraphics();
            quality(g);
            g.setFont(f);
            g.setColor(MUTED);
            drawRight(g, "पान " + (i + 1) + " / " + pages.size(),
                      PAGE_W - MARGIN_X, PAGE_H - MARGIN_Y);
            g.dispose();
        }
    }

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
}
