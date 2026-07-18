-- ═══════════════════════════════════════════════════════════════════════════════
-- EXAMFORGE AI — UNIFIED COMMUNICATION & COLLABORATION SYSTEM SCHEMA
-- ═══════════════════════════════════════════════════════════════════════════════
-- Real-time messaging, announcements, notifications, discussion forums,
-- calendar events, AI communication assistant, AI school knowledge assistant,
-- file sharing, moderation, and audit logging.
-- Depends on: schema.sql, school_management_schema.sql, parent_portal_schema.sql
-- ═══════════════════════════════════════════════════════════════════════════════

BEGIN;

-- ─── Custom Enums ──────────────────────────────────────────────────────────────

CREATE TYPE conversation_type AS ENUM (
  'direct',
  'group',
  'department',
  'class',
  'school_wide'
);

CREATE TYPE message_type AS ENUM (
  'text',
  'image',
  'pdf',
  'document',
  'voice_note',
  'audio',
  'video',
  'system'
);

CREATE TYPE announcement_type AS ENUM (
  'school_wide',
  'class',
  'subject',
  'emergency',
  'event',
  'holiday',
  'timetable_update',
  'examination',
  'general'
);

CREATE TYPE announcement_priority AS ENUM (
  'low',
  'normal',
  'high',
  'urgent'
);

CREATE TYPE notification_channel AS ENUM (
  'in_app',
  'push',
  'email',
  'sms'
);

CREATE TYPE forum_type AS ENUM (
  'school_community',
  'subject',
  'class',
  'club',
  'department'
);

CREATE TYPE calendar_event_type AS ENUM (
  'meeting',
  'parent_teacher',
  'academic',
  'exam',
  'holiday',
  'event',
  'deadline',
  'custom'
);

CREATE TYPE meeting_status AS ENUM (
  'scheduled',
  'confirmed',
  'in_progress',
  'completed',
  'cancelled',
  'rescheduled'
);

CREATE TYPE attachment_type AS ENUM (
  'pdf',
  'docx',
  'pptx',
  'xlsx',
  'image',
  'video',
  'audio',
  'other'
);

CREATE TYPE knowledge_document_status AS ENUM (
  'pending',
  'processing',
  'indexed',
  'failed'
);

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONVERSATIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS conversations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Conversation metadata
  type            conversation_type NOT NULL DEFAULT 'direct',
  name            TEXT,                    -- required for group/department/class/school_wide
  description     TEXT,
  avatar_url      TEXT,

  -- Context references
  department_id   UUID REFERENCES departments(id) ON DELETE SET NULL,
  class_id        UUID REFERENCES classes(id) ON DELETE SET NULL,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,

  -- Settings
  is_muted        BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
  is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,
  max_participants INTEGER DEFAULT 500,

  -- Creator
  created_by      UUID NOT NULL REFERENCES auth.users(id),

  -- Last message snapshot
  last_message_id     UUID,
  last_message_text   TEXT,
  last_message_at     TIMESTAMPTZ,
  last_sender_id      UUID,
  last_sender_name    TEXT,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_conversations_school ON conversations(school_id);
CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_conversations_class ON conversations(class_id);
CREATE INDEX idx_conversations_department ON conversations(department_id);
CREATE INDEX idx_conversations_last_message ON conversations(last_message_at DESC);
CREATE INDEX idx_conversations_created ON conversations(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- CONVERSATION PARTICIPANTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS conversation_participants (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Participant role in conversation
  role            TEXT NOT NULL DEFAULT 'member',  -- admin, moderator, member
  user_role       user_role NOT NULL,              -- system role for permission checks

  -- State
  is_muted        BOOLEAN NOT NULL DEFAULT FALSE,
  is_archived     BOOLEAN NOT NULL DEFAULT FALSE,
  is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,
  is_blocked      BOOLEAN NOT NULL DEFAULT FALSE,

  -- Read tracking
  last_read_message_id UUID,
  last_read_at    TIMESTAMPTZ,
  unread_count    INTEGER NOT NULL DEFAULT 0,

  -- Typing indicator
  is_typing       BOOLEAN NOT NULL DEFAULT FALSE,
  typing_at       TIMESTAMPTZ,

  -- Online / last seen
  is_online       BOOLEAN NOT NULL DEFAULT FALSE,
  last_seen_at    TIMESTAMPTZ,

  joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  left_at         TIMESTAMPTZ,
  removed_at      TIMESTAMPTZ,

  UNIQUE(conversation_id, user_id)
);

CREATE INDEX idx_conv_participants_conversation ON conversation_participants(conversation_id);
CREATE INDEX idx_conv_participants_user ON conversation_participants(user_id);
CREATE INDEX idx_conv_participants_school ON conversation_participants(school_id);
CREATE INDEX idx_conv_participants_unread ON conversation_participants(user_id, unread_count) WHERE unread_count > 0;
CREATE INDEX idx_conv_participants_online ON conversation_participants(is_online) WHERE is_online = TRUE;

-- ═══════════════════════════════════════════════════════════════════════════════
-- MESSAGES TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS messages (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,

  -- Sender
  sender_id       UUID NOT NULL REFERENCES auth.users(id),
  sender_role     user_role NOT NULL,
  sender_name     TEXT NOT NULL,
  sender_avatar   TEXT,

  -- Content
  type            message_type NOT NULL DEFAULT 'text',
  body            TEXT NOT NULL DEFAULT '',

  -- Reply / Forward / Pin
  reply_to_id     UUID REFERENCES messages(id) ON DELETE SET NULL,
  forwarded_from_id UUID REFERENCES messages(id) ON DELETE SET NULL,
  is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,
  pinned_at       TIMESTAMPTZ,
  pinned_by       UUID REFERENCES auth.users(id),

  -- Edit / Delete
  is_edited       BOOLEAN NOT NULL DEFAULT FALSE,
  edited_at       TIMESTAMPTZ,
  is_deleted      BOOLEAN NOT NULL DEFAULT FALSE,
  deleted_at      TIMESTAMPTZ,
  deleted_by      UUID REFERENCES auth.users(id),

  -- Read receipts
  read_by         UUID[] DEFAULT '{}',
  delivered_to    UUID[] DEFAULT '{}',

  -- Metadata
  metadata        JSONB DEFAULT '{}'::jsonb,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_school ON messages(school_id);
CREATE INDEX idx_messages_sender ON messages(sender_id);
CREATE INDEX idx_messages_reply ON messages(reply_to_id);
CREATE INDEX idx_messages_pinned ON messages(conversation_id, is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX idx_messages_created ON messages(created_at DESC);
CREATE INDEX idx_messages_type ON messages(type);

-- ═══════════════════════════════════════════════════════════════════════════════
-- MESSAGE REACTIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS message_reactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id      UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  emoji           TEXT NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(message_id, user_id, emoji)
);

CREATE INDEX idx_reactions_message ON message_reactions(message_id);
CREATE INDEX idx_reactions_user ON message_reactions(user_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- MESSAGE ATTACHMENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS message_attachments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id      UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  file_name       TEXT NOT NULL,
  file_url        TEXT NOT NULL,
  file_type       attachment_type NOT NULL DEFAULT 'other',
  file_size_bytes BIGINT,
  mime_type       TEXT,
  thumbnail_url   TEXT,

  -- Preview
  preview_text    TEXT,
  is_previewable  BOOLEAN NOT NULL DEFAULT FALSE,

  uploaded_by     UUID NOT NULL REFERENCES auth.users(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_attachments_message ON message_attachments(message_id);
CREATE INDEX idx_attachments_school ON message_attachments(school_id);
CREATE INDEX idx_attachments_type ON message_attachments(file_type);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ANNOUNCEMENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS communication_announcements (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Content
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  announcement_type announcement_type NOT NULL DEFAULT 'general',
  priority        announcement_priority NOT NULL DEFAULT 'normal',

  -- Targeting
  target_audience TEXT[] NOT NULL DEFAULT ARRAY['all']::text[],  -- all, teachers, students, parents, specific_roles
  target_class_ids UUID[] DEFAULT '{}',
  target_department_ids UUID[] DEFAULT '{}',
  target_subject_ids UUID[] DEFAULT '{}',

  -- Author
  author_id       UUID NOT NULL REFERENCES auth.users(id),
  author_name     TEXT NOT NULL,
  author_role     user_role NOT NULL,

  -- Scheduling & Expiry
  is_scheduled    BOOLEAN NOT NULL DEFAULT FALSE,
  scheduled_at    TIMESTAMPTZ,
  expires_at      TIMESTAMPTZ,
  is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,

  -- Attachments
  attachments     JSONB DEFAULT '[]'::jsonb,  -- [{name, url, type, size}]

  -- Status
  is_published    BOOLEAN NOT NULL DEFAULT FALSE,
  published_at    TIMESTAMPTZ,

  -- Tracking
  view_count      INTEGER NOT NULL DEFAULT 0,
  acknowledged_by UUID[] DEFAULT '{}',

  -- AI assistant generated
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  ai_reviewed     BOOLEAN NOT NULL DEFAULT FALSE,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_announcements_school ON communication_announcements(school_id);
CREATE INDEX idx_announcements_type ON communication_announcements(announcement_type);
CREATE INDEX idx_announcements_priority ON communication_announcements(priority);
CREATE INDEX idx_announcements_author ON communication_announcements(author_id);
CREATE INDEX idx_announcements_published ON communication_announcements(is_published, published_at DESC);
CREATE INDEX idx_announcements_scheduled ON communication_announcements(is_scheduled, scheduled_at) WHERE is_scheduled = TRUE AND is_published = FALSE;
CREATE INDEX idx_announcements_created ON communication_announcements(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMUNICATION NOTIFICATIONS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS communication_notifications (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id),

  -- Content
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,
  category        TEXT NOT NULL DEFAULT 'general',  -- message, assignment, exam, result, attendance, announcement, system, payment
  priority        TEXT NOT NULL DEFAULT 'normal',    -- low, normal, high, urgent

  -- Source reference
  source_type     TEXT,  -- conversation, announcement, exam, assignment, etc.
  source_id       UUID,

  -- Data payload
  data            JSONB DEFAULT '{}'::jsonb,

  -- Read status
  is_read         BOOLEAN NOT NULL DEFAULT FALSE,
  read_at         TIMESTAMPTZ,

  -- Delivery tracking
  delivered_in_app    BOOLEAN NOT NULL DEFAULT FALSE,
  delivered_push      BOOLEAN NOT NULL DEFAULT FALSE,
  delivered_email     BOOLEAN NOT NULL DEFAULT FALSE,
  delivered_sms       BOOLEAN NOT NULL DEFAULT FALSE,

  -- Action
  action_url      TEXT,
  action_label    TEXT,

  expires_at      TIMESTAMPTZ,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_comm_notifications_user ON communication_notifications(user_id);
CREATE INDEX idx_comm_notifications_user_unread ON communication_notifications(user_id, is_read) WHERE is_read = FALSE;
CREATE INDEX idx_comm_notifications_school ON communication_notifications(school_id);
CREATE INDEX idx_comm_notifications_category ON communication_notifications(category);
CREATE INDEX idx_comm_notifications_created ON communication_notifications(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- USER NOTIFICATION PREFERENCES TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS user_notification_preferences (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Channel preferences per category
  preferences     JSONB NOT NULL DEFAULT '{
    "message": {"in_app": true, "push": true, "email": true, "sms": false},
    "assignment": {"in_app": true, "push": true, "email": true, "sms": false},
    "exam": {"in_app": true, "push": true, "email": true, "sms": true},
    "result": {"in_app": true, "push": true, "email": true, "sms": true},
    "attendance": {"in_app": true, "push": true, "email": false, "sms": true},
    "announcement": {"in_app": true, "push": true, "email": true, "sms": false},
    "system": {"in_app": true, "push": false, "email": false, "sms": false},
    "payment": {"in_app": true, "push": true, "email": true, "sms": true}
  }'::jsonb,

  -- Quiet hours
  quiet_hours_enabled BOOLEAN NOT NULL DEFAULT FALSE,
  quiet_hours_start   TIME DEFAULT '22:00',
  quiet_hours_end     TIME DEFAULT '07:00',

  -- Digest
  digest_enabled    BOOLEAN NOT NULL DEFAULT FALSE,
  digest_frequency  TEXT DEFAULT 'daily',  -- daily, weekly

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  UNIQUE(user_id, school_id)
);

CREATE INDEX idx_notification_prefs_user ON user_notification_preferences(user_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- DISCUSSION FORUMS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS discussion_forums (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  name            TEXT NOT NULL,
  description     TEXT,
  forum_type      forum_type NOT NULL DEFAULT 'school_community',
  avatar_url      TEXT,

  -- Context references
  department_id   UUID REFERENCES departments(id) ON DELETE SET NULL,
  class_id        UUID REFERENCES classes(id) ON DELETE SET NULL,
  subject_id      UUID REFERENCES subjects(id) ON DELETE SET NULL,

  -- Moderation
  is_moderated    BOOLEAN NOT NULL DEFAULT TRUE,
  is_locked       BOOLEAN NOT NULL DEFAULT FALSE,
  is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,

  -- Moderators
  moderator_ids   UUID[] DEFAULT '{}',

  -- Creator
  created_by      UUID NOT NULL REFERENCES auth.users(id),

  -- Stats
  post_count      INTEGER NOT NULL DEFAULT 0,
  member_count    INTEGER NOT NULL DEFAULT 0,
  last_activity_at TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_forums_school ON discussion_forums(school_id);
CREATE INDEX idx_forums_type ON discussion_forums(forum_type);
CREATE INDEX idx_forums_class ON discussion_forums(class_id);
CREATE INDEX idx_forums_subject ON discussion_forums(subject_id);
CREATE INDEX idx_forums_activity ON discussion_forums(last_activity_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- FORUM POSTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS forum_posts (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  forum_id        UUID NOT NULL REFERENCES discussion_forums(id) ON DELETE CASCADE,
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Author
  author_id       UUID NOT NULL REFERENCES auth.users(id),
  author_name     TEXT NOT NULL,
  author_avatar   TEXT,
  author_role     user_role NOT NULL,

  -- Content
  title           TEXT NOT NULL,
  body            TEXT NOT NULL,

  -- Attachments
  attachments     JSONB DEFAULT '[]'::jsonb,

  -- Status
  is_pinned       BOOLEAN NOT NULL DEFAULT FALSE,
  is_locked       BOOLEAN NOT NULL DEFAULT FALSE,
  is_hidden       BOOLEAN NOT NULL DEFAULT FALSE,
  hidden_reason   TEXT,

  -- Stats
  comment_count   INTEGER NOT NULL DEFAULT 0,
  view_count      INTEGER NOT NULL DEFAULT 0,
  like_count      INTEGER NOT NULL DEFAULT 0,

  -- Moderation
  reported_count  INTEGER NOT NULL DEFAULT 0,
  is_reported     BOOLEAN NOT NULL DEFAULT FALSE,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_forum_posts_forum ON forum_posts(forum_id, created_at DESC);
CREATE INDEX idx_forum_posts_author ON forum_posts(author_id);
CREATE INDEX idx_forum_posts_pinned ON forum_posts(forum_id, is_pinned) WHERE is_pinned = TRUE;
CREATE INDEX idx_forum_posts_created ON forum_posts(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- FORUM COMMENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS forum_comments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id         UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  forum_id        UUID NOT NULL REFERENCES discussion_forums(id) ON DELETE CASCADE,
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Author
  author_id       UUID NOT NULL REFERENCES auth.users(id),
  author_name     TEXT NOT NULL,
  author_avatar   TEXT,
  author_role     user_role NOT NULL,

  -- Content
  body            TEXT NOT NULL,

  -- Threading
  parent_comment_id UUID REFERENCES forum_comments(id) ON DELETE SET NULL,
  reply_to_user_id  UUID REFERENCES auth.users(id),

  -- Attachments
  attachments     JSONB DEFAULT '[]'::jsonb,

  -- Status
  is_hidden       BOOLEAN NOT NULL DEFAULT FALSE,
  hidden_reason   TEXT,

  -- Stats
  like_count      INTEGER NOT NULL DEFAULT 0,

  -- Moderation
  reported_count  INTEGER NOT NULL DEFAULT 0,
  is_reported     BOOLEAN NOT NULL DEFAULT FALSE,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_forum_comments_post ON forum_comments(post_id, created_at);
CREATE INDEX idx_forum_comments_author ON forum_comments(author_id);
CREATE INDEX idx_forum_comments_parent ON forum_comments(parent_comment_id);
CREATE INDEX idx_forum_comments_created ON forum_comments(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- CALENDAR EVENTS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS communication_calendar_events (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Content
  title           TEXT NOT NULL,
  description     TEXT,
  event_type      calendar_event_type NOT NULL DEFAULT 'custom',

  -- Timing
  start_time      TIMESTAMPTZ NOT NULL,
  end_time        TIMESTAMPTZ NOT NULL,
  is_all_day      BOOLEAN NOT NULL DEFAULT FALSE,

  -- Location
  location        TEXT,
  meeting_link    TEXT,

  -- Recurrence
  is_recurring    BOOLEAN NOT NULL DEFAULT FALSE,
  recurrence_rule TEXT,

  -- Organizer
  organizer_id    UUID NOT NULL REFERENCES auth.users(id),
  organizer_name  TEXT NOT NULL,

  -- Targeting
  target_audience TEXT[] NOT NULL DEFAULT ARRAY['all']::text[],
  target_class_ids UUID[] DEFAULT '{}',
  target_department_ids UUID[] DEFAULT '{}',

  -- Attendees
  attendee_ids    UUID[] DEFAULT '{}',
  rsvp_required   BOOLEAN NOT NULL DEFAULT FALSE,

  -- Parent-Teacher meetings
  meeting_status  meeting_status DEFAULT 'scheduled',
  max_attendees   INTEGER,
  current_attendees INTEGER DEFAULT 0,

  -- Source reference
  source_type     TEXT,  -- 'announcement', 'exam', 'homework', 'custom'
  source_id       UUID,

  -- Reminders
  reminder_minutes INTEGER[] DEFAULT '{15, 60}',

  -- Calendar sync
  external_calendar_id TEXT,
  ical_uid        TEXT,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_calendar_events_school ON communication_calendar_events(school_id);
CREATE INDEX idx_calendar_events_type ON communication_calendar_events(event_type);
CREATE INDEX idx_calendar_events_time ON communication_calendar_events(start_time, end_time);
CREATE INDEX idx_calendar_events_organizer ON communication_calendar_events(organizer_id);
CREATE INDEX idx_calendar_events_attendee ON communication_calendar_events(attendee_ids);
CREATE INDEX idx_calendar_events_created ON communication_calendar_events(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMUNICATION AUDIT LOGS TABLE
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS communication_audit_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Who
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  user_role       user_role NOT NULL,
  user_name       TEXT NOT NULL,

  -- What
  action          TEXT NOT NULL,  -- sent_message, edited_message, deleted_message, created_announcement, etc.
  resource_type   TEXT NOT NULL,  -- conversation, message, announcement, forum_post, etc.
  resource_id     UUID,

  -- Details
  details         JSONB DEFAULT '{}'::jsonb,
  severity        TEXT NOT NULL DEFAULT 'info',  -- info, warning, critical

  -- Context
  ip_address      INET,
  user_agent      TEXT,
  device_type     TEXT,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_logs_school ON communication_audit_logs(school_id);
CREATE INDEX idx_audit_logs_user ON communication_audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON communication_audit_logs(action);
CREATE INDEX idx_audit_logs_resource ON communication_audit_logs(resource_type, resource_id);
CREATE INDEX idx_audit_logs_created ON communication_audit_logs(created_at DESC);
CREATE INDEX idx_audit_logs_severity ON communication_audit_logs(severity);

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCHOOL KNOWLEDGE DOCUMENTS TABLE (AI School Knowledge Assistant)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS school_knowledge_documents (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  -- Document info
  title           TEXT NOT NULL,
  description     TEXT,
  document_type   TEXT NOT NULL DEFAULT 'policy',  -- policy, handbook, calendar, timetable, faq, announcement, other
  file_name       TEXT NOT NULL,
  file_url        TEXT NOT NULL,
  file_size_bytes BIGINT,
  mime_type       TEXT,

  -- Processing
  status          knowledge_document_status NOT NULL DEFAULT 'pending',
  processing_error TEXT,
  chunk_count     INTEGER DEFAULT 0,

  -- Content (extracted text for search)
  extracted_text  TEXT,

  -- Metadata
  tags            TEXT[] DEFAULT '{}',
  is_active       BOOLEAN NOT NULL DEFAULT TRUE,
  version         INTEGER DEFAULT 1,

  -- Uploader
  uploaded_by     UUID NOT NULL REFERENCES auth.users(id),

  -- Search vector
  search_vector   tsvector,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_knowledge_docs_school ON school_knowledge_documents(school_id);
CREATE INDEX idx_knowledge_docs_type ON school_knowledge_documents(document_type);
CREATE INDEX idx_knowledge_docs_status ON school_knowledge_documents(status);
CREATE INDEX idx_knowledge_docs_active ON school_knowledge_documents(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_knowledge_docs_search ON school_knowledge_documents USING GIN(search_vector);
CREATE INDEX idx_knowledge_docs_created ON school_knowledge_documents(created_at DESC);

-- ═══════════════════════════════════════════════════════════════════════════════
-- SCHOOL KNOWLEDGE EMBEDDINGS TABLE (for retrieval-based AI assistant)
-- ═══════════════════════════════════════════════════════════════════════════════

CREATE TABLE IF NOT EXISTS school_knowledge_embeddings (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id     UUID NOT NULL REFERENCES school_knowledge_documents(id) ON DELETE CASCADE,
  school_id       UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,

  chunk_text      TEXT NOT NULL,
  chunk_index     INTEGER NOT NULL,
  embedding       VECTOR(1536),  -- OpenAI ada-002 dimension; adjust for your model

  metadata        JSONB DEFAULT '{}'::jsonb,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_knowledge_embeddings_document ON school_knowledge_embeddings(document_id);
CREATE INDEX idx_knowledge_embeddings_school ON school_knowledge_embeddings(school_id);

-- ═══════════════════════════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE discussion_forums ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE forum_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_calendar_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE communication_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_knowledge_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE school_knowledge_embeddings ENABLE ROW LEVEL SECURITY;

-- ─── Conversations RLS ────────────────────────────────────────────────────

CREATE POLICY "Users see conversations they belong to"
  ON conversations FOR SELECT
  USING (
    id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY "Users can create conversations"
  ON conversations FOR INSERT
  WITH CHECK (created_by = auth.uid());

CREATE POLICY "Participants and admins can update conversations"
  ON conversations FOR UPDATE
  USING (
    id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid() AND role IN ('admin', 'moderator'))
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Conversation Participants RLS ────────────────────────────────────────

CREATE POLICY "Users see participants of their conversations"
  ON conversation_participants FOR SELECT
  USING (
    conversation_id IN (SELECT cp.conversation_id FROM conversation_participants cp WHERE cp.user_id = auth.uid())
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY "System can manage participants"
  ON conversation_participants FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "Participants and admins can update participant state"
  ON conversation_participants FOR UPDATE
  USING (
    user_id = auth.uid()
    OR conversation_id IN (SELECT cp.conversation_id FROM conversation_participants cp WHERE cp.user_id = auth.uid() AND cp.role IN ('admin', 'moderator'))
  );

-- ─── Messages RLS ────────────────────────────────────────────────────────

CREATE POLICY "Users see messages in their conversations"
  ON messages FOR SELECT
  USING (
    conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY "Participants can send messages"
  ON messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid()
    AND conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid())
  );

CREATE POLICY "Senders can edit own messages"
  ON messages FOR UPDATE
  USING (
    sender_id = auth.uid()
    OR conversation_id IN (SELECT cp.conversation_id FROM conversation_participants cp WHERE cp.user_id = auth.uid() AND cp.role IN ('admin', 'moderator'))
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Message Reactions RLS ────────────────────────────────────────────────

CREATE POLICY "Users see reactions on accessible messages"
  ON message_reactions FOR SELECT
  USING (
    message_id IN (SELECT m.id FROM messages m WHERE m.conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid()))
  );

CREATE POLICY "Users can add reactions"
  ON message_reactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can remove own reactions"
  ON message_reactions FOR DELETE
  USING (user_id = auth.uid());

-- ─── Message Attachments RLS ────────────────────────────────────────────────

CREATE POLICY "Users see attachments on accessible messages"
  ON message_attachments FOR SELECT
  USING (
    message_id IN (SELECT m.id FROM messages m WHERE m.conversation_id IN (SELECT conversation_id FROM conversation_participants WHERE user_id = auth.uid()))
  );

-- ─── Announcements RLS ────────────────────────────────────────────────────

CREATE POLICY "Users see announcements for their audience"
  ON communication_announcements FOR SELECT
  USING (
    school_id IN (SELECT u.school_id FROM users u WHERE u.id = auth.uid())
    AND is_published = TRUE
    OR author_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY "Authorized users can create announcements"
  ON communication_announcements FOR INSERT
  WITH CHECK (
    author_id = auth.uid()
    AND author_role IN ('school_admin', 'super_admin', 'teacher')
  );

CREATE POLICY "Authors and admins can update announcements"
  ON communication_announcements FOR UPDATE
  USING (
    author_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Notifications RLS ────────────────────────────────────────────────────

CREATE POLICY "Users see own notifications"
  ON communication_notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON communication_notifications FOR INSERT
  WITH CHECK (TRUE);

CREATE POLICY "Users can update own notifications"
  ON communication_notifications FOR UPDATE
  USING (user_id = auth.uid());

-- ─── Notification Preferences RLS ────────────────────────────────────────

CREATE POLICY "Users manage own preferences"
  ON user_notification_preferences FOR ALL
  USING (user_id = auth.uid());

-- ─── Discussion Forums RLS ────────────────────────────────────────────────

CREATE POLICY "School members can view forums"
  ON discussion_forums FOR SELECT
  USING (
    school_id IN (SELECT u.school_id FROM users u WHERE u.id = auth.uid())
  );

CREATE POLICY "Teachers and admins can create forums"
  ON discussion_forums FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
  );

CREATE POLICY "Moderators and admins can update forums"
  ON discussion_forums FOR UPDATE
  USING (
    created_by = auth.uid()
    OR moderator_ids @> ARRAY[auth.uid()]
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Forum Posts RLS ────────────────────────────────────────────────────

CREATE POLICY "School members can view posts"
  ON forum_posts FOR SELECT
  USING (
    school_id IN (SELECT u.school_id FROM users u WHERE u.id = auth.uid())
    AND is_hidden = FALSE
    OR author_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY "School members can create posts"
  ON forum_posts FOR INSERT
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Authors and moderators can update posts"
  ON forum_posts FOR UPDATE
  USING (
    author_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Forum Comments RLS ────────────────────────────────────────────────────

CREATE POLICY "School members can view comments"
  ON forum_comments FOR SELECT
  USING (
    school_id IN (SELECT u.school_id FROM users u WHERE u.id = auth.uid())
    AND is_hidden = FALSE
    OR author_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY "School members can create comments"
  ON forum_comments FOR INSERT
  WITH CHECK (author_id = auth.uid());

CREATE POLICY "Authors and moderators can update comments"
  ON forum_comments FOR UPDATE
  USING (
    author_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Calendar Events RLS ────────────────────────────────────────────────

CREATE POLICY "Users see events for their audience"
  ON communication_calendar_events FOR SELECT
  USING (
    organizer_id = auth.uid()
    OR attendee_ids @> ARRAY[auth.uid()]
    OR school_id IN (SELECT u.school_id FROM users u WHERE u.id = auth.uid())
  );

CREATE POLICY "Users can create events"
  ON communication_calendar_events FOR INSERT
  WITH CHECK (organizer_id = auth.uid());

CREATE POLICY "Organizers and admins can update events"
  ON communication_calendar_events FOR UPDATE
  USING (
    organizer_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Audit Logs RLS ────────────────────────────────────────────────────

CREATE POLICY "Admins can view audit logs"
  ON communication_audit_logs FOR SELECT
  USING (
    user_id = auth.uid()
    OR school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY "System can create audit logs"
  ON communication_audit_logs FOR INSERT
  WITH CHECK (TRUE);

-- ─── Knowledge Documents RLS ────────────────────────────────────────────

CREATE POLICY "School members can view knowledge docs"
  ON school_knowledge_documents FOR SELECT
  USING (
    school_id IN (SELECT u.school_id FROM users u WHERE u.id = auth.uid())
  );

CREATE POLICY "Admins can manage knowledge docs"
  ON school_knowledge_documents FOR INSERT
  WITH CHECK (
    uploaded_by = auth.uid()
    AND school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin', 'teacher'))
  );

CREATE POLICY "Admins can update knowledge docs"
  ON school_knowledge_documents FOR UPDATE
  USING (
    school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ─── Knowledge Embeddings RLS ────────────────────────────────────────────

CREATE POLICY "System can manage embeddings"
  ON school_knowledge_embeddings FOR ALL
  USING (
    school_id IN (SELECT s.id FROM schools s JOIN users u ON u.school_id = s.id WHERE u.id = auth.uid() AND u.role IN ('school_admin', 'super_admin'))
  );

-- ═══════════════════════════════════════════════════════════════════════════════
-- TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Updated at triggers
CREATE TRIGGER set_conversations_updated_at
  BEFORE UPDATE ON conversations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_messages_updated_at
  BEFORE UPDATE ON messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_announcements_updated_at
  BEFORE UPDATE ON communication_announcements
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_notification_prefs_updated_at
  BEFORE UPDATE ON user_notification_preferences
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_forums_updated_at
  BEFORE UPDATE ON discussion_forums
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_forum_posts_updated_at
  BEFORE UPDATE ON forum_posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_forum_comments_updated_at
  BEFORE UPDATE ON forum_comments
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_calendar_events_updated_at
  BEFORE UPDATE ON communication_calendar_events
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER set_knowledge_docs_updated_at
  BEFORE UPDATE ON school_knowledge_documents
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ─── Update conversation last message on new message ─────────────────────

CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET last_message_id = NEW.id,
      last_message_text = LEFT(NEW.body, 100),
      last_message_at = NEW.created_at,
      last_sender_id = NEW.sender_id,
      last_sender_name = NEW.sender_name,
      updated_at = now()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_conversation_last_message
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION update_conversation_last_message();

-- ─── Increment unread count for participants on new message ─────────────

CREATE OR REPLACE FUNCTION increment_unread_counts()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversation_participants
  SET unread_count = unread_count + 1
  WHERE conversation_id = NEW.conversation_id
  AND user_id != NEW.sender_id
  AND left_at IS NULL;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_increment_unread_counts
  AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION increment_unread_counts();

-- ─── Update forum stats on new post ─────────────────────────────────────

CREATE OR REPLACE FUNCTION update_forum_post_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE discussion_forums
    SET post_count = post_count + 1,
        last_activity_at = now()
    WHERE id = NEW.forum_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE discussion_forums
    SET post_count = GREATEST(post_count - 1, 0)
    WHERE id = OLD.forum_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_forum_post_stats
  AFTER INSERT OR DELETE ON forum_posts
  FOR EACH ROW EXECUTE FUNCTION update_forum_post_stats();

-- ─── Update forum stats on new comment ─────────────────────────────────────

CREATE OR REPLACE FUNCTION update_post_comment_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE forum_posts
    SET comment_count = comment_count + 1
    WHERE id = NEW.post_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE forum_posts
    SET comment_count = GREATEST(comment_count - 1, 0)
    WHERE id = OLD.post_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_comment_stats
  AFTER INSERT OR DELETE ON forum_comments
  FOR EACH ROW EXECUTE FUNCTION update_post_comment_stats();

-- ─── Update announcement view count ────────────────────────────────────

CREATE OR REPLACE FUNCTION increment_announcement_view()
RETURNS TRIGGER AS $$
BEGIN
  NEW.view_count = OLD.view_count + 1;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ─── Update knowledge doc search vector on insert/update ─────────────────

CREATE OR REPLACE FUNCTION update_knowledge_doc_search()
RETURNS TRIGGER AS $$
BEGIN
  NEW.search_vector :=
    setweight(to_tsvector('english', COALESCE(NEW.title, '')), 'A') ||
    setweight(to_tsvector('english', COALESCE(NEW.description, '')), 'B') ||
    setweight(to_tsvector('english', COALESCE(NEW.extracted_text, '')), 'C') ||
    setweight(to_tsvector('english', COALESCE(array_to_string(NEW.tags, ' '), '')), 'D');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_knowledge_doc_search
  BEFORE INSERT OR UPDATE ON school_knowledge_documents
  FOR EACH ROW EXECUTE FUNCTION update_knowledge_doc_search();

-- ═══════════════════════════════════════════════════════════════════════════════
-- SUPABASE REALTIME SUBSCRIPTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

ALTER PUBLICATION supabase_realtime ADD TABLE conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE conversation_participants;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE communication_notifications;
ALTER PUBLICATION supabase_realtime ADD TABLE communication_announcements;
ALTER PUBLICATION supabase_realtime ADD TABLE communication_calendar_events;

-- ═══════════════════════════════════════════════════════════════════════════════
-- HELPER FUNCTIONS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Get conversations for a user
CREATE OR REPLACE FUNCTION get_user_conversations(
  p_user_id UUID,
  p_page INT DEFAULT 1,
  p_per_page INT DEFAULT 20
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(conv_data) INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', c.id,
      'type', c.type,
      'name', c.name,
      'avatar_url', c.avatar_url,
      'last_message_text', c.last_message_text,
      'last_message_at', c.last_message_at,
      'last_sender_name', c.last_sender_name,
      'unread_count', cp.unread_count,
      'is_muted', cp.is_muted,
      'is_pinned', cp.is_pinned,
      'is_archived', cp.is_archived,
      'is_typing', cp.is_typing,
      'participants', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'user_id', cp2.user_id,
            'role', cp2.role,
            'is_online', cp2.is_online,
            'last_seen_at', cp2.last_seen_at
          )
        ), '[]'::jsonb)
        FROM conversation_participants cp2
        WHERE cp2.conversation_id = c.id AND cp2.left_at IS NULL
      )
    ) AS conv_data
    FROM conversations c
    JOIN conversation_participants cp ON cp.conversation_id = c.id
    WHERE cp.user_id = p_user_id AND cp.left_at IS NULL
    ORDER BY cp.is_pinned DESC, c.last_message_at DESC NULLS LAST
    LIMIT p_per_page OFFSET (p_page - 1) * p_per_page
  ) sub;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get messages for a conversation
CREATE OR REPLACE FUNCTION get_conversation_messages(
  p_conversation_id UUID,
  p_page INT DEFAULT 1,
  p_per_page INT DEFAULT 50,
  p_before TIMESTAMPTZ DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_agg(msg_data) INTO v_result
  FROM (
    SELECT jsonb_build_object(
      'id', m.id,
      'conversation_id', m.conversation_id,
      'sender_id', m.sender_id,
      'sender_name', m.sender_name,
      'sender_avatar', m.sender_avatar,
      'sender_role', m.sender_role,
      'type', m.type,
      'body', m.body,
      'reply_to_id', m.reply_to_id,
      'is_pinned', m.is_pinned,
      'is_edited', m.is_edited,
      'is_deleted', m.is_deleted,
      'read_by', m.read_by,
      'reactions', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object('emoji', mr.emoji, 'user_id', mr.user_id, 'created_at', mr.created_at)
        ), '[]'::jsonb)
        FROM message_reactions mr WHERE mr.message_id = m.id
      ),
      'attachments', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'id', ma.id, 'file_name', ma.file_name, 'file_url', ma.file_url,
            'file_type', ma.file_type, 'file_size_bytes', ma.file_size_bytes,
            'thumbnail_url', ma.thumbnail_url, 'is_previewable', ma.is_previewable
          )
        ), '[]'::jsonb)
        FROM message_attachments ma WHERE ma.message_id = m.id
      ),
      'reply_to', CASE WHEN m.reply_to_id IS NOT NULL THEN (
        SELECT jsonb_build_object(
          'id', rm.id, 'sender_name', rm.sender_name, 'body', LEFT(rm.body, 80), 'type', rm.type
        )
        FROM messages rm WHERE rm.id = m.reply_to_id
      ) END,
      'created_at', m.created_at,
      'updated_at', m.updated_at
    ) AS msg_data
    FROM messages m
    WHERE m.conversation_id = p_conversation_id
    AND m.is_deleted = FALSE
    AND (p_before IS NULL OR m.created_at < p_before)
    ORDER BY m.created_at DESC
    LIMIT p_per_page OFFSET (p_page - 1) * p_per_page
  ) sub;

  RETURN COALESCE(v_result, '[]'::jsonb);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Search school knowledge base (for AI Knowledge Assistant)
CREATE OR REPLACE FUNCTION search_school_knowledge(
  p_school_id UUID,
  p_query TEXT,
  p_limit INT DEFAULT 5
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', skd.id,
      'title', skd.title,
      'document_type', skd.document_type,
      'relevance', ts_rank(skd.search_vector, plainto_tsquery('english', p_query)),
      'snippet', ts_headline('english', COALESCE(skd.extracted_text, ''), plainto_tsquery('english', p_query))
    )
  ), '[]'::jsonb) INTO v_result
  FROM school_knowledge_documents skd
  WHERE skd.school_id = p_school_id
  AND skd.is_active = TRUE
  AND skd.status = 'indexed'
  AND skd.search_vector @@ plainto_tsquery('english', p_query)
  ORDER BY ts_rank(skd.search_vector, plainto_tsquery('english', p_query)) DESC
  LIMIT p_limit;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get communication dashboard stats
CREATE OR REPLACE FUNCTION get_communication_dashboard(
  p_school_id UUID
)
RETURNS JSONB AS $$
DECLARE
  v_result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_conversations', (SELECT COUNT(*) FROM conversations WHERE school_id = p_school_id),
    'active_conversations', (SELECT COUNT(*) FROM conversations WHERE school_id = p_school_id AND last_message_at > now() - INTERVAL '24 hours'),
    'total_messages_today', (SELECT COUNT(*) FROM messages WHERE school_id = p_school_id AND created_at > date_trunc('day', now())),
    'total_announcements', (SELECT COUNT(*) FROM communication_announcements WHERE school_id = p_school_id AND is_published = TRUE),
    'unread_notifications', (SELECT COUNT(*) FROM communication_notifications WHERE school_id = p_school_id AND is_read = FALSE),
    'upcoming_events', (
      SELECT COALESCE(jsonb_agg(
        jsonb_build_object('id', id, 'title', title, 'start_time', start_time, 'event_type', event_type)
      ), '[]'::jsonb)
      FROM communication_calendar_events
      WHERE school_id = p_school_id AND start_time > now()
      ORDER BY start_time LIMIT 5
    ),
    'active_forums', (SELECT COUNT(*) FROM discussion_forums WHERE school_id = p_school_id AND is_locked = FALSE),
    'knowledge_documents', (SELECT COUNT(*) FROM school_knowledge_documents WHERE school_id = p_school_id AND is_active = TRUE)
  ) INTO v_result;

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ═══════════════════════════════════════════════════════════════════════════════
-- COMMENTS
-- ═══════════════════════════════════════════════════════════════════════════════

COMMENT ON TABLE conversations IS 'Real-time conversation threads supporting direct, group, department, class, and school-wide chats';
COMMENT ON TABLE conversation_participants IS 'User membership in conversations with read tracking and typing indicators';
COMMENT ON TABLE messages IS 'Individual messages within conversations with support for text, media, replies, edits, and soft deletes';
COMMENT ON TABLE message_reactions IS 'Emoji reactions attached to messages';
COMMENT ON TABLE message_attachments IS 'File attachments (PDF, DOCX, PPTX, images, etc.) linked to messages';
COMMENT ON TABLE communication_announcements IS 'School-wide and targeted announcements with scheduling and expiry';
COMMENT ON TABLE communication_notifications IS 'Centralized notification system with multi-channel delivery tracking';
COMMENT ON TABLE user_notification_preferences IS 'Per-user notification channel preferences and quiet hours';
COMMENT ON TABLE discussion_forums IS 'Moderated discussion spaces for school communities, subjects, classes, and departments';
COMMENT ON TABLE forum_posts IS 'Posts within discussion forums with attachments and moderation';
COMMENT ON TABLE forum_comments IS 'Threaded comments on forum posts with moderation support';
COMMENT ON TABLE communication_calendar_events IS 'Calendar events, meetings, and parent-teacher booking system';
COMMENT ON TABLE communication_audit_logs IS 'Audit trail for all communication actions';
COMMENT ON TABLE school_knowledge_documents IS 'School documents indexed for the AI School Knowledge Assistant';
COMMENT ON TABLE school_knowledge_embeddings IS 'Vector embeddings for retrieval-based AI knowledge search';

COMMIT;
