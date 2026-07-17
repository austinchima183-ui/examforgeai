-- ============================================================================
-- ExamForge AI - Question Bank Module Schema
-- ============================================================================
-- Production-ready schema for the Question Bank module.
-- Supports millions of questions across thousands of schools.
--
-- Prerequisites: Existing tables (schools, users, classes, subjects,
--                class_subjects, class_students, notifications, audit_log)
--                and existing enums (user_role, subscription_status,
--                exam_status, notification_type, question_type)
--
-- Performance: Designed for high-throughput with composite indexes,
--              GIN indexes for JSONB/full-text, and partitioning-ready layout.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. EXTEND EXISTING ENUMS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Extend question_type with additional types for richer question formats
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  -- Add new values to the existing question_type enum
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'multiple_response' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'multiple_response';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'matching' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'matching';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'ordering' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'ordering';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'numerical' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'numerical';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'image_based' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'image_based';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'audio_based' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'audio_based';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'video_based' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'video_based';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'practical' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'practical';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = 'case_study' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = 'question_type')) THEN
    ALTER TYPE question_type ADD VALUE 'case_study';
  END IF;
END
$$;

COMMENT ON TYPE question_type IS
  'Supported question formats: MC, MR, T/F, short answer, essay, fill-in-blank, matching, ordering, numerical, media-based, practical, case study';

-- ============================================================================
-- 2. NEW ENUMERATION TYPES
-- ============================================================================

DO $$
BEGIN
  -- difficulty_level: Question difficulty classification
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'difficulty_level') THEN
    CREATE TYPE difficulty_level AS ENUM (
      'easy',
      'medium',
      'hard',
      'expert'
    );
  END IF;

  -- exam_type: Nigerian and international examination bodies / contexts
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'exam_type') THEN
    CREATE TYPE exam_type AS ENUM (
      'waecc',
      'neco',
      'jamb',
      'school_exam',
      'mock',
      'practice',
      'custom'
    );
  END IF;

  -- share_permission: Granular permissions for shared questions
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'share_permission') THEN
    CREATE TYPE share_permission AS ENUM (
      'read',
      'comment',
      'edit'
    );
  END IF;

  -- import_status: Lifecycle states for bulk import jobs
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'import_status') THEN
    CREATE TYPE import_status AS ENUM (
      'pending',
      'processing',
      'completed',
      'failed'
    );
  END IF;

  -- content_type: Media / attachment content classification
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'content_type') THEN
    CREATE TYPE content_type AS ENUM (
      'text',
      'image',
      'audio',
      'video',
      'document'
    );
  END IF;

  -- curriculum_standard_type: Nigerian curriculum framework types
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'curriculum_standard_type') THEN
    CREATE TYPE curriculum_standard_type AS ENUM (
      'nigeria_erc',
      'waec',
      'neco',
      'jamb',
      'custom'
    );
  END IF;
END
$$;

COMMENT ON TYPE difficulty_level IS 'Question difficulty: easy → medium → hard → expert';
COMMENT ON TYPE exam_type IS 'Examination body or context for which the question is designed';
COMMENT ON TYPE share_permission IS 'Permission level when sharing a question: read, comment, or edit';
COMMENT ON TYPE import_status IS 'Status of a bulk question import/export job';
COMMENT ON TYPE content_type IS 'Type of media content attached to a question';
COMMENT ON TYPE curriculum_standard_type IS 'Curriculum framework a standard belongs to';

-- ============================================================================
-- 3. TOPICS TABLE
-- ============================================================================
-- Hierarchical grouping of subjects into topics (e.g., Mathematics → Algebra)
-- ============================================================================

