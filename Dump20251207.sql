-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
--
-- Host: localhost    Database: vjnt_class_management
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `language_level_audit`
--

DROP TABLE IF EXISTS `language_level_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `language_level_audit` (
  `audit_id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `phase` int NOT NULL,
  `action_type` varchar(50) DEFAULT NULL,
  `marathi_level_old` int DEFAULT NULL,
  `marathi_level_new` int DEFAULT NULL,
  `math_level_old` int DEFAULT NULL,
  `math_level_new` int DEFAULT NULL,
  `english_level_old` int DEFAULT NULL,
  `english_level_new` int DEFAULT NULL,
  `changed_by` varchar(100) DEFAULT NULL,
  `changed_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`audit_id`),
  KEY `student_id` (`student_id`),
  CONSTRAINT `language_level_audit_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `login_audit`
--

DROP TABLE IF EXISTS `login_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `login_audit` (
  `audit_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `login_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `logout_time` datetime DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `session_id` varchar(100) DEFAULT NULL,
  `login_status` enum('SUCCESS','FAILED','LOCKED') NOT NULL,
  `failure_reason` varchar(255) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`audit_id`),
  KEY `idx_user_id` (`user_id`),
  KEY `idx_login_time` (`login_time`),
  KEY `idx_login_status` (`login_status`),
  CONSTRAINT `login_audit_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `palak_melava`
--

