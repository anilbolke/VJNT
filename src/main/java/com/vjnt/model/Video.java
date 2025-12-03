package com.vjnt.model;

import java.util.Date;

/**
 * Video Model
 * Represents a video uploaded to YouTube
 */
public class Video {
    
    private int videoId;
    private String title;
    private String description;
    private String youtubeVideoId;
    private String youtubeUrl;
    private String thumbnailUrl;
    private String category; // e.g., "Marathi", "Math", "English", "General"
    private String subCategory; // e.g., "Week 1", "Phase 1", etc.
    private int uploadedBy; // User ID who uploaded
    private String uploaderName;
    private Date uploadDate;
    private int viewCount;
    private String status; // "active", "inactive", "processing"
    
    // Constructors
    public Video() {
    }
    
    public Video(String title, String description, String category) {
        this.title = title;
        this.description = description;
        this.category = category;
    }
    
    // Getters and Setters
    public int getVideoId() {
        return videoId;
    }
    
    public void setVideoId(int videoId) {
        this.videoId = videoId;
    }
    
    public String getTitle() {
        return title;
    }
    
    public void setTitle(String title) {
        this.title = title;
    }
    
    public String getDescription() {
        return description;
    }
    
    public void setDescription(String description) {
        this.description = description;
    }
    
    public String getYoutubeVideoId() {
        return youtubeVideoId;
    }
    
    public void setYoutubeVideoId(String youtubeVideoId) {
        this.youtubeVideoId = youtubeVideoId;
    }
    
    public String getYoutubeUrl() {
        return youtubeUrl;
    }
    
    public void setYoutubeUrl(String youtubeUrl) {
        this.youtubeUrl = youtubeUrl;
    }
    
    public String getThumbnailUrl() {
        return thumbnailUrl;
    }
    
    public void setThumbnailUrl(String thumbnailUrl) {
        this.thumbnailUrl = thumbnailUrl;
    }
    
    public String getCategory() {
        return category;
    }
    
    public void setCategory(String category) {
        this.category = category;
    }
    
    public String getSubCategory() {
        return subCategory;
    }
    
    public void setSubCategory(String subCategory) {
        this.subCategory = subCategory;
    }
    
    public int getUploadedBy() {
        return uploadedBy;
    }
    
    public void setUploadedBy(int uploadedBy) {
        this.uploadedBy = uploadedBy;
    }
    
    public String getUploaderName() {
        return uploaderName;
    }
    
    public void setUploaderName(String uploaderName) {
        this.uploaderName = uploaderName;
    }
    
    public Date getUploadDate() {
        return uploadDate;
    }
    
    public void setUploadDate(Date uploadDate) {
        this.uploadDate = uploadDate;
    }
    
    public int getViewCount() {
        return viewCount;
    }
    
    public void setViewCount(int viewCount) {
        this.viewCount = viewCount;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    @Override
    public String toString() {
        return "Video{" +
                "videoId=" + videoId +
                ", title='" + title + '\'' +
                ", youtubeVideoId='" + youtubeVideoId + '\'' +
                ", category='" + category + '\'' +
                ", uploadDate=" + uploadDate +
                '}';
    }
}