CREATE TABLE IF NOT EXISTS topics (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  subject_id    UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  description   TEXT,
  code          TEXT,                       -- e.g. "ALG-01"
  sort_order    INTEGER DEFAULT 0,
  is_active     BOOLEAN DEFAULT true,
  created_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE topics IS 'Topics within a subject (e.g. Algebra under Mathematics)';
COMMENT ON COLUMN topics.code IS 'Short code identifier for the topic (e.g. ALG-01)';

-- ============================================================================
-- 4. SUBTOPICS TABLE
-- ============================================================================
-- Further subdivision of topics into subtopics
-- ============================================================================

CREATE TABLE IF NOT EXISTS subtopics (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  topic_id      UUID NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  description   TEXT,
  code          TEXT,                       -- e.g. "ALG-01-01"
  sort_order    INTEGER DEFAULT 0,
  is_active     BOOLEAN DEFAULT true,
  created_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE subtopics IS 'Subtopics under a topic for finer-grained categorization';

-- ============================================================================
-- 5. QUESTION_CATEGORIES TABLE
-- ============================================================================
-- System-wide and school-specific question categories for organization
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_categories (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  description   TEXT,
  school_id     UUID REFERENCES schools(id) ON DELETE CASCADE,  -- NULL = system-wide
  icon          TEXT,                       -- Icon name or class
  color         TEXT,                       -- Hex color code
  sort_order    INTEGER DEFAULT 0,
  is_active     BOOLEAN DEFAULT true,
  created_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE question_categories IS
  'Categorization labels for questions; school_id NULL means platform-wide category';

-- ============================================================================
-- 6. ACADEMIC_SESSIONS TABLE
-- ============================================================================
-- Academic sessions/terms for organizing questions temporally
-- ============================================================================

CREATE TABLE IF NOT EXISTS academic_sessions (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,              -- e.g. "2024/2025"
  start_date    DATE NOT NULL,
  end_date      DATE NOT NULL,
  term          VARCHAR(20),                -- e.g. "First Term", "Second Term", "Third Term"
  is_current    BOOLEAN DEFAULT false,
  school_id     UUID REFERENCES schools(id) ON DELETE CASCADE,
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT academic_sessions_date_range CHECK (end_date > start_date)
);

COMMENT ON TABLE academic_sessions IS 'Academic sessions/terms for organizing questions by time period';
COMMENT ON COLUMN academic_sessions.term IS 'Term within the academic year (e.g. First Term, Second Term)';

-- ============================================================================
-- 7. CURRICULUM_STANDARDS TABLE
-- ============================================================================
-- Curriculum standards that questions can be aligned to
-- ============================================================================

CREATE TABLE IF NOT EXISTS curriculum_standards (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  type          curriculum_standard_type NOT NULL,
  description   TEXT,
  subject_id    UUID REFERENCES subjects(id) ON DELETE CASCADE,
  class_id      UUID REFERENCES classes(id) ON DELETE CASCADE,
  code          TEXT,
  objectives    TEXT[],                     -- Array of learning objectives
  is_active     BOOLEAN DEFAULT true,
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE curriculum_standards IS
  'Curriculum standards for aligning questions to educational frameworks';

-- ============================================================================
-- 8. QUESTION_BANK TABLE (THE MAIN TABLE)
-- ============================================================================
-- Central repository for all questions. Designed for millions of rows.
-- - school_id NULL = platform-wide question (visible to all schools)
-- - parent_id = previous version (versioning chain)
-- - content_json = structured data for complex question types
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_bank (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,  -- NULL = platform-wide
  subject_id              UUID NOT NULL REFERENCES subjects(id),
  topic_id                UUID REFERENCES topics(id) ON DELETE SET NULL,
  subtopic_id             UUID REFERENCES subtopics(id) ON DELETE SET NULL,
  class_id                UUID REFERENCES classes(id) ON DELETE SET NULL,
  category_id             UUID REFERENCES question_categories(id) ON DELETE SET NULL,
  curriculum_standard_id  UUID REFERENCES curriculum_standards(id) ON DELETE SET NULL,
  academic_session_id     UUID REFERENCES academic_sessions(id) ON DELETE SET NULL,
  question_type           question_type NOT NULL DEFAULT 'multiple_choice',
  difficulty              difficulty_level NOT NULL DEFAULT 'medium',
  exam_type               exam_type DEFAULT 'school_exam',
  content                 TEXT NOT NULL,                  -- Question text (HTML/LaTeX supported)
  content_json            JSONB DEFAULT '{}',             -- Structured content for complex types
  explanation             TEXT,                           -- Detailed answer explanation
  teacher_notes           TEXT,                           -- Private notes for teachers
  reference_materials     TEXT,                           -- Reference sources
  marks                   NUMERIC(5,2) NOT NULL DEFAULT 1.00,
  negative_marks          NUMERIC(5,2) DEFAULT 0.00,
  time_allowed_seconds    INTEGER,                        -- Suggested time to answer
  is_published            BOOLEAN DEFAULT false,
  is_archived             BOOLEAN DEFAULT false,
  is_featured             BOOLEAN DEFAULT false,
  version                 INTEGER DEFAULT 1,
  parent_id               UUID REFERENCES question_bank(id) ON DELETE SET NULL,  -- Version chain
  created_by              UUID NOT NULL REFERENCES users(id),
  updated_by              UUID REFERENCES users(id),
  usage_count             INTEGER DEFAULT 0,
  avg_score               NUMERIC(5,2) DEFAULT 0.00,
  metadata                JSONB DEFAULT '{}',             -- Extensible metadata
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now(),

  -- Ensure non-negative marks
  CONSTRAINT question_bank_marks_positive CHECK (marks >= 0),
  CONSTRAINT question_bank_negative_marks_non_negative CHECK (negative_marks >= 0),
  CONSTRAINT question_bank_avg_score_range CHECK (avg_score >= 0 AND avg_score <= marks),
  -- A question cannot be both published and archived
  CONSTRAINT question_bank_not_published_and_archived CHECK (NOT (is_published = true AND is_archived = true))
);

COMMENT ON TABLE question_bank IS 'Central question repository supporting millions of questions';
COMMENT ON COLUMN question_bank.school_id IS 'Owning school; NULL means platform-wide question visible to all';
COMMENT ON COLUMN question_bank.content IS 'The question text — supports HTML and LaTeX formatting';
COMMENT ON COLUMN question_bank.content_json IS 'Structured content payload for complex question types (matching, ordering, etc.)';
COMMENT ON COLUMN question_bank.parent_id IS 'Previous version of this question for versioning chain';
COMMENT ON COLUMN question_bank.metadata IS 'Extensible JSONB metadata for custom attributes and integrations';
COMMENT ON COLUMN question_bank.usage_count IS 'Number of times this question has been used in exams';

-- ============================================================================
-- 9. ANSWER_OPTIONS TABLE
-- ============================================================================
-- Options for multiple-choice, multiple-response, and true/false questions
-- ============================================================================

CREATE TABLE IF NOT EXISTS answer_options (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id   UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  content       TEXT NOT NULL,
  content_json  JSONB DEFAULT '{}',         -- For complex answer content (images, math, etc.)
  is_correct    BOOLEAN NOT NULL DEFAULT false,
  marks         NUMERIC(5,2) DEFAULT 0.00,  -- Partial marks for this option
  sort_order    INTEGER DEFAULT 0,
  explanation   TEXT,                        -- Why this option is correct/incorrect
  metadata      JSONB DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT now(),
  updated_at    TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE answer_options IS 'Answer options for MC, MR, and T/F question types';
COMMENT ON COLUMN answer_options.marks IS 'Partial marks awarded for selecting this option';

-- ============================================================================
-- 10. MATCHING_PAIRS TABLE
-- ============================================================================
-- Pairs for matching question type (left ↔ right mapping)
-- ============================================================================

CREATE TABLE IF NOT EXISTS matching_pairs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id     UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  left_content    TEXT NOT NULL,
  right_content   TEXT NOT NULL,
  left_media_url  TEXT,
  right_media_url TEXT,
  sort_order      INTEGER DEFAULT 0,
  created_at      TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE matching_pairs IS 'Left-right matching pairs for matching question type';

-- ============================================================================
-- 11. ORDERING_ITEMS TABLE
-- ============================================================================
-- Items for ordering/sequencing question type
-- ============================================================================

CREATE TABLE IF NOT EXISTS ordering_items (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id       UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  content           TEXT NOT NULL,
  correct_position  INTEGER NOT NULL,
  media_url         TEXT,
  created_at        TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE ordering_items IS 'Items to be ordered/sequenced for ordering question type';
COMMENT ON COLUMN ordering_items.correct_position IS 'The correct position of this item (1-based)';

-- ============================================================================
-- 12. FILL_IN_BLANK_ANSWERS TABLE
-- ============================================================================
-- Acceptable answers for fill-in-the-blank questions
-- ============================================================================

CREATE TABLE IF NOT EXISTS fill_in_blank_answers (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id         UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  blank_index         INTEGER NOT NULL,              -- Which blank (0-based)
  acceptable_answers  TEXT[] NOT NULL,               -- Array of acceptable answer strings
  is_case_sensitive   BOOLEAN DEFAULT false,
  marks               NUMERIC(5,2) DEFAULT 1.00,
  created_at          TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE fill_in_blank_answers IS 'Acceptable answers for each blank in fill-in-the-blank questions';
COMMENT ON COLUMN fill_in_blank_answers.blank_index IS 'Zero-based index of the blank in the question text';
COMMENT ON COLUMN fill_in_blank_answers.acceptable_answers IS 'Array of valid answer strings for this blank';

-- ============================================================================
-- 13. QUESTION_ATTACHMENTS TABLE
-- ============================================================================
-- Media attachments (images, audio, video, documents) for questions
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_attachments (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id   UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  content_type  content_type NOT NULL,
  url           TEXT NOT NULL,
  thumbnail_url TEXT,
  file_name     TEXT,
  file_size     BIGINT,                     -- Size in bytes
  mime_type     TEXT,
  alt_text      TEXT,                        -- Accessibility alt text
  caption       TEXT,
  sort_order    INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE question_attachments IS 'Media attachments for questions (images, audio, video, documents)';

-- ============================================================================
-- 14. QUESTION_TAGS TABLE
-- ============================================================================
-- Tags for flexible categorization and search. School-scoped or platform-wide.
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_tags (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name          TEXT NOT NULL,
  school_id     UUID REFERENCES schools(id) ON DELETE CASCADE,  -- NULL = system-wide
  usage_count   INTEGER DEFAULT 0,
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(name, school_id)
);

COMMENT ON TABLE question_tags IS 'Tags for flexible question categorization; school_id NULL = platform-wide';

-- ============================================================================
-- 15. QUESTION_TAG_RELATIONS TABLE
-- ============================================================================
-- Many-to-many relation between questions and tags
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_tag_relations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id   UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  tag_id        UUID NOT NULL REFERENCES question_tags(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(question_id, tag_id)
);

COMMENT ON TABLE question_tag_relations IS 'Many-to-many relationship between questions and tags';

-- ============================================================================
-- 16. QUESTION_COLLECTIONS TABLE
-- ============================================================================
-- Named collections / playlists of questions for organization and sharing
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_collections (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  description     TEXT,
  school_id       UUID REFERENCES schools(id) ON DELETE CASCADE,
  created_by      UUID NOT NULL REFERENCES users(id),
  is_shared       BOOLEAN DEFAULT false,     -- School-wide visibility
  is_official     BOOLEAN DEFAULT false,     -- Curated by school admin
  question_count  INTEGER DEFAULT 0,
  cover_image_url TEXT,
  sort_order      INTEGER DEFAULT 0,
  is_active       BOOLEAN DEFAULT true,
  created_at      TIMESTAMPTZ DEFAULT now(),
  updated_at      TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE question_collections IS
  'Named collections of questions; is_shared = visible school-wide, is_official = admin-curated';

-- ============================================================================
-- 17. COLLECTION_QUESTIONS TABLE
-- ============================================================================
-- Many-to-many between collections and questions with ordering
-- ============================================================================

CREATE TABLE IF NOT EXISTS collection_questions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  collection_id   UUID NOT NULL REFERENCES question_collections(id) ON DELETE CASCADE,
  question_id     UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  sort_order      INTEGER DEFAULT 0,
  added_by        UUID REFERENCES users(id) ON DELETE SET NULL,
  notes           TEXT,
  created_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE(collection_id, question_id)
);

COMMENT ON TABLE collection_questions IS 'Questions within a collection, with ordering and notes';

-- ============================================================================
-- 18. QUESTION_FAVORITES TABLE
-- ============================================================================
-- User bookmarks / favorites for quick access to questions
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_favorites (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  question_id   UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  created_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, question_id)
);

COMMENT ON TABLE question_favorites IS 'User bookmarks for quick access to frequently used questions';

-- ============================================================================
-- 19. QUESTION_SHARES TABLE
-- ============================================================================
-- Sharing questions between users and across schools with permission levels
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_shares (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id   UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  shared_by     UUID NOT NULL REFERENCES users(id),
  shared_with   UUID REFERENCES users(id),              -- NULL = school-wide share
  permission    share_permission NOT NULL DEFAULT 'read',
  message       TEXT,
  expires_at    TIMESTAMPTZ,
  is_accepted   BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE question_shares IS
  'Question sharing records; shared_with NULL = school-wide; permission controls access level';

-- ============================================================================
-- 20. QUESTION_VERSION_HISTORY TABLE
-- ============================================================================
-- Immutable version snapshots for audit trail and rollback capability
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_version_history (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id         UUID NOT NULL REFERENCES question_bank(id) ON DELETE CASCADE,
  version             INTEGER NOT NULL,
  snapshot            JSONB NOT NULL,           -- Complete question snapshot
  change_description  TEXT,
  changed_by          UUID NOT NULL REFERENCES users(id),
  change_type         VARCHAR(20) NOT NULL,     -- 'create', 'update', 'restore', 'archive', 'publish'
  created_at          TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT qvh_valid_change_type CHECK (
    change_type IN ('create', 'update', 'restore', 'archive', 'publish')
  )
);

COMMENT ON TABLE question_version_history IS 'Immutable version snapshots for question change tracking and rollback';
COMMENT ON COLUMN question_version_history.snapshot IS 'Complete JSONB snapshot of the question at this version';

-- ============================================================================
-- 21. QUESTION_IMPORTS TABLE
-- ============================================================================
-- Bulk import job tracking for CSV, Excel, DOCX, PDF, JSON uploads
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_imports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID REFERENCES schools(id) ON DELETE CASCADE,
  uploaded_by     UUID NOT NULL REFERENCES users(id),
  file_name       TEXT NOT NULL,
  file_url        TEXT NOT NULL,
  file_size       BIGINT,
  import_format   VARCHAR(20) NOT NULL,       -- 'csv', 'excel', 'docx', 'pdf', 'json'
  status          import_status NOT NULL DEFAULT 'pending',
  total_questions INTEGER DEFAULT 0,
  imported_count  INTEGER DEFAULT 0,
  failed_count    INTEGER DEFAULT 0,
  error_log       JSONB DEFAULT '[]',         -- Array of error details
  started_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT qi_valid_format CHECK (
    import_format IN ('csv', 'excel', 'docx', 'pdf', 'json')
  )
);

COMMENT ON TABLE question_imports IS 'Bulk question import job tracking';
COMMENT ON COLUMN question_imports.error_log IS 'JSONB array of per-row error details during import';

-- ============================================================================
-- 22. QUESTION_EXPORTS TABLE
-- ============================================================================
-- Export job tracking with filter details
-- ============================================================================

CREATE TABLE IF NOT EXISTS question_exports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID REFERENCES schools(id) ON DELETE CASCADE,
  exported_by     UUID NOT NULL REFERENCES users(id),
  file_name       TEXT NOT NULL,
  file_url        TEXT,
  export_format   VARCHAR(20) NOT NULL,
  total_questions INTEGER DEFAULT 0,
  filters         JSONB DEFAULT '{}',         -- What filters were applied
  status          import_status NOT NULL DEFAULT 'pending',
  created_at      TIMESTAMPTZ DEFAULT now(),
  started_at      TIMESTAMPTZ,
  completed_at    TIMESTAMPTZ
);

COMMENT ON TABLE question_exports IS 'Question export job tracking with filter metadata';

-- ============================================================================
-- 23. INDEXES — PERFORMANCE CRITICAL
-- ============================================================================
-- Designed for millions of rows. Composite indexes target the most common
-- query patterns. GIN indexes support full-text search and JSONB queries.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- question_bank: Single-column indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qb_school_id          ON question_bank(school_id);
CREATE INDEX IF NOT EXISTS idx_qb_subject_id         ON question_bank(subject_id);
CREATE INDEX IF NOT EXISTS idx_qb_topic_id           ON question_bank(topic_id);
CREATE INDEX IF NOT EXISTS idx_qb_difficulty         ON question_bank(difficulty);
CREATE INDEX IF NOT EXISTS idx_qb_question_type      ON question_bank(question_type);
CREATE INDEX IF NOT EXISTS idx_qb_exam_type          ON question_bank(exam_type);
CREATE INDEX IF NOT EXISTS idx_qb_is_published       ON question_bank(is_published);
CREATE INDEX IF NOT EXISTS idx_qb_is_archived        ON question_bank(is_archived);
CREATE INDEX IF NOT EXISTS idx_qb_created_by         ON question_bank(created_by);
CREATE INDEX IF NOT EXISTS idx_qb_created_at         ON question_bank(created_at);
CREATE INDEX IF NOT EXISTS idx_qb_usage_count        ON question_bank(usage_count);
CREATE INDEX IF NOT EXISTS idx_qb_subtopic_id        ON question_bank(subtopic_id);
CREATE INDEX IF NOT EXISTS idx_qb_category_id        ON question_bank(category_id);
CREATE INDEX IF NOT EXISTS idx_qb_curriculum_std_id  ON question_bank(curriculum_standard_id);
CREATE INDEX IF NOT EXISTS idx_qb_academic_session_id ON question_bank(academic_session_id);
CREATE INDEX IF NOT EXISTS idx_qb_parent_id          ON question_bank(parent_id);
CREATE INDEX IF NOT EXISTS idx_qb_class_id           ON question_bank(class_id);
CREATE INDEX IF NOT EXISTS idx_qb_is_featured        ON question_bank(is_featured) WHERE is_featured = true;
CREATE INDEX IF NOT EXISTS idx_qb_version            ON question_bank(version);

-- ---------------------------------------------------------------------------
-- question_bank: GIN indexes for full-text search and JSONB
-- ---------------------------------------------------------------------------
-- Full-text search on content column (supports to_tsvector queries)
CREATE INDEX IF NOT EXISTS idx_qb_content_fts    ON question_bank USING GIN (to_tsvector('english', content));

-- GIN index on metadata JSONB for key/value lookups
CREATE INDEX IF NOT EXISTS idx_qb_metadata_gin   ON question_bank USING GIN (metadata);

-- GIN index on content_json JSONB for complex question type queries
CREATE INDEX IF NOT EXISTS idx_qb_content_json_gin ON question_bank USING GIN (content_json);

-- ---------------------------------------------------------------------------
-- question_bank: Composite indexes for common filter combinations
-- ---------------------------------------------------------------------------
-- Most common query: questions for a subject in a school at a difficulty
CREATE INDEX IF NOT EXISTS idx_qb_school_subject_difficulty
  ON question_bank(school_id, subject_id, difficulty);

-- Published/non-archived questions in a school
CREATE INDEX IF NOT EXISTS idx_qb_school_published_archived
  ON question_bank(school_id, is_published, is_archived);

-- Questions by subject and type (for filtering by question type)
CREATE INDEX IF NOT EXISTS idx_qb_subject_type
  ON question_bank(subject_id, question_type);

-- Questions by school and exam type
CREATE INDEX IF NOT EXISTS idx_qb_school_exam_type
  ON question_bank(school_id, exam_type);

-- Topic + subtopic for hierarchical browsing
CREATE INDEX IF NOT EXISTS idx_qb_topic_subtopic
  ON question_bank(topic_id, subtopic_id);

-- Created by + published for teacher dashboard
CREATE INDEX IF NOT EXISTS idx_qb_created_by_published
  ON question_bank(created_by, is_published);

-- ---------------------------------------------------------------------------
-- answer_options
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ao_question_id    ON answer_options(question_id);
CREATE INDEX IF NOT EXISTS idx_ao_is_correct     ON answer_options(question_id, is_correct) WHERE is_correct = true;

-- ---------------------------------------------------------------------------
-- matching_pairs
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_mp_question_id    ON matching_pairs(question_id);

-- ---------------------------------------------------------------------------
-- ordering_items
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_oi_question_id    ON ordering_items(question_id);

-- ---------------------------------------------------------------------------
-- fill_in_blank_answers
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_fiba_question_id  ON fill_in_blank_answers(question_id);
CREATE INDEX IF NOT EXISTS idx_fiba_blank_index  ON fill_in_blank_answers(question_id, blank_index);

-- ---------------------------------------------------------------------------
-- question_attachments
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qatt_question_id  ON question_attachments(question_id);

-- ---------------------------------------------------------------------------
-- question_tags
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qt_name           ON question_tags(name);
CREATE INDEX IF NOT EXISTS idx_qt_school_id      ON question_tags(school_id);
CREATE INDEX IF NOT EXISTS idx_qt_usage_count    ON question_tags(usage_count DESC);

-- ---------------------------------------------------------------------------
-- question_tag_relations
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qtr_question_id   ON question_tag_relations(question_id);
CREATE INDEX IF NOT EXISTS idx_qtr_tag_id        ON question_tag_relations(tag_id);

-- ---------------------------------------------------------------------------
-- question_collections
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qcol_school_id    ON question_collections(school_id);
CREATE INDEX IF NOT EXISTS idx_qcol_created_by   ON question_collections(created_by);
CREATE INDEX IF NOT EXISTS idx_qcol_is_shared    ON question_collections(is_shared) WHERE is_shared = true;
CREATE INDEX IF NOT EXISTS idx_qcol_is_official  ON question_collections(is_official) WHERE is_official = true;

-- ---------------------------------------------------------------------------
-- collection_questions
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_cq_collection_id  ON collection_questions(collection_id);
CREATE INDEX IF NOT EXISTS idx_cq_question_id    ON collection_questions(question_id);

-- ---------------------------------------------------------------------------
-- question_favorites
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qf_user_id        ON question_favorites(user_id);
CREATE INDEX IF NOT EXISTS idx_qf_question_id    ON question_favorites(question_id);

-- ---------------------------------------------------------------------------
-- question_shares
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qs_question_id    ON question_shares(question_id);
CREATE INDEX IF NOT EXISTS idx_qs_shared_with    ON question_shares(shared_with);
CREATE INDEX IF NOT EXISTS idx_qs_shared_by      ON question_shares(shared_by);
CREATE INDEX IF NOT EXISTS idx_qs_expires        ON question_shares(expires_at) WHERE expires_at IS NOT NULL;

-- ---------------------------------------------------------------------------
-- question_version_history
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qvh_question_id   ON question_version_history(question_id);
CREATE INDEX IF NOT EXISTS idx_qvh_question_version ON question_version_history(question_id, version);
CREATE INDEX IF NOT EXISTS idx_qvh_changed_by    ON question_version_history(changed_by);
CREATE INDEX IF NOT EXISTS idx_qvh_change_type   ON question_version_history(change_type);
CREATE INDEX IF NOT EXISTS idx_qvh_created_at    ON question_version_history(created_at);

-- ---------------------------------------------------------------------------
-- question_imports
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qi_school_id      ON question_imports(school_id);
CREATE INDEX IF NOT EXISTS idx_qi_uploaded_by    ON question_imports(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_qi_status         ON question_imports(status);

-- ---------------------------------------------------------------------------
-- question_exports
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qe_school_id      ON question_exports(school_id);
CREATE INDEX IF NOT EXISTS idx_qe_exported_by    ON question_exports(exported_by);
CREATE INDEX IF NOT EXISTS idx_qe_status         ON question_exports(status);

-- ---------------------------------------------------------------------------
-- topics & subtopics
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_topics_subject_id ON topics(subject_id);
CREATE INDEX IF NOT EXISTS idx_topics_code       ON topics(code);
CREATE INDEX IF NOT EXISTS idx_topics_sort_order ON topics(subject_id, sort_order);
CREATE INDEX IF NOT EXISTS idx_subtopics_topic_id ON subtopics(topic_id);
CREATE INDEX IF NOT EXISTS idx_subtopics_code    ON subtopics(code);
CREATE INDEX IF NOT EXISTS idx_subtopics_sort    ON subtopics(topic_id, sort_order);

-- ---------------------------------------------------------------------------
-- question_categories
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_qcat_school_id    ON question_categories(school_id);
CREATE INDEX IF NOT EXISTS idx_qcat_sort         ON question_categories(school_id, sort_order);

-- ---------------------------------------------------------------------------
-- academic_sessions
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_as_school_id      ON academic_sessions(school_id);
CREATE INDEX IF NOT EXISTS idx_as_is_current     ON academic_sessions(is_current) WHERE is_current = true;

-- ---------------------------------------------------------------------------
-- curriculum_standards
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_cs_subject_id     ON curriculum_standards(subject_id);
CREATE INDEX IF NOT EXISTS idx_cs_class_id       ON curriculum_standards(class_id);
CREATE INDEX IF NOT EXISTS idx_cs_type           ON curriculum_standards(type);
CREATE INDEX IF NOT EXISTS idx_cs_code           ON curriculum_standards(code);

-- ============================================================================
-- 24. HELPER FUNCTIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- update_question_usage_count(question_id UUID)
-- Increments the usage_count of a question (called when used in an exam).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_question_usage_count(target_question_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE question_bank
  SET usage_count = usage_count + 1,
      updated_at  = now()
  WHERE id = target_question_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_question_usage_count(UUID) IS
  'Increment the usage_count of a question by 1';

-- ---------------------------------------------------------------------------
-- create_question_version(question_id UUID, change_type VARCHAR, change_desc TEXT)
-- Creates a version snapshot of a question before it is modified.
-- Returns the new version number.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION create_question_version(
  target_question_id UUID,
  p_change_type     VARCHAR,
  p_change_desc     TEXT DEFAULT NULL
)
RETURNS INTEGER AS $$
DECLARE
  v_question   RECORD;
  v_version    INTEGER;
  v_snapshot   JSONB;
  v_changed_by UUID;
BEGIN
  -- Get current auth user as the changer
  SELECT id INTO v_changed_by FROM users WHERE id = auth.uid();

  -- Fetch the current question row
  SELECT * INTO v_question FROM question_bank WHERE id = target_question_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Question % not found', target_question_id;
  END IF;

  -- Build the snapshot JSONB
  v_snapshot := jsonb_build_object(
    'id',                 v_question.id,
    'school_id',          v_question.school_id,
    'subject_id',         v_question.subject_id,
    'topic_id',           v_question.topic_id,
    'subtopic_id',        v_question.subtopic_id,
    'class_id',           v_question.class_id,
    'category_id',        v_question.category_id,
    'curriculum_standard_id', v_question.curriculum_standard_id,
    'academic_session_id',v_question.academic_session_id,
    'question_type',      v_question.question_type,
    'difficulty',         v_question.difficulty,
    'exam_type',          v_question.exam_type,
    'content',            v_question.content,
    'content_json',       v_question.content_json,
    'explanation',        v_question.explanation,
    'teacher_notes',      v_question.teacher_notes,
    'reference_materials',v_question.reference_materials,
    'marks',              v_question.marks,
    'negative_marks',     v_question.negative_marks,
    'time_allowed_seconds', v_question.time_allowed_seconds,
    'is_published',       v_question.is_published,
    'is_archived',        v_question.is_archived,
    'is_featured',        v_question.is_featured,
    'version',            v_question.version,
    'parent_id',          v_question.parent_id,
    'created_by',         v_question.created_by,
    'updated_by',         v_question.updated_by,
    'usage_count',        v_question.usage_count,
    'avg_score',          v_question.avg_score,
    'metadata',           v_question.metadata,
    'created_at',         v_question.created_at,
    'updated_at',         v_question.updated_at
  );

  -- Compute the next version number
  v_version := v_question.version + 1;

  -- Insert the version history record
  INSERT INTO question_version_history (
    question_id, version, snapshot, change_description, changed_by, change_type
  ) VALUES (
    target_question_id, v_version, v_snapshot,
    COALESCE(p_change_desc, 'Version ' || v_version),
    v_changed_by, p_change_type
  );

  -- Update the question's version counter
  UPDATE question_bank
  SET version    = v_version,
      updated_at = now()
  WHERE id = target_question_id;

  RETURN v_version;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION create_question_version(UUID, VARCHAR, TEXT) IS
  'Create a version snapshot of a question and increment its version number';

-- ---------------------------------------------------------------------------
-- get_question_with_details(target_question_id UUID)
-- Returns a JSONB object containing the question + all related data
-- (answer_options, matching_pairs, ordering_items, fill_in_blank_answers,
--  question_attachments, tags) in a single call.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_question_with_details(target_question_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'question',    to_jsonb(q.*),
    'options',     COALESCE(
      (SELECT jsonb_agg(to_jsonb(o.*) ORDER BY o.sort_order)
       FROM answer_options o WHERE o.question_id = target_question_id),
      '[]'::jsonb
    ),
    'matching_pairs', COALESCE(
      (SELECT jsonb_agg(to_jsonb(mp.*) ORDER BY mp.sort_order)
       FROM matching_pairs mp WHERE mp.question_id = target_question_id),
      '[]'::jsonb
    ),
    'ordering_items', COALESCE(
      (SELECT jsonb_agg(to_jsonb(oi.*) ORDER BY oi.correct_position)
       FROM ordering_items oi WHERE oi.question_id = target_question_id),
      '[]'::jsonb
    ),
    'fill_in_blank_answers', COALESCE(
      (SELECT jsonb_agg(to_jsonb(fib.*) ORDER BY fib.blank_index)
       FROM fill_in_blank_answers fib WHERE fib.question_id = target_question_id),
      '[]'::jsonb
    ),
    'attachments', COALESCE(
      (SELECT jsonb_agg(to_jsonb(a.*) ORDER BY a.sort_order)
       FROM question_attachments a WHERE a.question_id = target_question_id),
      '[]'::jsonb
    ),
    'tags', COALESCE(
      (SELECT jsonb_agg(jsonb_build_object('id', t.id, 'name', t.name))
       FROM question_tag_relations qtr
       JOIN question_tags t ON t.id = qtr.tag_id
       WHERE qtr.question_id = target_question_id),
      '[]'::jsonb
    )
  ) INTO v_result
  FROM question_bank q
  WHERE q.id = target_question_id;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_question_with_details(UUID) IS
  'Fetch a question with all its related data (options, pairs, items, blanks, attachments, tags) as a single JSONB';

-- ---------------------------------------------------------------------------
-- search_questions(search_query TEXT, filters JSONB)
-- Full-text search function with optional filters.
-- Filters JSONB can include:
--   school_id, subject_id, topic_id, difficulty, question_type, exam_type,
--   is_published, is_archived, class_id, category_id, created_by, limit, offset
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION search_questions(
  p_search_query TEXT,
  p_filters      JSONB DEFAULT '{}'
)
RETURNS TABLE (
  id                UUID,
  school_id         UUID,
  subject_id        UUID,
  topic_id          UUID,
  question_type     question_type,
  difficulty        difficulty_level,
  exam_type         exam_type,
  content           TEXT,
  marks             NUMERIC,
  is_published      BOOLEAN,
  is_archived       BOOLEAN,
  usage_count       INTEGER,
  avg_score         NUMERIC,
  created_by        UUID,
  created_at        TIMESTAMPTZ,
  rank              REAL
) AS $$
DECLARE
  v_limit  INTEGER := COALESCE((p_filters->>'limit')::INTEGER, 50);
  v_offset INTEGER := COALESCE((p_filters->>'offset')::INTEGER, 0);
BEGIN
  RETURN QUERY
  SELECT
    qb.id,
    qb.school_id,
    qb.subject_id,
    qb.topic_id,
    qb.question_type,
    qb.difficulty,
    qb.exam_type,
    qb.content,
    qb.marks,
    qb.is_published,
    qb.is_archived,
    qb.usage_count,
    qb.avg_score,
    qb.created_by,
    qb.created_at,
    ts_rank(to_tsvector('english', qb.content), plainto_tsquery('english', p_search_query)) AS rank
  FROM question_bank qb
  WHERE
    -- Full-text search filter
    (p_search_query IS NULL OR p_search_query = '' OR
     to_tsvector('english', qb.content) @@ plainto_tsquery('english', p_search_query))
    -- School filter (includes platform-wide NULL school_id)
    AND (p_filters->>'school_id' IS NULL OR qb.school_id::TEXT = p_filters->>'school_id' OR qb.school_id IS NULL)
    -- Subject filter
    AND (p_filters->>'subject_id' IS NULL OR qb.subject_id::TEXT = p_filters->>'subject_id')
    -- Topic filter
    AND (p_filters->>'topic_id' IS NULL OR qb.topic_id::TEXT = p_filters->>'topic_id')
    -- Difficulty filter
    AND (p_filters->>'difficulty' IS NULL OR qb.difficulty::TEXT = p_filters->>'difficulty')
    -- Question type filter
    AND (p_filters->>'question_type' IS NULL OR qb.question_type::TEXT = p_filters->>'question_type')
    -- Exam type filter
    AND (p_filters->>'exam_type' IS NULL OR qb.exam_type::TEXT = p_filters->>'exam_type')
    -- Published filter
    AND (p_filters->>'is_published' IS NULL OR qb.is_published = (p_filters->>'is_published')::BOOLEAN)
    -- Not archived (default: exclude archived)
    AND (p_filters->>'is_archived' IS NULL OR qb.is_archived = (p_filters->>'is_archived')::BOOLEAN)
    -- Class filter
    AND (p_filters->>'class_id' IS NULL OR qb.class_id::TEXT = p_filters->>'class_id')
    -- Category filter
    AND (p_filters->>'category_id' IS NULL OR qb.category_id::TEXT = p_filters->>'category_id')
    -- Created by filter
    AND (p_filters->>'created_by' IS NULL OR qb.created_by::TEXT = p_filters->>'created_by')
  ORDER BY
    rank DESC NULLS LAST,
    qb.created_at DESC
  LIMIT v_limit
  OFFSET v_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION search_questions(TEXT, JSONB) IS
  'Full-text search with JSONB filters for the question bank';

-- ---------------------------------------------------------------------------
-- update_collection_question_count(target_collection_id UUID)
-- Recalculates the question_count on a collection from collection_questions.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_collection_question_count(target_collection_id UUID)
RETURNS VOID AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM collection_questions
  WHERE collection_id = target_collection_id;

  UPDATE question_collections
  SET question_count = v_count,
      updated_at     = now()
  WHERE id = target_collection_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_collection_question_count(UUID) IS
  'Recalculate the denormalized question_count on a collection';

-- ---------------------------------------------------------------------------
-- update_tag_usage_count(target_tag_id UUID)
-- Recalculates the usage_count on a tag from question_tag_relations.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_tag_usage_count(target_tag_id UUID)
RETURNS VOID AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM question_tag_relations
  WHERE tag_id = target_tag_id;

  UPDATE question_tags
  SET usage_count = v_count
  WHERE id = target_tag_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION update_tag_usage_count(UUID) IS
  'Recalculate the denormalized usage_count on a tag';

-- ============================================================================
-- 25. TRIGGERS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Auto-update updated_at on all new tables
-- ---------------------------------------------------------------------------

-- topics
DROP TRIGGER IF EXISTS set_topics_updated_at ON topics;
CREATE TRIGGER set_topics_updated_at
  BEFORE UPDATE ON topics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- subtopics
DROP TRIGGER IF EXISTS set_subtopics_updated_at ON subtopics;
CREATE TRIGGER set_subtopics_updated_at
  BEFORE UPDATE ON subtopics
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- question_categories
DROP TRIGGER IF EXISTS set_question_categories_updated_at ON question_categories;
CREATE TRIGGER set_question_categories_updated_at
  BEFORE UPDATE ON question_categories
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- academic_sessions
DROP TRIGGER IF EXISTS set_academic_sessions_updated_at ON academic_sessions;
CREATE TRIGGER set_academic_sessions_updated_at
  BEFORE UPDATE ON academic_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- curriculum_standards
DROP TRIGGER IF EXISTS set_curriculum_standards_updated_at ON curriculum_standards;
CREATE TRIGGER set_curriculum_standards_updated_at
  BEFORE UPDATE ON curriculum_standards
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- question_bank
DROP TRIGGER IF EXISTS set_question_bank_updated_at ON question_bank;
CREATE TRIGGER set_question_bank_updated_at
  BEFORE UPDATE ON question_bank
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- answer_options
DROP TRIGGER IF EXISTS set_answer_options_updated_at ON answer_options;
CREATE TRIGGER set_answer_options_updated_at
  BEFORE UPDATE ON answer_options
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- question_collections
DROP TRIGGER IF EXISTS set_question_collections_updated_at ON question_collections;
CREATE TRIGGER set_question_collections_updated_at
  BEFORE UPDATE ON question_collections
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------------
-- Auto-create version history on question_bank update
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trigger_create_question_version()
RETURNS TRIGGER AS $$
DECLARE
  v_change_type VARCHAR(20);
BEGIN
  -- Determine the change type from the transition
  IF TG_OP = 'INSERT' THEN
    v_change_type := 'create';
    -- Insert initial version history on creation
    INSERT INTO question_version_history (
      question_id, version, snapshot, change_description, changed_by, change_type
    ) VALUES (
      NEW.id,
      1,
      to_jsonb(NEW),
      'Initial creation',
      NEW.created_by,
      v_change_type
    );
    RETURN NEW;
  END IF;

  -- For updates, determine the change type
  IF TG_OP = 'UPDATE' THEN
    -- Detect specific state transitions
    IF OLD.is_archived = false AND NEW.is_archived = true THEN
      v_change_type := 'archive';
    ELSIF OLD.is_published = false AND NEW.is_published = true THEN
      v_change_type := 'publish';
    ELSIF OLD.is_archived = true AND NEW.is_archived = false AND NEW.is_published = true THEN
      v_change_type := 'restore';
    ELSE
      v_change_type := 'update';
    END IF;

    -- Only create a version snapshot if substantive fields changed
    -- (skip updated_at-only changes to avoid noise)
    IF OLD.content            IS DISTINCT FROM NEW.content OR
       OLD.content_json       IS DISTINCT FROM NEW.content_json OR
       OLD.explanation        IS DISTINCT FROM NEW.explanation OR
       OLD.marks              IS DISTINCT FROM NEW.marks OR
       OLD.negative_marks     IS DISTINCT FROM NEW.negative_marks OR
       OLD.difficulty         IS DISTINCT FROM NEW.difficulty OR
       OLD.question_type      IS DISTINCT FROM NEW.question_type OR
       OLD.exam_type          IS DISTINCT FROM NEW.exam_type OR
       OLD.is_published       IS DISTINCT FROM NEW.is_published OR
       OLD.is_archived        IS DISTINCT FROM NEW.is_archived OR
       OLD.is_featured        IS DISTINCT FROM NEW.is_featured OR
       OLD.topic_id           IS DISTINCT FROM NEW.topic_id OR
       OLD.subtopic_id        IS DISTINCT FROM NEW.subtopic_id OR
       OLD.category_id        IS DISTINCT FROM NEW.category_id OR
       OLD.metadata           IS DISTINCT FROM NEW.metadata OR
       OLD.teacher_notes      IS DISTINCT FROM NEW.teacher_notes OR
       OLD.reference_materials IS DISTINCT FROM NEW.reference_materials OR
       OLD.time_allowed_seconds IS DISTINCT FROM NEW.time_allowed_seconds
    THEN
      PERFORM create_question_version(NEW.id, v_change_type);
    END IF;

    RETURN NEW;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_question_bank_version ON question_bank;
CREATE TRIGGER on_question_bank_version
  AFTER INSERT OR UPDATE ON question_bank
  FOR EACH ROW
  EXECUTE FUNCTION trigger_create_question_version();

COMMENT ON FUNCTION trigger_create_question_version() IS
  'Trigger: auto-create version history snapshots on question creation and substantive updates';

-- ---------------------------------------------------------------------------
-- Auto-update question_count on collection_questions insert/delete
-- ---------------------------------------------------------------------------

-- After INSERT on collection_questions
CREATE OR REPLACE FUNCTION trigger_update_collection_count_on_add()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_collection_question_count(NEW.collection_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_collection_question_add ON collection_questions;
CREATE TRIGGER on_collection_question_add
  AFTER INSERT ON collection_questions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_collection_count_on_add();

-- After DELETE on collection_questions
CREATE OR REPLACE FUNCTION trigger_update_collection_count_on_remove()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_collection_question_count(OLD.collection_id);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_collection_question_remove ON collection_questions;
CREATE TRIGGER on_collection_question_remove
  AFTER DELETE ON collection_questions
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_collection_count_on_remove();

-- ---------------------------------------------------------------------------
-- Auto-update usage_count on question_tags when tag relations change
-- ---------------------------------------------------------------------------

-- After INSERT on question_tag_relations
CREATE OR REPLACE FUNCTION trigger_update_tag_count_on_add()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_tag_usage_count(NEW.tag_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_tag_relation_add ON question_tag_relations;
CREATE TRIGGER on_tag_relation_add
  AFTER INSERT ON question_tag_relations
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_tag_count_on_add();

-- After DELETE on question_tag_relations
CREATE OR REPLACE FUNCTION trigger_update_tag_count_on_remove()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM update_tag_usage_count(OLD.tag_id);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_tag_relation_remove ON question_tag_relations;
CREATE TRIGGER on_tag_relation_remove
  AFTER DELETE ON question_tag_relations
  FOR EACH ROW
  EXECUTE FUNCTION trigger_update_tag_count_on_remove();

-- ---------------------------------------------------------------------------
-- Ensure only one current academic session per school
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION enforce_single_current_session()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_current = true AND NEW.school_id IS NOT NULL THEN
    UPDATE academic_sessions
    SET is_current = false,
        updated_at = now()
    WHERE school_id = NEW.school_id
      AND is_current = true
      AND id IS DISTINCT FROM NEW.id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_academic_session_current ON academic_sessions;
CREATE TRIGGER on_academic_session_current
  BEFORE INSERT OR UPDATE OF is_current ON academic_sessions
  FOR EACH ROW
  WHEN (NEW.is_current = true)
  EXECUTE FUNCTION enforce_single_current_session();

COMMENT ON FUNCTION enforce_single_current_session() IS
  'Ensures only one academic session can be current per school at a time';

-- ============================================================================
-- 26. ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Enable RLS on ALL new tables. Policies enforce multi-tenant isolation
-- and role-based access control.
-- ============================================================================

-- Enable RLS
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE subtopics ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE curriculum_standards ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_bank ENABLE ROW LEVEL SECURITY;
ALTER TABLE answer_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE matching_pairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE ordering_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE fill_in_blank_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_tag_relations ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE collection_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_version_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_imports ENABLE ROW LEVEL SECURITY;
ALTER TABLE question_exports ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- TOPICS RLS POLICIES
-- ===========================================================================

-- All authenticated users can read topics for subjects they can access
CREATE POLICY "Authenticated users can read topics"
  ON topics FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.id = subject_id
        AND (s.school_id IS NULL OR s.school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    )
  );

-- Teachers can create topics for subjects in their school
CREATE POLICY "Teachers can create topics"
  ON topics FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
    AND EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.id = subject_id
        AND (s.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
    )
  );

-- Teachers can update topics they created; school admins can update any in their school
CREATE POLICY "Teachers can update own topics"
  ON topics FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND EXISTS (
      SELECT 1 FROM subjects s WHERE s.id = subject_id
        AND s.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    ))
    OR get_user_role() = 'super_admin'
  )
  WITH CHECK (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND EXISTS (
      SELECT 1 FROM subjects s WHERE s.id = subject_id
        AND s.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    ))
    OR get_user_role() = 'super_admin'
  );

-- School admins and super admins can delete topics
CREATE POLICY "Admins can delete topics"
  ON topics FOR DELETE
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' AND EXISTS (
      SELECT 1 FROM subjects s WHERE s.id = subject_id
        AND s.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    ))
    OR get_user_role() = 'super_admin'
  );

-- ===========================================================================
-- SUBTOPICS RLS POLICIES
-- ===========================================================================

-- All authenticated users can read subtopics for topics they can access
CREATE POLICY "Authenticated users can read subtopics"
  ON subtopics FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM topics t
      JOIN subjects s ON s.id = t.subject_id
      WHERE t.id = topic_id
        AND (s.school_id IS NULL OR s.school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    )
  );

-- Teachers can create subtopics
CREATE POLICY "Teachers can create subtopics"
  ON subtopics FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
    AND EXISTS (
      SELECT 1 FROM topics t
      JOIN subjects s ON s.id = t.subject_id
      WHERE t.id = topic_id
        AND (s.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
    )
  );

-- Teachers can update own subtopics; admins can update any in their school
CREATE POLICY "Teachers can update own subtopics"
  ON subtopics FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND EXISTS (
      SELECT 1 FROM topics t
      JOIN subjects s ON s.id = t.subject_id
      WHERE t.id = topic_id
        AND s.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    ))
    OR get_user_role() = 'super_admin'
  )
  WITH CHECK (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND EXISTS (
      SELECT 1 FROM topics t
      JOIN subjects s ON s.id = t.subject_id
      WHERE t.id = topic_id
        AND s.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    ))
    OR get_user_role() = 'super_admin'
  );

