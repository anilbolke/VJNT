-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Host: localhost:3306
-- Generation Time: Jun 18, 2026 at 12:07 PM
-- Server version: 10.11.18-MariaDB
-- PHP Version: 8.4.21

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `gateepor_vjnt_class_management`
--

-- --------------------------------------------------------

--
-- Table structure for table `language_level_audit`
--

CREATE TABLE `language_level_audit` (
  `audit_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `phase` int(11) NOT NULL,
  `action_type` varchar(50) DEFAULT NULL,
  `marathi_level_old` int(11) DEFAULT NULL,
  `marathi_level_new` int(11) DEFAULT NULL,
  `math_level_old` int(11) DEFAULT NULL,
  `math_level_new` int(11) DEFAULT NULL,
  `english_level_old` int(11) DEFAULT NULL,
  `english_level_new` int(11) DEFAULT NULL,
  `changed_by` varchar(100) DEFAULT NULL,
  `changed_date` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `login_audit`
--

CREATE TABLE `login_audit` (
  `audit_id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `username` varchar(100) DEFAULT NULL,
  `login_time` datetime DEFAULT current_timestamp(),
  `logout_time` datetime DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `session_id` varchar(100) DEFAULT NULL,
  `login_status` enum('SUCCESS','FAILED','LOCKED') NOT NULL,
  `failure_reason` varchar(255) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `notifications`
--

CREATE TABLE `notifications` (
  `notification_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL COMMENT 'Notification title/subject',
  `message` text NOT NULL COMMENT 'Notification message content',
  `notification_type` enum('INFO','WARNING','URGENT','SUCCESS') DEFAULT 'INFO' COMMENT 'Type of notification',
  `target_audience` enum('ALL','SCHOOL_COORDINATOR','HEAD_MASTER','SPECIFIC_SCHOOL') DEFAULT 'ALL' COMMENT 'Who should see this',
  `division` varchar(100) DEFAULT NULL COMMENT 'Division name - if NULL, applies to all divisions',
  `district` varchar(100) DEFAULT NULL COMMENT 'District name - if NULL, applies to all districts in division',
  `udise_code` varchar(20) DEFAULT NULL COMMENT 'Specific school UDISE - if NULL, applies to all schools',
  `created_by` int(11) NOT NULL COMMENT 'User ID of who created the notification (Division Head)',
  `created_by_name` varchar(200) NOT NULL COMMENT 'Name of who created the notification',
  `created_date` timestamp NULL DEFAULT current_timestamp(),
  `expiry_date` timestamp NULL DEFAULT NULL COMMENT 'Notification expiry date - if NULL, never expires',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '1 = Active, 0 = Inactive/Archived',
  `priority` int(11) DEFAULT 0 COMMENT 'Priority level: 0=Normal, 1=High, 2=Urgent'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `other_school_activities`
--

CREATE TABLE `other_school_activities` (
  `activity_id` int(11) NOT NULL,
  `udise_no` varchar(20) NOT NULL,
  `school_name` varchar(255) DEFAULT NULL,
  `activity_date` date NOT NULL COMMENT 'Date of the activity',
  `activity_subject` varchar(255) NOT NULL COMMENT 'Subject / उपक्रमाचे नाव',
  `guests_present` text DEFAULT NULL COMMENT 'उपस्थित पाहुणे - Details of guests who attended',
  `description` text DEFAULT NULL COMMENT 'विवरण - Description of the activity',
  `photo1_path` varchar(500) DEFAULT NULL COMMENT 'Path for photo 1 (if stored on filesystem)',
  `photo2_path` varchar(500) DEFAULT NULL COMMENT 'Path for photo 2 (if stored on filesystem)',
  `photo1_content` longblob DEFAULT NULL COMMENT 'Photo 1 content stored in database',
  `photo2_content` longblob DEFAULT NULL COMMENT 'Photo 2 content stored in database',
  `photo1_filename` varchar(255) DEFAULT NULL COMMENT 'Original filename of photo 1',
  `photo2_filename` varchar(255) DEFAULT NULL COMMENT 'Original filename of photo 2',
  `video_link` varchar(500) DEFAULT NULL COMMENT 'व्हिडओ लिंक - YouTube or other video URL',
  `status` varchar(50) DEFAULT 'DRAFT' COMMENT 'DRAFT, SUBMITTED',
  `submitted_by` varchar(100) DEFAULT NULL COMMENT 'Username who submitted',
  `submitted_date` datetime DEFAULT NULL COMMENT 'When activity was submitted for approval',
  `approval_status` varchar(50) DEFAULT NULL COMMENT 'PENDING_APPROVAL, APPROVED, REJECTED',
  `approved_by` varchar(100) DEFAULT NULL COMMENT 'Headmaster username who approved/rejected',
  `approval_date` datetime DEFAULT NULL COMMENT 'When approval/rejection was done',
  `approval_remarks` text DEFAULT NULL COMMENT 'Approval remarks from headmaster',
  `rejection_reason` text DEFAULT NULL COMMENT 'Reason for rejection',
  `created_by` varchar(100) DEFAULT NULL COMMENT 'School coordinator who created',
  `created_date` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `updated_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Other School Activities requiring headmaster approval';

-- --------------------------------------------------------

--
-- Table structure for table `palak_melava`
--

CREATE TABLE `palak_melava` (
  `melava_id` int(11) NOT NULL,
  `udise_no` varchar(50) NOT NULL,
  `school_name` varchar(500) DEFAULT NULL,
  `meeting_date` date NOT NULL,
  `chief_attendee_info` text DEFAULT NULL,
  `total_parents_attended` varchar(100) DEFAULT NULL,
  `photo_1_path` varchar(500) DEFAULT NULL,
  `photo_1_content` longblob DEFAULT NULL,
  `photo_1_filename` varchar(255) DEFAULT NULL,
  `photo_2_path` varchar(500) DEFAULT NULL,
  `photo_2_content` longblob DEFAULT NULL,
  `photo_2_filename` varchar(255) DEFAULT NULL,
  `status` enum('DRAFT','PENDING_APPROVAL','APPROVED','REJECTED') DEFAULT 'DRAFT',
  `submitted_by` varchar(255) DEFAULT NULL,
  `submitted_date` datetime DEFAULT NULL,
  `approval_status` varchar(20) DEFAULT NULL,
  `approved_by` varchar(255) DEFAULT NULL,
  `approval_date` datetime DEFAULT NULL,
  `approval_remarks` text DEFAULT NULL,
  `rejection_reason` text DEFAULT NULL,
  `created_by` varchar(255) DEFAULT NULL,
  `created_date` datetime DEFAULT current_timestamp(),
  `updated_by` varchar(255) DEFAULT NULL,
  `updated_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phase_approvals`
--

CREATE TABLE `phase_approvals` (
  `approval_id` int(11) NOT NULL,
  `udise_no` varchar(50) NOT NULL,
  `phase_number` int(11) NOT NULL,
  `completed_by` varchar(100) DEFAULT NULL,
  `completed_date` datetime DEFAULT current_timestamp(),
  `completion_remarks` text DEFAULT NULL,
  `approval_status` enum('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
  `approved_by` varchar(100) DEFAULT NULL,
  `approved_date` datetime DEFAULT NULL,
  `approval_remarks` text DEFAULT NULL,
  `total_students` int(11) DEFAULT 0,
  `completed_students` int(11) DEFAULT 0,
  `pending_students` int(11) DEFAULT 0,
  `ignored_students` int(11) DEFAULT 0,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `phase_completion_status`
--

CREATE TABLE `phase_completion_status` (
  `id` int(11) NOT NULL,
  `udise_no` varchar(50) NOT NULL,
  `phase` int(11) NOT NULL,
  `is_complete` tinyint(1) DEFAULT 0,
  `completion_date` timestamp NULL DEFAULT NULL,
  `completed_by` varchar(100) DEFAULT NULL,
  `total_students` int(11) DEFAULT 0,
  `completed_students` int(11) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `report_approvals`
--

CREATE TABLE `report_approvals` (
  `approval_id` int(11) NOT NULL,
  `report_type` varchar(50) NOT NULL,
  `pen_number` varchar(20) NOT NULL,
  `student_name` varchar(100) NOT NULL,
  `class` varchar(10) NOT NULL,
  `section` varchar(5) NOT NULL,
  `udise_code` varchar(20) NOT NULL,
  `school_name` varchar(200) DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `division` varchar(100) DEFAULT NULL,
  `requested_by` int(11) NOT NULL,
  `requested_date` timestamp NULL DEFAULT current_timestamp(),
  `approval_status` enum('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
  `approved_by` int(11) DEFAULT NULL,
  `approval_date` timestamp NULL DEFAULT NULL,
  `approval_remarks` text DEFAULT NULL,
  `report_generated` tinyint(1) DEFAULT 0,
  `generated_date` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `schools`
--

CREATE TABLE `schools` (
  `school_id` int(11) NOT NULL,
  `udise_no` varchar(50) NOT NULL,
  `school_name` varchar(255) NOT NULL,
  `district_name` varchar(100) DEFAULT NULL,
  `created_date` datetime DEFAULT current_timestamp(),
  `created_by` varchar(100) DEFAULT NULL,
  `updated_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `school_contacts`
--

CREATE TABLE `school_contacts` (
  `contact_id` int(11) NOT NULL,
  `udise_no` varchar(50) NOT NULL,
  `school_name` varchar(255) DEFAULT NULL,
  `district_name` varchar(100) NOT NULL,
  `contact_type` varchar(50) NOT NULL,
  `full_name` varchar(200) NOT NULL,
  `mobile` varchar(15) NOT NULL,
  `whatsapp_number` varchar(15) DEFAULT NULL,
  `remarks` text DEFAULT NULL,
  `created_date` datetime DEFAULT current_timestamp(),
  `created_by` varchar(100) DEFAULT NULL,
  `updated_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `students`
--

CREATE TABLE `students` (
  `student_id` int(11) NOT NULL,
  `division` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `udise_no` varchar(20) DEFAULT NULL,
  `class` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `section` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `class_category` varchar(50) DEFAULT NULL,
  `student_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `gender` enum('Male','Female','Other','?????','??????','???') DEFAULT NULL,
  `student_pen` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `marathi_level` varchar(50) DEFAULT NULL,
  `math_level` varchar(50) DEFAULT NULL,
  `english_level` varchar(50) DEFAULT NULL,
  `created_date` datetime DEFAULT current_timestamp(),
  `created_by` varchar(100) DEFAULT 'SYSTEM',
  `updated_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL,
  `marathi_akshara_level` int(11) DEFAULT 0 COMMENT '????? ????????? (???? ? ????)',
  `marathi_shabda_level` int(11) DEFAULT 0 COMMENT '???? ????????? (???? ? ????)',
  `marathi_vakya_level` int(11) DEFAULT 0 COMMENT '????? ?????????',
  `marathi_samajpurvak_level` int(11) DEFAULT 0 COMMENT '????????? ???? ???? ?????????',
  `math_akshara_level` int(11) DEFAULT 0 COMMENT '???? - ????? ????',
  `math_shabda_level` int(11) DEFAULT 0 COMMENT '???? - ???? ????',
  `math_vakya_level` int(11) DEFAULT 0 COMMENT '???? - ????? ????',
  `math_samajpurvak_level` int(11) DEFAULT 0 COMMENT '???? - ????????? ????',
  `english_akshara_level` int(11) DEFAULT 0 COMMENT 'English - Letter Level',
  `english_shabda_level` int(11) DEFAULT 0 COMMENT 'English - Word Level',
  `english_vakya_level` int(11) DEFAULT 0 COMMENT 'English - Sentence Level',
  `english_samajpurvak_level` int(11) DEFAULT 0 COMMENT 'English - Comprehension Level',
  `phase1_marathi` int(11) DEFAULT NULL,
  `phase1_math` int(11) DEFAULT NULL,
  `phase1_english` int(11) DEFAULT NULL,
  `phase1_date` timestamp NULL DEFAULT NULL,
  `phase2_marathi` int(11) DEFAULT NULL,
  `phase2_math` int(11) DEFAULT NULL,
  `phase2_english` int(11) DEFAULT NULL,
  `phase2_date` timestamp NULL DEFAULT NULL,
  `phase3_marathi` int(11) DEFAULT NULL,
  `phase3_math` int(11) DEFAULT NULL,
  `phase3_english` int(11) DEFAULT NULL,
  `phase3_date` timestamp NULL DEFAULT NULL,
  `phase4_marathi` int(11) DEFAULT NULL,
  `phase4_math` int(11) DEFAULT NULL,
  `phase4_english` int(11) DEFAULT NULL,
  `phase4_date` timestamp NULL DEFAULT NULL,
  `fln_completed` tinyint(1) DEFAULT 0 COMMENT 'True if student achieved 100% FLN in all 3 subjects (Marathi=6, Math=8, English=6)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Triggers `students`
--
DELIMITER $$
CREATE TRIGGER `trg_students_after_insert` AFTER INSERT ON `students` FOR EACH ROW BEGIN
    INSERT INTO students_audit (
        action_type,
        student_id,
        division,
        district,
        udise_no,
        class,
        section,
        class_category,
        student_name,
        gender,
        student_pen,
        marathi_level,
        math_level,
        english_level,
        marathi_akshara_level,
        marathi_shabda_level,
        marathi_vakya_level,
        marathi_samajpurvak_level,
        math_akshara_level,
        math_shabda_level,
        math_vakya_level,
        math_samajpurvak_level,
        english_akshara_level,
        english_shabda_level,
        english_vakya_level,
        english_samajpurvak_level,
        phase1_marathi,
        phase1_math,
        phase1_english,
        phase2_marathi,
        phase2_math,
        phase2_english,
        phase3_marathi,
        phase3_math,
        phase3_english,
        phase4_marathi,
        phase4_math,
        phase4_english,
        phase1_date,
        phase2_date,
        phase3_date,
        phase4_date,
        is_active,
        created_date,
        created_by,
        updated_date,
        updated_by,
        changed_by,
        changed_at,
        new_values
    ) VALUES (
        'INSERT',
        NEW.student_id,
        NEW.division,
        NEW.district,
        NEW.udise_no,
        NEW.class,
        NEW.section,
        NEW.class_category,
        NEW.student_name,
        NEW.gender,
        NEW.student_pen,
        NEW.marathi_level,
        NEW.math_level,
        NEW.english_level,
        NEW.marathi_akshara_level,
        NEW.marathi_shabda_level,
        NEW.marathi_vakya_level,
        NEW.marathi_samajpurvak_level,
        NEW.math_akshara_level,
        NEW.math_shabda_level,
        NEW.math_vakya_level,
        NEW.math_samajpurvak_level,
        NEW.english_akshara_level,
        NEW.english_shabda_level,
        NEW.english_vakya_level,
        NEW.english_samajpurvak_level,
        NEW.phase1_marathi,
        NEW.phase1_math,
        NEW.phase1_english,
        NEW.phase2_marathi,
        NEW.phase2_math,
        NEW.phase2_english,
        NEW.phase3_marathi,
        NEW.phase3_math,
        NEW.phase3_english,
        NEW.phase4_marathi,
        NEW.phase4_math,
        NEW.phase4_english,
        NEW.phase1_date,
        NEW.phase2_date,
        NEW.phase3_date,
        NEW.phase4_date,
        NEW.is_active,
        NEW.created_date,
        NEW.created_by,
        NEW.updated_date,
        NEW.updated_by,
        COALESCE(@audit_user, USER()),
        NOW(),
        JSON_OBJECT(
            'student_id', NEW.student_id,
            'student_pen', NEW.student_pen,
            'student_name', NEW.student_name,
            'class', NEW.class,
            'section', NEW.section,
            'marathi_level', NEW.marathi_akshara_level,
            'math_level', NEW.math_akshara_level,
            'english_level', NEW.english_akshara_level,
            'is_active', NEW.is_active
        )
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `trg_students_after_update` AFTER UPDATE ON `students` FOR EACH ROW BEGIN
    INSERT INTO students_audit (
        action_type,
        student_id,
        division,
        district,
        udise_no,
        class,
        section,
        class_category,
        student_name,
        gender,
        student_pen,
        marathi_level,
        math_level,
        english_level,
        marathi_akshara_level,
        marathi_shabda_level,
        marathi_vakya_level,
        marathi_samajpurvak_level,
        math_akshara_level,
        math_shabda_level,
        math_vakya_level,
        math_samajpurvak_level,
        english_akshara_level,
        english_shabda_level,
        english_vakya_level,
        english_samajpurvak_level,
        phase1_marathi,
        phase1_math,
        phase1_english,
        phase2_marathi,
        phase2_math,
        phase2_english,
        phase3_marathi,
        phase3_math,
        phase3_english,
        phase4_marathi,
        phase4_math,
        phase4_english,
        phase1_date,
        phase2_date,
        phase3_date,
        phase4_date,
        is_active,
        created_date,
        created_by,
        updated_date,
        updated_by,
        changed_by,
        changed_at,
        old_values,
        new_values
    ) VALUES (
        'UPDATE',
        NEW.student_id,
        NEW.division,
        NEW.district,
        NEW.udise_no,
        NEW.class,
        NEW.section,
        NEW.class_category,
        NEW.student_name,
        NEW.gender,
        NEW.student_pen,
        NEW.marathi_level,
        NEW.math_level,
        NEW.english_level,
        NEW.marathi_akshara_level,
        NEW.marathi_shabda_level,
        NEW.marathi_vakya_level,
        NEW.marathi_samajpurvak_level,
        NEW.math_akshara_level,
        NEW.math_shabda_level,
        NEW.math_vakya_level,
        NEW.math_samajpurvak_level,
        NEW.english_akshara_level,
        NEW.english_shabda_level,
        NEW.english_vakya_level,
        NEW.english_samajpurvak_level,
        NEW.phase1_marathi,
        NEW.phase1_math,
        NEW.phase1_english,
        NEW.phase2_marathi,
        NEW.phase2_math,
        NEW.phase2_english,
        NEW.phase3_marathi,
        NEW.phase3_math,
        NEW.phase3_english,
        NEW.phase4_marathi,
        NEW.phase4_math,
        NEW.phase4_english,
        NEW.phase1_date,
        NEW.phase2_date,
        NEW.phase3_date,
        NEW.phase4_date,
        NEW.is_active,
        NEW.created_date,
        NEW.created_by,
        NEW.updated_date,
        NEW.updated_by,
        COALESCE(@audit_user, USER()),
        NOW(),
        JSON_OBJECT(
            'student_id', OLD.student_id,
            'student_pen', OLD.student_pen,
            'student_name', OLD.student_name,
            'class', OLD.class,
            'section', OLD.section,
            'marathi_akshara_level', OLD.marathi_akshara_level,
            'math_akshara_level', OLD.math_akshara_level,
            'english_akshara_level', OLD.english_akshara_level,
            'phase1_marathi', OLD.phase1_marathi,
            'phase1_math', OLD.phase1_math,
            'phase1_english', OLD.phase1_english,
            'phase2_marathi', OLD.phase2_marathi,
            'phase2_math', OLD.phase2_math,
            'phase2_english', OLD.phase2_english,
            'phase3_marathi', OLD.phase3_marathi,
            'phase3_math', OLD.phase3_math,
            'phase3_english', OLD.phase3_english,
            'phase4_marathi', OLD.phase4_marathi,
            'phase4_math', OLD.phase4_math,
            'phase4_english', OLD.phase4_english,
            'is_active', OLD.is_active
        ),
        JSON_OBJECT(
            'student_id', NEW.student_id,
            'student_pen', NEW.student_pen,
            'student_name', NEW.student_name,
            'class', NEW.class,
            'section', NEW.section,
            'marathi_akshara_level', NEW.marathi_akshara_level,
            'math_akshara_level', NEW.math_akshara_level,
            'english_akshara_level', NEW.english_akshara_level,
            'phase1_marathi', NEW.phase1_marathi,
            'phase1_math', NEW.phase1_math,
            'phase1_english', NEW.phase1_english,
            'phase2_marathi', NEW.phase2_marathi,
            'phase2_math', NEW.phase2_math,
            'phase2_english', NEW.phase2_english,
            'phase3_marathi', NEW.phase3_marathi,
            'phase3_math', NEW.phase3_math,
            'phase3_english', NEW.phase3_english,
            'phase4_marathi', NEW.phase4_marathi,
            'phase4_math', NEW.phase4_math,
            'phase4_english', NEW.phase4_english,
            'is_active', NEW.is_active
        )
    );
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `students_audit`
--

CREATE TABLE `students_audit` (
  `audit_id` bigint(20) NOT NULL,
  `action_type` varchar(10) NOT NULL COMMENT 'INSERT, UPDATE, DELETE',
  `student_id` int(11) NOT NULL COMMENT 'ID from students table',
  `division` varchar(100) DEFAULT NULL COMMENT 'Division',
  `district` varchar(100) DEFAULT NULL COMMENT 'District',
  `udise_no` varchar(50) DEFAULT NULL COMMENT 'School UDISE number',
  `class` varchar(10) DEFAULT NULL COMMENT 'Class/Standard',
  `section` varchar(10) DEFAULT NULL COMMENT 'Section',
  `class_category` varchar(50) DEFAULT NULL COMMENT 'Class Category',
  `student_name` varchar(255) DEFAULT NULL COMMENT 'Student full name',
  `gender` varchar(20) DEFAULT NULL COMMENT 'Gender',
  `student_pen` varchar(50) DEFAULT NULL COMMENT 'Student PEN number',
  `marathi_level` varchar(50) DEFAULT NULL COMMENT 'Legacy Marathi level',
  `math_level` varchar(50) DEFAULT NULL COMMENT 'Legacy Math level',
  `english_level` varchar(50) DEFAULT NULL COMMENT 'Legacy English level',
  `marathi_akshara_level` int(11) DEFAULT 0 COMMENT 'Marathi अक्षर level',
  `marathi_shabda_level` int(11) DEFAULT 0 COMMENT 'Marathi शब्द level',
  `marathi_vakya_level` int(11) DEFAULT 0 COMMENT 'Marathi वाक्य level',
  `marathi_samajpurvak_level` int(11) DEFAULT 0 COMMENT 'Marathi समजपूर्वक level',
  `math_akshara_level` int(11) DEFAULT 0 COMMENT 'Math level',
  `math_shabda_level` int(11) DEFAULT 0 COMMENT 'Math operations level',
  `math_vakya_level` int(11) DEFAULT 0 COMMENT 'Math problem level',
  `math_samajpurvak_level` int(11) DEFAULT 0 COMMENT 'Math comprehension level',
  `english_akshara_level` int(11) DEFAULT 0 COMMENT 'English letter level',
  `english_shabda_level` int(11) DEFAULT 0 COMMENT 'English word level',
  `english_vakya_level` int(11) DEFAULT 0 COMMENT 'English sentence level',
  `english_samajpurvak_level` int(11) DEFAULT 0 COMMENT 'English comprehension level',
  `phase1_marathi` int(11) DEFAULT NULL COMMENT 'Phase 1 Marathi level',
  `phase1_math` int(11) DEFAULT NULL COMMENT 'Phase 1 Math level',
  `phase1_english` int(11) DEFAULT NULL COMMENT 'Phase 1 English level',
  `phase2_marathi` int(11) DEFAULT NULL COMMENT 'Phase 2 Marathi level',
  `phase2_math` int(11) DEFAULT NULL COMMENT 'Phase 2 Math level',
  `phase2_english` int(11) DEFAULT NULL COMMENT 'Phase 2 English level',
  `phase3_marathi` int(11) DEFAULT NULL COMMENT 'Phase 3 Marathi level',
  `phase3_math` int(11) DEFAULT NULL COMMENT 'Phase 3 Math level',
  `phase3_english` int(11) DEFAULT NULL COMMENT 'Phase 3 English level',
  `phase4_marathi` int(11) DEFAULT NULL COMMENT 'Phase 4 Marathi level',
  `phase4_math` int(11) DEFAULT NULL COMMENT 'Phase 4 Math level',
  `phase4_english` int(11) DEFAULT NULL COMMENT 'Phase 4 English level',
  `phase1_date` datetime DEFAULT NULL COMMENT 'Phase 1 save timestamp',
  `phase2_date` datetime DEFAULT NULL COMMENT 'Phase 2 save timestamp',
  `phase3_date` datetime DEFAULT NULL COMMENT 'Phase 3 save timestamp',
  `phase4_date` datetime DEFAULT NULL COMMENT 'Phase 4 save timestamp',
  `is_active` tinyint(1) DEFAULT 1 COMMENT 'Student active status',
  `created_date` datetime DEFAULT NULL COMMENT 'Original creation date',
  `created_by` varchar(100) DEFAULT NULL COMMENT 'Original creator',
  `updated_date` datetime DEFAULT NULL COMMENT 'Original update date',
  `updated_by` varchar(100) DEFAULT NULL COMMENT 'Original updater',
  `changed_by` varchar(100) DEFAULT NULL COMMENT 'Username who made the change',
  `changed_at` timestamp NULL DEFAULT current_timestamp() COMMENT 'When the change was made',
  `ip_address` varchar(50) DEFAULT NULL COMMENT 'IP address of the user',
  `old_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON of old values for UPDATE operations' CHECK (json_valid(`old_values`)),
  `new_values` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL COMMENT 'JSON of new values for UPDATE operations' CHECK (json_valid(`new_values`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Audit trail for all changes to students table';

-- --------------------------------------------------------

--
-- Table structure for table `student_language_phase`
--

CREATE TABLE `student_language_phase` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `phase` int(11) NOT NULL,
  `marathi_level` int(11) DEFAULT 0,
  `math_level` int(11) DEFAULT 0,
  `english_level` int(11) DEFAULT 0,
  `created_date` timestamp NULL DEFAULT current_timestamp(),
  `created_by` varchar(100) DEFAULT NULL,
  `updated_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `student_phase_audit`
--

CREATE TABLE `student_phase_audit` (
  `audit_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `phase` int(11) NOT NULL,
  `marathi_level` int(11) DEFAULT NULL,
  `math_level` int(11) DEFAULT NULL,
  `english_level` int(11) DEFAULT NULL,
  `changed_by` varchar(100) DEFAULT NULL,
  `changed_date` timestamp NULL DEFAULT current_timestamp(),
  `action_type` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `student_videos`
--

CREATE TABLE `student_videos` (
  `video_id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `subject` varchar(50) NOT NULL COMMENT 'Marathi, Math, or English',
  `month` varchar(20) NOT NULL COMMENT 'Month of video (January to December)',
  `has_progress` varchar(10) NOT NULL COMMENT 'yes or no - विद्यार्थ्याची प्रगती झाली आहे का?',
  `file_path` varchar(500) NOT NULL COMMENT 'Path to video file',
  `original_file_name` varchar(255) NOT NULL COMMENT 'Original uploaded file name',
  `file_size` bigint(20) NOT NULL COMMENT 'File size in bytes',
  `uploaded_by` int(11) NOT NULL COMMENT 'User ID who uploaded',
  `uploaded_by_name` varchar(255) NOT NULL COMMENT 'Name of uploader',
  `udise_no` varchar(20) NOT NULL COMMENT 'School UDISE number',
  `youtube_video_id` varchar(50) DEFAULT NULL COMMENT 'YouTube video ID',
  `thumbnail_url` varchar(500) DEFAULT NULL COMMENT 'YouTube video thumbnail URL',
  `upload_date` timestamp NULL DEFAULT current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  `approval_status` varchar(20) DEFAULT 'PENDING' COMMENT 'PENDING, APPROVED, REJECTED',
  `approved_by` int(11) DEFAULT NULL COMMENT 'User ID of headmaster who approved/rejected',
  `approved_by_name` varchar(255) DEFAULT NULL COMMENT 'Name of headmaster who approved/rejected',
  `approval_date` datetime DEFAULT NULL COMMENT 'Date and time of approval/rejection',
  `rejection_reason` text DEFAULT NULL COMMENT 'Reason for rejection if status is REJECTED',
  `is_visible` tinyint(1) DEFAULT 1 COMMENT 'Whether video is visible to students (approved videos only)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Stores student progress videos uploaded by teachers';

-- --------------------------------------------------------

--
-- Table structure for table `student_weekly_activities`
--

CREATE TABLE `student_weekly_activities` (
  `id` int(11) NOT NULL,
  `student_id` int(11) NOT NULL,
  `student_pen` varchar(50) NOT NULL,
  `udise_no` varchar(50) NOT NULL,
  `student_class` varchar(10) NOT NULL,
  `section` varchar(5) NOT NULL,
  `student_name` varchar(200) NOT NULL,
  `language` varchar(20) NOT NULL,
  `week_number` int(11) NOT NULL,
  `day_number` int(11) NOT NULL,
  `activity_text` text NOT NULL,
  `activity_identifier` varchar(100) NOT NULL DEFAULT '',
  `activity_count` int(11) DEFAULT 1,
  `completed` tinyint(1) DEFAULT 0,
  `completed_date` datetime DEFAULT NULL,
  `assigned_by` varchar(200) DEFAULT NULL,
  `assigned_date` datetime DEFAULT current_timestamp(),
  `updated_at` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `teachers`
--

CREATE TABLE `teachers` (
  `teacher_id` int(11) NOT NULL,
  `udise_code` varchar(20) DEFAULT NULL,
  `teacher_name` varchar(100) NOT NULL,
  `mobile_number` varchar(10) NOT NULL,
  `subjects_taught` varchar(255) NOT NULL,
  `description` text DEFAULT NULL,
  `created_date` timestamp NULL DEFAULT current_timestamp(),
  `updated_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` int(11) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `teacher_assignments`
--

CREATE TABLE `teacher_assignments` (
  `assignment_id` int(11) NOT NULL,
  `udise_code` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `district` varchar(100) DEFAULT NULL,
  `division` varchar(100) DEFAULT NULL,
  `teacher_id` int(11) NOT NULL,
  `teacher_name` varchar(100) NOT NULL,
  `class` varchar(10) NOT NULL,
  `section` varchar(10) NOT NULL,
  `subjects_assigned` varchar(255) NOT NULL,
  `created_date` timestamp NULL DEFAULT current_timestamp(),
  `updated_date` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `created_by` int(11) DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT 1,
  `is_class_teacher` tinyint(1) DEFAULT 0 COMMENT 'Is this teacher the class teacher for this class-section? 1=Yes, 0=No'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `user_id` int(11) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `user_type` varchar(50) NOT NULL,
  `division_name` varchar(100) DEFAULT NULL,
  `district_name` varchar(100) DEFAULT NULL,
  `udise_no` varchar(50) DEFAULT NULL,
  `is_first_login` tinyint(1) DEFAULT 1,
  `password_changed_date` datetime DEFAULT NULL,
  `must_change_password` tinyint(1) DEFAULT 1,
  `is_active` tinyint(1) DEFAULT 1,
  `created_date` datetime DEFAULT current_timestamp(),
  `created_by` varchar(100) DEFAULT NULL,
  `last_login_date` datetime DEFAULT NULL,
  `failed_login_attempts` int(11) DEFAULT 0,
  `account_locked` tinyint(1) DEFAULT 0,
  `locked_date` datetime DEFAULT NULL,
  `email` varchar(100) DEFAULT NULL,
  `mobile` varchar(15) DEFAULT NULL,
  `full_name` varchar(200) DEFAULT NULL,
  `updated_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `updated_by` varchar(100) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- --------------------------------------------------------

--
-- Table structure for table `videos`
--

CREATE TABLE `videos` (
  `video_id` int(11) NOT NULL,
  `title` varchar(255) NOT NULL,
  `description` longtext DEFAULT NULL,
  `youtube_video_id` varchar(50) NOT NULL,
  `youtube_url` varchar(500) NOT NULL,
  `thumbnail_url` varchar(500) DEFAULT NULL,
  `category` varchar(100) DEFAULT NULL,
  `sub_category` varchar(100) DEFAULT NULL,
  `uploaded_by` int(11) DEFAULT NULL,
  `uploader_name` varchar(255) DEFAULT NULL,
  `upload_date` timestamp NULL DEFAULT current_timestamp(),
  `view_count` int(11) DEFAULT 0,
  `status` varchar(50) DEFAULT 'active'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `video_views`
--

CREATE TABLE `video_views` (
  `view_id` int(11) NOT NULL,
  `video_id` int(11) NOT NULL,
  `student_id` int(11) DEFAULT NULL,
  `viewer_name` varchar(255) DEFAULT NULL,
  `ip_address` varchar(50) DEFAULT NULL,
  `view_date` timestamp NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_active_users_summary`
-- (See below for the actual view)
--
CREATE TABLE `vw_active_users_summary` (
`user_type` varchar(50)
,`total_users` bigint(21)
,`active_users` decimal(23,0)
,`pending_first_login` decimal(23,0)
,`locked_accounts` decimal(23,0)
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_district_users`
-- (See below for the actual view)
--
CREATE TABLE `vw_district_users` (
`user_id` int(11)
,`username` varchar(100)
,`user_type` varchar(50)
,`district_name` varchar(100)
,`division_name` varchar(100)
,`is_active` tinyint(1)
,`is_first_login` tinyint(1)
,`last_login_date` datetime
,`created_date` datetime
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_division_users`
-- (See below for the actual view)
--
CREATE TABLE `vw_division_users` (
`user_id` int(11)
,`username` varchar(100)
,`division_name` varchar(100)
,`is_active` tinyint(1)
,`is_first_login` tinyint(1)
,`last_login_date` datetime
,`created_date` datetime
);

-- --------------------------------------------------------

--
-- Stand-in structure for view `vw_school_users`
-- (See below for the actual view)
--
CREATE TABLE `vw_school_users` (
`user_id` int(11)
,`username` varchar(100)
,`user_type` varchar(50)
,`udise_no` varchar(50)
,`district_name` varchar(100)
,`division_name` varchar(100)
,`is_active` tinyint(1)
,`is_first_login` tinyint(1)
,`last_login_date` datetime
,`created_date` datetime
);

-- --------------------------------------------------------

--
-- Table structure for table `weekly_activities`
--

CREATE TABLE `weekly_activities` (
  `id` int(11) NOT NULL,
  `udise_no` varchar(20) NOT NULL,
  `student_class` varchar(10) NOT NULL,
  `section` varchar(10) NOT NULL,
  `subject` varchar(20) NOT NULL COMMENT 'Marathi, English, or Math',
  `week_number` int(11) NOT NULL COMMENT 'Week number 1-52',
  `day` varchar(20) NOT NULL COMMENT 'Monday, Tuesday, Wednesday, Thursday, Friday, Saturday',
  `activity` text NOT NULL COMMENT 'Activity description',
  `completed` tinyint(1) DEFAULT 0,
  `completed_date` timestamp NULL DEFAULT NULL,
  `completed_by` varchar(100) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Table structure for table `youtube_credentials`
--

CREATE TABLE `youtube_credentials` (
  `id` int(11) NOT NULL,
  `credential_name` varchar(50) NOT NULL,
  `access_token` text NOT NULL,
  `refresh_token` text NOT NULL,
  `token_expiry` datetime DEFAULT NULL,
  `client_id` varchar(255) NOT NULL,
  `client_secret` varchar(255) NOT NULL,
  `created_date` datetime DEFAULT current_timestamp(),
  `updated_date` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  `last_refresh_date` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `language_level_audit`
--
ALTER TABLE `language_level_audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `student_id` (`student_id`);

--
-- Indexes for table `login_audit`
--
ALTER TABLE `login_audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `idx_user_id` (`user_id`),
  ADD KEY `idx_login_time` (`login_time`),
  ADD KEY `idx_login_status` (`login_status`);

--
-- Indexes for table `notifications`
--
ALTER TABLE `notifications`
  ADD PRIMARY KEY (`notification_id`),
  ADD KEY `idx_division` (`division`),
  ADD KEY `idx_district` (`district`),
  ADD KEY `idx_udise` (`udise_code`),
  ADD KEY `idx_active` (`is_active`),
  ADD KEY `idx_created_date` (`created_date`),
  ADD KEY `idx_expiry` (`expiry_date`),
  ADD KEY `idx_priority` (`priority`),
  ADD KEY `fk_notification_creator` (`created_by`),
  ADD KEY `idx_target_lookup` (`division`,`district`,`udise_code`,`is_active`,`expiry_date`);

--
-- Indexes for table `other_school_activities`
--
ALTER TABLE `other_school_activities`
  ADD PRIMARY KEY (`activity_id`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_activity_date` (`activity_date`),
  ADD KEY `idx_approval_status` (`approval_status`),
  ADD KEY `idx_status` (`status`);

--
-- Indexes for table `palak_melava`
--
ALTER TABLE `palak_melava`
  ADD PRIMARY KEY (`melava_id`),
  ADD KEY `idx_palak_melava_udise` (`udise_no`),
  ADD KEY `idx_palak_melava_status` (`status`),
  ADD KEY `idx_palak_melava_date` (`meeting_date`);

--
-- Indexes for table `phase_approvals`
--
ALTER TABLE `phase_approvals`
  ADD PRIMARY KEY (`approval_id`),
  ADD UNIQUE KEY `unique_phase_approval` (`udise_no`,`phase_number`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_status` (`approval_status`),
  ADD KEY `idx_phase` (`phase_number`);

--
-- Indexes for table `phase_completion_status`
--
ALTER TABLE `phase_completion_status`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_school_phase` (`udise_no`,`phase`);

--
-- Indexes for table `report_approvals`
--
ALTER TABLE `report_approvals`
  ADD PRIMARY KEY (`approval_id`),
  ADD KEY `idx_pen` (`pen_number`),
  ADD KEY `idx_udise` (`udise_code`),
  ADD KEY `idx_status` (`approval_status`),
  ADD KEY `idx_requested_by` (`requested_by`),
  ADD KEY `idx_approved_by` (`approved_by`);

--
-- Indexes for table `schools`
--
ALTER TABLE `schools`
  ADD PRIMARY KEY (`school_id`),
  ADD UNIQUE KEY `udise_no` (`udise_no`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_district` (`district_name`),
  ADD KEY `idx_school_name` (`school_name`);

--
-- Indexes for table `school_contacts`
--
ALTER TABLE `school_contacts`
  ADD PRIMARY KEY (`contact_id`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_district` (`district_name`),
  ADD KEY `idx_contact_type` (`contact_type`),
  ADD KEY `idx_mobile` (`mobile`);

--
-- Indexes for table `students`
--
ALTER TABLE `students`
  ADD PRIMARY KEY (`student_id`),
  ADD KEY `idx_division` (`division`),
  ADD KEY `idx_district` (`district`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_class` (`class`),
  ADD KEY `idx_student_pen` (`student_pen`),
  ADD KEY `idx_marathi_levels` (`marathi_akshara_level`,`marathi_shabda_level`,`marathi_vakya_level`,`marathi_samajpurvak_level`),
  ADD KEY `idx_math_levels` (`math_akshara_level`,`math_shabda_level`,`math_vakya_level`,`math_samajpurvak_level`),
  ADD KEY `idx_english_levels` (`english_akshara_level`,`english_shabda_level`,`english_vakya_level`,`english_samajpurvak_level`),
  ADD KEY `idx_is_active` (`is_active`),
  ADD KEY `idx_fln_completed` (`fln_completed`,`udise_no`),
  ADD KEY `idx_udise_class_section_active` (`udise_no`,`class`,`section`,`is_active`);

--
-- Indexes for table `students_audit`
--
ALTER TABLE `students_audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `idx_student_id` (`student_id`),
  ADD KEY `idx_action_type` (`action_type`),
  ADD KEY `idx_changed_at` (`changed_at`),
  ADD KEY `idx_changed_by` (`changed_by`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_student_pen` (`student_pen`),
  ADD KEY `idx_student_name` (`student_name`),
  ADD KEY `idx_class` (`class`);

--
-- Indexes for table `student_language_phase`
--
ALTER TABLE `student_language_phase`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_student_phase` (`student_id`,`phase`);

--
-- Indexes for table `student_phase_audit`
--
ALTER TABLE `student_phase_audit`
  ADD PRIMARY KEY (`audit_id`),
  ADD KEY `idx_student_phase` (`student_id`,`phase`),
  ADD KEY `idx_date` (`changed_date`);

--
-- Indexes for table `student_videos`
--
ALTER TABLE `student_videos`
  ADD PRIMARY KEY (`video_id`),
  ADD KEY `idx_student_id` (`student_id`),
  ADD KEY `idx_subject` (`subject`),
  ADD KEY `idx_month` (`month`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_upload_date` (`upload_date`),
  ADD KEY `idx_student_subject` (`student_id`,`subject`),
  ADD KEY `idx_student_month` (`student_id`,`month`),
  ADD KEY `idx_youtube_video_id` (`youtube_video_id`),
  ADD KEY `idx_approval_status` (`approval_status`),
  ADD KEY `idx_udise_approval` (`udise_no`,`approval_status`),
  ADD KEY `idx_approved_by` (`approved_by`);

--
-- Indexes for table `student_weekly_activities`
--
ALTER TABLE `student_weekly_activities`
  ADD PRIMARY KEY (`id`),
  ADD KEY `idx_student` (`student_id`),
  ADD KEY `idx_student_pen` (`student_pen`),
  ADD KEY `idx_udise_class_section` (`udise_no`,`student_class`,`section`),
  ADD KEY `idx_language_week` (`language`,`week_number`),
  ADD KEY `idx_completed` (`completed`),
  ADD KEY `idx_activity_identifier` (`student_id`,`language`,`week_number`,`day_number`,`activity_identifier`);

--
-- Indexes for table `teachers`
--
ALTER TABLE `teachers`
  ADD PRIMARY KEY (`teacher_id`),
  ADD KEY `idx_udise` (`udise_code`),
  ADD KEY `idx_mobile` (`mobile_number`),
  ADD KEY `idx_active` (`is_active`);

--
-- Indexes for table `teacher_assignments`
--
ALTER TABLE `teacher_assignments`
  ADD PRIMARY KEY (`assignment_id`),
  ADD KEY `idx_udise` (`udise_code`),
  ADD KEY `idx_teacher` (`teacher_id`),
  ADD KEY `idx_class_section` (`class`,`section`),
  ADD KEY `idx_active` (`is_active`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `idx_class_teacher` (`udise_code`,`class`,`section`,`is_class_teacher`),
  ADD KEY `idx_division` (`division`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`user_id`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `idx_username` (`username`),
  ADD KEY `idx_user_type` (`user_type`),
  ADD KEY `idx_division` (`division_name`),
  ADD KEY `idx_district` (`district_name`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_active` (`is_active`);

--
-- Indexes for table `videos`
--
ALTER TABLE `videos`
  ADD PRIMARY KEY (`video_id`),
  ADD UNIQUE KEY `youtube_video_id` (`youtube_video_id`),
  ADD KEY `idx_category` (`category`),
  ADD KEY `idx_sub_category` (`sub_category`),
  ADD KEY `idx_status` (`status`),
  ADD KEY `idx_upload_date` (`upload_date`);

--
-- Indexes for table `video_views`
--
ALTER TABLE `video_views`
  ADD PRIMARY KEY (`view_id`),
  ADD KEY `idx_video_id` (`video_id`),
  ADD KEY `idx_view_date` (`view_date`);

--
-- Indexes for table `weekly_activities`
--
ALTER TABLE `weekly_activities`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `unique_activity` (`udise_no`,`student_class`,`section`,`subject`,`week_number`,`day`),
  ADD KEY `idx_udise` (`udise_no`),
  ADD KEY `idx_class_section` (`student_class`,`section`),
  ADD KEY `idx_week` (`week_number`),
  ADD KEY `idx_subject` (`subject`),
  ADD KEY `idx_completed` (`completed`);

--
-- Indexes for table `youtube_credentials`
--
ALTER TABLE `youtube_credentials`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `credential_name` (`credential_name`),
  ADD KEY `idx_credential_name` (`credential_name`),
  ADD KEY `idx_active` (`is_active`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `language_level_audit`
--
ALTER TABLE `language_level_audit`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `login_audit`
--
ALTER TABLE `login_audit`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `notifications`
--
ALTER TABLE `notifications`
  MODIFY `notification_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `other_school_activities`
--
ALTER TABLE `other_school_activities`
  MODIFY `activity_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `palak_melava`
--
ALTER TABLE `palak_melava`
  MODIFY `melava_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phase_approvals`
--
ALTER TABLE `phase_approvals`
  MODIFY `approval_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `phase_completion_status`
--
ALTER TABLE `phase_completion_status`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `report_approvals`
--
ALTER TABLE `report_approvals`
  MODIFY `approval_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `schools`
--
ALTER TABLE `schools`
  MODIFY `school_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `school_contacts`
--
ALTER TABLE `school_contacts`
  MODIFY `contact_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `students`
--
ALTER TABLE `students`
  MODIFY `student_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `students_audit`
--
ALTER TABLE `students_audit`
  MODIFY `audit_id` bigint(20) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student_language_phase`
--
ALTER TABLE `student_language_phase`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student_phase_audit`
--
ALTER TABLE `student_phase_audit`
  MODIFY `audit_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student_videos`
--
ALTER TABLE `student_videos`
  MODIFY `video_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `student_weekly_activities`
--
ALTER TABLE `student_weekly_activities`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `teachers`
--
ALTER TABLE `teachers`
  MODIFY `teacher_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `teacher_assignments`
--
ALTER TABLE `teacher_assignments`
  MODIFY `assignment_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `user_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `videos`
--
ALTER TABLE `videos`
  MODIFY `video_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `video_views`
--
ALTER TABLE `video_views`
  MODIFY `view_id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `weekly_activities`
--
ALTER TABLE `weekly_activities`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `youtube_credentials`
--
ALTER TABLE `youtube_credentials`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT;

-- --------------------------------------------------------

--
-- Structure for view `vw_active_users_summary`
--
DROP TABLE IF EXISTS `vw_active_users_summary`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_active_users_summary`  AS SELECT `users`.`user_type` AS `user_type`, count(0) AS `total_users`, sum(case when `users`.`is_active` = 1 then 1 else 0 end) AS `active_users`, sum(case when `users`.`is_first_login` = 1 then 1 else 0 end) AS `pending_first_login`, sum(case when `users`.`account_locked` = 1 then 1 else 0 end) AS `locked_accounts` FROM `users` GROUP BY `users`.`user_type` ;

-- --------------------------------------------------------

--
-- Structure for view `vw_district_users`
--
DROP TABLE IF EXISTS `vw_district_users`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_district_users`  AS SELECT `users`.`user_id` AS `user_id`, `users`.`username` AS `username`, `users`.`user_type` AS `user_type`, `users`.`district_name` AS `district_name`, `users`.`division_name` AS `division_name`, `users`.`is_active` AS `is_active`, `users`.`is_first_login` AS `is_first_login`, `users`.`last_login_date` AS `last_login_date`, `users`.`created_date` AS `created_date` FROM `users` WHERE `users`.`user_type` in ('DISTRICT_COORDINATOR','DISTRICT_2ND_COORDINATOR') ORDER BY `users`.`district_name` ASC, `users`.`user_type` ASC ;

-- --------------------------------------------------------

--
-- Structure for view `vw_division_users`
--
DROP TABLE IF EXISTS `vw_division_users`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_division_users`  AS SELECT `users`.`user_id` AS `user_id`, `users`.`username` AS `username`, `users`.`division_name` AS `division_name`, `users`.`is_active` AS `is_active`, `users`.`is_first_login` AS `is_first_login`, `users`.`last_login_date` AS `last_login_date`, `users`.`created_date` AS `created_date` FROM `users` WHERE `users`.`user_type` = 'DIVISION' ;

-- --------------------------------------------------------

--
-- Structure for view `vw_school_users`
--
DROP TABLE IF EXISTS `vw_school_users`;

CREATE ALGORITHM=UNDEFINED DEFINER=`root`@`localhost` SQL SECURITY DEFINER VIEW `vw_school_users`  AS SELECT `users`.`user_id` AS `user_id`, `users`.`username` AS `username`, `users`.`user_type` AS `user_type`, `users`.`udise_no` AS `udise_no`, `users`.`district_name` AS `district_name`, `users`.`division_name` AS `division_name`, `users`.`is_active` AS `is_active`, `users`.`is_first_login` AS `is_first_login`, `users`.`last_login_date` AS `last_login_date`, `users`.`created_date` AS `created_date` FROM `users` WHERE `users`.`user_type` in ('SCHOOL_COORDINATOR','HEAD_MASTER') ORDER BY `users`.`udise_no` ASC, `users`.`user_type` ASC ;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `language_level_audit`
--
ALTER TABLE `language_level_audit`
  ADD CONSTRAINT `language_level_audit_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `login_audit`
--
ALTER TABLE `login_audit`
  ADD CONSTRAINT `login_audit_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `notifications`
--
ALTER TABLE `notifications`
  ADD CONSTRAINT `fk_notification_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE CASCADE;

--
-- Constraints for table `palak_melava`
--
ALTER TABLE `palak_melava`
  ADD CONSTRAINT `palak_melava_ibfk_1` FOREIGN KEY (`udise_no`) REFERENCES `schools` (`udise_no`) ON UPDATE CASCADE;

--
-- Constraints for table `report_approvals`
--
ALTER TABLE `report_approvals`
  ADD CONSTRAINT `report_approvals_ibfk_1` FOREIGN KEY (`requested_by`) REFERENCES `users` (`user_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `report_approvals_ibfk_2` FOREIGN KEY (`approved_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `student_language_phase`
--
ALTER TABLE `student_language_phase`
  ADD CONSTRAINT `student_language_phase_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `student_phase_audit`
--
ALTER TABLE `student_phase_audit`
  ADD CONSTRAINT `student_phase_audit_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`);

--
-- Constraints for table `student_videos`
--
ALTER TABLE `student_videos`
  ADD CONSTRAINT `student_videos_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `student_weekly_activities`
--
ALTER TABLE `student_weekly_activities`
  ADD CONSTRAINT `student_weekly_activities_ibfk_1` FOREIGN KEY (`student_id`) REFERENCES `students` (`student_id`) ON DELETE CASCADE;

--
-- Constraints for table `teacher_assignments`
--
ALTER TABLE `teacher_assignments`
  ADD CONSTRAINT `teacher_assignments_ibfk_1` FOREIGN KEY (`teacher_id`) REFERENCES `teachers` (`teacher_id`) ON DELETE CASCADE,
  ADD CONSTRAINT `teacher_assignments_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL;

--
-- Constraints for table `video_views`
--
ALTER TABLE `video_views`
  ADD CONSTRAINT `video_views_ibfk_1` FOREIGN KEY (`video_id`) REFERENCES `videos` (`video_id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
