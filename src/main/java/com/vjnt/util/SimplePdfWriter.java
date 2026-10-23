package com.vjnt.util;

import javax.imageio.IIOImage;
import javax.imageio.ImageIO;
import javax.imageio.ImageWriteParam;
import javax.imageio.ImageWriter;
import javax.imageio.stream.MemoryCacheImageOutputStream;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

/**
 * Writes a PDF whose pages are full-page images, with no third-party library.
 *
 * <p>Why images rather than text: the reports are Marathi, and Devanagari needs real complex-script
 * shaping — glyph reordering, matra placement, conjunct formation. The JVM does that correctly via
 * HarfBuzz when Java2D draws a string, so painting to a raster and embedding the raster preserves it
 * exactly. Emitting PDF text operators instead would mean shipping our own shaping engine, and every
 * free Java PDF library that writes text either lacks Devanagari shaping outright or puts it behind a
 * paid add-on. See {@link Java2DReportRenderer}.
 *
 * <p>The trade-off, stated plainly: the text in these PDFs is not selectable or searchable, and the
 * files are larger than a text PDF would be. For a school list read on a phone that is acceptable;
 * for anything that needs machine-readable text it is not.
 *
 * <p>Only the subset of PDF 1.4 needed for this is implemented: a catalogue, a page tree, and one
 * DCTDecode (JPEG) image XObject per page. JPEG is used because its bytes go into the file verbatim —
 * no additional compression step, and no dependency.
 */
public final class SimplePdfWriter {

    /** JPEG quality for page images. 0.82 keeps 9pt Devanagari clean without bloating the file. */
    private static final float JPEG_QUALITY = 0.82f;

    private SimplePdfWriter() { }

    /**
     * Write pages to a PDF file.
     *
     * @param pages      page images, in order; all are drawn to fill their page
     * @param widthPt    page width in PostScript points (A4 landscape = 842)
     * @param heightPt   page height in points (A4 landscape = 595)
     * @param target     file to write
     */
    public static void write(List<BufferedImage> pages, float widthPt, float heightPt, File target)
            throws IOException {
        if (pages == null || pages.isEmpty()) {
            throw new IOException("Refusing to write a PDF with no pages");
        }
        try (OutputStream out = new FileOutputStream(target)) {
            write(pages, widthPt, heightPt, out);
        }
    }

    static void write(List<BufferedImage> pages, float widthPt, float heightPt, OutputStream rawOut)
            throws IOException {
        CountingOutputStream out = new CountingOutputStream(rawOut);

        int pageCount = pages.size();
        // Object numbering: 1 catalogue, 2 page tree, then per page a page, a contents and an image.
        int firstPageObj = 3;
        int objectCount  = 2 + pageCount * 3;

        // offsets[n] = byte offset of object n; index 0 is the unused free entry.
        long[] offsets = new long[objectCount + 1];

        out.write(("%PDF-1.4\n").getBytes(StandardCharsets.US_ASCII));
        // Binary comment so tools treat the file as binary rather than text.
        out.write(new byte[]{ '%', (byte) 0xE2, (byte) 0xE3, (byte) 0xCF, (byte) 0xD3, '\n' });

        // 1: catalogue
        offsets[1] = out.count();
        writeObject(out, 1, "<< /Type /Catalog /Pages 2 0 R >>");

        // 2: page tree
        StringBuilder kids = new StringBuilder();
        for (int i = 0; i < pageCount; i++) {
            if (i > 0) kids.append(' ');
            kids.append(firstPageObj + i * 3).append(" 0 R");
        }
        offsets[2] = out.count();
        writeObject(out, 2, "<< /Type /Pages /Count " + pageCount + " /Kids [" + kids + "] >>");

        for (int i = 0; i < pageCount; i++) {
            BufferedImage image = pages.get(i);
            int pageObj     = firstPageObj + i * 3;
            int contentsObj = pageObj + 1;
            int imageObj    = pageObj + 2;

            offsets[pageObj] = out.count();
            writeObject(out, pageObj,
                    "<< /Type /Page /Parent 2 0 R"
                  + " /MediaBox [0 0 " + trim(widthPt) + " " + trim(heightPt) + "]"
                  + " /Resources << /XObject << /Im0 " + imageObj + " 0 R >> >>"
                  + " /Contents " + contentsObj + " 0 R >>");

            // Draw the image over the whole MediaBox. The cm matrix carries the scale, so the image
            // resolution is free to change without touching anything else.
            byte[] content = ("q\n" + trim(widthPt) + " 0 0 " + trim(heightPt) + " 0 0 cm\n"
                            + "/Im0 Do\nQ\n").getBytes(StandardCharsets.US_ASCII);
            offsets[contentsObj] = out.count();
            writeStreamObject(out, contentsObj, "<< /Length " + content.length + " >>", content);

            byte[] jpeg = toJpeg(image);
            offsets[imageObj] = out.count();
            writeStreamObject(out, imageObj,
                    "<< /Type /XObject /Subtype /Image"
                  + " /Width " + image.getWidth() + " /Height " + image.getHeight()
                  + " /ColorSpace /DeviceRGB /BitsPerComponent 8"
                  + " /Filter /DCTDecode /Length " + jpeg.length + " >>", jpeg);
        }

        long xrefOffset = out.count();
        StringBuilder xref = new StringBuilder();
        xref.append("xref\n0 ").append(objectCount + 1).append('\n');
        xref.append("0000000000 65535 f \n");
        for (int n = 1; n <= objectCount; n++) {
            xref.append(String.format("%010d 00000 n \n", offsets[n]));
        }
        xref.append("trailer\n<< /Size ").append(objectCount + 1).append(" /Root 1 0 R >>\n")
            .append("startxref\n").append(xrefOffset).append("\n%%EOF\n");
        out.write(xref.toString().getBytes(StandardCharsets.US_ASCII));
        out.flush();
    }