-- Admins can delete subtopics
CREATE POLICY "Admins can delete subtopics"
  ON subtopics FOR DELETE
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' AND EXISTS (
      SELECT 1 FROM topics t
      JOIN subjects s ON s.id = t.subject_id
      WHERE t.id = topic_id
        AND s.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    ))
    OR get_user_role() = 'super_admin'
  );

-- ===========================================================================
-- QUESTION_CATEGORIES RLS POLICIES
-- ===========================================================================

-- All authenticated users can read categories for their school + system-wide
CREATE POLICY "Authenticated users can read question categories"
  ON question_categories FOR SELECT
  TO authenticated
  USING (
    school_id IS NULL
    OR school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Teachers can create categories
CREATE POLICY "Teachers can create question categories"
  ON question_categories FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
    AND (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
  );

-- Teachers can update own categories; admins can update any in their school
CREATE POLICY "Users can update question categories"
  ON question_categories FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  )
  WITH CHECK (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

-- Admins can delete categories in their school
CREATE POLICY "Admins can delete question categories"
  ON question_categories FOR DELETE
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

-- ===========================================================================
-- ACADEMIC_SESSIONS RLS POLICIES
-- ===========================================================================

-- All authenticated users in a school can read their school's sessions
CREATE POLICY "Authenticated users can read academic sessions"
  ON academic_sessions FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

-- School admins can CRUD sessions in their school
CREATE POLICY "School admins can manage academic sessions"
  ON academic_sessions FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Super admins have full access
CREATE POLICY "Super admins have full access to academic sessions"
  ON academic_sessions FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- CURRICULUM_STANDARDS RLS POLICIES
-- ===========================================================================

-- All authenticated users can read standards for their school / system-wide
CREATE POLICY "Authenticated users can read curriculum standards"
  ON curriculum_standards FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM subjects s
      WHERE s.id = subject_id
        AND (s.school_id IS NULL OR s.school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    )
    OR get_user_role() = 'super_admin'
  );