DROP TABLE IF EXISTS `palak_melava`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `palak_melava` (
  `melava_id` int NOT NULL AUTO_INCREMENT,
  `udise_no` varchar(20) NOT NULL,
  `school_name` varchar(255) DEFAULT NULL,
  `meeting_date` date NOT NULL,
  `chief_attendee_info` text NOT NULL,
  `total_parents_attended` varchar(100) NOT NULL,
  `photo_1_path` varchar(500) DEFAULT NULL,
  `photo_1_content` longblob,
  `photo_1_filename` varchar(255) DEFAULT NULL,
  `photo_2_path` varchar(500) DEFAULT NULL,
  `photo_2_content` longblob,
  `photo_2_filename` varchar(255) DEFAULT NULL,
  `status` enum('DRAFT','PENDING_APPROVAL','APPROVED','REJECTED') DEFAULT 'DRAFT',
  `submitted_by` varchar(100) DEFAULT NULL,
  `submitted_date` datetime DEFAULT NULL,
  `approval_status` varchar(20) DEFAULT NULL,
  `approved_by` varchar(100) DEFAULT NULL,
  `approval_date` datetime DEFAULT NULL,
  `approval_remarks` text,
  `rejection_reason` text,
  `created_by` varchar(100) DEFAULT NULL,
  `created_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`melava_id`),
  KEY `idx_palak_melava_udise` (`udise_no`),
  KEY `idx_palak_melava_status` (`status`),
  KEY `idx_palak_melava_date` (`meeting_date`),
  CONSTRAINT `palak_melava_ibfk_1` FOREIGN KEY (`udise_no`) REFERENCES `schools` (`udise_no`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phase_approvals`
--

DROP TABLE IF EXISTS `phase_approvals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `phase_approvals` (
  `approval_id` int NOT NULL AUTO_INCREMENT,
  `udise_no` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phase_number` int NOT NULL,
  `completed_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `completed_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `completion_remarks` text COLLATE utf8mb4_unicode_ci,
  `approval_status` enum('PENDING','APPROVED','REJECTED') COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `approved_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approved_date` datetime DEFAULT NULL,
  `approval_remarks` text COLLATE utf8mb4_unicode_ci,
  `total_students` int DEFAULT '0',
  `completed_students` int DEFAULT '0',
  `pending_students` int DEFAULT '0',
  `ignored_students` int DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`approval_id`),
  UNIQUE KEY `unique_phase_approval` (`udise_no`,`phase_number`),
  KEY `idx_udise` (`udise_no`),
  KEY `idx_status` (`approval_status`),
  KEY `idx_phase` (`phase_number`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `phase_completion_status`
--

DROP TABLE IF EXISTS `phase_completion_status`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `phase_completion_status` (
  `id` int NOT NULL AUTO_INCREMENT,
  `udise_no` varchar(50) NOT NULL,
  `phase` int NOT NULL,
  `is_complete` tinyint(1) DEFAULT '0',
  `completion_date` timestamp NULL DEFAULT NULL,
  `completed_by` varchar(100) DEFAULT NULL,
  `total_students` int DEFAULT '0',
  `completed_students` int DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_school_phase` (`udise_no`,`phase`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `report_approvals`
--

DROP TABLE IF EXISTS `report_approvals`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `report_approvals` (
  `approval_id` int NOT NULL AUTO_INCREMENT,
  `report_type` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pen_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `class` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `section` varchar(5) COLLATE utf8mb4_unicode_ci NOT NULL,
  `udise_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `school_name` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `division` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `requested_by` int NOT NULL,
  `requested_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `approval_status` enum('PENDING','APPROVED','REJECTED') COLLATE utf8mb4_unicode_ci DEFAULT 'PENDING',
  `approved_by` int DEFAULT NULL,
  `approval_date` timestamp NULL DEFAULT NULL,
  `approval_remarks` text COLLATE utf8mb4_unicode_ci,
  `report_generated` tinyint(1) DEFAULT '0',
  `generated_date` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`approval_id`),
  KEY `idx_pen` (`pen_number`),
  KEY `idx_udise` (`udise_code`),
  KEY `idx_status` (`approval_status`),
  KEY `idx_requested_by` (`requested_by`),
  KEY `idx_approved_by` (`approved_by`),
  CONSTRAINT `report_approvals_ibfk_1` FOREIGN KEY (`requested_by`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  CONSTRAINT `report_approvals_ibfk_2` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `school_contacts`
--

DROP TABLE IF EXISTS `school_contacts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `school_contacts` (
  `contact_id` int NOT NULL AUTO_INCREMENT,
  `udise_no` varchar(50) NOT NULL,
  `school_name` varchar(255) DEFAULT NULL,
  `district_name` varchar(100) NOT NULL,
  `contact_type` varchar(50) NOT NULL,
  `full_name` varchar(200) NOT NULL,
  `mobile` varchar(15) NOT NULL,
  `whatsapp_number` varchar(15) DEFAULT NULL,
  `remarks` text,
  `created_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_by` varchar(100) DEFAULT NULL,
  `updated_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`contact_id`),
  KEY `idx_udise` (`udise_no`),
  KEY `idx_district` (`district_name`),
  KEY `idx_contact_type` (`contact_type`),
  KEY `idx_mobile` (`mobile`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `schools`
--

DROP TABLE IF EXISTS `schools`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `schools` (
  `school_id` int NOT NULL AUTO_INCREMENT,
  `udise_no` varchar(50) NOT NULL,
  `school_name` varchar(255) NOT NULL,
  `district_name` varchar(100) DEFAULT NULL,
  `created_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_by` varchar(100) DEFAULT NULL,
  `updated_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`school_id`),
  UNIQUE KEY `udise_no` (`udise_no`),
  KEY `idx_udise` (`udise_no`),
  KEY `idx_district` (`district_name`),
  KEY `idx_school_name` (`school_name`)
) ENGINE=InnoDB AUTO_INCREMENT=75963 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_language_phase`
--

DROP TABLE IF EXISTS `student_language_phase`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_language_phase` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `phase` int NOT NULL,
  `marathi_level` int DEFAULT '0',
  `math_level` int DEFAULT '0',
  `english_level` int DEFAULT '0',
  `created_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `created_by` varchar(100) DEFAULT NULL,
  `updated_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_student_phase` (`student_id`,`phase`),
  CONSTRAINT `student_language_phase_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_phase_audit`
--

DROP TABLE IF EXISTS `student_phase_audit`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_phase_audit` (
  `audit_id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `phase` int NOT NULL,
  `marathi_level` int DEFAULT NULL,
  `math_level` int DEFAULT NULL,
  `english_level` int DEFAULT NULL,
  `changed_by` varchar(100) DEFAULT NULL,
  `changed_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `action_type` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`audit_id`),
  KEY `idx_student_phase` (`student_id`,`phase`),
  KEY `idx_date` (`changed_date`),
  CONSTRAINT `student_phase_audit_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`)
) ENGINE=InnoDB AUTO_INCREMENT=334 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `student_weekly_activities`
--

