-- ═══════════════════════════════════════════════════════════════════════════════
-- EXAMFORGE AI — PARENT PORTAL MODULE SCHEMA
-- ═══════════════════════════════════════════════════════════════════════════════
-- Comprehensive parent portal: dashboard, child profiles, academic performance,
-- attendance, assignments, messaging, calendar, AI assistant, notifications,
-- reports, and parent engagement analytics.
-- Depends on: schema.sql, school_management_schema.sql, results_analytics_schema.sql
-- ═══════════════════════════════════════════════════════════════════════════════

-- ─── Custom Enums ──────────────────────────────────────────────────────────────

CREATE TYPE message_direction AS ENUM (
  'incoming',
  'outgoing'
);

CREATE TYPE message_status AS ENUM (
  'sent',
  'delivered',
  'read',
  'failed'
);

CREATE TYPE parent_insight_type AS ENUM (
  'performance_trend',
  'attendance_alert',
  'study_recommendation',
  'engagement_tip',
  'milestone',
  'concern'
);

CREATE TYPE engagement_metric_type AS ENUM (
  'report_card_viewed',
  'announcement_read',
  'message_sent',
  'meeting_attended',
  'assignment_checked',
  'attendance_checked',
  'calendar_viewed',
  'ai_assistant_used'
);

