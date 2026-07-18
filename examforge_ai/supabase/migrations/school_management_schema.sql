-- ============================================================================
-- ExamForge AI - School Management & Academic Administration Schema
-- ============================================================================
-- Production-ready schema for multi-school academic management.
-- Extends the base schema (schools, users, classes, subjects) with:
--   - School branches/campuses, branding, and settings
--   - Student profiles, teacher profiles, parent profiles
--   - Departments, academic sessions, terms, school calendar
--   - Timetable system with conflict detection
--   - Attendance tracking (student & teacher)
--   - Homework & assignments
--   - Announcements & document center
--   - Promotion history & graduation tracking
--
-- Dependencies: schema.sql (base tables)
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. CUSTOM ENUMERATION TYPES
-- ============================================================================

DO $$
BEGIN
  -- term_type: Whether a term is a semester or term-based system
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'term_type') THEN
    CREATE TYPE term_type AS ENUM (
      'first_term',
      'second_term',
      'third_term',
      'first_semester',
      'second_semester'
    );
  END IF;

  -- term_status: Lifecycle state of a term
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'term_status') THEN
    CREATE TYPE term_status AS ENUM (
      'upcoming',
      'active',
      'completed',
      'archived'
    );
  END IF;

  -- attendance_status: Student/teacher attendance state
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'attendance_status') THEN
    CREATE TYPE attendance_status AS ENUM (
      'present',
      'absent',
      'late',
      'excused',
      'sick'
    );
  END IF;

  -- homework_status: Homework lifecycle
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'homework_status') THEN
    CREATE TYPE homework_status AS ENUM (
        'draft',
        'published',
        'closed',
        'graded'
      );
  END IF;

  -- submission_status: Student homework submission state
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'submission_status') THEN
    CREATE TYPE submission_status AS ENUM (
      'pending',
      'submitted',
      'late_submitted',
      'graded',
      'returned'
    );
  END IF;

  -- announcement_type: Category of school announcement
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'announcement_type') THEN
    CREATE TYPE announcement_type AS ENUM (
      'notice',
      'event',
      'circular',
      'holiday',
      'emergency'
    );
  END IF;

  -- announcement_priority: Urgency level
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'announcement_priority') THEN
    CREATE TYPE announcement_priority AS ENUM (
      'low',
      'normal',
      'high',
      'urgent'
    );
  END IF;

  -- document_type: Category of uploaded document
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_type') THEN
    CREATE TYPE document_type AS ENUM (
      'student_document',
      'school_policy',
      'curriculum_file',
      'certificate',
      'general',
      'homework_attachment',
      'report_card'
    );
  END IF;

  -- day_of_week: Timetable day
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'day_of_week') THEN
    CREATE TYPE day_of_week AS ENUM (
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    );
  END IF;

  -- promotion_status: Student promotion state
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'promotion_status') THEN
    CREATE TYPE promotion_status AS ENUM (
      'promoted',
      'retained',
      'graduated',
      'transferred',
      'withdrawn'
    );
  END IF;

  -- employment_type: Teacher employment status
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'employment_type') THEN
    CREATE TYPE employment_type AS ENUM (
      'full_time',
      'part_time',
      'contract',
      'volunteer',
      'intern'
    );
  END IF;

  -- calendar_event_type: School calendar event category
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'calendar_event_type') THEN
    CREATE TYPE calendar_event_type AS ENUM (
      'holiday',
      'event',
      'exam_period',
      'parent_teacher_conference',
      'staff_meeting',
      'sports_day',
      'cultural_day',
      'graduation',
      'resumption',
      'mid_term_break'
    );
  END IF;
END
$$;

-- ============================================================================
-- 2. EXTEND SCHOOLS TABLE (add branding & extra fields)
-- ============================================================================

-- Add new columns to the existing schools table
DO $$
BEGIN
  -- Motto
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'motto'
  ) THEN
    ALTER TABLE schools ADD COLUMN motto TEXT;
  END IF;

  -- Principal name
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'principal_name'
  ) THEN
    ALTER TABLE schools ADD COLUMN principal_name TEXT;
  END IF;

  -- Branding primary color
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'primary_color'
  ) THEN
    ALTER TABLE schools ADD COLUMN primary_color TEXT DEFAULT '#4F46E5';
  END IF;

  -- Branding secondary color
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'secondary_color'
  ) THEN
    ALTER TABLE schools ADD COLUMN secondary_color TEXT DEFAULT '#7C3AED';
  END IF;

  -- Custom domain (future ready)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'custom_domain'
  ) THEN
    ALTER TABLE schools ADD COLUMN custom_domain TEXT UNIQUE;
  END IF;

  -- School type
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'school_type'
  ) THEN
    ALTER TABLE schools ADD COLUMN school_type TEXT DEFAULT 'mixed';
  END IF;

  -- Established date
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'established_date'
  ) THEN
    ALTER TABLE schools ADD COLUMN established_date DATE;
  END IF;

  -- Registration number
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'registration_number'
  ) THEN
    ALTER TABLE schools ADD COLUMN registration_number TEXT UNIQUE;
  END IF;

  -- School level (primary, secondary, tertiary)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'schools' AND column_name = 'school_level'
  ) THEN
    ALTER TABLE schools ADD COLUMN school_level TEXT DEFAULT 'secondary';
  END IF;
END
$$;