DROP TABLE IF EXISTS `student_weekly_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `student_weekly_activities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `student_id` int NOT NULL,
  `student_pen` varchar(50) NOT NULL,
  `udise_no` varchar(50) NOT NULL,
  `student_class` varchar(10) NOT NULL,
  `section` varchar(5) NOT NULL,
  `student_name` varchar(200) NOT NULL,
  `language` varchar(20) NOT NULL,
  `week_number` int NOT NULL,
  `day_number` int NOT NULL,
  `activity_text` text NOT NULL,
  `activity_identifier` varchar(100) NOT NULL DEFAULT '',
  `activity_count` int DEFAULT '1',
  `completed` tinyint(1) DEFAULT '0',
  `completed_date` datetime DEFAULT NULL,
  `assigned_by` varchar(200) DEFAULT NULL,
  `assigned_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_student` (`student_id`),
  KEY `idx_student_pen` (`student_pen`),
  KEY `idx_udise_class_section` (`udise_no`,`student_class`,`section`),
  KEY `idx_language_week` (`language`,`week_number`),
  KEY `idx_completed` (`completed`),
  KEY `idx_activity_identifier` (`student_id`,`language`,`week_number`,`day_number`,`activity_identifier`),
  CONSTRAINT `student_weekly_activities_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `students`
--

DROP TABLE IF EXISTS `students`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `students` (
  `student_id` int NOT NULL AUTO_INCREMENT,
  `division` varchar(100) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `udise_no` varchar(50) DEFAULT NULL,
  `class` varchar(10) DEFAULT NULL,
  `section` varchar(10) DEFAULT NULL,
  `class_category` varchar(50) DEFAULT NULL,
  `student_name` varchar(200) NOT NULL,
  `gender` enum('Male','Female','Other','?????','??????','???') DEFAULT NULL,
  `student_pen` varchar(50) DEFAULT NULL,
  `marathi_level` varchar(50) DEFAULT NULL,
  `math_level` varchar(50) DEFAULT NULL,
  `english_level` varchar(50) DEFAULT NULL,
  `created_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_by` varchar(100) DEFAULT 'SYSTEM',
  `updated_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  `marathi_akshara_level` int DEFAULT '0' COMMENT '????? ????????? (???? ? ????)',
  `marathi_shabda_level` int DEFAULT '0' COMMENT '???? ????????? (???? ? ????)',
  `marathi_vakya_level` int DEFAULT '0' COMMENT '????? ?????????',
  `marathi_samajpurvak_level` int DEFAULT '0' COMMENT '????????? ???? ???? ?????????',
  `math_akshara_level` int DEFAULT '0' COMMENT '???? - ????? ????',
  `math_shabda_level` int DEFAULT '0' COMMENT '???? - ???? ????',
  `math_vakya_level` int DEFAULT '0' COMMENT '???? - ????? ????',
  `math_samajpurvak_level` int DEFAULT '0' COMMENT '???? - ????????? ????',
  `english_akshara_level` int DEFAULT '0' COMMENT 'English - Letter Level',
  `english_shabda_level` int DEFAULT '0' COMMENT 'English - Word Level',
  `english_vakya_level` int DEFAULT '0' COMMENT 'English - Sentence Level',
  `english_samajpurvak_level` int DEFAULT '0' COMMENT 'English - Comprehension Level',
  `phase1_marathi` int DEFAULT NULL,
  `phase1_math` int DEFAULT NULL,
  `phase1_english` int DEFAULT NULL,
  `phase1_date` timestamp NULL DEFAULT NULL,
  `phase2_marathi` int DEFAULT NULL,
  `phase2_math` int DEFAULT NULL,
  `phase2_english` int DEFAULT NULL,
  `phase2_date` timestamp NULL DEFAULT NULL,
  `phase3_marathi` int DEFAULT NULL,
  `phase3_math` int DEFAULT NULL,
  `phase3_english` int DEFAULT NULL,
  `phase3_date` timestamp NULL DEFAULT NULL,
  `phase4_marathi` int DEFAULT NULL,
  `phase4_math` int DEFAULT NULL,
  `phase4_english` int DEFAULT NULL,
  `phase4_date` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`student_id`),
  KEY `idx_division` (`division`),
  KEY `idx_district` (`district`),
  KEY `idx_udise` (`udise_no`),
  KEY `idx_class` (`class`),
  KEY `idx_student_pen` (`student_pen`),
  KEY `idx_marathi_levels` (`marathi_akshara_level`,`marathi_shabda_level`,`marathi_vakya_level`,`marathi_samajpurvak_level`),
  KEY `idx_math_levels` (`math_akshara_level`,`math_shabda_level`,`math_vakya_level`,`math_samajpurvak_level`),
  KEY `idx_english_levels` (`english_akshara_level`,`english_shabda_level`,`english_vakya_level`,`english_samajpurvak_level`)
) ENGINE=InnoDB AUTO_INCREMENT=215791 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `teacher_assignments`
--