CREATE TYPE report_download_format AS ENUM (
  'pdf',
  'excel',
  'printable'
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT MESSAGES TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Sender & Recipient
  sender_id       UUID NOT NULL REFERENCES auth.users(id),
  sender_role     user_role NOT NULL DEFAULT 'parent',
  recipient_id    UUID NOT NULL REFERENCES auth.users(id),
  recipient_role  user_role NOT NULL DEFAULT 'teacher',

  -- Context
  student_id      UUID REFERENCES auth.users(id),  -- related student (optional)
  subject         TEXT NOT NULL,
  body            TEXT NOT NULL,

  -- Threading
  parent_message_id UUID REFERENCES parent_messages(id) ON DELETE SET NULL,
  thread_id       UUID,  -- grouping ID for conversation threads

  -- Status
  direction       message_direction NOT NULL DEFAULT 'outgoing',
  status          message_status NOT NULL DEFAULT 'sent',
  is_flagged      BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,

  -- Read tracking
  read_at         TIMESTAMPTZ,
  delivered_at    TIMESTAMPTZ,

  -- Attachments
  attachments     JSONB DEFAULT '[]'::jsonb,  -- [{name, url, type, size}]

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parent_messages_school ON parent_messages(school_id);
CREATE INDEX idx_parent_messages_sender ON parent_messages(sender_id);
CREATE INDEX idx_parent_messages_recipient ON parent_messages(recipient_id);
CREATE INDEX idx_parent_messages_student ON parent_messages(student_id);
CREATE INDEX idx_parent_messages_thread ON parent_messages(thread_id);
CREATE INDEX idx_parent_messages_unread ON parent_messages(recipient_id, read_at) WHERE read_at IS NULL;
CREATE INDEX idx_parent_messages_created ON parent_messages(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT NOTIFICATIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  parent_id       UUID NOT NULL REFERENCES auth.users(id),
  student_id      UUID REFERENCES auth.users(id),  -- related student

  -- Notification content
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  notification_type notification_type NOT NULL DEFAULT 'system',
  category        TEXT NOT NULL DEFAULT 'general',  -- result, attendance, assignment, announcement, exam, message, fee
  priority        TEXT NOT NULL DEFAULT 'normal',    -- low, normal, high, urgent

  -- Data payload
  data            JSONB DEFAULT '{}'::jsonb,

  -- Read status
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  read_at         TIMESTAMPTZ,

  -- Delivery channels
  delivered_in_app    BOOLEAN NOT NULL DEFAULT FALSE,
  delivered_push      BOOLEAN NOT NULL DEFAULT FALSE,
  delivered_email     BOOLEAN NOT NULL DEFAULT FALSE,
  delivered_sms       BOOLEAN NOT NULL DEFAULT FALSE,

  -- Action
  action_url      TEXT,    -- deep link to relevant page
  action_label    TEXT,    -- e.g. "View Results"

  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parent_notifications_parent ON parent_notifications(parent_id);
CREATE INDEX idx_parent_notifications_parent_unread ON parent_notifications(parent_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_parent_notifications_student ON parent_notifications(student_id);
CREATE INDEX idx_parent_notifications_type ON parent_notifications(notification_type);
CREATE INDEX idx_parent_notifications_created ON parent_notifications(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT ACTIVITY LOGS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_activity_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  parent_id       UUID NOT NULL REFERENCES auth.users(id),
  student_id      UUID REFERENCES auth.users(id),

  -- Activity tracking
  action          TEXT NOT NULL,          -- e.g. 'viewed_report_card', 'read_announcement'
  resource_type   TEXT,                   -- e.g. 'result', 'attendance', 'assignment'
  resource_id     UUID,
  details         JSONB DEFAULT '{}'::jsonb,

  -- Session info
  ip_address      INET,
  user_agent      TEXT,
  device_type     TEXT,  -- mobile, tablet, desktop

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parent_activity_parent ON parent_activity_logs(parent_id);
CREATE INDEX idx_parent_activity_student ON parent_activity_logs(student_id);
CREATE INDEX idx_parent_activity_action ON parent_activity_logs(action);
CREATE INDEX idx_parent_activity_created ON parent_activity_logs(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- AI PARENT INSIGHTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_ai_insights (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  parent_id       UUID NOT NULL REFERENCES auth.users(id),
  student_id      UUID NOT NULL REFERENCES auth.users(id),

  insight_type    parent_insight_type NOT NULL,
  title           TEXT NOT NULL,
  description     TEXT NOT NULL,
  severity        TEXT NOT NULL DEFAULT 'info',  -- info, warning, concern, positive
  recommendations TEXT[] DEFAULT '{}',

  -- AI generation context
  is_ai_generated BOOLEAN NOT NULL DEFAULT TRUE,
  ai_model        TEXT,
  data_snapshot   JSONB DEFAULT '{}'::jsonb,  -- the data that triggered this insight

  -- Status
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  is_dismissed    BOOLEAN NOT NULL DEFAULT FALSE,
  is_actionable   BOOLEAN NOT NULL DEFAULT TRUE,

  valid_from      TIMESTAMPTZ NOT NULL DEFAULT now(),
  valid_until     TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parent_insights_parent ON parent_ai_insights(parent_id);
CREATE INDEX idx_parent_insights_student ON parent_ai_insights(student_id);
CREATE INDEX idx_parent_insights_type ON parent_ai_insights(insight_type);
CREATE INDEX idx_parent_insights_unread ON parent_ai_insights(parent_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_parent_insights_active ON parent_ai_insights(parent_id, is_dismissed) WHERE is_dismissed = FALSE;
CREATE INDEX idx_parent_insights_created ON parent_ai_insights(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT REPORT DOWNLOADS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_report_downloads (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  parent_id       UUID NOT NULL REFERENCES auth.users(id),
  student_id      UUID NOT NULL REFERENCES auth.users(id),

  report_type     TEXT NOT NULL,    -- report_card, attendance, assignments, progress
  report_id       UUID,            -- reference to the actual report record
  format          report_download_format NOT NULL DEFAULT 'pdf',

  file_url        TEXT NOT NULL,
  file_name       TEXT NOT NULL,
  file_size_bytes BIGINT,

  downloaded_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parent_downloads_parent ON parent_report_downloads(parent_id);
CREATE INDEX idx_parent_downloads_student ON parent_report_downloads(student_id);
CREATE INDEX idx_parent_downloads_type ON parent_report_downloads(report_type);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT CALENDAR EVENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS parent_calendar_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  parent_id       UUID REFERENCES auth.users(id),  -- NULL = all parents
  student_id      UUID REFERENCES auth.users(id),  -- NULL = all students

  title           TEXT NOT NULL,
  description     TEXT,
  event_type      TEXT NOT NULL DEFAULT 'school',  -- school, holiday, meeting, exam, event, deadline
  start_time      TIMESTAMPTZ NOT NULL,
  end_time        TIMESTAMPTZ NOT NULL,
  location        TEXT,

  -- Source reference
  source_type     TEXT,   -- 'announcement', 'exam', 'homework', 'custom'
  source_id       UUID,

  -- Reminders
  reminder_minutes INTEGER[] DEFAULT '{60, 1440}',  -- 1 hour and 1 day before

  is_all_day      BOOLEAN NOT NULL DEFAULT FALSE,
  is_recurring    BOOLEAN NOT NULL DEFAULT FALSE,
  recurrence_rule TEXT,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_parent_calendar_parent ON parent_calendar_events(parent_id);
CREATE INDEX idx_parent_calendar_school ON parent_calendar_events(school_id);
CREATE INDEX idx_parent_calendar_student ON parent_calendar_events(student_id);
CREATE INDEX idx_parent_calendar_time ON parent_calendar_events(start_time, end_time);
CREATE INDEX idx_parent_calendar_type ON parent_calendar_events(event_type);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT ENGAGEMENT METRICS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════
-- Tracks parent engagement for the admin dashboard

CREATE TABLE IF NOT EXISTS parent_engagement_metrics (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  parent_id       UUID NOT NULL REFERENCES auth.users(id),
  student_id      UUID NOT NULL REFERENCES auth.users(id),

  metric_type     engagement_metric_type NOT NULL,
  metric_value    NUMERIC DEFAULT 1,
  details         JSONB DEFAULT '{}'::jsonb,

  recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_engagement_school ON parent_engagement_metrics(school_id);
CREATE INDEX idx_engagement_parent ON parent_engagement_metrics(parent_id);
CREATE INDEX idx_engagement_student ON parent_engagement_metrics(student_id);
CREATE INDEX idx_engagement_type ON parent_engagement_metrics(metric_type);
CREATE INDEX idx_engagement_recorded ON parent_engagement_metrics(recorded_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT ENGAGEMENT SUMMARY MATERIALIZED VIEW
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE MATERIALIZED VIEW IF NOT EXISTS parent_engagement_summary AS
SELECT
  pem.school_id,
  pem.parent_id,
  pem.student_id,
  COUNT(DISTINCT CASE WHEN pem.metric_type = 'report_card_viewed' THEN pem.id END) AS report_card_views,
  COUNT(DISTINCT CASE WHEN pem.metric_type = 'announcement_read' THEN pem.id END) AS announcements_read,
  COUNT(DISTINCT CASE WHEN pem.metric_type = 'message_sent' THEN pem.id END) AS messages_sent,
  COUNT(DISTINCT CASE WHEN pem.metric_type = 'meeting_attended' THEN pem.id END) AS meetings_attended,
  COUNT(DISTINCT CASE WHEN pem.metric_type = 'assignment_checked' THEN pem.id END) AS assignment_checks,
  COUNT(DISTINCT CASE WHEN pem.metric_type = 'attendance_checked' THEN pem.id END) AS attendance_checks,
  COUNT(DISTINCT CASE WHEN pem.metric_type = 'ai_assistant_used' THEN pem.id END) AS ai_assistant_uses,
  COUNT(DISTINCT pem.id) AS total_interactions,
  MAX(pem.recorded_at) AS last_active_at,
  CASE
    WHEN MAX(pem.recorded_at) > now() - INTERVAL '7 days' THEN 'active'
    WHEN MAX(pem.recorded_at) > now() - INTERVAL '30 days' THEN 'moderate'
    ELSE 'inactive'
  END AS engagement_level
FROM parent_engagement_metrics pem
GROUP BY pem.school_id, pem.parent_id, pem.student_id;

CREATE UNIQUE INDEX idx_engagement_summary_pk ON parent_engagement_summary(school_id, parent_id, student_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- PARENT DASHBOARD VIEW
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE OR REPLACE VIEW parent_dashboard_view AS
SELECT
  p.id AS parent_id,
  p.school_id,
  p.user_id,
  u.full_name AS parent_name,
  u.email AS parent_email,
  u.phone AS parent_phone,
  u.avatar_url AS parent_avatar,
  -- Child count
  (SELECT COUNT(*) FROM parent_students ps WHERE ps.parent_id = p.id AND ps.is_active = TRUE) AS child_count,
  -- Unread notifications
  (SELECT COUNT(*) FROM parent_notifications pn WHERE pn.parent_id = p.user_id AND pn.is_read = FALSE) AS unread_notifications,
  -- Unread messages
  (SELECT COUNT(*) FROM parent_messages pm WHERE pm.recipient_id = p.user_id AND pm.read_at IS NULL AND pm.is_archived = FALSE) AS unread_messages,
  -- Active insights
  (SELECT COUNT(*) FROM parent_ai_insights pai WHERE pai.parent_id = p.user_id AND pai.is_read = FALSE AND pai.is_dismissed = FALSE) AS active_insights,
  -- Last active
  (SELECT MAX(pal.created_at) FROM parent_activity_logs pal WHERE pal.parent_id = p.user_id) AS last_active_at
FROM parent_profiles p
JOIN users u ON u.id = p.user_id;

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE parent_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_ai_insights ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_report_downloads ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE parent_engagement_metrics ENABLE ROW LEVEL SECURITY;

-- ─── Parent Messages RLS ──────────────────────────────────────────────────────

CREATE POLICY "Parents can view their own messages"
  ON parent_messages FOR SELECT
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());

CREATE POLICY "Parents can send messages"
  ON parent_messages FOR INSERT
  WITH CHECK (sender_id = auth.uid());

CREATE POLICY "Senders/recipients can update message status"
  ON parent_messages FOR UPDATE
  USING (sender_id = auth.uid() OR recipient_id = auth.uid());

-- ─── Parent Notifications RLS ────────────────────────────────────────────────

CREATE POLICY "Parents see own notifications"
  ON parent_notifications FOR SELECT
  USING (parent_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON parent_notifications FOR INSERT
  WITH CHECK (TRUE);  -- system-triggered

CREATE POLICY "Parents can update own notifications"
  ON parent_notifications FOR UPDATE
  USING (parent_id = auth.uid());

-- ─── Parent Activity Logs RLS ────────────────────────────────────────────────

CREATE POLICY "Parents view own activity"
  ON parent_activity_logs FOR SELECT
  USING (parent_id = auth.uid());

CREATE POLICY "System can log activity"
  ON parent_activity_logs FOR INSERT
  WITH CHECK (TRUE);

-- ─── AI Parent Insights RLS ──────────────────────────────────────────────────

CREATE POLICY "Parents view own insights"
  ON parent_ai_insights FOR SELECT
  USING (parent_id = auth.uid());

CREATE POLICY "System can create insights"
  ON parent_ai_insights FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "Parents can update own insights"
  ON parent_ai_insights FOR UPDATE
  USING (parent_id = auth.uid());

-- ─── Parent Report Downloads RLS ─────────────────────────────────────────────

CREATE POLICY "Parents view own downloads"
  ON parent_report_downloads FOR SELECT
  USING (parent_id = auth.uid());

CREATE POLICY "Parents can download reports"
  ON parent_report_downloads FOR INSERT
  WITH CHECK (parent_id = auth.uid());

-- ─── Parent Calendar Events RLS ──────────────────────────────────────────────

CREATE POLICY "Parents view relevant events"
  ON parent_calendar_events FOR SELECT
  USING (
    parent_id = auth.uid()
    OR (parent_id IS NULL AND school_id IN (
      SELECT pp.school_id FROM parent_profiles pp WHERE pp.user_id = auth.uid()
    ))
  );

CREATE POLICY "System can create calendar events"
  ON parent_calendar_events FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "System can update calendar events"
  ON parent_calendar_events FOR UPDATE
  USING (TRUE);

-- ─── Engagement Metrics RLS ──────────────────────────────────────────────────

CREATE POLICY "School admins can view engagement"
  ON parent_engagement_metrics FOR SELECT
  USING (
    school_id IN (
      SELECT s.id FROM schools s
      JOIN users u ON u.school_id = s.id
      WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin')
    )
  );

CREATE POLICY "System can record engagement"
  ON parent_engagement_metrics FOR INSERT
  WITH CHECK (TRUE);

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TRIGGER set_parent_messages_updated_at
  BEFORE UPDATE ON parent_messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_parent_calendar_events_updated_at
  BEFORE UPDATE ON parent_calendar_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Get parent dashboard data
CREATE OR REPLACE FUNCTION get_parent_dashboard(p_parent_user_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
  v_school_id UUID;
  v_parent_id UUID;
BEGIN
  SELECT id, school_id INTO v_parent_id, v_school_id
  FROM parent_profiles WHERE user_id = p_parent_user_id LIMIT 1;

  SELECT jsonb_build_object(
    'parent_id', v_parent_id,
    'school_id', v_school_id,
    'children', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'student_id', ps.student_id,
          'student_name', ps.student_name,
          'admission_number', ps.student_admission_number,
          'class_name', (SELECT c.name FROM classes c JOIN class_students cs ON cs.class_id = c.id WHERE cs.student_id = ps.student_id LIMIT 1),
          'relationship', ps.relationship,
          'is_primary', ps.is_primary_contact,
          'attendance_summary', jsonb_build_object(
            'present_days', (SELECT COUNT(*) FROM attendance a WHERE a.student_id = ps.student_id AND a.status = 'present' AND a.date >= date_trunc('month', CURRENT_DATE)),
            'absent_days', (SELECT COUNT(*) FROM attendance a WHERE a.student_id = ps.student_id AND a.status = 'absent' AND a.date >= date_trunc('month', CURRENT_DATE)),
            'late_days', (SELECT COUNT(*) FROM attendance a WHERE a.student_id = ps.student_id AND a.status = 'late' AND a.date >= date_trunc('month', CURRENT_DATE))
          ),
          'pending_assignments', (SELECT COUNT(*) FROM homework h JOIN class_students cs ON cs.class_id = h.class_id WHERE cs.student_id = ps.student_id AND h.status = 'published' AND h.due_date > now()),
          'latest_results', (
            SELECT COALESCE(jsonb_agg(
              jsonb_build_object('exam_title', e.title, 'score', er.score, 'total_marks', e.total_marks, 'grade', er.grade)
            ), '[]'::jsonb)
            FROM exam_results er
            JOIN exams e ON e.id = er.exam_id
            WHERE er.student_id = ps.student_id
            ORDER BY er.created_at DESC LIMIT 3
          )
        )
      ), '[]'::jsonb)
      FROM parent_students ps
      WHERE ps.parent_id = v_parent_id AND ps.is_active = TRUE
    ),
    'upcoming_events', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object('id', id, 'title', title, 'start_time', start_time, 'end_time', end_time, 'event_type', event_type)
      ), '[]'::jsonb)
      FROM parent_calendar_events
      WHERE school_id = v_school_id
      AND (parent_id = p_parent_user_id OR parent_id IS NULL)
      AND start_time > now()
      ORDER BY start_time LIMIT 5
    ),
    'recent_announcements', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object('id', a.id, 'title', a.title, 'type', a.announcement_type, 'priority', a.priority, 'created_at', a.created_at)
      ), '[]'::jsonb)
      FROM announcements a
      WHERE a.school_id = v_school_id
      AND (a.target_audience @> ARRAY['parents'] OR a.target_audience = ARRAY['all']::text[])
      ORDER BY a.created_at DESC LIMIT 5
    ),
    'unread_notifications', (SELECT COUNT(*) FROM parent_notifications WHERE parent_id = p_parent_user_id AND is_read = FALSE),
    'unread_messages', (SELECT COUNT(*) FROM parent_messages WHERE recipient_id = p_parent_user_id AND read_at IS NULL AND is_archived = FALSE),
    'active_insights', (SELECT COUNT(*) FROM parent_ai_insights WHERE parent_id = p_parent_user_id AND is_read = FALSE AND is_dismissed = FALSE)
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get child academic performance
CREATE OR REPLACE FUNCTION get_child_performance(p_student_id UUID, p_academic_session_id UUID DEFAULT NULL)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'student_id', p_student_id,
    'subjects', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'subject_id', cs.subject_id,
          'subject_name', s.name,
          'teacher_name', (SELECT full_name FROM users WHERE id = cs.teacher_id),
          'latest_score', (
            SELECT er.score FROM exam_results er
            JOIN exams e ON e.id = er.exam_id
            JOIN exam_questions eq ON eq.exam_id = e.id
            WHERE er.student_id = p_student_id AND e.subject_id = cs.subject_id
            ORDER BY er.created_at DESC LIMIT 1
          ),
          'average_score', (
            SELECT AVG(er.score) FROM exam_results er
            JOIN exams e ON e.id = er.exam_id
            WHERE er.student_id = p_student_id AND e.subject_id = cs.subject_id
          ),
          'grade', (
            SELECT er.grade FROM exam_results er
            JOIN exams e ON e.id = er.exam_id
            WHERE er.student_id = p_student_id AND e.subject_id = cs.subject_id
            ORDER BY er.created_at DESC LIMIT 1
          )
        )
      ), '[]'::jsonb)
      FROM class_subjects cs
      JOIN subjects s ON s.id = cs.subject_id
      WHERE cs.class_id IN (SELECT cs2.class_id FROM class_students cs2 WHERE cs2.student_id = p_student_id)
    ),
    'overall_average', (
      SELECT AVG(er.score) FROM exam_results er
      WHERE er.student_id = p_student_id
    ),
    'class_average', (
      SELECT AVG(er.score) FROM exam_results er
      WHERE er.student_id IN (
        SELECT cs.student_id FROM class_students cs
        WHERE cs.class_id IN (SELECT cs2.class_id FROM class_students cs2 WHERE cs2.student_id = p_student_id)
      )
    ),
    'attendance_rate', (
      SELECT CASE COUNT(*)
        WHEN 0 THEN NULL
        ELSE ROUND((COUNT(*) FILTER (WHERE a.status = 'present')::NUMERIC / COUNT(*)) * 100, 1)
      END
      FROM attendance a WHERE a.student_id = p_student_id
    ),
    'teacher_remarks', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object('teacher_name', u.full_name, 'subject', s.name, 'remark', er.teacher_comment, 'date', er.created_at)
      ), '[]'::jsonb)
      FROM exam_results er
      JOIN users u ON u.id = er.graded_by
      JOIN exams e ON e.id = er.exam_id
      JOIN subjects s ON s.id = e.subject_id
      WHERE er.student_id = p_student_id AND er.teacher_comment IS NOT NULL
      ORDER BY er.created_at DESC LIMIT 5
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get parent engagement analytics (for school admins)
CREATE OR REPLACE FUNCTION get_parent_engagement_analytics(p_school_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_parents', (SELECT COUNT(DISTINCT parent_id) FROM parent_engagement_metrics WHERE school_id = p_school_id),
    'active_parents', (SELECT COUNT(DISTINCT parent_id) FROM parent_engagement_metrics WHERE school_id = p_school_id AND recorded_at > now() - INTERVAL '7 days'),
    'moderate_parents', (
      SELECT COUNT(DISTINCT parent_id) FROM parent_engagement_metrics
      WHERE school_id = p_school_id
      AND recorded_at BETWEEN now() - INTERVAL '30 days' AND now() - INTERVAL '7 days'
    ),
    'inactive_parents', (
      SELECT COUNT(DISTINCT pp.user_id) FROM parent_profiles pp
      WHERE pp.school_id = p_school_id
      AND pp.user_id NOT IN (SELECT DISTINCT parent_id FROM parent_engagement_metrics WHERE school_id = p_school_id AND recorded_at > now() - INTERVAL '30 days')
    ),
    'report_card_not_viewed', (
      SELECT COUNT(DISTINCT ps.parent_id) FROM parent_students ps
      WHERE ps.school_id = p_school_id
      AND ps.parent_id NOT IN (
        SELECT DISTINCT parent_id FROM parent_engagement_metrics
        WHERE school_id = p_school_id AND metric_type = 'report_card_viewed'
        AND recorded_at > now() - INTERVAL '30 days'
      )
    ),
    'avg_message_response_hours', (
      SELECT AVG(EXTRACT(EPOCH FROM (pm2.created_at - pm1.created_at)) / 3600)
      FROM parent_messages pm1
      JOIN parent_messages pm2 ON pm2.parent_message_id = pm1.id
      WHERE pm1.school_id = p_school_id
      AND pm1.direction = 'incoming'
      AND pm2.direction = 'outgoing'
      AND pm1.created_at > now() - INTERVAL '30 days'
    ),
    'unread_announcement_count', (
      SELECT COUNT(*) FROM announcements a
      WHERE a.school_id = p_school_id
      AND a.created_at > now() - INTERVAL '7 days'
    ),
    'engagement_by_metric', (
      SELECT jsonb_object_agg(metric_type, cnt)
      FROM (
        SELECT metric_type, COUNT(*) AS cnt
        FROM parent_engagement_metrics
        WHERE school_id = p_school_id
        AND recorded_at > now() - INTERVAL '30 days'
        GROUP BY metric_type
      ) sub
    ),
    'students_needing_support', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
          'student_id', ps.student_id,
          'student_name', ps.student_name,
          'parent_name', (SELECT full_name FROM users WHERE id = ps.parent_id),
          'engagement_level', pes.engagement_level,
          'last_active', pes.last_active_at
        )
      ), '[]'::jsonb)
      FROM parent_students ps
      LEFT JOIN parent_engagement_summary pes ON pes.parent_id = ps.parent_id AND pes.student_id = ps.student_id
      WHERE ps.school_id = p_school_id
      AND (pes.engagement_level = 'inactive' OR pes.last_active_at < now() - INTERVAL '30 days' OR pes.last_active_at IS NULL)
      LIMIT 20
    ),
    'engagement_trends', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object('date', date_trunc('week', recorded_at)::date, 'interactions', cnt)
        ORDER BY date_trunc('week', recorded_at)::date
      ), '[]'::jsonb)
      FROM (
        SELECT date_trunc('week', recorded_at) AS week, COUNT(*) AS cnt
        FROM parent_engagement_metrics
        WHERE school_id = p_school_id AND recorded_at > now() - INTERVAL '12 weeks'
        GROUP BY date_trunc('week', recorded_at)
      ) sub
    )
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Generate AI parent insight
CREATE OR REPLACE FUNCTION generate_parent_insight(
  p_parent_id UUID,
  p_student_id UUID,
  p_insight_type parent_insight_type,
  p_data JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID AS $$
DECLARE
  v_insight_id UUID;
  v_title TEXT;
  v_description TEXT;
  v_severity TEXT := 'info';
  v_recommendations TEXT[] := '{}';
BEGIN
  -- Route to specific insight generator based on type
  CASE p_insight_type
    WHEN 'performance_trend' THEN
      v_title := 'Academic Performance Update';
      v_description := COALESCE(p_data->>'summary', 'Your child''s performance has been analyzed.');
      v_severity := COALESCE(p_data->>'severity', 'info');
      v_recommendations := ARRAY[
        'Review the latest report card together',
        'Discuss challenging subjects with the teacher',
        'Set up a regular study schedule'
      ];

    WHEN 'attendance_alert' THEN
      v_title := 'Attendance Notice';
      v_description := COALESCE(p_data->>'summary', 'Attendance pattern has been detected.');
      v_severity := COALESCE(p_data->>'severity', 'warning');
      v_recommendations := ARRAY[
        'Ensure your child attends school regularly',
        'Contact the school if there are health concerns',
        'Schedule appointments outside school hours when possible'
      ];

    WHEN 'study_recommendation' THEN
      v_title := 'Study Support Recommendation';
      v_description := COALESCE(p_data->>'summary', 'Based on recent performance, here are study suggestions.');
      v_severity := 'info';
      v_recommendations := ARRAY[
        'Create a quiet study space at home',
        'Set specific study times each day',
        'Use the ExamForge practice tools for revision'
      ];

    WHEN 'engagement_tip' THEN
      v_title := 'Stay Engaged Tip';
      v_description := COALESCE(p_data->>'summary', 'Tips for supporting your child''s education.');
      v_severity := 'info';
      v_recommendations := ARRAY[
        'Ask about what they learned today',
        'Review homework together',
        'Attend parent-teacher meetings'
      ];

    WHEN 'milestone' THEN
      v_title := 'Achievement Milestone';
      v_description := COALESCE(p_data->>'summary', 'Your child has reached an academic milestone!');
      v_severity := 'positive';
      v_recommendations := ARRAY['Celebrate this achievement together!'];

    WHEN 'concern' THEN
      v_title := 'Academic Concern';
      v_description := COALESCE(p_data->>'summary', 'There may be an area requiring attention.');
      v_severity := 'concern';
      v_recommendations := ARRAY[
        'Schedule a meeting with the teacher',
        'Review recent assignments together',
        'Consider additional tutoring support'
      ];
  END CASE;

  INSERT INTO parent_ai_insights (school_id, parent_id, student_id, insight_type, title, description, severity, recommendations, data_snapshot)
  VALUES (
    (SELECT school_id FROM parent_profiles WHERE user_id = p_parent_id LIMIT 1),
    p_parent_id,
    p_student_id,
    p_insight_type,
    v_title,
    v_description,
    v_severity,
    v_recommendations,
    p_data
  ) RETURNING id INTO v_insight_id;

  RETURN v_insight_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Record parent engagement metric
CREATE OR REPLACE FUNCTION record_parent_engagement(
  p_parent_id UUID,
  p_student_id UUID,
  p_metric_type engagement_metric_type,
  p_details JSONB DEFAULT '{}'::jsonb
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO parent_engagement_metrics (school_id, parent_id, student_id, metric_type, details)
  VALUES (
    (SELECT school_id FROM parent_profiles WHERE user_id = p_parent_id LIMIT 1),
    p_parent_id,
    p_student_id,
    p_metric_type,
    p_details
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Refresh engagement summary
CREATE OR REPLACE FUNCTION refresh_parent_engagement_summary()
RETURNS VOID AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY parent_engagement_summary;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCHEDULED JOBS
-- ═══════════════════════════════════════════════════════════════════════════════

SELECT cron.schedule(
  'refresh-parent-engagement',
  '*/30 * * * *',
  $$ SELECT refresh_parent_engagement_summary(); $$
) WHERE EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron');
