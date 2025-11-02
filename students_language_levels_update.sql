-- =====================================================
-- Add Language Proficiency Tracking Columns
-- मराठी भाषा स्तर (Marathi Language Levels)
-- =====================================================

USE vjnt_class_management;

-- Add new columns for detailed Marathi language tracking
ALTER TABLE students
ADD COLUMN marathi_akshara_level INT DEFAULT 0 COMMENT 'अक्षर स्तरावरील (वाचन व लेखन)',
ADD COLUMN marathi_shabda_level INT DEFAULT 0 COMMENT 'शब्द स्तरावरील (वाचन व लेखन)',
ADD COLUMN marathi_vakya_level INT DEFAULT 0 COMMENT 'वाक्य स्तरावरील',
ADD COLUMN marathi_samajpurvak_level INT DEFAULT 0 COMMENT 'समजपुर्वक उतार वाचन स्तरावरील';

-- Add new columns for Math levels (गणित स्तर)
ALTER TABLE students
ADD COLUMN math_akshara_level INT DEFAULT 0 COMMENT 'गणित - अक्षर स्तर',
ADD COLUMN math_shabda_level INT DEFAULT 0 COMMENT 'गणित - शब्द स्तर',
ADD COLUMN math_vakya_level INT DEFAULT 0 COMMENT 'गणित - वाक्य स्तर',
ADD COLUMN math_samajpurvak_level INT DEFAULT 0 COMMENT 'गणित - समजपुर्वक स्तर';

-- Add new columns for English levels (इंग्रजी स्तर)
ALTER TABLE students
ADD COLUMN english_akshara_level INT DEFAULT 0 COMMENT 'English - Letter Level',
ADD COLUMN english_shabda_level INT DEFAULT 0 COMMENT 'English - Word Level',
ADD COLUMN english_vakya_level INT DEFAULT 0 COMMENT 'English - Sentence Level',
ADD COLUMN english_samajpurvak_level INT DEFAULT 0 COMMENT 'English - Comprehension Level';

-- Add index for performance queries
ALTER TABLE students
ADD INDEX idx_marathi_levels (marathi_akshara_level, marathi_shabda_level, marathi_vakya_level, marathi_samajpurvak_level),
ADD INDEX idx_math_levels (math_akshara_level, math_shabda_level, math_vakya_level, math_samajpurvak_level),
ADD INDEX idx_english_levels (english_akshara_level, english_shabda_level, english_vakya_level, english_samajpurvak_level);

-- Display updated schema
DESCRIBE students;

SELECT 'Schema updated successfully!' AS status;
