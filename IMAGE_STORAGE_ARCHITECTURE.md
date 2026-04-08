# Image Storage & Display - Current Architecture

## 📊 Current Image Storage Location

### **WHERE Images Are Stored:**

**Database: MySQL/MariaDB**
- **Table:** `palak_melava`
- **Columns:** 
  - `photo_1_content` - BLOB (binary data for image 1)
  - `photo_2_content` - BLOB (binary data for image 2)
  - `photo_1_filename` - VARCHAR (original filename)
  - `photo_2_filename` - VARCHAR (original filename)
  - `photo_1_path` - VARCHAR (path info)
  - `photo_2_path` - VARCHAR (path info)

**Also stored in `other_school_activity` table:**
- `photo_1_content` - BLOB
- `photo_2_content` - BLOB
- `photo_1_filename` - VARCHAR
- `photo_2_filename` - VARCHAR

### **Data Flow Diagram:**

```
Database (Images as BLOB)
        ↓
PalakMelavaDAO.getById()
        ↓
extractFromResultSet() → byte[] photo1Content = rs.getBytes("photo_1_content")
        ↓
PalakMelava object loaded with image bytes
        ↓
PublicSchoolLookupServlet fetches data
        ↓
JSON includes: hasPhoto1: true, hasPhoto2: true (flags only)
        ↓
HTML renders: <img src="/public-school-image?type=palak_melava&id=1&photo=1">
        ↓
Browser requests image from PublicSchoolImageServlet
        ↓
PublicSchoolImageServlet.doGet()
        ↓
PalakMelavaDAO.getById(id) → retrieves BLOB bytes again
        ↓
response.getOutputStream().write(imageBytes)
        ↓
Browser displays image ✅
```

## 🔄 Current Image Display Process

### **Step 1: School Details Request**
```
GET /public-school-lookup?udise=27150201202
```

**PublicSchoolLookupServlet:**
1. Calls `melavaDAO.getByUdise(udiseNo)` 
2. DAO retrieves all Palak Melava records from database
3. For each record, `extractFromResultSet()` loads:
   - `melava.setPhoto1Content(rs.getBytes("photo_1_content"))`
   - `melava.setPhoto2Content(rs.getBytes("photo_2_content"))`
4. Servlet builds JSON response with **flags only** (hasPhoto1, hasPhoto2)
   - NOT including actual image bytes in JSON (would be huge!)
5. HTML page renders with image URLs

### **Step 2: Image Request**
```
GET /public-school-image?type=palak_melava&id=1&photo=1
```

**PublicSchoolImageServlet:**
1. Receives image request with ID and photo number
2. Calls `melavaDAO.getById(id)` to fetch record from DB
3. DAO retrieves BLOB: `byte[] photoContent = rs.getBytes("photo_1_content")`
4. Sets response headers:
   - `Content-Type: image/jpeg`
   - `Content-Length: bytes`
5. Writes image bytes to response: `out.write(imageData)`
6. Browser displays image

## 📁 Image Files Structure

### **In Database:**
```
palak_melava table:
├── melava_id (Primary Key)
├── udise_no
├── meeting_date
├── chief_attendee_info
├── total_parents_attended
├── photo_1_path (VARCHAR - file path or folder)
├── photo_2_path (VARCHAR - file path or folder)
├── photo_1_content (BLOB - actual image bytes) ⭐
├── photo_2_content (BLOB - actual image bytes) ⭐
├── photo_1_filename (VARCHAR - original filename like "IMG_001.jpg")
├── photo_2_filename (VARCHAR - original filename)
├── status (APPROVED, DRAFT, PENDING_APPROVAL)
└── ... (other fields)
```

### **Image Properties:**
- **Format:** JPEG (image/jpeg)
- **Storage Type:** BLOB (Binary Large Object)
- **Size:** Varies (typically 1-10 MB per image)
- **Retrieval:** Via SQL query with rs.getBytes()

## 🎯 Current Display Behavior

### **What's Shown:**
1. ✅ Palak Melava photos
   - If `photo_1_content` IS NOT NULL → Show photo 1
   - If `photo_2_content` IS NOT NULL → Show photo 2
2. ✅ Activity photos (same logic for other_school_activity table)

### **Current HTML:**
```html
<img src="/VJNT_Class_Managment/public-school-image?type=palak_melava&id=1&photo=1">
```

### **Responsive Layout:**
- Desktop: 2 images side by side (grid)
- Mobile: Images stack vertically
- Size: 150px height, object-fit: cover

## 🚀 Alternative Storage Options

### **Option 1: File System (Current + Alternative)**
- Store images on disk: `/uploads/palak_melava/1/photo1.jpg`
- Store path in DB: `photo_1_path = "/uploads/palak_melava/1/photo1.jpg"`
- Serve from FileServlet instead of PublicSchoolImageServlet
- Pros: Faster, less DB load, easier backups
- Cons: Disk space needed on server

### **Option 2: Base64 Encoding (Current Alternative)**
- Convert BLOB to Base64 string
- Embed directly in JSON response: `photo1: "data:image/jpeg;base64,/9j/4AAQ..."`
- No separate image requests needed
- Pros: Single request for all data
- Cons: Larger JSON, slower initial load, harder to cache

### **Option 3: Cloud Storage (Alternative)**
- AWS S3, Google Cloud Storage, Azure Blob
- Store images in cloud
- Store URL in DB: `photo_1_path = "https://bucket.s3.amazonaws.com/photo1.jpg"`
- Serve directly from cloud URL
- Pros: Scalable, CDN included
- Cons: External dependency, costs

### **Option 4: File System + Cache (Alternative)**
- Store on disk with caching headers
- Browser caches images, reduces server load
- Fast serving for repeat views
- Pros: Best performance
- Cons: Cache invalidation complexity

## ❓ What Would You Like to Change?

**Please choose from:**

1. **Keep BLOB (Current)** - Working well, no changes needed
2. **Switch to File System** - Save images as files on disk
3. **Use Base64 in JSON** - Embed images directly in JSON response
4. **Add Cloud Storage** - Store in AWS S3 or similar
5. **Add Image Caching** - Improve performance with better caching
6. **Custom approach** - Something else?

**What's your preference?** I can implement any of these immediately!
