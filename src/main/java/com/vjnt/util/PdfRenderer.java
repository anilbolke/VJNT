package com.vjnt.util;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.concurrent.Semaphore;
import java.util.concurrent.TimeUnit;

/**
 * Renders HTML to PDF by driving a headless Chromium browser (Edge or Chrome).
 *
 * Why a browser and not a Java PDF library: school names are Devanagari with conjuncts and reordered
 * matras — "शंकर माध्यमिक व उच्च माध्यमिक आश्रम शाळा". Correct output needs real OpenType shaping
 * (GSUB/GPOS). OpenPDF and PDFBox map glyphs through Identity-H but perform no conjunct formation or
 * matra reordering, so Marathi comes out wrong; iText 7 can do it only with the paid pdfCalligraph
 * add-on; openhtmltopdf is weak on Indic. A browser already does it correctly, and this project
 * already builds its reports as Marathi HTML.
 *
 * Verified 2026-08-18 on the UAT machine: all conjuncts shape correctly and the fonts come out
 * embedded and subsetted (FontFile2 / Identity-H / Type0), so the PDF renders the same on a phone
 * that has no Devanagari font installed. The spike lives in
 * "Whatsapp -integrstion/pdf-render-spike.html" — rerun it after any environment change.
 *
 * <p><b>Deployment prerequisite.</b> The host needs a Chromium browser AND a Devanagari font. On
 * Windows both are present (Edge + Nirmala UI). On Linux install chromium and
 * fonts-noto-devanagari — without the font the PDF renders as empty boxes and nothing errors.
 */
public final class PdfRenderer {

    /** Override the browser location per environment: -Dgatee.browser.path=... */
    public static final String BROWSER_PATH_PROPERTY = "gatee.browser.path";

    /**
     * Hard-coded override, checked before everything else. Set this when the server cannot be given a
     * -D flag — Eclipse-launched Tomcat being the obvious case, where editing a constant is far easier
     * than editing the launch configuration.
     *
     * Left empty means "detect automatically". This project keeps configuration in Java constants
     * rather than properties files (see WhatsAppConfig), so this follows the same pattern.
     */
    public static final String CONFIGURED_BROWSER_PATH = "";

    /**
     * Candidates tried in order when nothing is configured. Edge first: it ships with Windows, so it
     * is the one most likely to be present on the UAT and production boxes.
     *
     * Built at class load because several locations depend on environment variables — per-user Chrome
     * installs under LOCALAPPDATA are common and were missing from the original fixed list, and
     * ProgramFiles is not always on C: .
     */
    private static final String[] BROWSER_CANDIDATES = buildCandidates();

    private static String[] buildCandidates() {
        List<String> c = new ArrayList<>();
        // Windows: both Program Files roots, plus per-user installs, which need no admin rights and
        // are therefore what a locked-down machine usually has.
        for (String root : new String[]{ System.getenv("ProgramFiles(x86)"),
                                         System.getenv("ProgramFiles"),
                                         System.getenv("LOCALAPPDATA") }) {
            if (root == null || root.trim().isEmpty()) continue;
            c.add(root + "\\Microsoft\\Edge\\Application\\msedge.exe");
            c.add(root + "\\Google\\Chrome\\Application\\chrome.exe");
            c.add(root + "\\Chromium\\Application\\chrome.exe");
        }
        // Absolute fallbacks, in case the environment variables are absent under a service account.
        c.add("C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe");
        c.add("C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe");
        c.add("C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe");
        c.add("C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe");
        // Linux / container.
        c.add("/usr/bin/chromium");
        c.add("/usr/bin/chromium-browser");
        c.add("/usr/bin/google-chrome");
        c.add("/usr/bin/google-chrome-stable");
        c.add("/usr/bin/microsoft-edge");
        c.add("/snap/bin/chromium");
        return c.toArray(new String[0]);
    }

    /** A browser launch is 1-3s; letting a bulk send fire dozens at once would take the server down. */
    private static final Semaphore RENDER_SLOT = new Semaphore(1, true);

    private static final long ACQUIRE_TIMEOUT_SECONDS = 120;
    private static final long RENDER_TIMEOUT_SECONDS  = 45;

    private PdfRenderer() { }