    private static void writeObject(CountingOutputStream out, int number, String body)
            throws IOException {
        out.write((number + " 0 obj\n" + body + "\nendobj\n").getBytes(StandardCharsets.US_ASCII));
    }

    private static void writeStreamObject(CountingOutputStream out, int number, String dict,
                                          byte[] data) throws IOException {
        out.write((number + " 0 obj\n" + dict + "\nstream\n").getBytes(StandardCharsets.US_ASCII));
        out.write(data);
        out.write("\nendstream\nendobj\n".getBytes(StandardCharsets.US_ASCII));
    }

    /** Encode as baseline JPEG. TYPE_INT_RGB in, so there is no alpha channel to lose. */
    private static byte[] toJpeg(BufferedImage image) throws IOException {
        Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpeg");
        if (!writers.hasNext()) {
            throw new IOException("No JPEG writer available in this JVM");
        }
        ImageWriter writer = writers.next();
        try {
            ByteArrayOutputStream buffer = new ByteArrayOutputStream(256 * 1024);
            try (MemoryCacheImageOutputStream ios = new MemoryCacheImageOutputStream(buffer)) {
                writer.setOutput(ios);
                ImageWriteParam param = writer.getDefaultWriteParam();
                if (param.canWriteCompressed()) {
                    param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
                    param.setCompressionQuality(JPEG_QUALITY);
                }
                writer.write(null, new IIOImage(image, null, null), param);
                ios.flush();
            }
            return buffer.toByteArray();
        } finally {
            writer.dispose();
        }
    }

    /** Points as short decimals; PDF does not accept exponent notation. */
    private static String trim(float value) {
        if (value == Math.rint(value)) {
            return String.valueOf((long) value);
        }
        return String.format(java.util.Locale.ROOT, "%.2f", value);
    }

    /** Tracks byte offsets, which the xref table needs and OutputStream does not expose. */
    private static final class CountingOutputStream extends OutputStream {
        private final OutputStream target;
        private long count;

        CountingOutputStream(OutputStream target) {
            this.target = target;
        }

        long count() {
            return count;
        }

        @Override public void write(int b) throws IOException {
            target.write(b);
            count++;
        }

        @Override public void write(byte[] b, int off, int len) throws IOException {
            target.write(b, off, len);
            count += len;
        }

        @Override public void flush() throws IOException {
            target.flush();
        }
    }

    /** Convenience for callers holding a single page. */
    public static void writeSingle(BufferedImage page, float widthPt, float heightPt, File target)
            throws IOException {
        List<BufferedImage> one = new ArrayList<>(1);
        one.add(page);
        write(one, widthPt, heightPt, target);
    }
}
