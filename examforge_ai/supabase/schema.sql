-- ============================================================================
-- ExamForge AI - Supabase Database Schema
-- ============================================================================
-- Production-ready schema for the ExamForge AI platform.
-- Manages schools, users, classes, subjects, notifications, and audit logs.
--
-- Dependencies: Supabase Auth (auth.users)
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. CUSTOM ENUMERATION TYPES
-- ============================================================================

DO $$
BEGIN
  -- user_role: Defines the hierarchy of user permissions
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
    CREATE TYPE user_role AS ENUM (
      'super_admin',
      'school_admin',
      'teacher',
      'student'
    );
  END IF;

  -- subscription_status: School subscription tier
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'subscription_status') THEN
    CREATE TYPE subscription_status AS ENUM (
      'free',
      'basic',
      'premium',
      'enterprise'
    );
  END IF;

  -- exam_status: Lifecycle states for an exam
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'exam_status') THEN
    CREATE TYPE exam_status AS ENUM (
      'draft',
      'published',
      'active',
      'completed',
      'archived'
    );
  END IF;

  -- notification_type: Category of notification
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type') THEN
    CREATE TYPE notification_type AS ENUM (
      'exam',
      'system',
      'result',
      'reminder'
    );
  END IF;

  -- question_type: Supported question formats
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'question_type') THEN
    CREATE TYPE question_type AS ENUM (
      'multiple_choice',
      'true_false',
      'short_answer',
      'essay',
      'fill_in_blank'
    );
  END IF;
END
$$;