-- ============================================================================
-- 3. SCHOOL BRANCHES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS school_branches (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,
  code                  TEXT NOT NULL,
  address               TEXT,
  city                  TEXT,
  state                 TEXT,
  country               TEXT DEFAULT 'Nigeria',
  phone                 TEXT,
  email                 TEXT,
  head_name             TEXT,                               -- Branch head / principal
  is_active             BOOLEAN DEFAULT true,
  is_main_campus        BOOLEAN DEFAULT false,
  settings              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, code)
);

COMMENT ON TABLE school_branches IS 'Campuses / branches of a school for multi-location support';
COMMENT ON COLUMN school_branches.is_main_campus IS 'Whether this is the primary/main campus';

-- ============================================================================
-- 4. DEPARTMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS departments (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,
  code                  TEXT NOT NULL,
  head_teacher_id       UUID REFERENCES users(id) ON DELETE SET NULL,
  description           TEXT,
  is_active             BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, code)
);

COMMENT ON TABLE departments IS 'Academic departments within a school';

-- ============================================================================
-- 5. STUDENT PROFILES TABLE (extends users for students)
-- ============================================================================

CREATE TABLE IF NOT EXISTS student_profiles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  admission_number      TEXT NOT NULL,
  student_id_card_number TEXT,
  passport_photo_url    TEXT,
  date_of_birth         DATE,
  gender                TEXT,
  blood_group           TEXT,
  genotype              TEXT,
  medical_conditions    TEXT,
  emergency_contact_name TEXT,
  emergency_contact_phone TEXT,
  emergency_contact_relationship TEXT,
  home_address          TEXT,
  state_of_origin       TEXT,
  local_government      TEXT,
  nationality           TEXT DEFAULT 'Nigerian',
  religion              TEXT,
  admission_date        DATE DEFAULT CURRENT_DATE,
  current_class_id      UUID REFERENCES classes(id) ON DELETE SET NULL,
  is_active             BOOLEAN DEFAULT true,
  is_graduated          BOOLEAN DEFAULT false,
  graduation_date       DATE,
  is_alumni             BOOLEAN DEFAULT false,
  promoted_to_class_id  UUID REFERENCES classes(id) ON DELETE SET NULL,
  metadata              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, admission_number)
);

COMMENT ON TABLE student_profiles IS 'Extended profile information for student users';
COMMENT ON COLUMN student_profiles.admission_number IS 'Unique admission number within the school';

-- ============================================================================
-- 6. TEACHER PROFILES TABLE (extends users for teachers)
-- ============================================================================

CREATE TABLE IF NOT EXISTS teacher_profiles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  employee_id           TEXT NOT NULL,
  staff_id_card_number  TEXT,
  passport_photo_url    TEXT,
  date_of_birth         DATE,
  gender                TEXT,
  qualification         TEXT,                               -- e.g. B.Ed, M.Sc, Ph.D
  specialization        TEXT,
  department_id         UUID REFERENCES departments(id) ON DELETE SET NULL,
  employment_type       employment_type DEFAULT 'full_time',
  employment_start_date DATE,
  employment_end_date   DATE,
  years_of_experience   INTEGER DEFAULT 0,
  is_head_of_department BOOLEAN DEFAULT false,
  is_active             BOOLEAN DEFAULT true,
  metadata              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, employee_id)
);

COMMENT ON TABLE teacher_profiles IS 'Extended profile information for teacher users';