DROP TABLE IF EXISTS `teacher_assignments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teacher_assignments` (
  `assignment_id` int NOT NULL AUTO_INCREMENT,
  `udise_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `district` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `division` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `teacher_id` int NOT NULL,
  `teacher_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `class` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `section` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subjects_assigned` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by` int DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`assignment_id`),
  KEY `idx_udise` (`udise_code`),
  KEY `idx_teacher` (`teacher_id`),
  KEY `idx_class_section` (`class`,`section`),
  KEY `idx_active` (`is_active`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `teacher_assignments_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`teacher_id`) ON DELETE CASCADE,
  CONSTRAINT `teacher_assignments_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `teachers`
--

DROP TABLE IF EXISTS `teachers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `teachers` (
  `teacher_id` int NOT NULL AUTO_INCREMENT,
  `udise_code` varchar(20) NOT NULL,
  `teacher_name` varchar(100) NOT NULL,
  `mobile_number` varchar(10) NOT NULL,
  `subjects_taught` varchar(255) NOT NULL,
  `description` text,
  `created_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `created_by` int DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '1',
  PRIMARY KEY (`teacher_id`),
  KEY `idx_udise` (`udise_code`),
  KEY `idx_mobile` (`mobile_number`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `user_type` enum('DIVISION','DISTRICT_COORDINATOR','DISTRICT_2ND_COORDINATOR','SCHOOL_COORDINATOR','HEAD_MASTER','DATA_ADMIN') NOT NULL,
  `division_name` varchar(100) DEFAULT NULL,
  `district_name` varchar(100) DEFAULT NULL,
  `udise_no` varchar(50) DEFAULT NULL,
  `is_first_login` tinyint(1) DEFAULT '1',
  `password_changed_date` datetime DEFAULT NULL,
  `must_change_password` tinyint(1) DEFAULT '1',
  `is_active` tinyint(1) DEFAULT '1',
  `created_date` datetime DEFAULT CURRENT_TIMESTAMP,
  `created_by` varchar(100) DEFAULT NULL,
  `last_login_date` datetime DEFAULT NULL,
  `failed_login_attempts` int DEFAULT '0',
  `account_locked` tinyint(1) DEFAULT '0',
  `locked_date` datetime DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `mobile` varchar(15) DEFAULT NULL,
  `full_name` varchar(200) DEFAULT NULL,
  `updated_date` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `updated_by` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `username` (`username`),
  KEY `idx_username` (`username`),
  KEY `idx_user_type` (`user_type`),
  KEY `idx_division` (`division_name`),
  KEY `idx_district` (`district_name`),
  KEY `idx_udise` (`udise_no`),
  KEY `idx_active` (`is_active`)
) ENGINE=InnoDB AUTO_INCREMENT=2366 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `video_views`
--

DROP TABLE IF EXISTS `video_views`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `video_views` (
  `view_id` int NOT NULL AUTO_INCREMENT,
  `video_id` int NOT NULL,
  `student_id` int DEFAULT NULL,
  `viewer_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ip_address` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `view_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`view_id`),
  KEY `idx_video_id` (`video_id`),
  KEY `idx_view_date` (`view_date`),
  CONSTRAINT `video_views_ibfk_1` FOREIGN KEY (`video_id`) REFERENCES `videos` (`video_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `videos`
--

DROP TABLE IF EXISTS `videos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `videos` (
  `video_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` longtext COLLATE utf8mb4_unicode_ci,
  `youtube_video_id` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `youtube_url` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `thumbnail_url` varchar(500) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `category` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sub_category` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uploaded_by` int DEFAULT NULL,
  `uploader_name` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `upload_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `view_count` int DEFAULT '0',
  `status` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT 'active',
  PRIMARY KEY (`video_id`),
  UNIQUE KEY `youtube_video_id` (`youtube_video_id`),
  KEY `idx_category` (`category`),
  KEY `idx_sub_category` (`sub_category`),
  KEY `idx_status` (`status`),
  KEY `idx_upload_date` (`upload_date`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary view structure for view `vw_active_users_summary`
--

DROP TABLE IF EXISTS `vw_active_users_summary`;
/*!50001 DROP VIEW IF EXISTS `vw_active_users_summary`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_active_users_summary` AS SELECT 
 1 AS `user_type`,
 1 AS `total_users`,
 1 AS `active_users`,
 1 AS `pending_first_login`,
 1 AS `locked_accounts`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_district_users`
--

DROP TABLE IF EXISTS `vw_district_users`;
/*!50001 DROP VIEW IF EXISTS `vw_district_users`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_district_users` AS SELECT 
 1 AS `user_id`,
 1 AS `username`,
 1 AS `user_type`,
 1 AS `district_name`,
 1 AS `division_name`,
 1 AS `is_active`,
 1 AS `is_first_login`,
 1 AS `last_login_date`,
 1 AS `created_date`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_division_users`
--

DROP TABLE IF EXISTS `vw_division_users`;
/*!50001 DROP VIEW IF EXISTS `vw_division_users`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_division_users` AS SELECT 
 1 AS `user_id`,
 1 AS `username`,
 1 AS `division_name`,
 1 AS `is_active`,
 1 AS `is_first_login`,
 1 AS `last_login_date`,
 1 AS `created_date`*/;
SET character_set_client = @saved_cs_client;

--
-- Temporary view structure for view `vw_school_users`
--

DROP TABLE IF EXISTS `vw_school_users`;
/*!50001 DROP VIEW IF EXISTS `vw_school_users`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `vw_school_users` AS SELECT 
 1 AS `user_id`,
 1 AS `username`,
 1 AS `user_type`,
 1 AS `udise_no`,
 1 AS `district_name`,
 1 AS `division_name`,
 1 AS `is_active`,
 1 AS `is_first_login`,
 1 AS `last_login_date`,
 1 AS `created_date`*/;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `weekly_activities`
--

DROP TABLE IF EXISTS `weekly_activities`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `weekly_activities` (
  `id` int NOT NULL AUTO_INCREMENT,
  `udise_no` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `student_class` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `section` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL,
  `subject` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Marathi, English, or Math',
  `week_number` int NOT NULL COMMENT 'Week number 1-52',
  `day` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Monday, Tuesday, Wednesday, Thursday, Friday, Saturday',
  `activity` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Activity description',
  `completed` tinyint(1) DEFAULT '0',
  `completed_date` timestamp NULL DEFAULT NULL,
  `completed_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_activity` (`udise_no`,`student_class`,`section`,`subject`,`week_number`,`day`),
  KEY `idx_udise` (`udise_no`),
  KEY `idx_class_section` (`student_class`,`section`),
  KEY `idx_week` (`week_number`),
  KEY `idx_subject` (`subject`),
  KEY `idx_completed` (`completed`)
) ENGINE=InnoDB AUTO_INCREMENT=37 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Final view structure for view `vw_active_users_summary`
--

/*!50001 DROP VIEW IF EXISTS `vw_active_users_summary`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_active_users_summary` AS select `users`.`user_type` AS `user_type`,count(0) AS `total_users`,sum((case when (`users`.`is_active` = true) then 1 else 0 end)) AS `active_users`,sum((case when (`users`.`is_first_login` = true) then 1 else 0 end)) AS `pending_first_login`,sum((case when (`users`.`account_locked` = true) then 1 else 0 end)) AS `locked_accounts` from `users` group by `users`.`user_type` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_district_users`
--

/*!50001 DROP VIEW IF EXISTS `vw_district_users`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_district_users` AS select `users`.`user_id` AS `user_id`,`users`.`username` AS `username`,`users`.`user_type` AS `user_type`,`users`.`district_name` AS `district_name`,`users`.`division_name` AS `division_name`,`users`.`is_active` AS `is_active`,`users`.`is_first_login` AS `is_first_login`,`users`.`last_login_date` AS `last_login_date`,`users`.`created_date` AS `created_date` from `users` where (`users`.`user_type` in ('DISTRICT_COORDINATOR','DISTRICT_2ND_COORDINATOR')) order by `users`.`district_name`,`users`.`user_type` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_division_users`
--

/*!50001 DROP VIEW IF EXISTS `vw_division_users`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_division_users` AS select `users`.`user_id` AS `user_id`,`users`.`username` AS `username`,`users`.`division_name` AS `division_name`,`users`.`is_active` AS `is_active`,`users`.`is_first_login` AS `is_first_login`,`users`.`last_login_date` AS `last_login_date`,`users`.`created_date` AS `created_date` from `users` where (`users`.`user_type` = 'DIVISION') */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `vw_school_users`
--

/*!50001 DROP VIEW IF EXISTS `vw_school_users`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=`root`@`localhost` SQL SECURITY DEFINER */
/*!50001 VIEW `vw_school_users` AS select `users`.`user_id` AS `user_id`,`users`.`username` AS `username`,`users`.`user_type` AS `user_type`,`users`.`udise_no` AS `udise_no`,`users`.`district_name` AS `district_name`,`users`.`division_name` AS `division_name`,`users`.`is_active` AS `is_active`,`users`.`is_first_login` AS `is_first_login`,`users`.`last_login_date` AS `last_login_date`,`users`.`created_date` AS `created_date` from `users` where (`users`.`user_type` in ('SCHOOL_COORDINATOR','HEAD_MASTER')) order by `users`.`udise_no`,`users`.`user_type` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-12-07 11:00:27