-- ============================================================================
-- 2. SCHOOLS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS schools (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,
  code                  TEXT UNIQUE NOT NULL,               -- School registration code
  address               TEXT,
  city                  TEXT,
  state                 TEXT,
  country               TEXT DEFAULT 'Nigeria',
  phone                 TEXT,
  email                 TEXT UNIQUE,
  website               TEXT,
  logo_url              TEXT,
  subscription_status   subscription_status DEFAULT 'free',
  subscription_expires_at TIMESTAMPTZ,
  max_students          INTEGER DEFAULT 100,
  max_teachers          INTEGER DEFAULT 10,
  is_active             BOOLEAN DEFAULT true,
  settings              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE schools IS 'Registered schools / institutions on the platform';
COMMENT ON COLUMN schools.code IS 'Unique registration code used to identify and join a school';
COMMENT ON COLUMN schools.subscription_status IS 'Current subscription tier of the school';
COMMENT ON COLUMN schools.settings IS 'Arbitrary school-wide configuration stored as JSONB';

-- ============================================================================
-- 3. USERS TABLE (extends Supabase auth.users)
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  id                    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email                 TEXT NOT NULL UNIQUE,
  full_name             TEXT NOT NULL,
  phone                 TEXT,
  avatar_url            TEXT,
  role                  user_role NOT NULL DEFAULT 'student',
  school_id             UUID REFERENCES schools(id) ON DELETE SET NULL,
  is_active             BOOLEAN DEFAULT true,
  is_email_verified     BOOLEAN DEFAULT false,
  last_login_at         TIMESTAMPTZ,
  settings              JSONB DEFAULT '{}',
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE users IS 'Application-level user profiles linked 1-to-1 with auth.users';
COMMENT ON COLUMN users.role IS 'Role-based access control: super_admin > school_admin > teacher > student';
COMMENT ON COLUMN users.school_id IS 'The school the user belongs to; NULL for super_admins';

-- ============================================================================
-- 4. CLASSES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS classes (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,                       -- e.g. "SS1A", "JSS2B"
  section               TEXT,                                -- e.g. "A", "B", "Science", "Arts"
  school_id             UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  teacher_id            UUID REFERENCES users(id) ON DELETE SET NULL,  -- Class teacher
  academic_year         TEXT NOT NULL,                       -- e.g. "2024/2025"
  grade_level           TEXT,                                -- e.g. "SS1", "JSS2"
  capacity              INTEGER DEFAULT 40,
  is_active             BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE classes IS 'Class / arm within a school (e.g. SS1A - Science)';
COMMENT ON COLUMN classes.teacher_id IS 'The class teacher assigned to this class';
COMMENT ON COLUMN classes.academic_year IS 'Academic session, e.g. 2024/2025';

-- ============================================================================
-- 5. SUBJECTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS subjects (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,                       -- e.g. "Mathematics", "English Language"
  code                  TEXT NOT NULL,                       -- e.g. "MTH", "ENG"
  description           TEXT,
  school_id             UUID REFERENCES schools(id) ON DELETE CASCADE,  -- NULL for system-wide subjects
  category              TEXT,                                -- e.g. "Science", "Arts", "Commercial"
  icon_url              TEXT,
  is_active             BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE subjects IS 'Subjects available for exams; school_id NULL means system-provided';
COMMENT ON COLUMN subjects.code IS 'Short code identifier for the subject (e.g. MTH, ENG)';

-- ============================================================================
-- 6. CLASS_SUBJECTS TABLE (many-to-many: classes <-> subjects)
-- ============================================================================

CREATE TABLE IF NOT EXISTS class_subjects (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id              UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  subject_id            UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  teacher_id            UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at            TIMESTAMPTZ DEFAULT now(),
  UNIQUE(class_id, subject_id)
);

COMMENT ON TABLE class_subjects IS 'Maps which subjects are offered in which class and who teaches them';

-- ============================================================================
-- 7. CLASS_STUDENTS TABLE (many-to-many: classes <-> students)
-- ============================================================================

CREATE TABLE IF NOT EXISTS class_students (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  class_id              UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  student_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  enrolled_at           TIMESTAMPTZ DEFAULT now(),
  is_active             BOOLEAN DEFAULT true,
  UNIQUE(class_id, student_id)
);

COMMENT ON TABLE class_students IS 'Enrolment records linking students to classes';

-- ============================================================================
-- 8. NOTIFICATIONS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS notifications (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type                  notification_type NOT NULL DEFAULT 'system',
  title                 TEXT NOT NULL,
  message               TEXT NOT NULL,
  data                  JSONB DEFAULT '{}',
  is_read               BOOLEAN DEFAULT false,
  read_at               TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE notifications IS 'In-app notifications for users';
COMMENT ON COLUMN notifications.data IS 'Optional structured payload (e.g. exam_id, result summary)';

-- ============================================================================
-- 9. AUDIT LOG TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS audit_log (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id               UUID REFERENCES users(id) ON DELETE SET NULL,
  action                TEXT NOT NULL,                       -- e.g. "create", "update", "delete"
  resource_type         TEXT NOT NULL,                       -- e.g. "exam", "user", "school"
  resource_id           UUID,
  details               JSONB DEFAULT '{}',
  ip_address            INET,
  created_at            TIMESTAMPTZ DEFAULT now()
);

COMMENT ON TABLE audit_log IS 'Immutable audit trail for all significant actions';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Foreign key columns (speed up JOINs and lookups)
-- ---------------------------------------------------------------------------

-- users
CREATE INDEX IF NOT EXISTS idx_users_school_id ON users(school_id);

-- classes
CREATE INDEX IF NOT EXISTS idx_classes_school_id ON classes(school_id);
CREATE INDEX IF NOT EXISTS idx_classes_teacher_id ON classes(teacher_id);

-- subjects
CREATE INDEX IF NOT EXISTS idx_subjects_school_id ON subjects(school_id);

-- class_subjects
CREATE INDEX IF NOT EXISTS idx_class_subjects_class_id ON class_subjects(class_id);
CREATE INDEX IF NOT EXISTS idx_class_subjects_subject_id ON class_subjects(subject_id);
CREATE INDEX IF NOT EXISTS idx_class_subjects_teacher_id ON class_subjects(teacher_id);

-- class_students
CREATE INDEX IF NOT EXISTS idx_class_students_class_id ON class_students(class_id);
CREATE INDEX IF NOT EXISTS idx_class_students_student_id ON class_students(student_id);

-- notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);

-- audit_log
CREATE INDEX IF NOT EXISTS idx_audit_log_user_id ON audit_log(user_id);

-- ---------------------------------------------------------------------------
-- Business-query columns
-- ---------------------------------------------------------------------------

-- users
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- schools
CREATE INDEX IF NOT EXISTS idx_schools_code ON schools(code);
CREATE INDEX IF NOT EXISTS idx_schools_is_active ON schools(is_active);

-- subjects
CREATE INDEX IF NOT EXISTS idx_subjects_code ON subjects(code);

-- notifications (composite: unread count per user)
CREATE INDEX IF NOT EXISTS idx_notifications_user_id_is_read ON notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- audit_log
CREATE INDEX IF NOT EXISTS idx_audit_log_created_at ON audit_log(created_at);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- update_updated_at_column()
-- Automatically sets updated_at = now() on every row update.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column() IS
  'Trigger function: automatically refreshes updated_at to the current timestamp';

-- ---------------------------------------------------------------------------
-- is_school_member(school_id)
-- Returns TRUE if the currently authenticated user belongs to the given school.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION is_school_member(target_school_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM users
    WHERE id = auth.uid()
      AND school_id = target_school_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION is_school_member(UUID) IS
  'Checks whether the current auth user is a member of the specified school';

-- ---------------------------------------------------------------------------
-- get_user_role()
-- Returns the user_role of the currently authenticated user.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
DECLARE
  current_role user_role;
BEGIN
  SELECT role INTO current_role
  FROM users
  WHERE id = auth.uid();

  RETURN current_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

COMMENT ON FUNCTION get_user_role() IS
  'Returns the role of the currently authenticated user';

-- ---------------------------------------------------------------------------
-- handle_new_user()
-- Trigger function: automatically creates a user profile row in public.users
-- after a new row is inserted into auth.users.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, role, is_email_verified)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.email),
    COALESCE(
      (NEW.raw_user_meta_data ->> 'role')::user_role,
      'student'
    ),
    NEW.email_confirmed_at IS NOT NULL
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION handle_new_user() IS
  'Trigger: auto-creates a public.users profile when a new auth.users row is inserted';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Auto-update updated_at on all tables that have the column
-- ---------------------------------------------------------------------------

-- schools
DROP TRIGGER IF EXISTS set_schools_updated_at ON schools;
CREATE TRIGGER set_schools_updated_at
  BEFORE UPDATE ON schools
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- users
DROP TRIGGER IF EXISTS set_users_updated_at ON users;
CREATE TRIGGER set_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- classes
DROP TRIGGER IF EXISTS set_classes_updated_at ON classes;
CREATE TRIGGER set_classes_updated_at
  BEFORE UPDATE ON classes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- subjects
DROP TRIGGER IF EXISTS set_subjects_updated_at ON subjects;
CREATE TRIGGER set_subjects_updated_at
  BEFORE UPDATE ON subjects
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------------
-- Auto-create user profile after auth.users insert
-- ---------------------------------------------------------------------------

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Enable RLS on ALL data tables
-- ---------------------------------------------------------------------------

ALTER TABLE schools ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE class_students ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- SCHOOLS RLS POLICIES
-- ===========================================================================

-- Any authenticated user can read active schools
CREATE POLICY "Authenticated users can read active schools"
  ON schools FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Super admins can read all schools (including inactive)
CREATE POLICY "Super admins can read all schools"
  ON schools FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- School admins can update their own school
CREATE POLICY "School admins can update own school"
  ON schools FOR UPDATE
  TO authenticated
  USING (
    role = 'school_admin'
    AND school_id = id
  )
  WITH CHECK (
    role = 'school_admin'
    AND school_id = id
  );

-- Super admins can do everything on schools
CREATE POLICY "Super admins have full access to schools"
  ON schools FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Super admins can insert schools
CREATE POLICY "Super admins can insert schools"
  ON schools FOR INSERT
  TO authenticated
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- USERS RLS POLICIES
-- ===========================================================================

-- Users can read their own row
CREATE POLICY "Users can read own row"
  ON users FOR SELECT
  TO authenticated
  USING (id = auth.uid());

-- School admins can read users in their school
CREATE POLICY "School admins can read school users"
  ON users FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    AND school_id IS NOT NULL
  );

-- Super admins can read all users
CREATE POLICY "Super admins can read all users"
  ON users FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- Users can update their own row (except role)
CREATE POLICY "Users can update own row"
  ON users FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (
    id = auth.uid()
    AND role = (SELECT role FROM users WHERE id = auth.uid())  -- prevent role change
  );

-- Only super admins can change roles
CREATE POLICY "Super admins can update any user"
  ON users FOR UPDATE
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- Super admins can delete users
CREATE POLICY "Super admins can delete users"
  ON users FOR DELETE
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- ===========================================================================
-- CLASSES RLS POLICIES
-- ===========================================================================

-- Teachers can read classes they teach (as class teacher or via class_subjects)
CREATE POLICY "Teachers can read classes they teach"
  ON classes FOR SELECT
  TO authenticated
  USING (
    teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM class_subjects cs
      WHERE cs.class_id = id AND cs.teacher_id = auth.uid()
    )
  );

