-- ============================================================
-- VJNT Class Management — Audit & Graduation Tables
-- Run once against gateepor_vjnt_class_management
-- ============================================================

-- 1. Master log: one row per promotion event
CREATE TABLE IF NOT EXISTS class_promotion_log (
    promotion_id       INT          NOT NULL AUTO_INCREMENT,
    academic_year      VARCHAR(10)  NOT NULL,
    promoted_by        VARCHAR(100) NOT NULL,
    promotion_date     DATETIME     NOT NULL,
    students_promoted  INT          NOT NULL DEFAULT 0,
    students_graduated INT          NOT NULL DEFAULT 0,
    remarks            TEXT,
    PRIMARY KEY (promotion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Phase snapshot for every active student at promotion time
CREATE TABLE IF NOT EXISTS student_phase_history (
    history_id      INT          NOT NULL AUTO_INCREMENT,
    promotion_id    INT          NOT NULL,
    student_id      INT          NOT NULL,
    student_name    VARCHAR(255),
    student_pen     VARCHAR(50),
    udise_no        VARCHAR(20),
    division        VARCHAR(100),
    district        VARCHAR(100),
    class_before    VARCHAR(10),
    class_after     VARCHAR(10),
    phase1_marathi  INT,
    phase1_math     INT,
    phase1_english  INT,
    phase1_date     DATETIME,
    phase2_marathi  INT,
    phase2_math     INT,
    phase2_english  INT,
    phase2_date     DATETIME,
    phase3_marathi  INT,
    phase3_math     INT,
    phase3_english  INT,
    phase3_date     DATETIME,
    phase4_marathi  INT,
    phase4_math     INT,
    phase4_english  INT,
    phase4_date     DATETIME,
    archived_at     DATETIME     NOT NULL,
    PRIMARY KEY (history_id),
    INDEX idx_sph_promotion (promotion_id),
    INDEX idx_sph_student   (student_id),
    INDEX idx_sph_udise     (udise_no),
    CONSTRAINT fk_sph_promotion FOREIGN KEY (promotion_id)
        REFERENCES class_promotion_log (promotion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Permanent graduate record (Class 9 exits)
CREATE TABLE IF NOT EXISTS graduated_students (
    graduation_id        INT          NOT NULL AUTO_INCREMENT,
    promotion_id         INT          NOT NULL,
    student_id           INT          NOT NULL,
    student_name         VARCHAR(255) NOT NULL,
    student_pen          VARCHAR(50),
    gender               VARCHAR(10),
    udise_no             VARCHAR(20),
    division             VARCHAR(100),
    district             VARCHAR(100),
    section              VARCHAR(10),
    graduated_from_class VARCHAR(10)  NOT NULL DEFAULT '9',
    academic_year        VARCHAR(10),
    final_marathi_level  INT,
    final_math_level     INT,
    final_english_level  INT,
    fln_completed        TINYINT(1)   NOT NULL DEFAULT 0,
    phase1_marathi       INT,
    phase1_math          INT,
    phase1_english       INT,
    phase2_marathi       INT,
    phase2_math          INT,
    phase2_english       INT,
    phase3_marathi       INT,
    phase3_math          INT,
    phase3_english       INT,
    phase4_marathi       INT,
    phase4_math          INT,
    phase4_english       INT,
    graduated_at         DATETIME     NOT NULL,
    PRIMARY KEY (graduation_id),
    INDEX idx_gs_promotion    (promotion_id),
    INDEX idx_gs_udise        (udise_no),
    INDEX idx_gs_academic_year(academic_year),
    CONSTRAINT fk_gs_promotion FOREIGN KEY (promotion_id)
        REFERENCES class_promotion_log (promotion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Archive of Head Master approval decisions before phase_approvals is cleared
CREATE TABLE IF NOT EXISTS phase_approvals_history (
    history_id      INT          NOT NULL AUTO_INCREMENT,
    promotion_id    INT          NOT NULL,
    udise_no        VARCHAR(20),
    phase_number    INT,
    approval_status VARCHAR(50),
    approved_by     VARCHAR(100),
    approval_date   DATETIME,
    remarks         TEXT,
    archived_at     DATETIME     NOT NULL,
    PRIMARY KEY (history_id),
    INDEX idx_pah_promotion (promotion_id),
    CONSTRAINT fk_pah_promotion FOREIGN KEY (promotion_id)
        REFERENCES class_promotion_log (promotion_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