-- ============================================================================
-- 7. PARENT PROFILES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS parent_profiles (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  occupation            TEXT,
  employer              TEXT,
  home_address          TEXT,
  office_address        TEXT,
  relationship_type     TEXT DEFAULT 'parent',               -- parent, guardian, sponsor
  is_active             BOOLEAN DEFAULT true,
  metadata              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE parent_profiles IS 'Extended profile information for parent/guardian users';

-- ============================================================================
-- 8. PARENT-STUDENT RELATIONSHIP TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS parent_students (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id             UUID NOT NULL REFERENCES parent_profiles(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
  relationship          TEXT NOT NULL DEFAULT 'parent',      -- father, mother, guardian, etc.
  is_primary_contact    BOOLEAN DEFAULT false,
  can_pickup            BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(parent_id, student_id)
);

COMMENT ON TABLE parent_students IS 'Many-to-many relationship between parents and students';

-- ============================================================================
-- 9. ACADEMIC SESSIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS academic_sessions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,                       -- e.g. "2024/2025 Academic Session"
  session_year          TEXT NOT NULL,                       -- e.g. "2024/2025"
  start_date            DATE NOT NULL,
  end_date              DATE NOT NULL,
  is_current            BOOLEAN DEFAULT false,
  is_active             BOOLEAN DEFAULT true,
  settings              JSONB DEFAULT '{}',                 -- Session-wide settings
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(school_id, session_year)
);

COMMENT ON TABLE academic_sessions IS 'Academic year/session management';
COMMENT ON COLUMN academic_sessions.is_current IS 'Only one session per school should be current';

-- ============================================================================
-- 10. TERMS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS terms (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_session_id   UUID NOT NULL REFERENCES academic_sessions(id) ON DELETE CASCADE,
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,                       -- e.g. "First Term", "Semester 1"
  term_type             term_type NOT NULL,
  term_number           INTEGER NOT NULL DEFAULT 1,          -- 1, 2, or 3
  start_date            DATE NOT NULL,
  end_date              DATE NOT NULL,
  is_current            BOOLEAN DEFAULT false,
  status                term_status DEFAULT 'upcoming',
  settings              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(academic_session_id, term_number)
);

COMMENT ON TABLE terms IS 'Terms/Semesters within an academic session';

-- ============================================================================
-- 11. SCHOOL CALENDAR EVENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS school_calendar_events (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  term_id               UUID REFERENCES terms(id) ON DELETE SET NULL,
  title                 TEXT NOT NULL,
  description           TEXT,
  event_type            calendar_event_type NOT NULL DEFAULT 'event',
  start_date            DATE NOT NULL,
  end_date              DATE,
  is_full_day           BOOLEAN DEFAULT true,
  is_recurring          BOOLEAN DEFAULT false,
  recurrence_rule       TEXT,                                -- iCal RRULE format
  target_audience       TEXT DEFAULT 'all',                  -- all, students, teachers, parents
  created_by            UUID REFERENCES users(id) ON DELETE SET NULL,
  is_active             BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE school_calendar_events IS 'School calendar events, holidays, and important dates';

-- ============================================================================
-- 12. TIMETABLES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS timetables (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  term_id               UUID NOT NULL REFERENCES terms(id) ON DELETE CASCADE,
  name                  TEXT NOT NULL,                       -- e.g. "SS1 2024/2025 First Term"
  timetable_type        TEXT NOT NULL DEFAULT 'class',       -- class, teacher, classroom, exam
  class_id              UUID REFERENCES classes(id) ON DELETE CASCADE,
  is_active             BOOLEAN DEFAULT true,
  is_published          BOOLEAN DEFAULT false,
  created_by            UUID REFERENCES users(id) ON DELETE SET NULL,
  settings              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE timetables IS 'Timetable containers (one per class/teacher per term)';

-- ============================================================================
-- 13. TIMETABLE SLOTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS timetable_slots (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  timetable_id          UUID NOT NULL REFERENCES timetables(id) ON DELETE CASCADE,
  day_of_week           day_of_week NOT NULL,
  period_number         INTEGER NOT NULL,                    -- 1, 2, 3, etc.
  start_time            TIME NOT NULL,
  end_time              TIME NOT NULL,
  subject_id            UUID REFERENCES subjects(id) ON DELETE SET NULL,
  teacher_id            UUID REFERENCES users(id) ON DELETE SET NULL,
  classroom             TEXT,                                -- e.g. "Room 101", "Lab A"
  class_id              UUID REFERENCES classes(id) ON DELETE SET NULL,
  is_break              BOOLEAN DEFAULT false,
  break_label           TEXT,                                -- e.g. "Short Break", "Lunch"
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(timetable_id, day_of_week, period_number)
);

COMMENT ON TABLE timetable_slots IS 'Individual period slots within a timetable';

-- ============================================================================
-- 14. ATTENDANCE RECORDS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS attendance_records (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  term_id               UUID NOT NULL REFERENCES terms(id) ON DELETE CASCADE,
  class_id              UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  date                  DATE NOT NULL,
  attendance_type       TEXT NOT NULL DEFAULT 'student',     -- student, teacher
  subject_id            UUID REFERENCES subjects(id) ON DELETE SET NULL,
  recorded_by           UUID REFERENCES users(id) ON DELETE SET NULL,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(class_id, date, attendance_type, subject_id)
);

COMMENT ON TABLE attendance_records IS 'Daily attendance record (one per class per day per type)';

-- ============================================================================
-- 15. ATTENDANCE ENTRIES TABLE (individual entries within a record)
-- ============================================================================

CREATE TABLE IF NOT EXISTS attendance_entries (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_record_id  UUID NOT NULL REFERENCES attendance_records(id) ON DELETE CASCADE,
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status                attendance_status NOT NULL DEFAULT 'present',
  check_in_time         TIMESTAMPTZ,
  check_out_time        TIMESTAMPTZ,
  notes                 TEXT,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(attendance_record_id, user_id)
);

COMMENT ON TABLE attendance_entries IS 'Individual attendance entries (one per student/teacher per record)';

-- ============================================================================
-- 16. HOMEWORK TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS homework (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  term_id               UUID NOT NULL REFERENCES terms(id) ON DELETE CASCADE,
  class_id              UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id            UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  teacher_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title                 TEXT NOT NULL,
  description           TEXT,
  instructions          TEXT,
  attachment_urls       JSONB DEFAULT '[]',                  -- Array of file URLs
  total_marks           NUMERIC(6,2) DEFAULT 0,
  deadline              TIMESTAMPTZ,
  allow_late_submission BOOLEAN DEFAULT false,
  status                homework_status DEFAULT 'draft',
  is_published          BOOLEAN DEFAULT false,
  metadata              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE homework IS 'Homework and assignments created by teachers';

-- ============================================================================
-- 17. HOMEWORK SUBMISSIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS homework_submissions (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homework_id           UUID NOT NULL REFERENCES homework(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content               TEXT,                                -- Text submission
  attachment_urls       JSONB DEFAULT '[]',                  -- Uploaded files
  status                submission_status DEFAULT 'pending',
  submitted_at          TIMESTAMPTZ,
  marks_awarded         NUMERIC(6,2),
  max_marks             NUMERIC(6,2),
  teacher_comment       TEXT,
  graded_by             UUID REFERENCES users(id) ON DELETE SET NULL,
  graded_at             TIMESTAMPTZ,
  is_late               BOOLEAN DEFAULT false,
  metadata              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(homework_id, student_id)
);

COMMENT ON TABLE homework_submissions IS 'Student submissions for homework assignments';

-- ============================================================================
-- 18. ANNOUNCEMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS announcements (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title                 TEXT NOT NULL,
  content               TEXT NOT NULL,
  announcement_type     announcement_type NOT NULL DEFAULT 'notice',
  priority              announcement_priority NOT NULL DEFAULT 'normal',
  target_audience       TEXT DEFAULT 'all',                  -- all, students, teachers, parents, specific_class
  target_class_ids      JSONB DEFAULT '[]',                  -- Array of class UUIDs if targeted
  attachment_urls       JSONB DEFAULT '[]',
  is_pinned             BOOLEAN DEFAULT false,
  is_published          BOOLEAN DEFAULT false,
  published_at          TIMESTAMPTZ,
  expires_at            TIMESTAMPTZ,
  created_by            UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE announcements IS 'School-wide announcements, notices, and circulars';

-- ============================================================================
-- 19. DOCUMENTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS documents (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  title                 TEXT NOT NULL,
  description           TEXT,
  document_type         document_type NOT NULL DEFAULT 'general',
  file_url              TEXT NOT NULL,
  file_name             TEXT NOT NULL,
  file_size             BIGINT,                              -- bytes
  mime_type             TEXT,
  category              TEXT,                                -- User-defined category
  tags                  JSONB DEFAULT '[]',
  is_public             BOOLEAN DEFAULT false,
  downloadable          BOOLEAN DEFAULT true,
  target_audience       TEXT DEFAULT 'all',
  uploaded_by           UUID REFERENCES users(id) ON DELETE SET NULL,
  student_id            UUID REFERENCES users(id) ON DELETE SET NULL, -- If student-specific doc
  download_count        INTEGER DEFAULT 0,
  version               INTEGER DEFAULT 1,
  parent_document_id    UUID REFERENCES documents(id) ON DELETE SET NULL, -- Versioning
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE documents IS 'Centralized document management for school files';

-- ============================================================================
-- 20. PROMOTION HISTORY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS promotion_history (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  from_class_id         UUID REFERENCES classes(id) ON DELETE SET NULL,
  to_class_id           UUID REFERENCES classes(id) ON DELETE SET NULL,
  academic_session_id   UUID REFERENCES academic_sessions(id) ON DELETE SET NULL,
  term_id               UUID REFERENCES terms(id) ON DELETE SET NULL,
  promotion_status      promotion_status NOT NULL,
  average_score         NUMERIC(6,2),
  class_teacher_comment TEXT,
  principal_comment     TEXT,
  promoted_by           UUID REFERENCES users(id) ON DELETE SET NULL,
  promoted_at           TIMESTAMPTZ DEFAULT now(),
  created_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE promotion_history IS 'Student promotion/demotion history across academic sessions';

-- ============================================================================
-- 21. SUBJECT TEACHER ASSIGNMENTS (enhanced class_subjects)
-- ============================================================================

-- Extend existing class_subjects with more metadata via alter
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'class_subjects' AND column_name = 'is_compulsory'
  ) THEN
    ALTER TABLE class_subjects ADD COLUMN is_compulsory BOOLEAN DEFAULT true;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'class_subjects' AND column_name = 'is_elective'
  ) THEN
    ALTER TABLE class_subjects ADD COLUMN is_elective BOOLEAN DEFAULT false;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'class_subjects' AND column_name = 'term_id'
  ) THEN
    ALTER TABLE class_subjects ADD COLUMN term_id UUID REFERENCES terms(id) ON DELETE SET NULL;
  END IF;
END
$$;

-- ============================================================================
-- 22. INDEXES
-- ============================================================================

-- school_branches
CREATE INDEX IF NOT EXISTS idx_school_branches_school_id ON school_branches(school_id);
CREATE INDEX IF NOT EXISTS idx_school_branches_is_active ON school_branches(is_active);

-- departments
CREATE INDEX IF NOT EXISTS idx_departments_school_id ON departments(school_id);
CREATE INDEX IF NOT EXISTS idx_departments_head_teacher_id ON departments(head_teacher_id);
CREATE INDEX IF NOT EXISTS idx_departments_is_active ON departments(is_active);

-- student_profiles
CREATE INDEX IF NOT EXISTS idx_student_profiles_user_id ON student_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_school_id ON student_profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_admission_number ON student_profiles(admission_number);
CREATE INDEX IF NOT EXISTS idx_student_profiles_current_class_id ON student_profiles(current_class_id);
CREATE INDEX IF NOT EXISTS idx_student_profiles_is_active ON student_profiles(is_active);
CREATE INDEX IF NOT EXISTS idx_student_profiles_is_graduated ON student_profiles(is_graduated);

-- teacher_profiles
CREATE INDEX IF NOT EXISTS idx_teacher_profiles_user_id ON teacher_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_teacher_profiles_school_id ON teacher_profiles(school_id);
CREATE INDEX IF NOT EXISTS idx_teacher_profiles_department_id ON teacher_profiles(department_id);
CREATE INDEX IF NOT EXISTS idx_teacher_profiles_employee_id ON teacher_profiles(employee_id);
CREATE INDEX IF NOT EXISTS idx_teacher_profiles_is_active ON teacher_profiles(is_active);

-- parent_profiles
CREATE INDEX IF NOT EXISTS idx_parent_profiles_user_id ON parent_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_parent_profiles_school_id ON parent_profiles(school_id);

-- parent_students
CREATE INDEX IF NOT EXISTS idx_parent_students_parent_id ON parent_students(parent_id);
CREATE INDEX IF NOT EXISTS idx_parent_students_student_id ON parent_students(student_id);

-- academic_sessions
CREATE INDEX IF NOT EXISTS idx_academic_sessions_school_id ON academic_sessions(school_id);
CREATE INDEX IF NOT EXISTS idx_academic_sessions_is_current ON academic_sessions(is_current);

-- terms
CREATE INDEX IF NOT EXISTS idx_terms_academic_session_id ON terms(academic_session_id);
CREATE INDEX IF NOT EXISTS idx_terms_school_id ON terms(school_id);
CREATE INDEX IF NOT EXISTS idx_terms_is_current ON terms(is_current);
CREATE INDEX IF NOT EXISTS idx_terms_status ON terms(status);

-- school_calendar_events
CREATE INDEX IF NOT EXISTS idx_school_calendar_events_school_id ON school_calendar_events(school_id);
CREATE INDEX IF NOT EXISTS idx_school_calendar_events_term_id ON school_calendar_events(term_id);
CREATE INDEX IF NOT EXISTS idx_school_calendar_events_event_type ON school_calendar_events(event_type);
CREATE INDEX IF NOT EXISTS idx_school_calendar_events_start_date ON school_calendar_events(start_date);
CREATE INDEX IF NOT EXISTS idx_school_calendar_events_is_active ON school_calendar_events(is_active);

-- timetables
CREATE INDEX IF NOT EXISTS idx_timetables_school_id ON timetables(school_id);
CREATE INDEX IF NOT EXISTS idx_timetables_term_id ON timetables(term_id);
CREATE INDEX IF NOT EXISTS idx_timetables_class_id ON timetables(class_id);
CREATE INDEX IF NOT EXISTS idx_timetables_is_active ON timetables(is_active);

-- timetable_slots
CREATE INDEX IF NOT EXISTS idx_timetable_slots_timetable_id ON timetable_slots(timetable_id);
CREATE INDEX IF NOT EXISTS idx_timetable_slots_day_of_week ON timetable_slots(day_of_week);
CREATE INDEX IF NOT EXISTS idx_timetable_slots_teacher_id ON timetable_slots(teacher_id);
CREATE INDEX IF NOT EXISTS idx_timetable_slots_subject_id ON timetable_slots(subject_id);
CREATE INDEX IF NOT EXISTS idx_timetable_slots_class_id ON timetable_slots(class_id);
-- Composite index for conflict detection queries
CREATE INDEX IF NOT EXISTS idx_timetable_slots_teacher_day_period ON timetable_slots(teacher_id, day_of_week, period_number);
CREATE INDEX IF NOT EXISTS idx_timetable_slots_class_day_period ON timetable_slots(class_id, day_of_week, period_number);

-- attendance_records
CREATE INDEX IF NOT EXISTS idx_attendance_records_school_id ON attendance_records(school_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_term_id ON attendance_records(term_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_class_id ON attendance_records(class_id);
CREATE INDEX IF NOT EXISTS idx_attendance_records_date ON attendance_records(date);
CREATE INDEX IF NOT EXISTS idx_attendance_records_attendance_type ON attendance_records(attendance_type);
-- Composite for daily lookups
CREATE INDEX IF NOT EXISTS idx_attendance_records_class_date ON attendance_records(class_id, date);

-- attendance_entries
CREATE INDEX IF NOT EXISTS idx_attendance_entries_attendance_record_id ON attendance_entries(attendance_record_id);
CREATE INDEX IF NOT EXISTS idx_attendance_entries_user_id ON attendance_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_entries_status ON attendance_entries(status);

-- homework
CREATE INDEX IF NOT EXISTS idx_homework_school_id ON homework(school_id);
CREATE INDEX IF NOT EXISTS idx_homework_term_id ON homework(term_id);
CREATE INDEX IF NOT EXISTS idx_homework_class_id ON homework(class_id);
CREATE INDEX IF NOT EXISTS idx_homework_subject_id ON homework(subject_id);
CREATE INDEX IF NOT EXISTS idx_homework_teacher_id ON homework(teacher_id);
CREATE INDEX IF NOT EXISTS idx_homework_status ON homework(status);
CREATE INDEX IF NOT EXISTS idx_homework_deadline ON homework(deadline);

-- homework_submissions
CREATE INDEX IF NOT EXISTS idx_homework_submissions_homework_id ON homework_submissions(homework_id);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_student_id ON homework_submissions(student_id);
CREATE INDEX IF NOT EXISTS idx_homework_submissions_status ON homework_submissions(status);

-- announcements
CREATE INDEX IF NOT EXISTS idx_announcements_school_id ON announcements(school_id);
CREATE INDEX IF NOT EXISTS idx_announcements_type ON announcements(announcement_type);
CREATE INDEX IF NOT EXISTS idx_announcements_priority ON announcements(priority);
CREATE INDEX IF NOT EXISTS idx_announcements_is_published ON announcements(is_published);
CREATE INDEX IF NOT EXISTS idx_announcements_published_at ON announcements(published_at);
CREATE INDEX IF NOT EXISTS idx_announcements_created_by ON announcements(created_by);

-- documents
CREATE INDEX IF NOT EXISTS idx_documents_school_id ON documents(school_id);
CREATE INDEX IF NOT EXISTS idx_documents_document_type ON documents(document_type);
CREATE INDEX IF NOT EXISTS idx_documents_student_id ON documents(student_id);
CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON documents(uploaded_by);
CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category);
CREATE INDEX IF NOT EXISTS idx_documents_is_public ON documents(is_public);

-- promotion_history
CREATE INDEX IF NOT EXISTS idx_promotion_history_student_id ON promotion_history(student_id);
CREATE INDEX IF NOT EXISTS idx_promotion_history_school_id ON promotion_history(school_id);
CREATE INDEX IF NOT EXISTS idx_promotion_history_academic_session_id ON promotion_history(academic_session_id);
CREATE INDEX IF NOT EXISTS idx_promotion_history_promotion_status ON promotion_history(promotion_status);

-- ============================================================================
-- 23. TRIGGERS
-- ============================================================================

-- Auto-update updated_at on all new tables
DROP TRIGGER IF EXISTS set_school_branches_updated_at ON school_branches;
CREATE TRIGGER set_school_branches_updated_at
  BEFORE UPDATE ON school_branches FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_departments_updated_at ON departments;
CREATE TRIGGER set_departments_updated_at
  BEFORE UPDATE ON departments FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_student_profiles_updated_at ON student_profiles;
CREATE TRIGGER set_student_profiles_updated_at
  BEFORE UPDATE ON student_profiles FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_teacher_profiles_updated_at ON teacher_profiles;
CREATE TRIGGER set_teacher_profiles_updated_at
  BEFORE UPDATE ON teacher_profiles FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_parent_profiles_updated_at ON parent_profiles;
CREATE TRIGGER set_parent_profiles_updated_at
  BEFORE UPDATE ON parent_profiles FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_academic_sessions_updated_at ON academic_sessions;
CREATE TRIGGER set_academic_sessions_updated_at
  BEFORE UPDATE ON academic_sessions FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_terms_updated_at ON terms;
CREATE TRIGGER set_terms_updated_at
  BEFORE UPDATE ON terms FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_school_calendar_events_updated_at ON school_calendar_events;
CREATE TRIGGER set_school_calendar_events_updated_at
  BEFORE UPDATE ON school_calendar_events FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_timetables_updated_at ON timetables;
CREATE TRIGGER set_timetables_updated_at
  BEFORE UPDATE ON timetables FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_timetable_slots_updated_at ON timetable_slots;
CREATE TRIGGER set_timetable_slots_updated_at
  BEFORE UPDATE ON timetable_slots FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_attendance_records_updated_at ON attendance_records;
CREATE TRIGGER set_attendance_records_updated_at
  BEFORE UPDATE ON attendance_records FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_attendance_entries_updated_at ON attendance_entries;
CREATE TRIGGER set_attendance_entries_updated_at
  BEFORE UPDATE ON attendance_entries FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_homework_updated_at ON homework;
CREATE TRIGGER set_homework_updated_at
  BEFORE UPDATE ON homework FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_homework_submissions_updated_at ON homework_submissions;
CREATE TRIGGER set_homework_submissions_updated_at
  BEFORE UPDATE ON homework_submissions FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_announcements_updated_at ON announcements;
CREATE TRIGGER set_announcements_updated_at
  BEFORE UPDATE ON announcements FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS set_documents_updated_at ON documents;
CREATE TRIGGER set_documents_updated_at
  BEFORE UPDATE ON documents FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 24. HELPER FUNCTIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- ensure_single_current_session()
-- Ensures only one session per school is marked as current.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ensure_single_current_session()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_current = true THEN
    UPDATE academic_sessions
    SET is_current = false
    WHERE school_id = NEW.school_id
      AND id != NEW.id
      AND is_current = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_ensure_single_current_session ON academic_sessions;
CREATE TRIGGER trg_ensure_single_current_session
  BEFORE INSERT OR UPDATE OF is_current ON academic_sessions
  FOR EACH ROW
  WHEN (NEW.is_current = true)
  EXECUTE FUNCTION ensure_single_current_session();

-- ---------------------------------------------------------------------------
-- ensure_single_current_term()
-- Ensures only one term per school is marked as current.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION ensure_single_current_term()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.is_current = true THEN
    UPDATE terms
    SET is_current = false
    WHERE school_id = NEW.school_id
      AND id != NEW.id
      AND is_current = true;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_ensure_single_current_term ON terms;
CREATE TRIGGER trg_ensure_single_current_term
  BEFORE INSERT OR UPDATE OF is_current ON terms
  FOR EACH ROW
  WHEN (NEW.is_current = true)
  EXECUTE FUNCTION ensure_single_current_term();

-- ---------------------------------------------------------------------------
-- detect_timetable_conflicts()
-- Raises an exception if a teacher or class is double-booked.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION detect_timetable_conflicts()
RETURNS TRIGGER AS $$
BEGIN
  -- Check teacher conflict (same teacher, same day, same period, different slot)
  IF NEW.teacher_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM timetable_slots ts
      JOIN timetables t ON t.id = ts.timetable_id
      WHERE ts.teacher_id = NEW.teacher_id
        AND ts.day_of_week = NEW.day_of_week
        AND ts.period_number = NEW.period_number
        AND ts.id != NEW.id
        AND t.is_active = true
    ) THEN
      RAISE EXCEPTION 'Teacher is already assigned to another class at % period % on %',
        NEW.teacher_id, NEW.period_number, NEW.day_of_week;
    END IF;
  END IF;

  -- Check class conflict (same class, same day, same period, different slot)
  IF NEW.class_id IS NOT NULL THEN
    IF EXISTS (
      SELECT 1 FROM timetable_slots ts
      JOIN timetables t ON t.id = ts.timetable_id
      WHERE ts.class_id = NEW.class_id
        AND ts.day_of_week = NEW.day_of_week
        AND ts.period_number = NEW.period_number
        AND ts.id != NEW.id
        AND t.is_active = true
    ) THEN
      RAISE EXCEPTION 'Class is already occupied at period % on %',
        NEW.period_number, NEW.day_of_week;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_detect_timetable_conflicts ON timetable_slots;
CREATE TRIGGER trg_detect_timetable_conflicts
  BEFORE INSERT OR UPDATE ON timetable_slots
  FOR EACH ROW
  EXECUTE FUNCTION detect_timetable_conflicts();

-- ---------------------------------------------------------------------------
-- notify_announcement_published()
-- Creates notifications when an announcement is published.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION notify_announcement_published()
RETURNS TRIGGER AS $$
DECLARE
  target_user RECORD;
  notification_message TEXT;
BEGIN
  IF NEW.is_published = true AND (OLD.is_published = false OR OLD.is_published IS NULL) THEN
    notification_message := CASE NEW.priority
      WHEN 'urgent' THEN 'URGENT: ' || NEW.title
      WHEN 'high' THEN 'IMPORTANT: ' || NEW.title
      ELSE NEW.title
    END;

    -- Notify all users in the school based on target audience
    FOR target_user IN
      SELECT id FROM users
      WHERE school_id = NEW.school_id
        AND is_active = true
        AND CASE NEW.target_audience
          WHEN 'students' THEN role = 'student'
          WHEN 'teachers' THEN role = 'teacher'
          WHEN 'parents' THEN role = 'parent'
          ELSE true
        END
    LOOP
      INSERT INTO notifications (user_id, type, title, message, data)
      VALUES (
        target_user.id,
        'system',
        'New Announcement',
        notification_message,
        jsonb_build_object('announcement_id', NEW.id, 'type', 'announcement')
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_announcement_published ON announcements;
CREATE TRIGGER trg_notify_announcement_published
  AFTER INSERT OR UPDATE OF is_published ON announcements
  FOR EACH ROW
  WHEN (NEW.is_published = true)
  EXECUTE FUNCTION notify_announcement_published();

-- ============================================================================
-- 25. ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all new tables
ALTER TABLE school_branches ENABLE ROW LEVEL SECURITY;
ALTER TABLE departments ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE teacher_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE academic_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE terms ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetables ENABLE ROW LEVEL SECURITY;
ALTER TABLE timetable_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework ENABLE ROW LEVEL SECURITY;
ALTER TABLE homework_submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotion_history ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- SCHOOL BRANCHES RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school branches"
  ON school_branches FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "School admins can manage school branches"
  ON school_branches FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Super admins have full access to school branches"
  ON school_branches FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- DEPARTMENTS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school departments"
  ON departments FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "School admins can manage departments"
  ON departments FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- STUDENT PROFILES RLS
-- ===========================================================================

CREATE POLICY "Students can read own profile"
  ON student_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "School admins can read school student profiles"
  ON student_profiles FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Teachers can read profiles of students in their classes"
  ON student_profiles FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND EXISTS (
      SELECT 1 FROM class_students cs
      JOIN classes c ON c.id = cs.class_id
      WHERE cs.student_id = student_profiles.user_id
        AND (c.teacher_id = auth.uid()
             OR EXISTS (SELECT 1 FROM class_subjects cs2 WHERE cs2.class_id = c.id AND cs2.teacher_id = auth.uid()))
        AND cs.is_active = true
    )
  );

CREATE POLICY "School admins can manage student profiles"
  ON student_profiles FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Super admins can read all student profiles"
  ON student_profiles FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- ===========================================================================
-- TEACHER PROFILES RLS
-- ===========================================================================

CREATE POLICY "Teachers can read own profile"
  ON teacher_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "School admins can manage teacher profiles"
  ON teacher_profiles FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Authenticated users can read teacher profiles in school"
  ON teacher_profiles FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- PARENT PROFILES RLS
-- ===========================================================================

CREATE POLICY "Parents can read own profile"
  ON parent_profiles FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "School admins can manage parent profiles"
  ON parent_profiles FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- PARENT_STUDENTS RLS
-- ===========================================================================

CREATE POLICY "Parents can read own parent_student links"
  ON parent_students FOR SELECT
  TO authenticated
  USING (
    parent_id IN (SELECT id FROM parent_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "Students can read own parent links"
  ON parent_students FOR SELECT
  TO authenticated
  USING (
    student_id IN (SELECT id FROM student_profiles WHERE user_id = auth.uid())
  );

CREATE POLICY "School admins can manage parent_students"
  ON parent_students FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM parent_profiles pp
      WHERE pp.id = parent_students.parent_id
        AND pp.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
  );

-- ===========================================================================
-- ACADEMIC SESSIONS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school sessions"
  ON academic_sessions FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

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

-- ===========================================================================
-- TERMS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school terms"
  ON terms FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "School admins can manage terms"
  ON terms FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- SCHOOL CALENDAR EVENTS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school calendar events"
  ON school_calendar_events FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "School admins can manage calendar events"
  ON school_calendar_events FOR ALL
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- TIMETABLES RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school timetables"
  ON timetables FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "School admins can manage timetables"
  ON timetables FOR ALL
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- TIMETABLE SLOTS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read timetable slots"
  ON timetable_slots FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM timetables
      WHERE timetables.id = timetable_slots.timetable_id
        AND (timetables.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
             OR get_user_role() = 'super_admin')
    )
  );

CREATE POLICY "School admins and teachers can manage timetable slots"
  ON timetable_slots FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM timetables
      WHERE timetables.id = timetable_slots.timetable_id
        AND timetables.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
        AND (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM timetables
      WHERE timetables.id = timetable_slots.timetable_id
        AND timetables.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
        AND (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    )
  );

-- ===========================================================================
-- ATTENDANCE RECORDS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school attendance records"
  ON attendance_records FOR SELECT
  TO authenticated
  USING (
    school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "Teachers and admins can manage attendance records"
  ON attendance_records FOR ALL
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- ATTENDANCE ENTRIES RLS
-- ===========================================================================

CREATE POLICY "Students can read own attendance entries"
  ON attendance_entries FOR SELECT
  TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM attendance_records ar
      WHERE ar.id = attendance_entries.attendance_record_id
        AND ar.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

CREATE POLICY "Teachers and admins can manage attendance entries"
  ON attendance_entries FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM attendance_records ar
      WHERE ar.id = attendance_entries.attendance_record_id
        AND ar.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
        AND (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM attendance_records ar
      WHERE ar.id = attendance_entries.attendance_record_id
        AND ar.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
        AND (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    )
  );

-- ===========================================================================
-- HOMEWORK RLS
-- ===========================================================================

CREATE POLICY "Teachers can read own homework"
  ON homework FOR SELECT
  TO authenticated
  USING (
    teacher_id = auth.uid()
    OR (school_id = (SELECT school_id FROM users WHERE id = auth.uid())
        AND get_user_role() = 'school_admin')
    OR get_user_role() = 'super_admin'
  );

CREATE POLICY "Students can read published homework for their class"
  ON homework FOR SELECT
  TO authenticated
  USING (
    is_published = true
    AND EXISTS (
      SELECT 1 FROM class_students cs
      WHERE cs.class_id = homework.class_id
        AND cs.student_id = auth.uid()
        AND cs.is_active = true
    )
  );

CREATE POLICY "Teachers can manage own homework"
  ON homework FOR ALL
  TO authenticated
  USING (
    teacher_id = auth.uid()
    OR (get_user_role() = 'school_admin'
        AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
  )
  WITH CHECK (
    teacher_id = auth.uid()
    OR (get_user_role() = 'school_admin'
        AND school_id = (SELECT school_id FROM users WHERE id = auth.uid()))
  );

-- ===========================================================================
-- HOMEWORK SUBMISSIONS RLS
-- ===========================================================================

CREATE POLICY "Students can read own homework submissions"
  ON homework_submissions FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "Teachers can read submissions for their homework"
  ON homework_submissions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM homework
      WHERE homework.id = homework_submissions.homework_id
        AND homework.teacher_id = auth.uid()
    )
    OR get_user_role() = 'school_admin'
  );

CREATE POLICY "Students can create own submissions"
  ON homework_submissions FOR INSERT
  TO authenticated
  WITH CHECK (student_id = auth.uid());

CREATE POLICY "Students can update own pending submissions"
  ON homework_submissions FOR UPDATE
  TO authenticated
  USING (student_id = auth.uid() AND status = 'pending');

CREATE POLICY "Teachers can grade submissions for their homework"
  ON homework_submissions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM homework
      WHERE homework.id = homework_submissions.homework_id
        AND homework.teacher_id = auth.uid()
    )
    OR get_user_role() = 'school_admin'
  );

-- ===========================================================================
-- ANNOUNCEMENTS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read published announcements"
  ON announcements FOR SELECT
  TO authenticated
  USING (
    is_published = true
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "School admins can manage announcements"
  ON announcements FOR ALL
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- DOCUMENTS RLS
-- ===========================================================================

CREATE POLICY "Authenticated users can read school documents"
  ON documents FOR SELECT
  TO authenticated
  USING (
    (is_public = true OR student_id = auth.uid() OR uploaded_by = auth.uid())
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "School admins can manage documents"
  ON documents FOR ALL
  TO authenticated
  USING (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    (get_user_role() = 'school_admin' OR get_user_role() = 'teacher')
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ===========================================================================
-- PROMOTION HISTORY RLS
-- ===========================================================================

CREATE POLICY "Students can read own promotion history"
  ON promotion_history FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

CREATE POLICY "School admins can manage promotion history"
  ON promotion_history FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "Teachers can read promotion history for their students"
  ON promotion_history FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'teacher'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- ============================================================================
-- 26. REALTIME SUBSCRIPTIONS
-- ============================================================================

-- Enable Realtime for tables that need live updates
ALTER PUBLICATION supabase_realtime ADD TABLE school_branches;
ALTER PUBLICATION supabase_realtime ADD TABLE attendance_records;
ALTER PUBLICATION supabase_realtime ADD TABLE attendance_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE homework;
ALTER PUBLICATION supabase_realtime ADD TABLE homework_submissions;
ALTER PUBLICATION supabase_realtime ADD TABLE announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE terms;

COMMIT;

-- ============================================================================
-- END OF SCHOOL MANAGEMENT SCHEMA
-- ============================================================================