-- Teachers and admins can create standards
CREATE POLICY "Teachers can create curriculum standards"
  ON curriculum_standards FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
  );

-- Admins and creators can update standards
CREATE POLICY "Users can update curriculum standards"
  ON curriculum_standards FOR UPDATE
  TO authenticated
  USING (
    get_user_role() IN ('school_admin', 'super_admin')
  )
  WITH CHECK (
    get_user_role() IN ('school_admin', 'super_admin')
  );

-- Admins can delete standards
CREATE POLICY "Admins can delete curriculum standards"
  ON curriculum_standards FOR DELETE
  TO authenticated
  USING (
    get_user_role() IN ('school_admin', 'super_admin')
  );

-- ===========================================================================
-- QUESTION_BANK RLS POLICIES
-- ===========================================================================

-- Teachers can read published questions in their school + platform-wide
CREATE POLICY "Teachers can read published questions in school"
  ON question_bank FOR SELECT
  TO authenticated
  USING (
    -- Platform-wide questions (school_id IS NULL) are readable by all authenticated users
    school_id IS NULL
    -- Published questions in the user's school
    OR (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND is_published = true)
    -- User's own questions (draft or published)
    OR created_by = auth.uid()
  );

-- School admins can read all questions in their school
CREATE POLICY "School admins can read all school questions"
  ON question_bank FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Super admins have full read access
