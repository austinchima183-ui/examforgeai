-- ============================================================================
-- ExamForge AI — RLS Policy Fix Migration
-- ============================================================================
-- Fixes RLS policies that reference columns from the wrong table or use
-- incorrect role comparisons. The original policies had issues like:
--   1. Using `role = 'school_admin'` on the schools table (role column
--      doesn't exist on schools, it's on users)
--   2. Using `school_id = id` on schools update (comparing user's
--      school_id with school's id, but not going through users table)
--   3. Missing 'parent' role in the user_role enum
--   4. Policies that use `get_user_role()` which may not exist or
--      may not handle all role types correctly
--
-- This migration drops and recreates all affected RLS policies with
-- correct table references and role checks.
-- ============================================================================

BEGIN;

-- ════════════════════════════════════════════════════════════════════════════
-- 1. ADD 'parent' ROLE TO user_role ENUM
-- ════════════════════════════════════════════════════════════════════════════
-- The platform supports 6 roles but the enum only has 4.

DO $$
BEGIN
  -- Add parent role
  IF NOT EXISTS (
    SELECT 1 FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'user_role' AND e.enumlabel = 'parent'
  ) THEN
    ALTER TYPE user_role ADD VALUE 'parent';
  END IF;
END $$;

-- ════════════════════════════════════════════════════════════════════════════
-- 2. CREATE get_user_role() HELPER FUNCTION
-- ════════════════════════════════════════════════════════════════════════════
-- Used by RLS policies to get the current user's role without a subquery
-- on every row evaluation.

CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
  SELECT role FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ════════════════════════════════════════════════════════════════════════════
-- 3. CREATE get_user_school_id() HELPER FUNCTION
-- ════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION get_user_school_id()
RETURNS UUID AS $$
  SELECT school_id FROM public.users WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- ════════════════════════════════════════════════════════════════════════════
-- 4. FIX SCHOOLS RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════

-- Drop all existing policies on schools
DROP POLICY IF EXISTS "Authenticated users can read active schools" ON schools;
DROP POLICY IF EXISTS "Super admins can read all schools" ON schools;
DROP POLICY IF EXISTS "School admins can update own school" ON schools;
DROP POLICY IF EXISTS "Super admins have full access to schools" ON schools;
DROP POLICY IF EXISTS "Super admins can insert schools" ON schools;

-- Recreate with correct role references
CREATE POLICY "Authenticated users can read active schools"
  ON schools FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "Super admins can read all schools"
  ON schools FOR SELECT
  TO authenticated
  USING (get_user_role() = 'super_admin');

-- FIX: Use get_user_school_id() and get_user_role() instead of
-- directly referencing `role` and `school_id` columns which don't
-- exist on the schools table.
CREATE POLICY "School admins can update own school"
  ON schools FOR UPDATE
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND get_user_school_id() = id
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND get_user_school_id() = id
  );

CREATE POLICY "Super admins have full access to schools"
  ON schools FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

CREATE POLICY "Super admins can insert schools"
  ON schools FOR INSERT
  TO authenticated
  WITH CHECK (get_user_role() = 'super_admin');

-- ════════════════════════════════════════════════════════════════════════════
-- 5. FIX CLASSES RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════

-- Drop existing class policies
DROP POLICY IF EXISTS "Teachers can read classes they teach" ON classes;
DROP POLICY IF EXISTS "Students can read enrolled classes" ON classes;
DROP POLICY IF EXISTS "School admins can manage classes" ON classes;
DROP POLICY IF EXISTS "Super admins have full access to classes" ON classes;
DROP POLICY IF EXISTS "Teachers can create classes" ON classes;

-- Recreate with correct role checks
CREATE POLICY "Teachers can read classes they teach"
  ON classes FOR SELECT
  TO authenticated
  USING (
    teacher_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM class_subjects cs
      WHERE cs.class_id = classes.id AND cs.teacher_id = auth.uid()
    )
    OR get_user_role() IN ('school_admin', 'super_admin')
  );

CREATE POLICY "Students can read enrolled classes"
  ON classes FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM class_students cst
      WHERE cst.class_id = classes.id
        AND cst.student_id = auth.uid()
        AND cst.is_active = true
    )
  );

-- FIX: Use get_user_school_id() for school scoping
CREATE POLICY "School admins can manage classes"
  ON classes FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = get_user_school_id()
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND school_id = get_user_school_id()
  );

CREATE POLICY "Super admins have full access to classes"
  ON classes FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

CREATE POLICY "Teachers can create classes"
  ON classes FOR INSERT
  TO authenticated
  WITH CHECK (
    get_user_role() = 'teacher'
    AND school_id = get_user_school_id()
  );

-- ════════════════════════════════════════════════════════════════════════════
-- 6. FIX SUBJECTS RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════

DROP POLICY IF EXISTS "Authenticated users can read active subjects" ON subjects;
DROP POLICY IF EXISTS "School admins can manage subjects" ON subjects;
DROP POLICY IF EXISTS "Super admins have full access to subjects" ON subjects;

CREATE POLICY "Authenticated users can read active subjects"
  ON subjects FOR SELECT
  TO authenticated
  USING (is_active = true);

CREATE POLICY "School admins can manage subjects"
  ON subjects FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND (school_id = get_user_school_id() OR school_id IS NULL)
  )
  WITH CHECK (
    get_user_role() = 'school_admin'
    AND (school_id = get_user_school_id() OR school_id IS NULL)
  );

CREATE POLICY "Super admins have full access to subjects"
  ON subjects FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin')
  WITH CHECK (get_user_role() = 'super_admin');

-- ════════════════════════════════════════════════════════════════════════════
-- 7. FIX USERS RLS POLICIES
-- ════════════════════════════════════════════════════════════════════════════
-- Add parent role access

DROP POLICY IF EXISTS "School admins can read school users" ON users;

CREATE POLICY "School admins can read school users"
  ON users FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND school_id = get_user_school_id()
    AND school_id IS NOT NULL
  );

-- Add policy for parents to read their children's data
CREATE POLICY "Parents can read own children"
  ON users FOR SELECT
  TO authenticated
  USING (
    get_user_role() = 'parent'
    AND EXISTS (
      SELECT 1 FROM parent_children pc
      WHERE pc.parent_id = auth.uid()
        AND pc.child_id = users.id
    )
  );

-- ════════════════════════════════════════════════════════════════════════════
-- 8. CREATE parent_children JUNCTION TABLE (if not exists)
-- ════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_children (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  child_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  relationship TEXT NOT NULL DEFAULT 'parent',
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(parent_id, child_id)
);

ALTER TABLE parent_children ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Parents can read own parent_children"
  ON parent_children FOR SELECT
  TO authenticated
  USING (parent_id = auth.uid());

CREATE POLICY "School admins can manage parent_children"
  ON parent_children FOR ALL
  TO authenticated
  USING (
    get_user_role() = 'school_admin'
    AND EXISTS (
      SELECT 1 FROM users WHERE id = parent_id AND school_id = get_user_school_id()
    )
  );

CREATE POLICY "Super admins have full access to parent_children"
  ON parent_children FOR ALL
  TO authenticated
  USING (get_user_role() = 'super_admin');

COMMIT;
