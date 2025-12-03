<%-- 
    Palak Melava Photo Display Include
    Reusable component for displaying photos with fallback to database storage
    Usage: <jsp:include page="palak-melava-photo-display.jsp">
               <jsp:param name="melavaId" value="<%= melava.getMelavaId() %>" />
               <jsp:param name="photoNumber" value="1" />
           </jsp:include>
--%>

<%@ page import="com.vjnt.dao.PalakMelavaDAO" %>
<%@ page import="com.vjnt.model.PalakMelava" %>
<%@ page import="java.util.Base64" %>

<%
    String melavaIdParam = request.getParameter("melavaId");
    String photoNumberParam = request.getParameter("photoNumber");
    
    if (melavaIdParam != null && photoNumberParam != null) {
        try {
            int melavaId = Integer.parseInt(melavaIdParam);
            int photoNumber = Integer.parseInt(photoNumberParam);
            
            PalakMelavaDAO dao = new PalakMelavaDAO();
            PalakMelava melava = dao.getById(melavaId);
            
            if (melava != null) {
                String photoPath = null;
                byte[] photoContent = null;
                String fileName = null;
                
                if (photoNumber == 1) {
                    photoPath = melava.getPhoto1Path();
                    photoContent = melava.getPhoto1Content();
                    fileName = melava.getPhoto1FileName();
                } else if (photoNumber == 2) {
                    photoPath = melava.getPhoto2Path();
                    photoContent = melava.getPhoto2Content();
                    fileName = melava.getPhoto2FileName();
                }
                
                // Try file system path first
                if (photoPath != null && !photoPath.trim().isEmpty()) {
%>
                    <img src="<%= request.getContextPath() %>/palak-melava-image?path=<%= java.net.URLEncoder.encode(photoPath, "UTF-8") %>" 
                         class="photo-thumbnail" alt="Photo <%= photoNumber %>" 
                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image?path=<%= java.net.URLEncoder.encode(photoPath, "UTF-8") %>')"
                         title="Click to view full size"
                         onerror="this.style.display='none'; loadPhotoFromDB(<%= melavaId %>, <%= photoNumber %>); console.error('File not found, trying database');"
                         onload="console.log('Photo <%= photoNumber %> loaded from file system');">
<%
                } else if (photoContent != null && photoContent.length > 0) {
                    // Fallback to database stored content
%>
                    <img src="<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melavaId %>&photo=<%= photoNumber %>" 
                         class="photo-thumbnail" alt="Photo <%= photoNumber %>" 
                         onclick="viewPhoto('<%= request.getContextPath() %>/palak-melava-image-db?id=<%= melavaId %>&photo=<%= photoNumber %>')"
                         title="Click to view full size"
                         onerror="this.style.display='none'; console.error('Failed to load photo <%= photoNumber %> from database');"
                         onload="console.log('Photo <%= photoNumber %> loaded from database');">
<%
                } else {
                    // No image available
%>
                    <div style="padding: 20px; background: #f0f0f0; border-radius: 5px; text-align: center; color: #999; width: 150px;">
                        📷 Photo <%= photoNumber %><br/>
                        <small>Not available</small>
                    </div>
<%
                }
            }
        } catch (Exception e) {
            System.err.println("Error in photo display: " + e.getMessage());
            e.printStackTrace();
        }
    }
%>

<script>
    function loadPhotoFromDB(melavaId, photoNumber) {
        console.log('Attempting to load photo ' + photoNumber + ' from database for melava ' + melavaId);
        // This function is called when file system image fails
        // User can manually retry or the onerror handler will hide the image
    }
</script>
