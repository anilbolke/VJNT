package com.vjnt.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.AbstractMap.SimpleEntry;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * VJNT-002 remediation — one-time migration that hashes every legacy
 * plaintext password in the `users` table with BCrypt and forces a reset.
 *
 * Runs once from {@link AppLifecycleListener#contextInitialized}, not from a
 * request-triggered endpoint: an admin-gated "run migration" page is exactly
 * the kind of tool VJNT-003/VJNT-004 flagged for removal, and this needs to
 * run exactly once per environment regardless of who deploys it or whether
 * they remember to click something afterwards.
 *
 * Idempotent by construction — {@code WHERE password NOT LIKE '$2%'} only
 * ever matches rows nothing has hashed yet, so it is safe (and cheap: a
 * single indexed-free table scan that matches nothing) to leave this call in
 * place permanently rather than remove it after first use. A row already
 * migrated is never touched again, so it is not possible for this to
 * double-hash anything.
 *
 * Deliberately does not attempt a "hash in place with the existing value as
 * salt input" approach or any reversible transform — the whole point is that
 * the plaintext is retired, not obfuscated. Every migrated account must
 * change its password at next login (must_change_password = 1); there is no
 * way back to the old value, by design.
 *
 * Runs in a background daemon thread, not inline in contextInitialized:
 * BCrypt at work factor 12 costs roughly a quarter-second per password by
 * design (that cost is the point of BCrypt), so a table with thousands of
 * legacy rows would otherwise hold up Tomcat's startup for minutes. Hashing
 * is parallelised across CPU cores for the same reason. Until a given row is
 * migrated, verifyPassword() fails closed for it (it isn't yet a BCrypt
 * value) — that account's login fails, correctly, rather than falling back
 * to a plaintext comparison. On a large user base that means a window of a
 * few minutes after a fresh deploy where a not-yet-migrated account can't
 * log in; there is no scenario where it can log in on a weaker check.
 */
public final class PasswordMigration {

    private PasswordMigration() {}

    /**
     * Kick off the migration in the background and return immediately —
     * called once from {@link AppLifecycleListener#contextInitialized}.
     */
    public static void hashLegacyPasswordsIfNeeded() {
        if (!PasswordUtil.HASHING_ENABLED) {
            // Toggled off (see PasswordUtil.HASHING_ENABLED) — hashPassword() is
            // currently an identity function, so running this would just set
            // must_change_password on every account for no security benefit.
            System.out.println("[PasswordMigration] PasswordUtil.HASHING_ENABLED is false — skipped.");
            return;
        }
        Thread t = new Thread(() -> {
            try (Connection conn = DatabaseConnection.getConnection()) {
                hashLegacyPasswordsIfNeeded(conn);
            } catch (SQLException e) {
                System.err.println("[PasswordMigration] Skipped — database error: " + e.getMessage());
            } catch (Exception e) {
                System.err.println("[PasswordMigration] Skipped — unexpected error: " + e.getMessage());
            }
        }, "password-migration");
        t.setDaemon(true);
        t.start();
    }

    /**
     * Same migration, synchronous, against a caller-supplied connection —
     * split out from the no-arg entry point above so it can be awaited
     * directly in a test (against a connection that isn't
     * {@link DatabaseConnection}'s, which is hardwired to one environment's
     * credentials at compile time — see VJNT-001) and so the background
     * thread above has a plain blocking call to make. Not called directly by
     * application request-handling code.
     */
    static void hashLegacyPasswordsIfNeeded(Connection conn) throws SQLException {
        Map<Integer, String> legacy = new LinkedHashMap<>();

        // BCrypt hashes always start with "$2" (2a/2b/2y) — anything else
        // here is a legacy plaintext value left over from before VJNT-002.
        try (Statement st = conn.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT user_id, password FROM users " +
                 "WHERE password IS NOT NULL AND password <> '' AND password NOT LIKE '$2%'")) {
            while (rs.next()) {
                legacy.put(rs.getInt("user_id"), rs.getString("password"));
            }
        }

        if (legacy.isEmpty()) {
            System.out.println("[PasswordMigration] No legacy plaintext passwords found — nothing to do.");
            return;
        }

        long started = System.currentTimeMillis();

        // The hashing itself — not the DB round trips — is what's slow (BCrypt
        // is deliberately expensive), and it's pure CPU work with no shared
        // state per entry, so it parallelises cleanly across cores.
        List<Map.Entry<Integer, String>> hashed = legacy.entrySet().parallelStream()
                .map(e -> new SimpleEntry<>(e.getKey(), PasswordUtil.hashPassword(e.getValue())))
                .collect(Collectors.toList());

        int updated = 0;
        try (PreparedStatement ps = conn.prepareStatement(
                "UPDATE users SET password = ?, must_change_password = 1 " +
                "WHERE user_id = ? AND password NOT LIKE '$2%'")) {
            // Re-checking "NOT LIKE '$2%'" in the WHERE clause (not just in the
            // SELECT above) means a row hashed by a concurrent app instance
            // between the SELECT and this UPDATE is left alone rather than
            // double-hashed.
            for (Map.Entry<Integer, String> e : hashed) {
                ps.setString(1, e.getValue());
                ps.setInt(2, e.getKey());
                ps.addBatch();
            }
            int[] counts = ps.executeBatch();
            for (int c : counts) if (c > 0 || c == Statement.SUCCESS_NO_INFO) updated++;
        }

        long tookMs = System.currentTimeMillis() - started;
        System.out.println("[PasswordMigration] Hashed " + updated + " of " + legacy.size()
                + " legacy plaintext password(s) in " + tookMs
                + "ms; those accounts must change their password at next login.");
    }
}
