-- =====================================================================
-- Division-wise Activity Visibility (managed by Data Admin)
-- Controls which Quick Action cards School Coordinators can see,
-- per division. Missing config rows = activity visible (default).
--
-- NOTE: These tables are ALSO auto-created and seeded by
-- ActivityVisibilityDAO.ensureTables() on first use, so running this
-- script manually is optional (reference / fresh-DB setup).
-- =====================================================================

CREATE TABLE IF NOT EXISTS activity_master (
  activity_code VARCHAR(50) PRIMARY KEY,
  activity_name VARCHAR(100) NOT NULL,
  activity_name_marathi VARCHAR(150),
  icon VARCHAR(10),
  display_order INT DEFAULT 0,
  is_active TINYINT(1) DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS division_activity_config (
  config_id INT AUTO_INCREMENT PRIMARY KEY,
  division_name VARCHAR(100) NOT NULL,
  activity_code VARCHAR(50) NOT NULL,
  is_enabled TINYINT(1) NOT NULL DEFAULT 1,
  updated_by VARCHAR(100),
  updated_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uk_division_activity (division_name, activity_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

INSERT IGNORE INTO activity_master (activity_code, activity_name, activity_name_marathi, icon, display_order) VALUES
('MANAGE_STUDENTS',         'Manage Students',                    'विद्यार्थी स्तर निश्चिती',            '📚', 1),
('PALAK_MELAVA',            'Parents Meeting',                    'पालक मेळावा',                         '👥', 2),
('ADD_STUDENT',             'Add Student',                        'विद्यार्थी जोडा',                     '➕', 3),
('ADD_TEACHER',             'Add Teacher',                        'शिक्षक जोडा',                         '👨‍🏫', 4),
('EDIT_STUDENT',            'Edit Student',                       'विद्यार्थी संपादित करा',               '✏️', 5),
('MANAGE_TEACHERS',         'Manage Teachers',                    'शिक्षक व्यवस्थापन',                   '👨‍🏫', 6),
('ASSIGN_TEACHER',          'Class / Subject Teacher Assignment', 'वर्ग शिक्षक / विषय शिक्षक निश्चिती',   '📋', 7),
('OTHER_SCHOOL_ACTIVITY',   'Other School Activity',              'इतर शालेय उपक्रम',                    '🎯', 8),
('VIEW_STUDENT_DATA',       'View All Student Data',              'सर्व विद्यार्थी डेटा',                '📊', 9),
('STUDENT_PHASE_HISTORY',   'Student Phase History',              'विद्यार्थी टप्पा इतिहास',              '📋', 10),
('STUDENT_ACTIVITY',        'Student Activities',                 'विद्यार्थी उपक्रम',                   '🏅', 11),
('GRADUATED_STUDENTS',      'Graduated Students',                 'उत्तीर्ण विद्यार्थी',                 '🎓', 12),
('FLN_COMPLETED',           'FLN Completed Students',             'FLN 100% पूर्ण विद्यार्थी',           '🏆', 13),
('GENERATE_STUDENT_REPORT', 'Generate Student Report',            'विद्यार्थी अहवाल तयार करा',            '📊', 14);