-- Students can read classes they are enrolled in
CREATE POLICY "Students can read enrolled classes"
  ON classes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM class_students cst
      WHERE cst.class_id = id
        AND cst.student_id = auth.uid()
        AND cst.is_active = true
    )
  );

-- School admins can CRUD classes in their school
CREATE POLICY "School admins can read school classes"
  ON classes FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "School admins can insert school classes"
  ON classes FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "School admins can update school classes"
  ON classes FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

CREATE POLICY "School admins can delete school classes"
  ON classes FOR DELETE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Super admins can read all classes
CREATE POLICY "Super admins can read all classes"
  ON classes FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- ===========================================================================
-- SUBJECTS RLS POLICIES
-- ===========================================================================

-- All authenticated users in a school can read their school's subjects + system subjects
CREATE POLICY "Authenticated users can read school subjects"
  ON subjects FOR SELECT
  TO authenticated
  USING (
    school_id IS NULL  -- system-wide subjects
    OR school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- School admins can insert subjects for their school
CREATE POLICY "School admins can insert school subjects"
  ON subjects FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- School admins can update subjects in their school
CREATE POLICY "School admins can update school subjects"
  ON subjects FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- School admins can delete subjects in their school
CREATE POLICY "School admins can delete school subjects"
  ON subjects FOR DELETE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = (SELECT school_id FROM users WHERE id = auth.uid())
  );