CREATE POLICY "Super admins can read all questions"
  ON question_bank FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- Teachers can create questions in their school or as platform-wide (super_admin only)
CREATE POLICY "Teachers can create questions"
  ON question_bank FOR INSERT
  TO authenticated
  WITH CHECK (
    -- Teachers create questions in their school
    (get_user_role() = 'teacher' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    -- School admins create questions in their school
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    -- Super admins can create any
    OR get_user_role() = 'super_admin'
  );

-- Teachers can update their own questions
CREATE POLICY "Teachers can update own questions"
  ON question_bank FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
  )
  WITH CHECK (
    created_by = auth.uid()
  );

-- School admins can update all questions in their school
CREATE POLICY "School admins can update school questions"
  ON question_bank FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Super admins can update any question
CREATE POLICY "Super admins can update any question"
  ON question_bank FOR UPDATE
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Teachers can delete their own questions
CREATE POLICY "Teachers can delete own questions"
  ON question_bank FOR DELETE
  TO authenticated
  USING (created_by = auth.uid());

-- School admins can delete questions in their school
CREATE POLICY "School admins can delete school questions"
  ON question_bank FOR DELETE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Super admins can delete any question
CREATE POLICY "Super admins can delete any question"
  ON question_bank FOR DELETE
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- ===========================================================================
-- ANSWER_OPTIONS RLS POLICIES (same access as parent question)
-- ===========================================================================

