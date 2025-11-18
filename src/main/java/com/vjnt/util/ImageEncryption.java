package com.vjnt.util;

import javax.crypto.Cipher;
import javax.crypto.KeyGenerator;
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.io.*;
import java.security.SecureRandom;
import java.util.Base64;

/**
 * Utility class for encrypting and decrypting image files
 */
public class ImageEncryption {
    
    private static final String ALGORITHM = "AES";
    private static final int KEY_SIZE = 256;
    private static final String SECRET_KEY = "VJNT_IMAGE_SECURITY_KEY_2025_PALAK"; // Fixed key for consistency
    
    /**
     * Get the secret key for encryption/decryption
     */
    private static SecretKey getSecretKey() {
        byte[] decodedKey = new byte[32]; // 256 bits = 32 bytes
        byte[] keyBytes = SECRET_KEY.getBytes();
        System.arraycopy(keyBytes, 0, decodedKey, 0, Math.min(keyBytes.length, decodedKey.length));
        return new SecretKeySpec(decodedKey, 0, decodedKey.length, ALGORITHM);
    }
    
    /**
     * Encrypt a file and save it with .enc extension
     * @param inputFilePath Path to the original image file
     * @param outputFilePath Path where encrypted file will be saved
     * @return true if encryption successful
     */
    public static boolean encryptFile(String inputFilePath, String outputFilePath) {
        try {
            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.ENCRYPT_MODE, getSecretKey());
            
            FileInputStream fis = new FileInputStream(inputFilePath);
            FileOutputStream fos = new FileOutputStream(outputFilePath);
            
            byte[] inputBytes = new byte[1024];
            int bytesRead;
            
            while ((bytesRead = fis.read(inputBytes)) != -1) {
                byte[] outputBytes = cipher.update(inputBytes, 0, bytesRead);
                if (outputBytes != null) {
                    fos.write(outputBytes);
                }
            }
            
            byte[] finalBytes = cipher.doFinal();
            if (finalBytes != null) {
                fos.write(finalBytes);
            }
            
            fis.close();
            fos.close();
            
            // Delete original file after successful encryption
            new File(inputFilePath).delete();
            
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * Decrypt a file and return the decrypted bytes
     * @param encryptedFilePath Path to the encrypted file
     * @return Decrypted file bytes
     */
    public static byte[] decryptFile(String encryptedFilePath) {
        try {
            Cipher cipher = Cipher.getInstance(ALGORITHM);
            cipher.init(Cipher.DECRYPT_MODE, getSecretKey());
            
            FileInputStream fis = new FileInputStream(encryptedFilePath);
            
            byte[] inputBytes = new byte[1024];
            int bytesRead;
            ByteArrayOutputStream baos = new ByteArrayOutputStream();
            
            while ((bytesRead = fis.read(inputBytes)) != -1) {
                byte[] outputBytes = cipher.update(inputBytes, 0, bytesRead);
                if (outputBytes != null) {
                    baos.write(outputBytes);
                }
            }
            
            byte[] finalBytes = cipher.doFinal();
            if (finalBytes != null) {
                baos.write(finalBytes);
            }
            
            fis.close();
            baos.close();
            
            return baos.toByteArray();
        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
    
    /**
     * Get file extension without dot
     */
    public static String getFileExtension(String filename) {
        int lastDot = filename.lastIndexOf('.');
        if (lastDot > 0) {
            return filename.substring(lastDot + 1).toLowerCase();
        }
        return "jpg";
    }
    
    /**
     * Get MIME type based on file extension
     */
    public static String getMimeType(String extension) {
        switch (extension.toLowerCase()) {
            case "jpg":
            case "jpeg":
                return "image/jpeg";
            case "png":
                return "image/png";
            case "gif":
                return "image/gif";
            case "webp":
                return "image/webp";
            default:
                return "image/jpeg";
        }
    }
}