-- Super admins have full access to subjects
CREATE POLICY "Super admins have full access to subjects"
  ON subjects FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ===========================================================================
-- CLASS_SUBJECTS RLS POLICIES
-- ===========================================================================

-- Teachers can read class_subjects for classes they teach
CREATE POLICY "Teachers can read own class_subjects"
  ON class_subjects FOR SELECT
  TO authenticated
  USING (
    teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM classes c WHERE c.id = class_id AND c.teacher_id = auth.uid()
    )
  );

-- Students can read class_subjects for classes they are in
CREATE POLICY "Students can read enrolled class_subjects"
  ON class_subjects FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM class_students cst
      WHERE cst.class_id = class_id
        AND cst.student_id = auth.uid()
        AND cst.is_active = true
    )
  );

-- School admins can CRUD class_subjects in their school
CREATE POLICY "School admins can manage class_subjects"
  ON class_subjects FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM classes c
      WHERE c.id = class_id
        AND c.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM classes c
      WHERE c.id = class_id
        AND c.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Super admins can read all class_subjects
CREATE POLICY "Super admins can read all class_subjects"
  ON class_subjects FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- ===========================================================================
-- CLASS_STUDENTS RLS POLICIES
-- ===========================================================================

-- Students can read their own enrolments
CREATE POLICY "Students can read own enrolments"
  ON class_students FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Teachers can read enrolments for classes they teach
CREATE POLICY "Teachers can read class enrolments"
  ON class_students FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM classes c WHERE c.id = class_id AND c.teacher_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM class_subjects cs WHERE cs.class_id = class_id AND cs.teacher_id = auth.uid()
    )
  );

-- School admins can CRUD enrolments in their school
CREATE POLICY "School admins can manage class_students"
  ON class_students FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM classes c
      WHERE c.id = class_id
        AND c.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM classes c
      WHERE c.id = class_id
        AND c.school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Super admins can read all class_students
CREATE POLICY "Super admins can read all class_students"
  ON class_students FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- ===========================================================================
-- NOTIFICATIONS RLS POLICIES
-- ===========================================================================

-- Users can only read their own notifications
CREATE POLICY "Users can read own notifications"
  ON notifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update own notifications"
  ON notifications FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can delete their own notifications
CREATE POLICY "Users can delete own notifications"
  ON notifications FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- System can insert notifications (service role bypasses RLS)
-- No INSERT policy for authenticated users; notifications are created
-- server-side via the service_role key.

-- ===========================================================================
-- AUDIT LOG RLS POLICIES
-- ===========================================================================

-- Super admins can read all audit logs
CREATE POLICY "Super admins can read audit_log"
  ON audit_log FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- School admins can read audit logs for their school
CREATE POLICY "School admins can read school audit_log"
  ON audit_log FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND user_id IN (
      SELECT id FROM users
      WHERE school_id = (SELECT school_id FROM users WHERE id = auth.uid())
    )
  );

-- Audit logs are insert-only via service_role; no INSERT policy for authenticated users.
-- Audit logs are immutable; no UPDATE or DELETE policies.

COMMIT;

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
