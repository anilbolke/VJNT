package com.vjnt.util;

import java.security.SecureRandom;

import org.mindrot.jbcrypt.BCrypt;

/**
 * Password Utility Class
 * Handles password hashing and validation.
 *
 * VJNT-002 remediation (see PT POINTS/VJNT-GATEE-Security-Assessment.html): this
 * class used to return the password unchanged from hashPassword() and compare
 * with String.equals() in verifyPassword() — i.e. passwords were stored and
 * checked in plaintext. It now uses BCrypt (work factor 12) — gated behind
 * {@link #HASHING_ENABLED}, currently OFF by request (2026-09-11: "for now I
 * want to use plain text" — production isn't ready for a forced fleet-wide
 * password reset yet).
 *
 * Everything downstream (LoginServlet, ChangePasswordServlet,
 * DistrictProfileServlet, UserDAO, PasswordMigration, ...) calls hashPassword
 * / verifyPassword / isBcryptHash rather than comparing raw strings, so this
 * one flag is the entire toggle — nothing else needs to change to switch
 * back and forth. See PT POINTS/CRITICAL-Remediation-Plan.md for what state
 * each environment's data is actually in right now; the flag does not by
 * itself change what's already stored in any `users` table.
 */
public class PasswordUtil {

    /**
     * Master switch for VJNT-002. true = BCrypt (hashPassword produces a real
     * hash, verifyPassword only accepts a BCrypt hash, PasswordMigration runs
     * at startup). false = the original plaintext behaviour: hashPassword is
     * an identity function and verifyPassword is String.equals() — exactly
     * pre-2026-09-11 behaviour, including its defect (VJNT-002). Overridable
     * without a rebuild via -Dvjnt.password.hashing=true on the server's JVM
     * args; defaults to false (plaintext) until that's set.
     *
     * IMPORTANT: this does not migrate data in either direction. If a
     * database's `users.password` values are already BCrypt hashes (because
     * PasswordMigration ran while this was true) and this is then set back to
     * false, plain-text verification will fail for every one of those rows —
     * restore that table from its pre-hash backup, or leave this true for
     * that specific environment, before flipping it off there.
     */
    public static final boolean HASHING_ENABLED =
            Boolean.parseBoolean(System.getProperty("vjnt.password.hashing", "false"));

    private static final String DEFAULT_PASSWORD = "Pass@123";

    /** BCrypt work factor. 12 is a reasonable balance of cost vs. login latency in 2026. */
    private static final int BCRYPT_ROUNDS = 12;

    /**
     * Get default password for new users
     */
    public static String getDefaultPassword() {
        return DEFAULT_PASSWORD;
    }

    /**
     * Hash a plaintext password with BCrypt (a fresh random salt every call —
     * two calls with the same input never produce the same output, which is
     * expected and correct; use verifyPassword() to check a password against
     * a stored hash, never hashPassword(x).equals(storedHash)).
     */
    public static String hashPassword(String password) {
        if (!HASHING_ENABLED) {
            return password; // legacy behaviour — see HASHING_ENABLED
        }
        return BCrypt.hashpw(password, BCrypt.gensalt(BCRYPT_ROUNDS));
    }

    /**
     * Verify a plaintext password against a stored value — a BCrypt hash when
     * {@link #HASHING_ENABLED}, otherwise a legacy plaintext comparison.
     */
    public static boolean verifyPassword(String password, String storedPassword) {
        if (!HASHING_ENABLED) {
            return password != null && password.equals(storedPassword); // legacy behaviour
        }
        if (password == null || storedPassword == null || !isBcryptHash(storedPassword)) {
            return false;
        }
        try {
            return BCrypt.checkpw(password, storedPassword);
        } catch (IllegalArgumentException e) {
            // Malformed hash — fail closed.
            return false;
        }
    }

    /**
     * True if the given stored value is already a BCrypt hash (as opposed to
     * a legacy plaintext value, or null/empty). BCrypt hashes always start
     * with one of these version prefixes and are 60 characters long.
     *
     * Used by {@link PasswordMigration} to skip rows already migrated (so the
     * migration is idempotent and safe to run on every startup), and by
     * {@link com.vjnt.dao.UserDAO#updateUser} to tell "an admin is setting a
     * new plaintext password" apart from "this User object was fetched from
     * the DB and its (already-hashed) password field was never touched" —
     * without that check, editing a user's profile without changing their
     * password would re-hash the existing hash and lock them out.
     */
    public static boolean isBcryptHash(String value) {
        return value != null && value.length() == 60
                && (value.startsWith("$2a$") || value.startsWith("$2b$") || value.startsWith("$2y$"));
    }

    /**
     * Validate password strength
     * Rules: Min 8 chars, at least 1 uppercase, 1 lowercase, 1 digit, 1 special char
     */
    public static boolean isValidPassword(String password) {
        if (password == null || password.length() < 8) {
            return false;
        }

        boolean hasUpper = false;
        boolean hasLower = false;
        boolean hasDigit = false;
        boolean hasSpecial = false;

        for (char c : password.toCharArray()) {
            if (Character.isUpperCase(c)) hasUpper = true;
            else if (Character.isLowerCase(c)) hasLower = true;
            else if (Character.isDigit(c)) hasDigit = true;
            else hasSpecial = true;
        }

        return hasUpper && hasLower && hasDigit && hasSpecial;
    }

    /**
     * Generate username from name or ID
     */
    public static String generateUsername(String prefix, String identifier) {
        return (prefix + "_" + identifier).toLowerCase().replaceAll("\\s+", "_");
    }

    private static final String TEMP_PW_UPPER = "ABCDEFGHJKLMNPQRSTUVWXYZ";   // no I/O — avoids 0/O, 1/I confusion
    private static final String TEMP_PW_LOWER = "abcdefghijkmnopqrstuvwxyz";
    private static final String TEMP_PW_DIGIT = "23456789";
    private static final String TEMP_PW_SPECIAL = "@#%*+=";
    private static final SecureRandom RNG = new SecureRandom();

    /**
     * Generate a one-time, human-typeable temporary password: satisfies
     * {@link #isValidPassword} by construction (one char from each required
     * class, guaranteed, rest random) and avoids visually ambiguous
     * characters (0/O, 1/I/l) since it is meant to be read off a WhatsApp
     * message and typed on a phone keyboard. Used for admin/self-service
     * resets — the caller must hash it before storing and must set
     * must_change_password so it cannot become a long-lived credential.
     */
    public static String generateTempPassword() {
        String all = TEMP_PW_UPPER + TEMP_PW_LOWER + TEMP_PW_DIGIT + TEMP_PW_SPECIAL;
        char[] pw = new char[10];
        pw[0] = TEMP_PW_UPPER.charAt(RNG.nextInt(TEMP_PW_UPPER.length()));
        pw[1] = TEMP_PW_LOWER.charAt(RNG.nextInt(TEMP_PW_LOWER.length()));
        pw[2] = TEMP_PW_DIGIT.charAt(RNG.nextInt(TEMP_PW_DIGIT.length()));
        pw[3] = TEMP_PW_SPECIAL.charAt(RNG.nextInt(TEMP_PW_SPECIAL.length()));
        for (int i = 4; i < pw.length; i++) {
            pw[i] = all.charAt(RNG.nextInt(all.length()));
        }
        // Shuffle so the required-class characters aren't always in the same 4 positions.
        for (int i = pw.length - 1; i > 0; i--) {
            int j = RNG.nextInt(i + 1);
            char tmp = pw[i]; pw[i] = pw[j]; pw[j] = tmp;
        }
        return new String(pw);
    }
}
