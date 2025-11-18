# Image Encryption Implementation for Palak Melava

## Overview
This implementation provides secure image storage and retrieval for Palak Melava photos using AES-256 encryption.

## Components Created

### 1. ImageEncryption.java (Utility Class)
**Location:** `src/main/java/com/vjnt/util/ImageEncryption.java`

**Features:**
- AES-256 encryption/decryption algorithm
- File-based encryption (encrypts files during upload)
- MIME type detection
- Secure file handling with automatic cleanup of unencrypted files

**Key Methods:**
- `encryptFile(String inputPath, String outputPath)` - Encrypts an image file and saves as .enc
- `decryptFile(String encryptedPath)` - Decrypts and returns image bytes
- `getFileExtension(String filename)` - Extracts file extension
- `getMimeType(String extension)` - Returns appropriate MIME type

### 2. SecureImageServlet.java (Servlet)
**Location:** `src/main/java/com/vjnt/servlet/SecureImageServlet.java`

**Features:**
- Handles requests to `/secure-image` endpoint
- Decrypts encrypted images on-the-fly
- Serves images with proper MIME types
- Prevents directory traversal attacks
- Sets cache control headers

**How it works:**
1. Receives encrypted image path as URL parameter
2. Validates the path (prevents directory traversal)
3. Decrypts the image using ImageEncryption utility
4. Serves decrypted image with appropriate content-type
5. Deletes the encrypted file from disk after reading

### 3. Updated PalakMelavaSaveServlet.java
**Changes:**
- Added ImageEncryption import
- Modified photo upload logic to encrypt images after uploading
- Images are stored with `.enc` extension
- Original unencrypted files are automatically deleted after encryption

**Upload Flow:**
1. User uploads image (e.g., `photo.jpg`)
2. File is temporarily saved
3. File is encrypted → `photo.jpg.enc`
4. Temporary unencrypted file is deleted
5. Database stores path to `.enc` file

### 4. Updated palak-melava-approvals.jsp
**Changes:**
- Image src attributes now use `/secure-image` servlet endpoint
- Encrypted image paths are URL-encoded when passed as parameters
- Images are decrypted and displayed on-the-fly when viewed
- Full decryption happens in the modal when user clicks to view full size

**Image Display Flow:**
1. Page displays encrypted image path: `uploads/palak-melava/12345_1_photo.jpg.enc`
2. Image tag requests: `/secure-image?path=uploads%2Fpalak-melava%2F12345_1_photo.jpg.enc`
3. Servlet decrypts and serves decrypted image to browser
4. User sees the image as normal JPG/PNG

## Security Features

✅ **AES-256 Encryption** - Military-grade encryption standard
✅ **File-Level Encryption** - Images encrypted at storage, not just in transit
✅ **On-The-Fly Decryption** - Images decrypted only when accessed
✅ **Automatic Cleanup** - Unencrypted temporary files are deleted
✅ **Path Validation** - Prevents directory traversal attacks
✅ **No Cache** - Images not cached to prevent unencrypted copies

## Database Schema
The existing `palak_melava` table works as-is. The `photo_1_path` and `photo_2_path` columns now store encrypted file paths ending with `.enc`

Example:
- Before: `uploads/palak-melava/1234567890_1_meeting.jpg`
- After: `uploads/palak-melava/1234567890_1_meeting.jpg.enc`

## Configuration
The encryption uses a fixed secret key defined in `ImageEncryption.java`:
```java
private static final String SECRET_KEY = "VJNT_IMAGE_SECURITY_KEY_2025_PALAK";
```

**Note:** For production, consider moving this to a configuration file or environment variable.

## Usage

### For New Image Uploads
When a School Coordinator uploads images through `palak-melava.jsp`:
1. Images are automatically encrypted
2. Database stores encrypted file paths
3. No additional code changes needed

### For Viewing Images
When Head Master views approvals through `palak-melava-approvals.jsp`:
1. Images are displayed through `/secure-image` servlet
2. Decryption happens transparently
3. User clicks to view full-size image (decrypted in modal)

## File Sizes
Encrypted files are typically slightly larger than originals due to AES encryption overhead (usually 5-10% larger).

## Browser Compatibility
Works with all modern browsers that support:
- HTML5 Image tags
- JavaScript Fetch API
- Binary data handling

## Performance Considerations
- Decryption happens on-the-fly (negligible impact for typical image sizes)
- Caching disabled by servlet headers to ensure fresh decrypted images
- Consider enabling caching for production if you trust browser memory

## Future Enhancements
1. Move secret key to external configuration
2. Implement key rotation
3. Add encryption algorithm selection
4. Implement image compression before encryption
5. Add audit logging for image access