-- Users can read options for questions they can access
CREATE POLICY "Users can read answer options for accessible questions"
  ON answer_options FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (
          qb.school_id IS NULL
          OR (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND qb.is_published = true)
          OR qb.created_by = auth.uid()
          OR get_user_role() IN ('school_admin', 'super_admin')
        )
    )
  );

-- Users can insert/update/delete options for questions they own or can manage
CREATE POLICY "Users can insert answer options for own questions"
  ON answer_options FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can update answer options for own questions"
  ON answer_options FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can delete answer options for own questions"
  ON answer_options FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

-- ===========================================================================
-- MATCHING_PAIRS RLS POLICIES (same access as parent question)
-- ===========================================================================

CREATE POLICY "Users can read matching pairs for accessible questions"
  ON matching_pairs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (
          qb.school_id IS NULL
          OR (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND qb.is_published = true)
          OR qb.created_by = auth.uid()
          OR get_user_role() IN ('school_admin', 'super_admin')
        )
    )
  );

CREATE POLICY "Users can insert matching pairs for own questions"
  ON matching_pairs FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can update matching pairs for own questions"
  ON matching_pairs FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can delete matching pairs for own questions"
  ON matching_pairs FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

-- ===========================================================================
-- ORDERING_ITEMS RLS POLICIES (same access as parent question)
-- ===========================================================================