    /**
     * Render HTML to a PDF file.
     *
     * @param html         complete HTML document, UTF-8; page size and margins come from its own
     *                     {@code @page} CSS
     * @param fileBaseName base name for the output, without extension — this becomes the filename the
     *                     recipient sees in WhatsApp, so it should be self-describing
     * @return the generated PDF. <b>The caller owns it and must delete it</b> once uploaded.
     * @throws IOException if no browser is available, the render times out, or no PDF is produced
     */
    public static File renderToPdf(String html, String fileBaseName) throws IOException {
        String browser = resolveBrowserPath();
        if (browser == null) {
            throw new IOException("No Chromium browser found for PDF rendering. Set -D"
                    + BROWSER_PATH_PROPERTY + " or install Edge/Chrome/Chromium. Tried: "
                    + String.join(", ", BROWSER_CANDIDATES));
        }

        boolean acquired;
        try {
            acquired = RENDER_SLOT.tryAcquire(ACQUIRE_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new IOException("Interrupted waiting for a PDF render slot", e);
        }
        if (!acquired) {
            throw new IOException("Timed out waiting for a PDF render slot (" + ACQUIRE_TIMEOUT_SECONDS + "s)");
        }

        Path workDir = null;
        File htmlFile = null;
        File pdfFile;
        try {
            workDir  = Files.createTempDirectory("gatee-pdf-");
            htmlFile = workDir.resolve("report.html").toFile();
            Files.write(htmlFile.toPath(), html.getBytes(StandardCharsets.UTF_8));

            pdfFile = File.createTempFile(safeBaseName(fileBaseName) + "-", ".pdf");
            runBrowser(browser, workDir, htmlFile, pdfFile);

            if (!pdfFile.isFile() || pdfFile.length() == 0) {
                // A silent empty file is the dangerous failure: it would be uploaded and attached as
                // a blank report. Fail the send instead.
                safeDelete(pdfFile);
                throw new IOException("Browser produced no PDF output (empty file)");
            }
            return pdfFile;

        } finally {
            safeDelete(htmlFile);
            deleteRecursively(workDir);
            RENDER_SLOT.release();
        }
    }

    private static void runBrowser(String browser, Path workDir, File htmlFile, File pdfFile)
            throws IOException {
        List<String> cmd = new ArrayList<>();
        cmd.add(browser);
        cmd.add("--headless");
        cmd.add("--disable-gpu");
        // Own profile per invocation: concurrent runs sharing one profile corrupt each other, and a
        // stale lock in the default profile makes the browser exit without rendering.
        cmd.add("--user-data-dir=" + workDir.resolve("profile").toAbsolutePath());
        cmd.add("--no-first-run");
        cmd.add("--no-default-browser-check");
        cmd.add("--disable-extensions");
        // Both spellings of "no browser-generated date/URL header": the flag was renamed, and an
        // unrecognised flag is ignored, so passing both covers old and new builds.
        cmd.add("--no-pdf-header-footer");
        cmd.add("--print-to-pdf-no-header");
        // Needed when Tomcat runs as root or inside a container; harmless otherwise.
        cmd.add("--no-sandbox");
        cmd.add("--disable-dev-shm-usage");
        cmd.add("--print-to-pdf=" + pdfFile.getAbsolutePath());
        cmd.add(htmlFile.toURI().toString());

        ProcessBuilder pb = new ProcessBuilder(cmd);
        pb.redirectErrorStream(true);
        Process process = pb.start();

        StringBuilder output = new StringBuilder();
        Thread drain = new Thread(() -> {
            // Chromium is chatty on stderr; an undrained pipe can block the process forever.
            try (java.io.BufferedReader r = new java.io.BufferedReader(
                    new java.io.InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = r.readLine()) != null) {
                    if (output.length() < 4000) output.append(line).append('\n');
                }
            } catch (IOException ignored) {
            }
        });
        drain.setDaemon(true);
        drain.start();

        boolean finished;
        try {
            finished = process.waitFor(RENDER_TIMEOUT_SECONDS, TimeUnit.SECONDS);
        } catch (InterruptedException e) {
            process.destroyForcibly();
            Thread.currentThread().interrupt();
            throw new IOException("Interrupted while rendering PDF", e);
        }
        if (!finished) {
            process.destroyForcibly();
            throw new IOException("PDF render timed out after " + RENDER_TIMEOUT_SECONDS + "s");
        }
        if (process.exitValue() != 0) {
            throw new IOException("Browser exited " + process.exitValue() + ": " + output);
        }
    }

    /** Constant, then -D property, then CHROME_PATH, then known locations, then PATH. Null if none. */
    public static String resolveBrowserPath() {
        if (isExecutable(CONFIGURED_BROWSER_PATH)) return CONFIGURED_BROWSER_PATH.trim();

        String configured = System.getProperty(BROWSER_PATH_PROPERTY);
        if (isExecutable(configured)) return configured.trim();

        String fromEnv = System.getenv("CHROME_PATH");
        if (isExecutable(fromEnv)) return fromEnv.trim();

        for (String candidate : BROWSER_CANDIDATES) {
            if (isExecutable(candidate)) return candidate;
        }
        return searchPath();
    }