CREATE POLICY "Users can read ordering items for accessible questions"
  ON ordering_items FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (
          qb.school_id IS NULL
          OR (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND qb.is_published = true)
          OR qb.created_by = auth.uid()
          OR get_user_role() IN ('school_admin', 'super_admin')
        )
    )
  );

CREATE POLICY "Users can insert ordering items for own questions"
  ON ordering_items FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can update ordering items for own questions"
  ON ordering_items FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can delete ordering items for own questions"
  ON ordering_items FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

-- ===========================================================================
-- FILL_IN_BLANK_ANSWERS RLS POLICIES (same access as parent question)
-- ===========================================================================

CREATE POLICY "Users can read fill blank answers for accessible questions"
  ON fill_in_blank_answers FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (
          qb.school_id IS NULL
          OR (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND qb.is_published = true)
          OR qb.created_by = auth.uid()
          OR get_user_role() IN ('school_admin', 'super_admin')
        )
    )
  );

CREATE POLICY "Users can insert fill blank answers for own questions"
  ON fill_in_blank_answers FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can update fill blank answers for own questions"
  ON fill_in_blank_answers FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can delete fill blank answers for own questions"
  ON fill_in_blank_answers FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

-- ===========================================================================
-- QUESTION_ATTACHMENTS RLS POLICIES (same access as parent question)
-- ===========================================================================

CREATE POLICY "Users can read attachments for accessible questions"
  ON question_attachments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (
          qb.school_id IS NULL
          OR (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND qb.is_published = true)
          OR qb.created_by = auth.uid()
          OR get_user_role() IN ('school_admin', 'super_admin')
        )
    )
  );

CREATE POLICY "Users can insert attachments for own questions"
  ON question_attachments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can update attachments for own questions"
  ON question_attachments FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can delete attachments for own questions"
  ON question_attachments FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

-- ===========================================================================
-- QUESTION_TAGS RLS POLICIES
-- ===========================================================================

-- All authenticated users can read tags in their school + system-wide tags
CREATE POLICY "Authenticated users can read question tags"
  ON question_tags FOR SELECT
  TO authenticated
  USING (
    school_id IS NULL
    OR school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

-- Teachers can create tags in their school
CREATE POLICY "Teachers can create question tags"
  ON question_tags FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
    AND (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
  );

-- School admins can manage tags in their school
CREATE POLICY "School admins can manage school question tags"
  ON question_tags FOR UPDATE
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  )
  WITH CHECK (
    (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "School admins can delete school question tags"
  ON question_tags FOR DELETE
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

-- ===========================================================================
-- QUESTION_TAG_RELATIONS RLS POLICIES
-- ===========================================================================

-- Users can read tag relations for questions they can access
CREATE POLICY "Users can read question tag relations"
  ON question_tag_relations FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (
          qb.school_id IS NULL
          OR (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND qb.is_published = true)
          OR qb.created_by = auth.uid()
          OR get_user_role() IN ('school_admin', 'super_admin')
        )
    )
  );