    /**
     * Last resort: walk PATH looking for a browser executable.
     *
     * Worth having because a server can have Chrome installed somewhere entirely unexpected, and a
     * feature refusing to work when the binary is plainly on PATH is an annoying way to fail.
     */
    private static String searchPath() {
        String path = System.getenv("PATH");
        if (path == null || path.isEmpty()) return null;
        String[] names = File.separatorChar == '\\'
                ? new String[]{ "msedge.exe", "chrome.exe" }
                : new String[]{ "chromium", "chromium-browser", "google-chrome", "microsoft-edge" };

        for (String dir : path.split(File.pathSeparator)) {
            if (dir == null || dir.trim().isEmpty()) continue;
            for (String name : names) {
                File f = new File(dir.trim(), name);
                if (isExecutable(f.getAbsolutePath())) {
                    return f.getAbsolutePath();
                }
            }
        }
        return null;
    }

    /** Cached availability. Detection touches the filesystem and is asked on every console load. */
    private static volatile String cachedPath;
    private static volatile long cachedAt;
    private static final long CACHE_TTL_MS = 30_000;

    /**
     * True when a browser is available, so the console can warn before a send rather than after.
     *
     * Re-checked every 30 seconds rather than cached for the life of the JVM: installing chromium on
     * a server should start working without a Tomcat restart, but a per-call filesystem sweep of
     * ~20 candidate paths on every console load is waste.
     */
    public static boolean isAvailable() {
        long now = System.currentTimeMillis();
        if (cachedAt == 0 || now - cachedAt > CACHE_TTL_MS) {
            cachedPath = resolveBrowserPath();
            cachedAt = now;
        }
        return cachedPath != null;
    }

    /**
     * Why detection succeeded or failed, for the console and the log.
     *
     * A bare "no browser available" is close to useless on someone else's server — this names every
     * location that was tried so the gap is obvious, and can be read without shell access to the box.
     */
    public static String describeAvailability() {
        String found = resolveBrowserPath();
        StringBuilder sb = new StringBuilder();
        if (found != null) {
            sb.append("OK: ").append(found);
            return sb.toString();
        }
        sb.append("No Chromium browser found. Set PdfRenderer.CONFIGURED_BROWSER_PATH or -D")
          .append(BROWSER_PATH_PROPERTY).append(". Tried: ");
        sb.append("[property=").append(String.valueOf(System.getProperty(BROWSER_PATH_PROPERTY)))
          .append("] [CHROME_PATH=").append(String.valueOf(System.getenv("CHROME_PATH"))).append("] ");
        for (String candidate : BROWSER_CANDIDATES) {
            File f = new File(candidate);
            sb.append(candidate).append(f.exists() ? "(exists, not usable) " : "(missing) ");
        }
        return sb.toString();
    }

    /**
     * Whether this path can be launched.
     *
     * Deliberately does NOT require {@link File#canExecute()}: under some Windows service accounts and
     * any restrictive security policy that returns false for a binary the process can in fact run,
     * which made the renderer report itself unavailable on a machine where the browser was sitting
     * right there. Existence is the check that matters; a genuinely unlaunchable binary fails loudly
     * at ProcessBuilder.start() instead, with a real error message.
     *
     * SecurityException is swallowed for the same reason it is caught in the loaders: a sandboxed
     * lookup should skip the candidate, not take down the console.
     */
    private static boolean isExecutable(String path) {
        if (path == null || path.trim().isEmpty()) return false;
        try {
            return new File(path.trim()).isFile();
        } catch (SecurityException e) {
            return false;
        }
    }

    /** Keep filenames to characters that survive a URL path and a Windows filesystem. */
    private static String safeBaseName(String value) {
        if (value == null || value.trim().isEmpty()) return "report";
        String cleaned = value.trim().replaceAll("[^A-Za-z0-9._-]", "_");
        return cleaned.length() > 80 ? cleaned.substring(0, 80) : cleaned;
    }

    private static void safeDelete(File file) {
        if (file != null) {
            try {
                Files.deleteIfExists(file.toPath());
            } catch (IOException ignored) {
            }
        }
    }

    private static void deleteRecursively(Path dir) {
        if (dir == null) return;
        try (java.util.stream.Stream<Path> paths = Files.walk(dir)) {
            paths.sorted(Comparator.reverseOrder()).forEach(p -> {
                try {
                    Files.deleteIfExists(p);
                } catch (IOException ignored) {
                }
            });
        } catch (IOException ignored) {
            // A leftover temp profile is untidy, not harmful; never fail a send over it.
        }
    }
}