-- Users can tag/untag questions they own or can manage
CREATE POLICY "Users can insert question tag relations for own questions"
  ON question_tag_relations FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can delete question tag relations for own questions"
  ON question_tag_relations FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

-- ===========================================================================
-- QUESTION_COLLECTIONS RLS POLICIES
-- ===========================================================================

-- Teachers can read shared collections and their own
CREATE POLICY "Users can read accessible collections"
  ON question_collections FOR SELECT
  TO authenticated
  USING (
    created_by = auth.uid()
    OR (is_shared = true AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR (is_official = true AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
  );

-- Teachers can create collections
CREATE POLICY "Teachers can create collections"
  ON question_collections FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
    AND (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
  );

-- Teachers can update their own collections; admins can update school collections
CREATE POLICY "Users can update own collections"
  ON question_collections FOR UPDATE
  TO authenticated
  USING (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  )
  WITH CHECK (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

-- Teachers can delete their own collections; admins can delete school collections
CREATE POLICY "Users can delete own collections"
  ON question_collections FOR DELETE
  TO authenticated
  USING (
    created_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

-- ===========================================================================
-- COLLECTION_QUESTIONS RLS POLICIES
-- ===========================================================================

-- Users can read questions in collections they can access
CREATE POLICY "Users can read collection questions for accessible collections"
  ON collection_questions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_collections qc
      WHERE qc.id = collection_id
        AND (
          qc.created_by = auth.uid()
          OR (qc.is_shared = true AND qc.school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
          OR (qc.is_official = true AND qc.school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
          OR get_user_role() = 'super_admin'
          OR (get_user_role() = 'school_admin' AND qc.school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
        )
    )
  );

-- Users can add/remove questions in their own collections
CREATE POLICY "Users can insert collection questions for own collections"
  ON collection_questions FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM question_collections qc
      WHERE qc.id = collection_id
        AND (qc.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

CREATE POLICY "Users can delete collection questions for own collections"
  ON collection_questions FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_collections qc
      WHERE qc.id = collection_id
        AND (qc.created_by = auth.uid() OR get_user_role() IN ('school_admin', 'super_admin'))
    )
  );

-- ===========================================================================
-- QUESTION_FAVORITES RLS POLICIES
-- ===========================================================================

-- Users can only access their own favorites
CREATE POLICY "Users can read own favorites"
  ON question_favorites FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own favorites"
  ON question_favorites FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can delete own favorites"
  ON question_favorites FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ===========================================================================
-- QUESTION_SHARES RLS POLICIES
-- ===========================================================================

-- Users can see shares involving them (as sharer or recipient) + school-wide shares
CREATE POLICY "Users can see relevant shares"
  ON question_shares FOR SELECT
  TO authenticated
  USING (
    shared_by = auth.uid()
    OR shared_with = auth.uid()
    OR (shared_with IS NULL AND EXISTS (
        SELECT 1 FROM question_bank qb
        WHERE qb.id = question_id
          AND qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
      ))
    OR get_user_role() = 'super_admin'
  );

-- Users can share their own questions
CREATE POLICY "Users can share own questions"
  ON question_shares FOR INSERT
  TO authenticated
  WITH CHECK (
    shared_by = auth.uid()
    AND EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id AND qb.created_by = auth.uid()
    )
  );

-- School admins and super admins can share any question in their school
CREATE POLICY "Admins can share school questions"
  ON question_shares FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('school_admin', 'super_admin')
    AND EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
    )
  );

-- Users can update shares they created (e.g., change permission, accept)
CREATE POLICY "Users can update own shares"
  ON question_shares FOR UPDATE
  TO authenticated
  USING (
    shared_by = auth.uid()
    OR shared_with = auth.uid()
    OR get_user_role() = 'super_admin'
  )
  WITH CHECK (
    shared_by = auth.uid()
    OR shared_with = auth.uid()
    OR get_user_role() = 'super_admin'
  );

-- Users can delete shares they created
CREATE POLICY "Users can delete own shares"
  ON question_shares FOR DELETE
  TO authenticated
  USING (
    shared_by = auth.uid()
    OR get_user_role() = 'super_admin'
  );

-- ===========================================================================
-- QUESTION_VERSION_HISTORY RLS POLICIES
-- ===========================================================================

-- Users can read history of questions they can access
CREATE POLICY "Users can read version history for accessible questions"
  ON question_version_history FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM question_bank qb
      WHERE qb.id = question_id
        AND (
          qb.school_id IS NULL
          OR (qb.school_id = (SELECT school_id FROM users WHERE id = auth.uid()) AND qb.is_published = true)
          OR qb.created_by = auth.uid()
          OR get_user_role() IN ('school_admin', 'super_admin')
        )
    )
  );

-- Version history is created by system triggers; no manual INSERT/UPDATE/DELETE for users
-- Only service_role (which bypasses RLS) can insert/update/delete version history

-- ===========================================================================
-- QUESTION_IMPORTS RLS POLICIES
-- ===========================================================================

-- Users can read their own imports; admins can read school imports
CREATE POLICY "Users can read own imports"
  ON question_imports FOR SELECT
  TO authenticated
  USING (
    uploaded_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

-- Users can create imports for their school
CREATE POLICY "Users can create imports"
  ON question_imports FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
    AND (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
  );

-- Only system (service_role) updates import status; no user UPDATE/DELETE policies needed

-- ===========================================================================
-- QUESTION_EXPORTS RLS POLICIES
-- ===========================================================================

-- Users can read their own exports; admins can read school exports
CREATE POLICY "Users can read own exports"
  ON question_exports FOR SELECT
  TO authenticated
  USING (
    exported_by = auth.uid()
    OR (get_user_role() = 'school_admin' AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
    OR get_user_role() = 'super_admin'
  );

-- Users can create exports for their school
CREATE POLICY "Users can create exports"
  ON question_exports FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() IN ('teacher', 'school_admin', 'super_admin')
    AND (school_id = (SELECT school_id FROM users WHERE id = auth.uid()) OR get_user_role() = 'super_admin')
  );

-- Only system (service_role) updates export status; no user UPDATE/DELETE policies needed

-- ============================================================================
-- 27. TABLE COMMENTS SUMMARY
-- ============================================================================

COMMENT ON TABLE topics IS 'Hierarchical grouping of subjects into topics (e.g. Mathematics → Algebra)';
COMMENT ON TABLE subtopics IS 'Further subdivision of topics for finer-grained categorization';
COMMENT ON TABLE question_categories IS 'System-wide and school-specific question categories';
COMMENT ON TABLE academic_sessions IS 'Academic sessions/terms for temporal organization';
COMMENT ON TABLE curriculum_standards IS 'Curriculum standards for question alignment';
COMMENT ON TABLE question_bank IS 'Central question repository — the primary table for millions of questions';
COMMENT ON TABLE answer_options IS 'Answer options for MC, MR, and T/F question types';
COMMENT ON TABLE matching_pairs IS 'Left-right pairs for matching question type';
COMMENT ON TABLE ordering_items IS 'Sequencing items for ordering question type';
COMMENT ON TABLE fill_in_blank_answers IS 'Acceptable answers for fill-in-the-blank blanks';
COMMENT ON TABLE question_attachments IS 'Media attachments (images, audio, video, docs) for questions';
COMMENT ON TABLE question_tags IS 'Flexible tags for question categorization and search';
COMMENT ON TABLE question_tag_relations IS 'Many-to-many between questions and tags';
COMMENT ON TABLE question_collections IS 'Named collections/playlists of questions';
COMMENT ON TABLE collection_questions IS 'Questions within collections with ordering';
COMMENT ON TABLE question_favorites IS 'User bookmarks for quick access to questions';
COMMENT ON TABLE question_shares IS 'Question sharing records with permission levels';
COMMENT ON TABLE question_version_history IS 'Immutable version snapshots for audit and rollback';
COMMENT ON TABLE question_imports IS 'Bulk import job tracking (CSV, Excel, DOCX, PDF, JSON)';
COMMENT ON TABLE question_exports IS 'Export job tracking with filter metadata';

COMMIT;

-- ============================================================================
-- END OF QUESTION BANK MODULE SCHEMA
-- ============================================================================
