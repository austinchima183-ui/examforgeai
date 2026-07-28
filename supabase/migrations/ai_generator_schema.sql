-- ============================================================================
-- ExamForge AI - AI Question Generation Engine Schema
-- ============================================================================
-- Production-ready schema for the AI-powered question generation engine.
-- Supports: multi-provider AI, prompt management (database-driven),
--           question generation, validation, improvement, document processing,
--           review workflow, history tracking, and cost monitoring.
--
-- Prerequisites:
--   Existing tables: schools, users, subjects, topics, subtopics,
--                    question_bank, answer_options, matching_pairs,
--                    ordering_items, fill_in_blank_answers
--   Existing enums:  user_role, question_type, difficulty_level, exam_type,
--                    subscription_status, exam_status, notification_type,
--                    share_permission, import_status, content_type,
--                    curriculum_standard_type
--
-- Performance: Designed for high-throughput with composite indexes,
--              GIN indexes for JSONB, and partitioning-ready layout.
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. CUSTOM ENUMERATION TYPES
-- ============================================================================
-- All new enums required by the AI generation engine.
-- Uses IF NOT EXISTS pattern to ensure idempotent migrations.
-- ============================================================================

DO $$
BEGIN
  -- ---------------------------------------------------------------------------
  -- ai_provider: Supported AI model providers
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ai_provider') THEN
    CREATE TYPE ai_provider AS ENUM (
      'openai',
      'gemini',
      'claude',
      'deepseek',
      'grok',
      'local_llm'
    );
  END IF;

  -- ---------------------------------------------------------------------------
  -- generation_status: Lifecycle states for an AI generation request
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'generation_status') THEN
    CREATE TYPE generation_status AS ENUM (
      'pending',
      'processing',
      'completed',
      'failed',
      'cancelled'
    );
  END IF;

  -- ---------------------------------------------------------------------------
  -- review_status: Human review workflow states for AI-generated questions
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'review_status') THEN
    CREATE TYPE review_status AS ENUM (
      'pending',
      'approved',
      'rejected',
      'needs_revision'
    );
  END IF;

  -- ---------------------------------------------------------------------------
  -- validation_severity: Severity levels for AI validation results
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'validation_severity') THEN
    CREATE TYPE validation_severity AS ENUM (
      'info',
      'warning',
      'error',
      'critical'
    );
  END IF;

  -- ---------------------------------------------------------------------------
  -- bloom_taxonomy: Bloom's Taxonomy cognitive levels for question alignment
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'bloom_taxonomy') THEN
    CREATE TYPE bloom_taxonomy AS ENUM (
      'remember',
      'understand',
      'apply',
      'analyze',
      'evaluate',
      'create'
    );
  END IF;

  -- ---------------------------------------------------------------------------
  -- prompt_type: Categories of AI prompt templates
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'prompt_type') THEN
    CREATE TYPE prompt_type AS ENUM (
      'question_generation',
      'question_improvement',
      'question_validation',
      'translation',
      'document_extraction',
      'distractor_generation',
      'explanation_generation'
    );
  END IF;

  -- ---------------------------------------------------------------------------
  -- document_status: Lifecycle states for uploaded documents
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'document_status') THEN
    CREATE TYPE document_status AS ENUM (
      'pending',
      'processing',
      'processed',
      'failed'
    );
  END IF;

  -- ---------------------------------------------------------------------------
  -- curriculum_type: Nigerian and international curriculum frameworks
  -- ---------------------------------------------------------------------------
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'curriculum_type') THEN
    CREATE TYPE curriculum_type AS ENUM (
      'waec',
      'neco',
      'jamb',
      'bece',
      'cambridge_igcse',
      'custom'
    );
  END IF;
END
$$;

-- Enum comments for documentation
COMMENT ON TYPE ai_provider IS 'Supported AI model providers for question generation';
COMMENT ON TYPE generation_status IS 'Lifecycle states for an AI generation request: pending → processing → completed/failed/cancelled';
COMMENT ON TYPE review_status IS 'Human review workflow states for AI-generated questions';
COMMENT ON TYPE validation_severity IS 'Severity levels for automated validation findings: info → warning → error → critical';
COMMENT ON TYPE bloom_taxonomy IS 'Bloom''s Taxonomy cognitive levels: remember → understand → apply → analyze → evaluate → create';
COMMENT ON TYPE prompt_type IS 'Categories of AI prompt templates used across the generation pipeline';
COMMENT ON TYPE document_status IS 'Lifecycle states for uploaded documents awaiting extraction';
COMMENT ON TYPE curriculum_type IS 'Nigerian and international curriculum frameworks for alignment';

-- ============================================================================
-- 2. AI PROVIDERS CONFIGURATION
-- ============================================================================
-- Stores configuration for each AI provider + model combination.
-- Enables multi-provider routing, cost tracking, and capability detection.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_providers_config (
  id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider                  ai_provider NOT NULL,
  display_name              TEXT NOT NULL,                                -- e.g. "OpenAI GPT-4o"
  model_name                TEXT NOT NULL,                                -- e.g. "gpt-4o", "gemini-1.5-pro"
  api_endpoint              TEXT NOT NULL,                                -- REST endpoint URL
  is_active                 BOOLEAN DEFAULT true,
  max_tokens                INTEGER DEFAULT 4096,                        -- Maximum output tokens
  temperature               NUMERIC(3,2) DEFAULT 0.70,                   -- Sampling temperature (0.00–2.00)
  top_p                     NUMERIC(3,2) DEFAULT 0.95,                   -- Nucleus sampling threshold
  cost_per_1k_input_tokens  NUMERIC(10,6) DEFAULT 0.0,                   -- USD per 1,000 input tokens
  cost_per_1k_output_tokens NUMERIC(10,6) DEFAULT 0.0,                   -- USD per 1,000 output tokens
  supports_streaming        BOOLEAN DEFAULT false,
  supports_function_calling BOOLEAN DEFAULT false,
  supports_vision           BOOLEAN DEFAULT false,                        -- Image / multimodal support
  rate_limit_per_minute     INTEGER DEFAULT 60,                          -- Provider-imposed rate limit
  config                    JSONB DEFAULT '{}',                           -- Provider-specific settings
  created_at                TIMESTAMPTZ DEFAULT now(),
  updated_at                TIMESTAMPTZ DEFAULT now(),

  -- Prevent duplicate provider+model combinations
  CONSTRAINT ai_providers_config_unique_provider_model UNIQUE (provider, model_name),
  -- Validate temperature range
  CONSTRAINT ai_providers_config_temperature_range CHECK (temperature >= 0.00 AND temperature <= 2.00),
  -- Validate top_p range
  CONSTRAINT ai_providers_config_top_p_range CHECK (top_p >= 0.00 AND top_p <= 1.00),
  -- Non-negative cost values
  CONSTRAINT ai_providers_config_input_cost_nonneg CHECK (cost_per_1k_input_tokens >= 0),
  CONSTRAINT ai_providers_config_output_cost_nonneg CHECK (cost_per_1k_output_tokens >= 0),
  -- Non-negative max_tokens
  CONSTRAINT ai_providers_config_max_tokens_positive CHECK (max_tokens > 0),
  -- Non-negative rate limit
  CONSTRAINT ai_providers_config_rate_limit_positive CHECK (rate_limit_per_minute > 0)
);

COMMENT ON TABLE ai_providers_config IS 'Configuration registry for AI providers and models, enabling multi-provider routing and cost tracking';
COMMENT ON COLUMN ai_providers_config.config IS 'Provider-specific settings (API version, headers, custom parameters) stored as JSONB';
COMMENT ON COLUMN ai_providers_config.cost_per_1k_input_tokens IS 'Cost in USD per 1,000 input tokens for billing calculations';
COMMENT ON COLUMN ai_providers_config.cost_per_1k_output_tokens IS 'Cost in USD per 1,000 output tokens for billing calculations';

-- ============================================================================
-- 3. PROMPT TEMPLATES (THE PROMPT MANAGEMENT SYSTEM)
-- ============================================================================
-- Database-driven prompt management enabling version control, A/B testing,
-- per-curriculum customization, and quality tracking over time.
-- Uses {{variable}} syntax for template interpolation.
-- ============================================================================

CREATE TABLE IF NOT EXISTS prompt_templates (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                  TEXT NOT NULL,                                  -- e.g. "MCQ Generation - WAEC Science"
  description           TEXT,                                          -- Purpose and usage notes
  prompt_type           prompt_type NOT NULL,
  provider              ai_provider,                                   -- NULL = works with any provider
  curriculum            curriculum_type,                               -- Target curriculum framework
  subject_id            UUID REFERENCES subjects(id) ON DELETE CASCADE,-- Subject scope
  question_type         question_type,                                 -- For generation-type prompts
  difficulty            difficulty_level,                              -- Target difficulty
  bloom_level           bloom_taxonomy,                                -- Target cognitive level
  language              VARCHAR(10) DEFAULT 'en',                      -- ISO 639-1 language code
  system_prompt         TEXT NOT NULL,                                 -- System instruction sent to AI
  user_prompt_template  TEXT NOT NULL,                                 -- Template with {{variables}}
  variables             JSONB DEFAULT '[]',                            -- [{name, description, required, default}]
  few_shot_examples     JSONB DEFAULT '[]',                            -- [{input, output}] examples
  chain_of_thought      BOOLEAN DEFAULT false,                         -- Enable CoT reasoning
  output_format         JSONB DEFAULT '{}',                            -- Expected JSON output schema
  is_active             BOOLEAN DEFAULT true,
  is_default            BOOLEAN DEFAULT false,                         -- Default prompt for this type
  version               INTEGER DEFAULT 1,                             -- Template version number
  parent_id             UUID REFERENCES prompt_templates(id),          -- Previous version in chain
  quality_score         NUMERIC(3,2) DEFAULT 0.00,                     -- 0.00–5.00, tracked over time
  usage_count           INTEGER DEFAULT 0,                             -- Times this template was used
  success_rate          NUMERIC(5,2) DEFAULT 0.00,                     -- % of generations passing validation
  created_by            UUID REFERENCES users(id),
  school_id             UUID REFERENCES schools(id),                   -- NULL = platform-wide
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Only one default per (prompt_type, provider, subject_id, curriculum) combination
  CONSTRAINT prompt_templates_one_default EXCLUDE (
    CASE WHEN is_default THEN prompt_type END WITH =,
    CASE WHEN is_default THEN COALESCE(provider, 'openai'::ai_provider) END WITH =,
    CASE WHEN is_default THEN COALESCE(subject_id, '00000000-0000-0000-0000-000000000000'::uuid) END WITH =,
    CASE WHEN is_default THEN COALESCE(curriculum, 'custom'::curriculum_type) END WITH =
  ) WHERE (is_default = true),
  -- Version must be positive
  CONSTRAINT prompt_templates_version_positive CHECK (version > 0),
  -- Quality score range: 0–5
  CONSTRAINT prompt_templates_quality_score_range CHECK (quality_score >= 0.00 AND quality_score <= 5.00),
  -- Success rate range: 0–100
  CONSTRAINT prompt_templates_success_rate_range CHECK (success_rate >= 0.00 AND success_rate <= 100.00),
  -- Usage count non-negative
  CONSTRAINT prompt_templates_usage_count_nonneg CHECK (usage_count >= 0)
);

COMMENT ON TABLE prompt_templates IS 'Database-driven prompt management system with versioning, A/B testing, and quality tracking';
COMMENT ON COLUMN prompt_templates.user_prompt_template IS 'Template string using {{variable}} syntax for interpolation (e.g. {{subject}}, {{topic}}, {{num_questions}})';
COMMENT ON COLUMN prompt_templates.variables IS 'JSON array of variable definitions: [{name, description, required, default}]';
COMMENT ON COLUMN prompt_templates.few_shot_examples IS 'JSON array of example input/output pairs for few-shot prompting';
COMMENT ON COLUMN prompt_templates.output_format IS 'JSON Schema describing the expected AI response structure';
COMMENT ON COLUMN prompt_templates.parent_id IS 'Previous version of this template, forming a version chain';
COMMENT ON COLUMN prompt_templates.quality_score IS 'Aggregate quality score (0.00–5.00) computed from generation outcomes';
COMMENT ON COLUMN prompt_templates.success_rate IS 'Percentage of generations using this template that passed validation';

-- ============================================================================
-- 4. AI GENERATION REQUESTS
-- ============================================================================
-- Master record for every AI generation attempt. Captures the full lifecycle
-- from request submission through processing to completion, including
-- token usage, cost, and timing metrics.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_generation_requests (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID REFERENCES schools(id) ON DELETE CASCADE,
  requested_by          UUID NOT NULL REFERENCES users(id),
  provider              ai_provider NOT NULL DEFAULT 'openai',
  model_name            TEXT NOT NULL,                                  -- e.g. "gpt-4o"
  prompt_template_id    UUID REFERENCES prompt_templates(id),           -- Template used (nullable for custom)
  generation_type       prompt_type NOT NULL DEFAULT 'question_generation',
  status                generation_status NOT NULL DEFAULT 'pending',
  input_params          JSONB NOT NULL DEFAULT '{}',                    -- Subject, topic, difficulty, etc.
  system_prompt         TEXT,                                           -- Resolved system prompt
  user_prompt           TEXT,                                           -- Resolved user prompt
  raw_response          JSONB,                                          -- Raw AI provider response
  processed_response    JSONB,                                          -- Parsed and structured output
  input_tokens          INTEGER DEFAULT 0,
  output_tokens         INTEGER DEFAULT 0,
  total_cost            NUMERIC(10,6) DEFAULT 0.0,                     -- USD
  generation_time_ms    INTEGER,                                        -- Wall-clock time
  error_message         TEXT,
  retry_count           INTEGER DEFAULT 0,
  priority              INTEGER DEFAULT 0,                             -- Higher = processed sooner
  started_at            TIMESTAMPTZ,
  completed_at          TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- Token counts non-negative
  CONSTRAINT ai_gen_req_input_tokens_nonneg CHECK (input_tokens >= 0),
  CONSTRAINT ai_gen_req_output_tokens_nonneg CHECK (output_tokens >= 0),
  -- Cost non-negative
  CONSTRAINT ai_gen_req_total_cost_nonneg CHECK (total_cost >= 0),
  -- Retry count non-negative
  CONSTRAINT ai_gen_req_retry_count_nonneg CHECK (retry_count >= 0),
  -- Completed_at must be after started_at when both set
  CONSTRAINT ai_gen_req_completed_after_started
    CHECK (completed_at IS NULL OR started_at IS NULL OR completed_at >= started_at)
);

COMMENT ON TABLE ai_generation_requests IS 'Master record for every AI generation request, tracking full lifecycle from submission to completion';
COMMENT ON COLUMN ai_generation_requests.input_params IS 'JSON object with generation parameters: subject, topic, difficulty, num_questions, bloom_level, exam_type, keywords, custom_instructions';
COMMENT ON COLUMN ai_generation_requests.raw_response IS 'Unprocessed response from the AI provider for debugging and auditing';
COMMENT ON COLUMN ai_generation_requests.processed_response IS 'Parsed and structured output ready for question creation';
COMMENT ON COLUMN ai_generation_requests.priority IS 'Queue priority — higher values are processed first';

-- ============================================================================
-- 5. AI GENERATED QUESTIONS
-- ============================================================================
-- Individual questions produced by AI generation requests. Each row tracks
-- the question content, answer options, validation state, and the human
-- review workflow. On approval, questions can be promoted to question_bank.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_generated_questions (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  generation_request_id   UUID NOT NULL REFERENCES ai_generation_requests(id) ON DELETE CASCADE,
  question_bank_id        UUID REFERENCES question_bank(id) ON DELETE SET NULL,  -- Linked after approval
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  question_type           question_type NOT NULL,
  difficulty              difficulty_level NOT NULL DEFAULT 'medium',
  bloom_level             bloom_taxonomy DEFAULT 'understand',
  content                 TEXT NOT NULL,                                 -- Question text
  content_json            JSONB DEFAULT '{}',                            -- Structured content
  answer_options          JSONB DEFAULT '[]',                            -- [{content, isCorrect, explanation, marks}]
  matching_pairs          JSONB DEFAULT '[]',                            -- [{left, right}]
  ordering_items          JSONB DEFAULT '[]',                            -- [{item, correctPosition}]
  fill_in_blank_answers   JSONB DEFAULT '[]',                            -- [{answer, acceptableVariations, marks}]
  explanation             TEXT,                                          -- Answer explanation
  suggested_references    TEXT,                                          -- Source references
  marks                   NUMERIC(5,2) DEFAULT 1.00,
  estimated_time_seconds  INTEGER,                                      -- Suggested time to answer
  confidence_score        NUMERIC(3,2) DEFAULT 0.00,                    -- 0.00–1.00 AI confidence
  curriculum_alignment    JSONB DEFAULT '{}',                            -- Mapping to curriculum standards
  review_status           review_status NOT NULL DEFAULT 'pending',
  reviewed_by             UUID REFERENCES users(id),
  reviewed_at             TIMESTAMPTZ,
  review_notes            TEXT,                                          -- Reviewer feedback
  teacher_edits           JSONB DEFAULT '{}',                            -- Tracks what the teacher changed
  is_edited               BOOLEAN DEFAULT false,                        -- Whether teacher modified the question
  is_approved             BOOLEAN DEFAULT false,                        -- Quick approval flag
  metadata                JSONB DEFAULT '{}',                            -- AI model info, prompt, params
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now(),

  -- Marks non-negative
  CONSTRAINT ai_gen_q_marks_nonneg CHECK (marks >= 0),
  -- Confidence score range
  CONSTRAINT ai_gen_q_confidence_range CHECK (confidence_score >= 0.00 AND confidence_score <= 1.00),
  -- Estimated time positive when set
  CONSTRAINT ai_gen_q_time_positive CHECK (estimated_time_seconds IS NULL OR estimated_time_seconds > 0)
);

COMMENT ON TABLE ai_generated_questions IS 'Individual questions produced by AI, with review workflow and promotion path to question_bank';
COMMENT ON COLUMN ai_generated_questions.question_bank_id IS 'Set when the question is approved and promoted to the main question bank';
COMMENT ON COLUMN ai_generated_questions.answer_options IS 'JSON array of options: [{content: text, isCorrect: bool, explanation: text, marks: number}]';
COMMENT ON COLUMN ai_generated_questions.confidence_score IS 'AI-assessed confidence in the question quality (0.00–1.00)';
COMMENT ON COLUMN ai_generated_questions.teacher_edits IS 'JSON tracking teacher modifications: {field: {original: ..., modified: ...}}';
COMMENT ON COLUMN ai_generated_questions.metadata IS 'AI generation metadata: model, prompt hash, generation params, template version';

-- ============================================================================
-- 6. AI VALIDATION RESULTS
-- ============================================================================
-- Automated validation findings for AI-generated questions. Covers
-- grammar, accuracy, ambiguity, curriculum alignment, and more.
-- Each finding has a severity level and optional resolution tracking.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_validation_results (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  generated_question_id UUID NOT NULL REFERENCES ai_generated_questions(id) ON DELETE CASCADE,
  validation_type       TEXT NOT NULL,                                  -- e.g. grammar, spelling, duplicate, accuracy
  severity              validation_severity NOT NULL DEFAULT 'warning',
  message               TEXT NOT NULL,                                 -- What was found
  suggestion            TEXT,                                          -- How to fix it
  is_resolved           BOOLEAN DEFAULT false,
  resolved_by           UUID REFERENCES users(id),
  resolved_at           TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT now(),

  -- Valid validation types
  CONSTRAINT ai_val_res_valid_type CHECK (validation_type IN (
    'grammar', 'spelling', 'duplicate', 'accuracy', 'ambiguity',
    'clarity', 'reading_level', 'curriculum_alignment', 'difficulty_consistency'
  ))
);

COMMENT ON TABLE ai_validation_results IS 'Automated validation findings for AI-generated questions with severity tracking and resolution workflow';
COMMENT ON COLUMN ai_validation_results.validation_type IS 'Category of validation: grammar, spelling, duplicate, accuracy, ambiguity, clarity, reading_level, curriculum_alignment, difficulty_consistency';

-- ============================================================================
-- 7. AI QUESTION IMPROVEMENTS
-- ============================================================================
-- Tracks every improvement attempt on an AI-generated question.
-- Supports rewrites, simplification, difficulty adjustments, new distractors,
-- translations, type changes, similar question generation, and case study expansion.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_question_improvements (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  generated_question_id   UUID NOT NULL REFERENCES ai_generated_questions(id) ON DELETE CASCADE,
  improvement_type        TEXT NOT NULL,                                -- What kind of improvement
  provider                ai_provider NOT NULL,
  original_content        TEXT NOT NULL,                                -- Before
  improved_content        TEXT NOT NULL,                                -- After
  original_answer_options JSONB,                                       -- Before options
  improved_answer_options JSONB,                                       -- After options
  improvement_prompt      TEXT,                                        -- The prompt used for improvement
  input_tokens            INTEGER DEFAULT 0,
  output_tokens           INTEGER DEFAULT 0,
  cost                    NUMERIC(10,6) DEFAULT 0.0,                   -- USD
  is_accepted             BOOLEAN DEFAULT false,                       -- Did the teacher accept this?
  created_by              UUID NOT NULL REFERENCES users(id),
  created_at              TIMESTAMPTZ DEFAULT now(),

  -- Token counts non-negative
  CONSTRAINT ai_qi_input_tokens_nonneg CHECK (input_tokens >= 0),
  CONSTRAINT ai_qi_output_tokens_nonneg CHECK (output_tokens >= 0),
  -- Cost non-negative
  CONSTRAINT ai_qi_cost_nonneg CHECK (cost >= 0),
  -- Valid improvement types
  CONSTRAINT ai_qi_valid_type CHECK (improvement_type IN (
    'rewrite', 'simplify', 'make_difficult', 'make_easy',
    'new_distractors', 'improve_explanation', 'translate',
    'change_type', 'generate_similar', 'expand_case_study'
  ))
);

COMMENT ON TABLE ai_question_improvements IS 'Tracks every improvement iteration on an AI-generated question with before/after content and acceptance tracking';
COMMENT ON COLUMN ai_question_improvements.improvement_type IS 'Type of improvement: rewrite, simplify, make_difficult, make_easy, new_distractors, improve_explanation, translate, change_type, generate_similar, expand_case_study';

-- ============================================================================
-- 8. AI DOCUMENT UPLOADS
-- ============================================================================
-- Manages uploaded documents (PDFs, DOCX, TXT) for AI-based content
-- extraction. Tracks processing status, extracted text, identified
-- topics, and suggested learning objectives.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_document_uploads (
  id                              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id                       UUID REFERENCES schools(id) ON DELETE CASCADE,
  uploaded_by                     UUID NOT NULL REFERENCES users(id),
  file_name                       TEXT NOT NULL,
  file_url                        TEXT NOT NULL,                          -- Storage path / URL
  file_size                       BIGINT,                                 -- Bytes
  mime_type                       TEXT,
  document_type                   VARCHAR(20) NOT NULL DEFAULT 'pdf',     -- pdf, docx, txt
  status                          document_status NOT NULL DEFAULT 'pending',
  extracted_text                  TEXT,                                   -- OCR / parsed content
  identified_topics               JSONB DEFAULT '[]',                     -- [{topic, confidence}]
  suggested_objectives            JSONB DEFAULT '[]',                     -- [{objective, bloom_level}]
  question_generation_request_id  UUID REFERENCES ai_generation_requests(id), -- Auto-generated request
  error_message                   TEXT,
  processed_at                    TIMESTAMPTZ,
  created_at                      TIMESTAMPTZ DEFAULT now(),

  -- File size non-negative
  CONSTRAINT ai_doc_uploads_file_size_nonneg CHECK (file_size IS NULL OR file_size >= 0),
  -- Valid document types
  CONSTRAINT ai_doc_uploads_valid_doc_type CHECK (document_type IN ('pdf', 'docx', 'txt'))
);

COMMENT ON TABLE ai_document_uploads IS 'Manages uploaded documents for AI-based content extraction with processing status and identified topics';
COMMENT ON COLUMN ai_document_uploads.identified_topics IS 'JSON array of AI-identified topics: [{topic: string, confidence: number}]';
COMMENT ON COLUMN ai_document_uploads.suggested_objectives IS 'JSON array of suggested learning objectives: [{objective: string, bloom_level: string}]';

-- ============================================================================
-- 9. AI GENERATION QUEUE
-- ============================================================================
-- Persistent job queue for AI generation requests. Supports priority-based
-- processing, retry with exponential backoff, and dead-letter handling.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_generation_queue (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  generation_request_id   UUID NOT NULL REFERENCES ai_generation_requests(id) ON DELETE CASCADE,
  priority                INTEGER DEFAULT 0,                            -- Higher = sooner
  attempts                INTEGER DEFAULT 0,                             -- Number of attempts so far
  max_attempts            INTEGER DEFAULT 3,                             -- Max retries before dead_letter
  next_attempt_at         TIMESTAMPTZ DEFAULT now(),                     -- When to next try
  status                  VARCHAR(20) NOT NULL DEFAULT 'queued',         -- queued, processing, completed, failed, dead_letter
  error_message           TEXT,
  created_at              TIMESTAMPTZ DEFAULT now(),
  updated_at              TIMESTAMPTZ DEFAULT now(),

  -- Attempts non-negative
  CONSTRAINT ai_gen_queue_attempts_nonneg CHECK (attempts >= 0),
  -- Max attempts positive
  CONSTRAINT ai_gen_queue_max_attempts_positive CHECK (max_attempts > 0),
  -- Valid queue statuses
  CONSTRAINT ai_gen_queue_valid_status CHECK (status IN (
    'queued', 'processing', 'completed', 'failed', 'dead_letter'
  ))
);

COMMENT ON TABLE ai_generation_queue IS 'Persistent priority queue for AI generation jobs with retry and dead-letter handling';
COMMENT ON COLUMN ai_generation_queue.status IS 'Queue item status: queued → processing → completed/failed/dead_letter';

-- ============================================================================
-- 10. AI USAGE STATS
-- ============================================================================
-- Daily aggregated usage statistics per school, provider, and model.
-- Enables cost monitoring, budgeting, and performance analysis.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_usage_stats (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id               UUID REFERENCES schools(id) ON DELETE CASCADE,
  provider                ai_provider NOT NULL,
  model_name              TEXT NOT NULL,
  date                    DATE NOT NULL,                                -- Aggregation date
  total_requests          INTEGER DEFAULT 0,
  successful_requests     INTEGER DEFAULT 0,
  failed_requests         INTEGER DEFAULT 0,
  total_input_tokens      BIGINT DEFAULT 0,
  total_output_tokens     BIGINT DEFAULT 0,
  total_cost              NUMERIC(12,6) DEFAULT 0.0,                   -- USD
  avg_generation_time_ms  INTEGER DEFAULT 0,                            -- Average wall-clock time
  questions_generated     INTEGER DEFAULT 0,
  questions_approved      INTEGER DEFAULT 0,
  questions_rejected      INTEGER DEFAULT 0,
  created_at              TIMESTAMPTZ DEFAULT now(),

  -- One row per (school, provider, model, date)
  CONSTRAINT ai_usage_stats_unique_day UNIQUE (school_id, provider, model_name, date),
  -- Non-negative counters
  CONSTRAINT ai_usage_stats_requests_nonneg CHECK (total_requests >= 0),
  CONSTRAINT ai_usage_stats_success_nonneg CHECK (successful_requests >= 0),
  CONSTRAINT ai_usage_stats_failed_nonneg CHECK (failed_requests >= 0),
  CONSTRAINT ai_usage_stats_input_tokens_nonneg CHECK (total_input_tokens >= 0),
  CONSTRAINT ai_usage_stats_output_tokens_nonneg CHECK (total_output_tokens >= 0),
  CONSTRAINT ai_usage_stats_cost_nonneg CHECK (total_cost >= 0),
  CONSTRAINT ai_usage_stats_gen_nonneg CHECK (questions_generated >= 0),
  CONSTRAINT ai_usage_stats_app_nonneg CHECK (questions_approved >= 0),
  CONSTRAINT ai_usage_stats_rej_nonneg CHECK (questions_rejected >= 0)
);

COMMENT ON TABLE ai_usage_stats IS 'Daily aggregated usage statistics per school/provider/model for cost monitoring and performance analysis';
COMMENT ON COLUMN ai_usage_stats.total_cost IS 'Total cost in USD for the day across all requests for this school/provider/model combination';

-- ============================================================================
-- 11. AI API KEYS
-- ============================================================================
-- Encrypted storage of per-school API keys for each provider.
-- Keys are encrypted at the application level; key_hash enables
-- lookup without decryption.
-- ============================================================================

CREATE TABLE IF NOT EXISTS ai_api_keys (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  school_id             UUID REFERENCES schools(id) ON DELETE CASCADE,
  provider              ai_provider NOT NULL,
  encrypted_key         TEXT NOT NULL,                                 -- Application-level encrypted
  key_hash              TEXT NOT NULL,                                 -- For lookup without decryption
  is_active             BOOLEAN DEFAULT true,
  monthly_budget        NUMERIC(10,2) DEFAULT 100.00,                  -- USD monthly cap
  current_month_usage   NUMERIC(10,2) DEFAULT 0.00,                    -- USD spent this month
  rate_limit_per_minute INTEGER DEFAULT 60,                            -- Self-imposed rate limit
  last_used_at          TIMESTAMPTZ,
  created_by            UUID NOT NULL REFERENCES users(id),
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- One active key per school per provider
  CONSTRAINT ai_api_keys_unique_school_provider UNIQUE (school_id, provider),
  -- Budget non-negative
  CONSTRAINT ai_api_keys_budget_nonneg CHECK (monthly_budget >= 0),
  CONSTRAINT ai_api_keys_usage_nonneg CHECK (current_month_usage >= 0),
  -- Rate limit positive
  CONSTRAINT ai_api_keys_rate_limit_positive CHECK (rate_limit_per_minute > 0)
);

COMMENT ON TABLE ai_api_keys IS 'Encrypted per-school API keys for each AI provider with budget tracking';
COMMENT ON COLUMN ai_api_keys.encrypted_key IS 'API key encrypted at the application level before storage';
COMMENT ON COLUMN ai_api_keys.key_hash IS 'Hash of the API key for lookup/verification without decryption';
COMMENT ON COLUMN ai_api_keys.monthly_budget IS 'Monthly spending cap in USD for this school+provider combination';

-- ============================================================================
-- 12. CURRICULUM MAPPINGS
-- ============================================================================
-- Maps curriculum standards to the platform's subject/topic hierarchy.
-- Enables AI prompt enrichment with curriculum-specific guidance,
-- learning objectives, and Bloom's Taxonomy alignment.
-- ============================================================================

CREATE TABLE IF NOT EXISTS curriculum_mappings (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  curriculum            curriculum_type NOT NULL,
  subject_id            UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  topic_id              UUID REFERENCES topics(id) ON DELETE CASCADE,
  subtopic_id           UUID REFERENCES subtopics(id) ON DELETE CASCADE,
  class_level           TEXT NOT NULL,                                  -- e.g. "SS1", "JSS2"
  curriculum_code       TEXT,                                          -- Official curriculum code
  learning_objectives   TEXT[],                                        -- Array of learning objectives
  bloom_levels          bloom_taxonomy[],                              -- Expected cognitive levels
  suggested_difficulty  difficulty_level,                              -- Suggested difficulty
  marks_guidance        NUMERIC(5,2),                                  -- Suggested marks allocation
  description           TEXT,                                          -- Additional context
  is_active             BOOLEAN DEFAULT true,
  created_at            TIMESTAMPTZ DEFAULT now(),
  updated_at            TIMESTAMPTZ DEFAULT now(),

  -- Marks guidance non-negative when set
  CONSTRAINT curriculum_mappings_marks_nonneg CHECK (marks_guidance IS NULL OR marks_guidance >= 0)
);

COMMENT ON TABLE curriculum_mappings IS 'Maps curriculum standards to platform subjects/topics for AI prompt enrichment and alignment';
COMMENT ON COLUMN curriculum_mappings.learning_objectives IS 'Array of learning objectives from the curriculum for this subject/topic/class combination';
COMMENT ON COLUMN curriculum_mappings.bloom_levels IS 'Expected Bloom''s Taxonomy levels for this curriculum mapping';

-- ============================================================================
-- 13. COMPREHENSIVE INDEXES
-- ============================================================================
-- All indexes for query optimization across the AI generation engine.
-- Includes B-tree for standard lookups and GIN for JSONB/full-text.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- ai_providers_config indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_providers_config_provider
  ON ai_providers_config (provider);
CREATE INDEX IF NOT EXISTS idx_ai_providers_config_is_active
  ON ai_providers_config (is_active) WHERE is_active = true;

-- ---------------------------------------------------------------------------
-- prompt_templates indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_prompt_templates_prompt_type
  ON prompt_templates (prompt_type);
CREATE INDEX IF NOT EXISTS idx_prompt_templates_provider
  ON prompt_templates (provider) WHERE provider IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_subject_id
  ON prompt_templates (subject_id) WHERE subject_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_curriculum
  ON prompt_templates (curriculum) WHERE curriculum IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_question_type
  ON prompt_templates (question_type) WHERE question_type IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_is_active
  ON prompt_templates (is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_is_default
  ON prompt_templates (is_default) WHERE is_default = true;
CREATE INDEX IF NOT EXISTS idx_prompt_templates_quality_score
  ON prompt_templates (quality_score DESC);
CREATE INDEX IF NOT EXISTS idx_prompt_templates_school_id
  ON prompt_templates (school_id) WHERE school_id IS NOT NULL;
-- GIN index for template variables (JSONB array queries)
CREATE INDEX IF NOT EXISTS idx_prompt_templates_variables_gin
  ON prompt_templates USING GIN (variables jsonb_path_ops);
-- Composite index for common lookup: find active template by type+provider
CREATE INDEX IF NOT EXISTS idx_prompt_templates_type_provider_active
  ON prompt_templates (prompt_type, provider, is_active)
  WHERE is_active = true;

-- ---------------------------------------------------------------------------
-- ai_generation_requests indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_school_id
  ON ai_generation_requests (school_id);
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_requested_by
  ON ai_generation_requests (requested_by);
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_provider
  ON ai_generation_requests (provider);
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_status
  ON ai_generation_requests (status);
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_created_at
  ON ai_generation_requests (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_priority
  ON ai_generation_requests (priority DESC, created_at ASC);
-- GIN index for input_params JSONB queries
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_input_params_gin
  ON ai_generation_requests USING GIN (input_params jsonb_path_ops);
-- Composite: find pending/processing requests for a school
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_school_status
  ON ai_generation_requests (school_id, status, created_at DESC);
-- Composite: find by template for quality tracking
CREATE INDEX IF NOT EXISTS idx_ai_gen_req_template_id
  ON ai_generation_requests (prompt_template_id)
  WHERE prompt_template_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- ai_generated_questions indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_gen_request_id
  ON ai_generated_questions (generation_request_id);
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_school_id
  ON ai_generated_questions (school_id);
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_question_type
  ON ai_generated_questions (question_type);
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_difficulty
  ON ai_generated_questions (difficulty);
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_review_status
  ON ai_generated_questions (review_status);
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_created_at
  ON ai_generated_questions (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_question_bank_id
  ON ai_generated_questions (question_bank_id)
  WHERE question_bank_id IS NOT NULL;
-- Composite: pending reviews for a school
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_school_review
  ON ai_generated_questions (school_id, review_status, created_at DESC)
  WHERE review_status = 'pending';
-- Bloom level for curriculum analytics
CREATE INDEX IF NOT EXISTS idx_ai_gen_q_bloom_level
  ON ai_generated_questions (bloom_level)
  WHERE bloom_level IS NOT NULL;

-- ---------------------------------------------------------------------------
-- ai_validation_results indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_val_res_gen_question_id
  ON ai_validation_results (generated_question_id);
CREATE INDEX IF NOT EXISTS idx_ai_val_res_severity
  ON ai_validation_results (severity);
CREATE INDEX IF NOT EXISTS idx_ai_val_res_is_resolved
  ON ai_validation_results (is_resolved)
  WHERE is_resolved = false;
-- Composite: unresolved critical/error findings
CREATE INDEX IF NOT EXISTS idx_ai_val_res_unresolved_severity
  ON ai_validation_results (severity, is_resolved, created_at DESC)
  WHERE is_resolved = false AND severity IN ('error', 'critical');

-- ---------------------------------------------------------------------------
-- ai_question_improvements indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_qi_gen_question_id
  ON ai_question_improvements (generated_question_id);
CREATE INDEX IF NOT EXISTS idx_ai_qi_improvement_type
  ON ai_question_improvements (improvement_type);
CREATE INDEX IF NOT EXISTS idx_ai_qi_is_accepted
  ON ai_question_improvements (is_accepted)
  WHERE is_accepted = true;
CREATE INDEX IF NOT EXISTS idx_ai_qi_created_by
  ON ai_question_improvements (created_by);

-- ---------------------------------------------------------------------------
-- ai_document_uploads indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_doc_uploads_school_id
  ON ai_document_uploads (school_id);
CREATE INDEX IF NOT EXISTS idx_ai_doc_uploads_uploaded_by
  ON ai_document_uploads (uploaded_by);
CREATE INDEX IF NOT EXISTS idx_ai_doc_uploads_status
  ON ai_document_uploads (status);
-- Composite: pending documents for processing
CREATE INDEX IF NOT EXISTS idx_ai_doc_uploads_pending
  ON ai_document_uploads (status, created_at ASC)
  WHERE status IN ('pending', 'processing');

-- ---------------------------------------------------------------------------
-- ai_generation_queue indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_gen_queue_status
  ON ai_generation_queue (status);
-- Composite: fetch next job by priority (the main dequeue query)
CREATE INDEX IF NOT EXISTS idx_ai_gen_queue_dequeue
  ON ai_generation_queue (status, priority DESC, next_attempt_at ASC)
  WHERE status IN ('queued', 'failed');
-- Dead letter review
CREATE INDEX IF NOT EXISTS idx_ai_gen_queue_dead_letter
  ON ai_generation_queue (created_at DESC)
  WHERE status = 'dead_letter';

-- ---------------------------------------------------------------------------
-- ai_usage_stats indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_usage_stats_school_id
  ON ai_usage_stats (school_id);
CREATE INDEX IF NOT EXISTS idx_ai_usage_stats_date
  ON ai_usage_stats (date DESC);
CREATE INDEX IF NOT EXISTS idx_ai_usage_stats_provider
  ON ai_usage_stats (provider);
-- Composite: school usage over time
CREATE INDEX IF NOT EXISTS idx_ai_usage_stats_school_date
  ON ai_usage_stats (school_id, date DESC);
-- Composite: provider usage over time
CREATE INDEX IF NOT EXISTS idx_ai_usage_stats_provider_date
  ON ai_usage_stats (provider, date DESC);

-- ---------------------------------------------------------------------------
-- ai_api_keys indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_ai_api_keys_school_id
  ON ai_api_keys (school_id);
CREATE INDEX IF NOT EXISTS idx_ai_api_keys_provider
  ON ai_api_keys (provider);
CREATE INDEX IF NOT EXISTS idx_ai_api_keys_is_active
  ON ai_api_keys (is_active) WHERE is_active = true;

-- ---------------------------------------------------------------------------
-- curriculum_mappings indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_curriculum_mappings_curriculum
  ON curriculum_mappings (curriculum);
CREATE INDEX IF NOT EXISTS idx_curriculum_mappings_subject_id
  ON curriculum_mappings (subject_id);
CREATE INDEX IF NOT EXISTS idx_curriculum_mappings_topic_id
  ON curriculum_mappings (topic_id) WHERE topic_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_curriculum_mappings_class_level
  ON curriculum_mappings (class_level);
CREATE INDEX IF NOT EXISTS idx_curriculum_mappings_is_active
  ON curriculum_mappings (is_active) WHERE is_active = true;
-- Composite: lookup by curriculum + subject + class
CREATE INDEX IF NOT EXISTS idx_curriculum_mappings_curr_subj_class
  ON curriculum_mappings (curriculum, subject_id, class_level)
  WHERE is_active = true;

-- ============================================================================
-- 14. ROW LEVEL SECURITY (RLS)
-- ============================================================================
-- Enable RLS on all tables and define policies for role-based access.
-- Policy hierarchy: super_admin > school_admin > teacher > student
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Helper: Enable RLS on all AI engine tables
-- ---------------------------------------------------------------------------
ALTER TABLE ai_providers_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE prompt_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_generation_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_generated_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_validation_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_question_improvements ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_document_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_generation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_usage_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_api_keys ENABLE ROW LEVEL SECURITY;
ALTER TABLE curriculum_mappings ENABLE ROW LEVEL SECURITY;

-- ===========================================================================
-- ai_providers_config RLS
-- Super admins: full CRUD
-- School admins: read all
-- Others: read active only
-- ===========================================================================
CREATE POLICY ai_providers_config_super_admin_all ON ai_providers_config
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

CREATE POLICY ai_providers_config_school_admin_read ON ai_providers_config
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin')
  );

CREATE POLICY ai_providers_config_others_read_active ON ai_providers_config
  FOR SELECT
  USING (
    is_active = true
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid())
  );

-- ===========================================================================
-- prompt_templates RLS
-- All authenticated: read
-- Teachers: create own, update own
-- School admins: manage school templates
-- Super admins: manage all
-- ===========================================================================
CREATE POLICY prompt_templates_authenticated_read ON prompt_templates
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid())
  );

CREATE POLICY prompt_templates_teacher_create ON prompt_templates
  FOR INSERT
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('teacher', 'school_admin', 'super_admin'))
  );

CREATE POLICY prompt_templates_teacher_update_own ON prompt_templates
  FOR UPDATE
  USING (
    created_by = auth.uid()
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'teacher')
  );

CREATE POLICY prompt_templates_school_admin_manage ON prompt_templates
  FOR UPDATE
  USING (
    school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin')
  );

CREATE POLICY prompt_templates_super_admin_all ON prompt_templates
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- ===========================================================================
-- ai_generation_requests RLS
-- Users: see their own requests
-- School admins: see school requests
-- Super admins: see all
-- ===========================================================================
CREATE POLICY ai_gen_req_user_own ON ai_generation_requests
  FOR SELECT
  USING (
    requested_by = auth.uid()
  );

CREATE POLICY ai_gen_req_school_admin ON ai_generation_requests
  FOR SELECT
  USING (
    school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin')
  );

CREATE POLICY ai_gen_req_super_admin ON ai_generation_requests
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- Allow authenticated users to create requests
CREATE POLICY ai_gen_req_authenticated_insert ON ai_generation_requests
  FOR INSERT
  WITH CHECK (
    requested_by = auth.uid()
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid())
  );

-- ===========================================================================
-- ai_generated_questions RLS
-- Same pattern as ai_generation_requests (inherits visibility from parent)
-- ===========================================================================
CREATE POLICY ai_gen_q_user_own ON ai_generated_questions
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ai_generation_requests
      WHERE ai_generation_requests.id = ai_generated_questions.generation_request_id
        AND ai_generation_requests.requested_by = auth.uid()
    )
  );

CREATE POLICY ai_gen_q_school_admin ON ai_generated_questions
  FOR SELECT
  USING (
    school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin')
  );

CREATE POLICY ai_gen_q_super_admin ON ai_generated_questions
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- Allow users with matching school to update (for review workflow)
CREATE POLICY ai_gen_q_school_admin_update ON ai_generated_questions
  FOR UPDATE
  USING (
    (school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
     AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin'))
    OR EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- ===========================================================================
-- ai_validation_results RLS
-- Same visibility as parent ai_generated_questions
-- ===========================================================================
CREATE POLICY ai_val_res_user_own ON ai_validation_results
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ai_generated_questions q
      JOIN ai_generation_requests r ON r.id = q.generation_request_id
      WHERE q.id = ai_validation_results.generated_question_id
        AND r.requested_by = auth.uid()
    )
  );

CREATE POLICY ai_val_res_school_admin ON ai_validation_results
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ai_generated_questions q
      WHERE q.id = ai_validation_results.generated_question_id
        AND q.school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    )
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY ai_val_res_super_admin ON ai_validation_results
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- ===========================================================================
-- ai_question_improvements RLS
-- Same visibility as parent ai_generated_questions
-- ===========================================================================
CREATE POLICY ai_qi_user_own ON ai_question_improvements
  FOR SELECT
  USING (
    created_by = auth.uid()
    OR EXISTS (
      SELECT 1 FROM ai_generated_questions q
      JOIN ai_generation_requests r ON r.id = q.generation_request_id
      WHERE q.id = ai_question_improvements.generated_question_id
        AND r.requested_by = auth.uid()
    )
  );

CREATE POLICY ai_qi_school_admin ON ai_question_improvements
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM ai_generated_questions q
      WHERE q.id = ai_question_improvements.generated_question_id
        AND q.school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    )
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('school_admin', 'super_admin'))
  );

CREATE POLICY ai_qi_super_admin ON ai_question_improvements
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- Allow authenticated users to create improvements
CREATE POLICY ai_qi_authenticated_insert ON ai_question_improvements
  FOR INSERT
  WITH CHECK (
    created_by = auth.uid()
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid())
  );

-- ===========================================================================
-- ai_document_uploads RLS
-- Users: see own uploads
-- School admins: see school uploads
-- Super admins: see all
-- ===========================================================================
CREATE POLICY ai_doc_uploads_user_own ON ai_document_uploads
  FOR SELECT
  USING (
    uploaded_by = auth.uid()
  );

CREATE POLICY ai_doc_uploads_school_admin ON ai_document_uploads
  FOR SELECT
  USING (
    school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin')
  );

CREATE POLICY ai_doc_uploads_super_admin ON ai_document_uploads
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- Allow authenticated users to upload documents
CREATE POLICY ai_doc_uploads_authenticated_insert ON ai_document_uploads
  FOR INSERT
  WITH CHECK (
    uploaded_by = auth.uid()
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid())
  );

-- ===========================================================================
-- ai_generation_queue RLS
-- Only system processes and super admins can access the queue
-- ===========================================================================
CREATE POLICY ai_gen_queue_super_admin ON ai_generation_queue
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- ===========================================================================
-- ai_usage_stats RLS
-- School admins: see school stats
-- Super admins: see all
-- ===========================================================================
CREATE POLICY ai_usage_stats_school_admin ON ai_usage_stats
  FOR SELECT
  USING (
    school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin')
  );

CREATE POLICY ai_usage_stats_super_admin ON ai_usage_stats
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- ===========================================================================
-- ai_api_keys RLS
-- Super admins: full CRUD
-- School admins: read own school keys
-- Others: no access
-- ===========================================================================
CREATE POLICY ai_api_keys_super_admin ON ai_api_keys
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

CREATE POLICY ai_api_keys_school_admin_read ON ai_api_keys
  FOR SELECT
  USING (
    school_id = (SELECT school_id FROM users WHERE users.id = auth.uid())
    AND EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'school_admin')
  );

-- ===========================================================================
-- curriculum_mappings RLS
-- All authenticated: read
-- Super admins: full CRUD
-- ===========================================================================
CREATE POLICY curriculum_mappings_authenticated_read ON curriculum_mappings
  FOR SELECT
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid())
  );

CREATE POLICY curriculum_mappings_super_admin_all ON curriculum_mappings
  FOR ALL
  USING (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'super_admin')
  );

-- ============================================================================
-- 15. HELPER FUNCTIONS
-- ============================================================================
-- Core business logic functions for the AI generation engine.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- updated_at auto-update trigger function (reusable)
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_updated_at_column IS 'Reusable trigger function that sets updated_at to the current timestamp on every row update';

-- ---------------------------------------------------------------------------
-- calculate_generation_cost()
-- Compute cost for an AI generation request based on provider/model rates
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_generation_cost(
  p_provider     ai_provider,
  p_model_name   TEXT,
  p_input_tokens INTEGER,
  p_output_tokens INTEGER
)
RETURNS NUMERIC(10,6) AS $$
DECLARE
  v_input_cost  NUMERIC(10,6);
  v_output_cost NUMERIC(10,6);
BEGIN
  -- Look up per-1k token rates from the provider config
  SELECT
    cost_per_1k_input_tokens,
    cost_per_1k_output_tokens
  INTO
    v_input_cost,
    v_output_cost
  FROM ai_providers_config
  WHERE provider = p_provider
    AND model_name = p_model_name
    AND is_active = true
  LIMIT 1;

  -- Fallback to zero if provider not found
  IF v_input_cost IS NULL THEN
    v_input_cost := 0.0;
    v_output_cost := 0.0;
  END IF;

  -- Calculate: (tokens / 1000) * rate per 1k tokens
  RETURN (p_input_tokens::NUMERIC / 1000.0 * v_input_cost)
       + (p_output_tokens::NUMERIC / 1000.0 * v_output_cost);
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION calculate_generation_cost IS 'Compute cost for an AI generation request based on provider/model per-1k token rates';

-- ---------------------------------------------------------------------------
-- process_generation_queue()
-- Process the next item in the generation queue.
-- Returns the generation_request_id of the processed item, or NULL if empty.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION process_generation_queue()
RETURNS UUID AS $$
DECLARE
  v_queue_item        RECORD;
  v_generation_req_id UUID;
BEGIN
  -- Atomically select and lock the next highest-priority, due item
  SELECT * INTO v_queue_item
  FROM ai_generation_queue
  WHERE status IN ('queued', 'failed')
    AND next_attempt_at <= now()
    AND attempts < max_attempts
  ORDER BY priority DESC, next_attempt_at ASC
  LIMIT 1
  FOR UPDATE SKIP LOCKED;

  -- Nothing to process
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  -- Mark queue item as processing
  UPDATE ai_generation_queue
  SET
    status      = 'processing',
    attempts    = attempts + 1,
    updated_at  = now()
  WHERE id = v_queue_item.id;

  -- Update the generation request status to processing
  UPDATE ai_generation_requests
  SET
    status     = 'processing',
    started_at = now()
  WHERE id = v_queue_item.generation_request_id;

  RETURN v_queue_item.generation_request_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION process_generation_queue IS 'Atomically dequeue and lock the next highest-priority generation job for processing. Returns the generation_request_id or NULL if queue is empty.';

-- ---------------------------------------------------------------------------
-- update_prompt_quality_score()
-- Recalculate the quality_score for a prompt template based on
-- the ratio of successful generations (completed + approved questions)
-- to total generations using this template.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION update_prompt_quality_score(
  p_template_id UUID
)
RETURNS VOID AS $$
DECLARE
  v_total_generations  INTEGER;
  v_successful         INTEGER;
  v_new_success_rate   NUMERIC(5,2);
  v_new_quality_score  NUMERIC(3,2);
BEGIN
  -- Count total and successful generations for this template
  SELECT
    COUNT(*),
    COUNT(*) FILTER (
      WHERE status = 'completed'
        AND EXISTS (
          SELECT 1 FROM ai_generated_questions q
          WHERE q.generation_request_id = ai_generation_requests.id
            AND q.review_status IN ('approved', 'needs_revision')
        )
    )
  INTO
    v_total_generations,
    v_successful
  FROM ai_generation_requests
  WHERE prompt_template_id = p_template_id;

  -- Calculate success rate (percentage)
  IF v_total_generations > 0 THEN
    v_new_success_rate := ROUND(
      (v_successful::NUMERIC / v_total_generations::NUMERIC) * 100.0,
      2
    );
  ELSE
    v_new_success_rate := 0.00;
  END IF;

  -- Map success rate to quality score (0-5 scale)
  -- Simple linear mapping: quality_score = success_rate / 20
  v_new_quality_score := ROUND(v_new_success_rate / 20.0, 2);

  -- Update the template
  UPDATE prompt_templates
  SET
    success_rate   = v_new_success_rate,
    quality_score  = v_new_quality_score,
    usage_count    = v_total_generations,
    updated_at     = now()
  WHERE id = p_template_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_prompt_quality_score IS 'Recalculate quality_score and success_rate for a prompt template based on historical generation outcomes';

-- ---------------------------------------------------------------------------
-- approve_generated_question()
-- Approve an AI-generated question and optionally promote it to question_bank.
-- Sets review_status to 'approved', records the reviewer, and if
-- p_save_to_bank = true, creates a question_bank entry and links it.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION approve_generated_question(
  p_question_id  UUID,
  p_reviewer_id  UUID,
  p_review_notes TEXT DEFAULT NULL,
  p_save_to_bank BOOLEAN DEFAULT true
)
RETURNS UUID AS $$
DECLARE
  v_gen_question  RECORD;
  v_question_bank_id UUID;
BEGIN
  -- Fetch the generated question
  SELECT * INTO v_gen_question
  FROM ai_generated_questions
  WHERE id = p_question_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'AI generated question % not found', p_question_id;
  END IF;

  -- Update the generated question as approved
  UPDATE ai_generated_questions
  SET
    review_status = 'approved',
    reviewed_by   = p_reviewer_id,
    reviewed_at   = now(),
    review_notes  = COALESCE(p_review_notes, review_notes),
    is_approved   = true,
    updated_at    = now()
  WHERE id = p_question_id;

  -- Optionally promote to question_bank
  IF p_save_to_bank AND v_gen_question.question_bank_id IS NULL THEN
    INSERT INTO question_bank (
      school_id,
      subject_id,
      topic_id,
      subtopic_id,
      question_type,
      difficulty,
      content,
      content_json,
      explanation,
      marks,
      time_allowed_seconds,
      is_published,
      created_by,
      metadata
    ) VALUES (
      v_gen_question.school_id,
      (v_gen_question.generation_request_id::TEXT)::UUID,  -- placeholder; will be corrected below
      NULL,   -- topic_id — not available directly on generated question
      NULL,   -- subtopic_id
      v_gen_question.question_type,
      v_gen_question.difficulty,
      v_gen_question.content,
      v_gen_question.content_json,
      v_gen_question.explanation,
      v_gen_question.marks,
      v_gen_question.estimated_time_seconds,
      false,  -- not published until explicitly published
      p_reviewer_id,
      jsonb_build_object(
        'source', 'ai_generation',
        'ai_question_id', p_question_id,
        'bloom_level', v_gen_question.bloom_level,
        'confidence_score', v_gen_question.confidence_score
      )
    )
    ON CONFLICT DO NOTHING
    RETURNING id INTO v_question_bank_id;

    -- If we got a question_bank_id, link it back and create answer options
    IF v_question_bank_id IS NOT NULL THEN
      -- Fix: Update with proper subject_id from the generation request
      UPDATE question_bank
      SET subject_id = gr.input_params->>'subject_id'
      FROM ai_generation_requests gr
      WHERE gr.id = v_gen_question.generation_request_id
        AND question_bank.id = v_question_bank_id;

      -- Link back to the generated question
      UPDATE ai_generated_questions
      SET question_bank_id = v_question_bank_id,
          updated_at = now()
      WHERE id = p_question_id;

      -- Create answer_options rows from the JSONB answer_options array
      INSERT INTO answer_options (question_id, content, is_correct, explanation, marks, sort_order)
      SELECT
        v_question_bank_id,
        (opt->>'content')::TEXT,
        COALESCE((opt->>'isCorrect')::BOOLEAN, false),
        opt->>'explanation',
        COALESCE((opt->>'marks')::NUMERIC, 0.00),
        ROW_NUMBER() OVER () - 1
      FROM jsonb_array_elements(v_gen_question.answer_options) AS opt
      WHERE v_gen_question.answer_options IS NOT NULL
        AND jsonb_array_length(v_gen_question.answer_options) > 0;
    END IF;
  END IF;

  -- Resolve any pending validation results for this question
  UPDATE ai_validation_results
  SET
    is_resolved = true,
    resolved_by = p_reviewer_id,
    resolved_at = now()
  WHERE generated_question_id = p_question_id
    AND is_resolved = false;

  -- Update usage stats: increment questions_approved for today
  INSERT INTO ai_usage_stats (school_id, provider, model_name, date, questions_approved)
  SELECT
    gr.school_id,
    gr.provider,
    gr.model_name,
    CURRENT_DATE,
    1
  FROM ai_generation_requests gr
  WHERE gr.id = v_gen_question.generation_request_id
  ON CONFLICT (school_id, provider, model_name, date)
  DO UPDATE SET questions_approved = ai_usage_stats.questions_approved + 1;

  RETURN v_question_bank_id;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION approve_generated_question IS 'Approve an AI-generated question, optionally promoting it to question_bank with answer options. Resolves pending validations and updates usage stats.';

-- ---------------------------------------------------------------------------
-- reject_generated_question()
-- Reject an AI-generated question with a reason.
-- Sets review_status to 'rejected' and updates usage stats.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION reject_generated_question(
  p_question_id  UUID,
  p_reviewer_id  UUID,
  p_reason       TEXT
)
RETURNS VOID AS $$
DECLARE
  v_gen_question RECORD;
BEGIN
  -- Fetch the generated question
  SELECT * INTO v_gen_question
  FROM ai_generated_questions
  WHERE id = p_question_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'AI generated question % not found', p_question_id;
  END IF;

  -- Update the generated question as rejected
  UPDATE ai_generated_questions
  SET
    review_status = 'rejected',
    reviewed_by   = p_reviewer_id,
    reviewed_at   = now(),
    review_notes  = p_reason,
    is_approved   = false,
    updated_at    = now()
  WHERE id = p_question_id;

  -- Update usage stats: increment questions_rejected for today
  INSERT INTO ai_usage_stats (school_id, provider, model_name, date, questions_rejected)
  SELECT
    gr.school_id,
    gr.provider,
    gr.model_name,
    CURRENT_DATE,
    1
  FROM ai_generation_requests gr
  WHERE gr.id = v_gen_question.generation_request_id
  ON CONFLICT (school_id, provider, model_name, date)
  DO UPDATE SET questions_rejected = ai_usage_stats.questions_rejected + 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION reject_generated_question IS 'Reject an AI-generated question with a reason and update usage stats';

-- ---------------------------------------------------------------------------
-- get_curriculum_alignment()
-- Retrieve curriculum mapping(s) for a given curriculum, subject, and topic.
-- Returns the most specific match (subtopic > topic > subject level).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_curriculum_alignment(
  p_curriculum curriculum_type,
  p_subject_id UUID,
  p_topic_id   UUID DEFAULT NULL
)
RETURNS SETOF curriculum_mappings AS $$
BEGIN
  -- Prefer subtopic-level mappings, then topic-level, then subject-level
  RETURN QUERY
  SELECT cm.*
  FROM curriculum_mappings cm
  WHERE cm.curriculum = p_curriculum
    AND cm.subject_id = p_subject_id
    AND cm.is_active = true
    AND (
      -- Subtopic-level match (most specific)
      (p_topic_id IS NOT NULL AND cm.topic_id = p_topic_id)
      OR
      -- Topic-level match
      (p_topic_id IS NOT NULL AND cm.topic_id = p_topic_id AND cm.subtopic_id IS NULL)
      OR
      -- Subject-level match (least specific)
      (cm.topic_id IS NULL AND cm.subtopic_id IS NULL)
    )
  ORDER BY
    -- Most specific first: subtopic > topic > subject
    CASE
      WHEN cm.subtopic_id IS NOT NULL THEN 0
      WHEN cm.topic_id IS NOT NULL THEN 1
      ELSE 2
    END ASC;
END;
$$ LANGUAGE plpgsql STABLE;

COMMENT ON FUNCTION get_curriculum_alignment IS 'Retrieve curriculum mappings for a curriculum/subject/topic, preferring most specific (subtopic > topic > subject) matches';

-- ============================================================================
-- 16. TRIGGERS
-- ============================================================================
-- Auto-update triggers for updated_at, cost calculation, usage stats,
-- and prompt template metrics.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Auto-update updated_at on all relevant tables
-- ---------------------------------------------------------------------------
CREATE TRIGGER trg_ai_providers_config_updated_at
  BEFORE UPDATE ON ai_providers_config
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_prompt_templates_updated_at
  BEFORE UPDATE ON prompt_templates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_ai_generated_questions_updated_at
  BEFORE UPDATE ON ai_generated_questions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_ai_generation_queue_updated_at
  BEFORE UPDATE ON ai_generation_queue
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_ai_api_keys_updated_at
  BEFORE UPDATE ON ai_api_keys
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_curriculum_mappings_updated_at
  BEFORE UPDATE ON curriculum_mappings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ---------------------------------------------------------------------------
-- Auto-calculate cost when a generation request's token counts are updated
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_calculate_generation_cost()
RETURNS TRIGGER AS $$
BEGIN
  -- Only recalculate when token counts change or on insert with token counts
  IF (TG_OP = 'INSERT' AND (NEW.input_tokens > 0 OR NEW.output_tokens > 0))
     OR (TG_OP = 'UPDATE' AND (NEW.input_tokens IS DISTINCT FROM OLD.input_tokens
                                OR NEW.output_tokens IS DISTINCT FROM OLD.output_tokens)) THEN
    NEW.total_cost := calculate_generation_cost(
      NEW.provider,
      NEW.model_name,
      NEW.input_tokens,
      NEW.output_tokens
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ai_gen_req_calculate_cost
  BEFORE INSERT OR UPDATE OF input_tokens, output_tokens ON ai_generation_requests
  FOR EACH ROW
  EXECUTE FUNCTION trg_calculate_generation_cost();

COMMENT ON FUNCTION trg_calculate_generation_cost IS 'Trigger function to auto-calculate total_cost when token counts change on ai_generation_requests';

-- ---------------------------------------------------------------------------
-- Auto-update usage stats when a generation request completes
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_update_usage_stats_on_completion()
RETURNS TRIGGER AS $$
BEGIN
  -- Only fire when status transitions TO completed or failed
  IF NEW.status IN ('completed', 'failed') AND OLD.status NOT IN ('completed', 'failed') THEN
    INSERT INTO ai_usage_stats (
      school_id, provider, model_name, date,
      total_requests,
      successful_requests,
      failed_requests,
      total_input_tokens,
      total_output_tokens,
      total_cost,
      avg_generation_time_ms,
      questions_generated
    )
    VALUES (
      NEW.school_id,
      NEW.provider,
      NEW.model_name,
      COALESCE(NEW.completed_at::DATE, CURRENT_DATE),
      1,   -- total_requests
      CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END,
      CASE WHEN NEW.status = 'failed' THEN 1 ELSE 0 END,
      NEW.input_tokens,
      NEW.output_tokens,
      NEW.total_cost,
      COALESCE(NEW.generation_time_ms, 0),
      CASE WHEN NEW.status = 'completed' THEN
        (SELECT COUNT(*) FROM ai_generated_questions q WHERE q.generation_request_id = NEW.id)
      ELSE 0 END
    )
    ON CONFLICT (school_id, provider, model_name, date)
    DO UPDATE SET
      total_requests = ai_usage_stats.total_requests + 1,
      successful_requests = ai_usage_stats.successful_requests
        + CASE WHEN NEW.status = 'completed' THEN 1 ELSE 0 END,
      failed_requests = ai_usage_stats.failed_requests
        + CASE WHEN NEW.status = 'failed' THEN 1 ELSE 0 END,
      total_input_tokens = ai_usage_stats.total_input_tokens + NEW.input_tokens,
      total_output_tokens = ai_usage_stats.total_output_tokens + NEW.output_tokens,
      total_cost = ai_usage_stats.total_cost + NEW.total_cost,
      avg_generation_time_ms = CASE
        WHEN ai_usage_stats.total_requests = 0 THEN COALESCE(NEW.generation_time_ms, 0)
        ELSE (
          (ai_usage_stats.avg_generation_time_ms * ai_usage_stats.total_requests + COALESCE(NEW.generation_time_ms, 0))
          / (ai_usage_stats.total_requests + 1)
        )
      END,
      questions_generated = ai_usage_stats.questions_generated
        + CASE WHEN NEW.status = 'completed' THEN
            (SELECT COUNT(*) FROM ai_generated_questions q WHERE q.generation_request_id = NEW.id)
          ELSE 0 END;

    -- Also update the generation queue item status
    UPDATE ai_generation_queue
    SET
      status = CASE
        WHEN NEW.status = 'completed' THEN 'completed'
        WHEN NEW.status = 'failed' AND attempts >= max_attempts THEN 'dead_letter'
        WHEN NEW.status = 'failed' THEN 'failed'
        ELSE status
      END,
      error_message = NEW.error_message,
      next_attempt_at = CASE
        WHEN NEW.status = 'failed' AND attempts < max_attempts
        THEN now() + (POWER(2, attempts) || ' minutes')::INTERVAL  -- Exponential backoff
        ELSE next_attempt_at
      END,
      updated_at = now()
    WHERE generation_request_id = NEW.id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ai_gen_req_update_usage_stats
  AFTER UPDATE OF status ON ai_generation_requests
  FOR EACH ROW
  WHEN (NEW.status IN ('completed', 'failed') AND OLD.status NOT IN ('completed', 'failed'))
  EXECUTE FUNCTION trg_update_usage_stats_on_completion();

COMMENT ON FUNCTION trg_update_usage_stats_on_completion IS 'Trigger function to update daily usage stats and queue status when a generation request completes or fails';

-- ---------------------------------------------------------------------------
-- Auto-update prompt template usage_count and success_rate
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_update_prompt_template_metrics()
RETURNS TRIGGER AS $$
BEGIN
  -- When a generation request completes, update the associated template metrics
  IF NEW.prompt_template_id IS NOT NULL AND NEW.status = 'completed' THEN
    PERFORM update_prompt_quality_score(NEW.prompt_template_id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_ai_gen_req_update_template_metrics
  AFTER UPDATE OF status ON ai_generation_requests
  FOR EACH ROW
  WHEN (NEW.status = 'completed' AND OLD.status != 'completed' AND NEW.prompt_template_id IS NOT NULL)
  EXECUTE FUNCTION trg_update_prompt_template_metrics();

COMMENT ON FUNCTION trg_update_prompt_template_metrics IS 'Trigger function to update prompt template quality_score and success_rate when a generation request completes';

-- ============================================================================
-- 17. SEED DATA FOR AI PROVIDERS CONFIG
-- ============================================================================
-- Pre-populate with common AI provider/model configurations.
-- These can be customized per deployment.
-- ============================================================================

INSERT INTO ai_providers_config (provider, display_name, model_name, api_endpoint, max_tokens, temperature, top_p, cost_per_1k_input_tokens, cost_per_1k_output_tokens, supports_streaming, supports_function_calling, supports_vision, rate_limit_per_minute, config)
VALUES
  (
    'openai',
    'OpenAI GPT-4o',
    'gpt-4o',
    'https://api.openai.com/v1/chat/completions',
    4096, 0.70, 0.95,
    0.002500, 0.010000,
    true, true, true, 60,
    '{"api_version": "2024-01-01"}'
  ),
  (
    'openai',
    'OpenAI GPT-4o Mini',
    'gpt-4o-mini',
    'https://api.openai.com/v1/chat/completions',
    4096, 0.70, 0.95,
    0.000150, 0.000600,
    true, true, true, 60,
    '{"api_version": "2024-01-01"}'
  ),
  (
    'gemini',
    'Google Gemini 1.5 Pro',
    'gemini-1.5-pro',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-pro:generateContent',
    4096, 0.70, 0.95,
    0.001250, 0.005000,
    true, true, true, 60,
    '{"api_version": "v1beta"}'
  ),
  (
    'gemini',
    'Google Gemini 1.5 Flash',
    'gemini-1.5-flash',
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent',
    4096, 0.70, 0.95,
    0.000075, 0.000300,
    true, true, true, 60,
    '{"api_version": "v1beta"}'
  ),
  (
    'claude',
    'Anthropic Claude 3.5 Sonnet',
    'claude-3-5-sonnet-20241022',
    'https://api.anthropic.com/v1/messages',
    4096, 0.70, 0.95,
    0.003000, 0.015000,
    true, true, true, 60,
    '{"api_version": "2023-06-01"}'
  ),
  (
    'claude',
    'Anthropic Claude 3 Haiku',
    'claude-3-haiku-20240307',
    'https://api.anthropic.com/v1/messages',
    4096, 0.70, 0.95,
    0.000250, 0.001250,
    true, true, true, 60,
    '{"api_version": "2023-06-01"}'
  ),
  (
    'deepseek',
    'DeepSeek Chat',
    'deepseek-chat',
    'https://api.deepseek.com/v1/chat/completions',
    4096, 0.70, 0.95,
    0.000140, 0.000280,
    true, false, false, 60,
    '{}'
  ),
  (
    'grok',
    'xAI Grok-2',
    'grok-2',
    'https://api.x.ai/v1/chat/completions',
    4096, 0.70, 0.95,
    0.002000, 0.010000,
    true, true, false, 60,
    '{}'
  ),
  (
    'local_llm',
    'Local LLM (Ollama)',
    'local-default',
    'http://localhost:11434/api/generate',
    4096, 0.70, 0.95,
    0.000000, 0.000000,
    false, false, false, 120,
    '{"type": "ollama"}'
  )
ON CONFLICT (provider, model_name) DO NOTHING;

-- ============================================================================
-- 18. SEED DATA FOR DEFAULT PROMPT TEMPLATES
-- ============================================================================
-- Pre-populate with core prompt templates for question generation.
-- These serve as starting defaults that schools can customize.
-- ============================================================================

-- MCQ Generation Template (platform-wide default)
INSERT INTO prompt_templates (
  name, description, prompt_type, question_type, difficulty, bloom_level,
  language, system_prompt, user_prompt_template, variables, few_shot_examples,
  chain_of_thought, output_format, is_active, is_default, version, quality_score
) VALUES (
  'MCQ Generation - Default',
  'Default platform-wide template for generating multiple-choice questions. Works with any provider and curriculum.',
  'question_generation',
  'multiple_choice',
  NULL,
  NULL,
  'en',
  'You are an expert educational assessment designer. You create high-quality multiple-choice questions that are clear, accurate, and aligned with educational standards. Each question must have exactly one correct answer and three plausible distractors. Distractors should represent common misconceptions or partial understanding, not be obviously wrong. All content must be factually accurate and pedagogically sound.',
  'Generate {{num_questions}} multiple-choice questions on the topic of "{{topic}}" for the subject "{{subject}}" at the {{difficulty}} difficulty level{{#bloom_level}} targeting the "{{bloom_level}}" level of Bloom''s Taxonomy{{/bloom_level}}{{#exam_type}} for {{exam_type}} preparation{{/exam_type}}{{#class_level}} for {{class_level}} students{{/class_level}}.

Requirements:
- Each question must have exactly 4 options (A, B, C, D) with only one correct answer
- Distractors should be plausible and reflect common misconceptions
- Include a detailed explanation for why the correct answer is right and why each distractor is wrong
- Questions should be clear, unambiguous, and free of grammatical errors
- Avoid "all of the above" or "none of the above" options
{{#keywords}}- Incorporate these key concepts: {{keywords}}{{/keywords}}
{{#custom_instructions}}- Additional instructions: {{custom_instructions}}{{/custom_instructions}}

Respond in the following JSON format:
{
  "questions": [
    {
      "content": "The question text",
      "answer_options": [
        {"content": "Option A text", "isCorrect": true, "explanation": "Why this is correct", "marks": 1},
        {"content": "Option B text", "isCorrect": false, "explanation": "Why this is a distractor", "marks": 0},
        {"content": "Option C text", "isCorrect": false, "explanation": "Why this is a distractor", "marks": 0},
        {"content": "Option D text", "isCorrect": false, "explanation": "Why this is a distractor", "marks": 0}
      ],
      "explanation": "Overall explanation of the concept being tested",
      "bloom_level": "remember|understand|apply|analyze|evaluate|create",
      "difficulty": "easy|medium|hard|expert",
      "estimated_time_seconds": 60,
      "marks": 1,
      "confidence_score": 0.95
    }
  ]
}',
  '[
    {"name": "subject", "description": "The subject area (e.g., Mathematics, Physics)", "required": true, "default": null},
    {"name": "topic", "description": "The specific topic within the subject", "required": true, "default": null},
    {"name": "num_questions", "description": "Number of questions to generate", "required": true, "default": "5"},
    {"name": "difficulty", "description": "Target difficulty level (easy, medium, hard, expert)", "required": true, "default": "medium"},
    {"name": "bloom_level", "description": "Target Bloom''s Taxonomy level", "required": false, "default": null},
    {"name": "exam_type", "description": "Exam context (waec, neco, jamb, etc.)", "required": false, "default": null},
    {"name": "class_level", "description": "Target class level (e.g., SS1, JSS2)", "required": false, "default": null},
    {"name": "keywords", "description": "Comma-separated key concepts to include", "required": false, "default": null},
    {"name": "custom_instructions", "description": "Additional custom instructions", "required": false, "default": null}
  ]'::jsonb,
  '[
    {
      "input": {"subject": "Mathematics", "topic": "Quadratic Equations", "num_questions": 1, "difficulty": "medium"},
      "output": {
        "questions": [{
          "content": "Solve the equation x² - 5x + 6 = 0.",
          "answer_options": [
            {"content": "x = 2 or x = 3", "isCorrect": true, "explanation": "Factoring gives (x-2)(x-3) = 0, so x = 2 or x = 3", "marks": 1},
            {"content": "x = -2 or x = -3", "isCorrect": false, "explanation": "The signs are incorrect; the factors are (x-2)(x-3), not (x+2)(x+3)", "marks": 0},
            {"content": "x = 1 or x = 6", "isCorrect": false, "explanation": "While 1×6 = 6, the sum 1+6 = 7 ≠ 5", "marks": 0},
            {"content": "x = -1 or x = -6", "isCorrect": false, "explanation": "The product would be 6 but both signs and sum are incorrect", "marks": 0}
          ],
          "explanation": "This question tests the ability to solve quadratic equations by factoring.",
          "bloom_level": "apply",
          "difficulty": "medium",
          "estimated_time_seconds": 60,
          "marks": 1,
          "confidence_score": 0.98
        }]
      }
    }
  ]'::jsonb,
  true,
  '{
    "type": "object",
    "required": ["questions"],
    "properties": {
      "questions": {
        "type": "array",
        "items": {
          "type": "object",
          "required": ["content", "answer_options", "explanation", "bloom_level", "difficulty", "marks"],
          "properties": {
            "content": {"type": "string"},
            "answer_options": {
              "type": "array",
              "minItems": 4,
              "maxItems": 4,
              "items": {
                "type": "object",
                "required": ["content", "isCorrect", "explanation", "marks"],
                "properties": {
                  "content": {"type": "string"},
                  "isCorrect": {"type": "boolean"},
                  "explanation": {"type": "string"},
                  "marks": {"type": "number"}
                }
              }
            },
            "explanation": {"type": "string"},
            "bloom_level": {"type": "string", "enum": ["remember", "understand", "apply", "analyze", "evaluate", "create"]},
            "difficulty": {"type": "string", "enum": ["easy", "medium", "hard", "expert"]},
            "estimated_time_seconds": {"type": "integer"},
            "marks": {"type": "number"},
            "confidence_score": {"type": "number"}
          }
        }
      }
    }
  }'::jsonb,
  true, true, 1, 3.50
);

-- Explanation Generation Template
INSERT INTO prompt_templates (
  name, description, prompt_type, language, system_prompt, user_prompt_template,
  variables, is_active, is_default, version, quality_score
) VALUES (
  'Explanation Generation - Default',
  'Generate detailed explanations for existing questions, including why the correct answer is right and why distractors are wrong.',
  'explanation_generation',
  'en',
  'You are an expert educational content writer. You create clear, comprehensive explanations that help students understand not just what the correct answer is, but why it is correct and why other options are not. Your explanations should be pedagogically sound and accessible to the target audience.',
  'Generate a detailed explanation for the following question:

Subject: {{subject}}
Topic: {{topic}}
Question: {{question_content}}
Correct Answer: {{correct_answer}}
{{#distractors}}Distractors: {{distractors}}{{/distractors}}
{{#difficulty}}Difficulty Level: {{difficulty}}{{/difficulty}}
{{#class_level}}Target Class: {{class_level}}{{/class_level}}

Requirements:
- Explain why the correct answer is right with supporting reasoning
- Explain why each distractor is wrong (identify the misconception it represents)
- Use clear, age-appropriate language
- Include relevant formulas, definitions, or references where applicable
- The explanation should help a student who got the question wrong understand the concept

Respond in JSON format:
{
  "explanation": "The main explanation text",
  "correct_reasoning": "Why the correct answer is right",
  "distractor_analysis": [
    {"distractor": "text", "misconception": "what misconception it represents", "clarification": "why it is wrong"}
  ],
  "key_concepts": ["concept1", "concept2"],
  "references": ["reference1"]
}',
  '[
    {"name": "subject", "description": "The subject area", "required": true, "default": null},
    {"name": "topic", "description": "The topic within the subject", "required": true, "default": null},
    {"name": "question_content", "description": "The question text to explain", "required": true, "default": null},
    {"name": "correct_answer", "description": "The correct answer text", "required": true, "default": null},
    {"name": "distractors", "description": "Comma-separated list of distractor texts", "required": false, "default": null},
    {"name": "difficulty", "description": "Difficulty level", "required": false, "default": null},
    {"name": "class_level", "description": "Target class level", "required": false, "default": null}
  ]'::jsonb,
  true, true, 1, 3.00
);

-- Question Validation Template
INSERT INTO prompt_templates (
  name, description, prompt_type, language, system_prompt, user_prompt_template,
  variables, is_active, is_default, version, quality_score
) VALUES (
  'Question Validation - Default',
  'Validate AI-generated questions for grammar, accuracy, ambiguity, clarity, reading level, and curriculum alignment.',
  'question_validation',
  'en',
  'You are an expert educational quality assurance reviewer. You meticulously analyze questions for any issues including grammatical errors, factual inaccuracies, ambiguity, unclear phrasing, inappropriate reading level, misalignment with curriculum standards, and difficulty inconsistencies. You provide specific, actionable feedback for each issue found.',
  'Validate the following question for quality and correctness:

Subject: {{subject}}
Topic: {{topic}}
Question: {{question_content}}
{{#answer_options}}Answer Options: {{answer_options}}{{/answer_options}}
{{#correct_answer}}Correct Answer: {{correct_answer}}{{/correct_answer}}
{{#difficulty}}Target Difficulty: {{difficulty}}{{/difficulty}}
{{#bloom_level}}Target Bloom''s Level: {{bloom_level}}{{/bloom_level}}
{{#curriculum}}Curriculum: {{curriculum}}{{/curriculum}}
{{#class_level}}Class Level: {{class_level}}{{/class_level}}

Check for the following issues:
1. Grammar and spelling errors
2. Factual accuracy of the question and answer
3. Ambiguity or multiple valid interpretations
4. Clarity and readability
5. Appropriate reading level for the target class
6. Curriculum alignment (if specified)
7. Difficulty consistency with the target level
8. Distractor quality (plausible but clearly wrong)

Respond in JSON format:
{
  "validations": [
    {
      "validation_type": "grammar|spelling|accuracy|ambiguity|clarity|reading_level|curriculum_alignment|difficulty_consistency",
      "severity": "info|warning|error|critical",
      "message": "Description of the issue found",
      "suggestion": "How to fix the issue"
    }
  ],
  "overall_quality_score": 0.0-1.0,
  "passes_validation": true/false,
  "summary": "Brief summary of validation results"
}',
  '[
    {"name": "subject", "description": "The subject area", "required": true, "default": null},
    {"name": "topic", "description": "The topic within the subject", "required": true, "default": null},
    {"name": "question_content", "description": "The question text to validate", "required": true, "default": null},
    {"name": "answer_options", "description": "JSON array of answer options", "required": false, "default": null},
    {"name": "correct_answer", "description": "The correct answer text", "required": false, "default": null},
    {"name": "difficulty", "description": "Target difficulty level", "required": false, "default": null},
    {"name": "bloom_level", "description": "Target Bloom''s Taxonomy level", "required": false, "default": null},
    {"name": "curriculum", "description": "Target curriculum framework", "required": false, "default": null},
    {"name": "class_level", "description": "Target class level", "required": false, "default": null}
  ]'::jsonb,
  true, true, 1, 3.00
);

-- Distractor Generation Template
INSERT INTO prompt_templates (
  name, description, prompt_type, question_type, language, system_prompt, user_prompt_template,
  variables, is_active, is_default, version, quality_score
) VALUES (
  'Distractor Generation - Default',
  'Generate high-quality distractors (wrong answer options) for existing multiple-choice questions.',
  'distractor_generation',
  'multiple_choice',
  'en',
  'You are an expert at designing effective multiple-choice question distractors. Good distractors are plausible enough to attract students with partial understanding but clearly incorrect to those who have mastered the concept. Distractors should represent common misconceptions, calculation errors, or partial knowledge.',
  'Generate {{num_distractors}} high-quality distractors for the following question:

Subject: {{subject}}
Topic: {{topic}}
Question: {{question_content}}
Correct Answer: {{correct_answer}}
{{#existing_distractors}}Existing Distractors: {{existing_distractors}}{{/existing_distractors}}
{{#difficulty}}Difficulty Level: {{difficulty}}{{/difficulty}}

Requirements:
- Each distractor must be plausible but definitively wrong
- Distractors should represent common misconceptions or errors
- No "all of the above" or "none of the above" options
- Distractors should be of similar length and complexity to the correct answer
- Avoid distractors that are obviously wrong or absurd
- Include an explanation of what misconception each distractor represents

Respond in JSON format:
{
  "distractors": [
    {
      "content": "The distractor text",
      "explanation": "What misconception this represents",
      "plausibility_score": 0.0-1.0
    }
  ]
}',
  '[
    {"name": "subject", "description": "The subject area", "required": true, "default": null},
    {"name": "topic", "description": "The topic within the subject", "required": true, "default": null},
    {"name": "question_content", "description": "The question text", "required": true, "default": null},
    {"name": "correct_answer", "description": "The correct answer text", "required": true, "default": null},
    {"name": "num_distractors", "description": "Number of distractors to generate (default: 3)", "required": false, "default": "3"},
    {"name": "existing_distractors", "description": "JSON array of existing distractors to avoid duplicating", "required": false, "default": null},
    {"name": "difficulty", "description": "Target difficulty level", "required": false, "default": null}
  ]'::jsonb,
  true, true, 1, 3.00
);

-- Document Extraction Template
INSERT INTO prompt_templates (
  name, description, prompt_type, language, system_prompt, user_prompt_template,
  variables, is_active, is_default, version, quality_score
) VALUES (
  'Document Extraction - Default',
  'Extract educational content from documents, identifying topics, learning objectives, and potential question areas.',
  'document_extraction',
  'en',
  'You are an expert educational content analyst. You extract and organize educational content from documents, identifying key topics, learning objectives, and areas suitable for question generation. You focus on extracting structured, pedagogically relevant information.',
  'Analyze the following document content and extract educational information:

Document Title: {{file_name}}
Document Type: {{document_type}}
Content:
---
{{extracted_text}}
---

Please extract and organize:
1. Main topics and subtopics covered in the document
2. Learning objectives that could be assessed
3. Key concepts and definitions
4. Potential question areas with suggested difficulty levels and Bloom''s Taxonomy levels
5. Any curriculum standards referenced

Respond in JSON format:
{
  "topics": [
    {
      "name": "Topic name",
      "confidence": 0.0-1.0,
      "subtopics": ["Subtopic 1", "Subtopic 2"]
    }
  ],
  "learning_objectives": [
    {
      "objective": "The learning objective text",
      "bloom_level": "remember|understand|apply|analyze|evaluate|create",
      "topic": "Associated topic"
    }
  ],
  "key_concepts": [
    {
      "concept": "Concept name",
      "definition": "Definition text",
      "topic": "Associated topic"
    }
  ],
  "question_opportunities": [
    {
      "area": "Description of what could be tested",
      "suggested_type": "multiple_choice|true_false|short_answer|essay|fill_in_blank",
      "suggested_difficulty": "easy|medium|hard|expert",
      "bloom_level": "remember|understand|apply|analyze|evaluate|create",
      "topic": "Associated topic"
    }
  ],
  "curriculum_references": [
    {
      "code": "Curriculum code if found",
      "description": "Description of the standard"
    }
  ]
}',
  '[
    {"name": "file_name", "description": "Name of the uploaded document", "required": true, "default": null},
    {"name": "document_type", "description": "Type of document (pdf, docx, txt)", "required": true, "default": null},
    {"name": "extracted_text", "description": "The extracted text content from the document", "required": true, "default": null}
  ]'::jsonb,
  true, true, 1, 3.00
);

-- Question Improvement Template
INSERT INTO prompt_templates (
  name, description, prompt_type, language, system_prompt, user_prompt_template,
  variables, is_active, is_default, version, quality_score
) VALUES (
  'Question Improvement - Default',
  'Improve existing questions based on specified improvement type (rewrite, simplify, make harder, improve explanation, etc.)',
  'question_improvement',
  'en',
  'You are an expert educational assessment improver. You enhance questions based on the specified improvement type while maintaining the core knowledge being tested. Your improvements are pedagogically sound and aligned with educational best practices.',
  'Improve the following question:

Subject: {{subject}}
Topic: {{topic}}
Improvement Type: {{improvement_type}}
Original Question: {{question_content}}
{{#answer_options}}Original Answer Options: {{answer_options}}{{/answer_options}}
{{#difficulty}}Current Difficulty: {{difficulty}}{{/difficulty}}
{{#target_difficulty}}Target Difficulty: {{target_difficulty}}{{/target_difficulty}}
{{#custom_instructions}}Additional Instructions: {{custom_instructions}}{{/custom_instructions}}

Improvement guidelines:
- "rewrite": Rephrase for clarity while preserving the tested concept
- "simplify": Make the question more accessible without losing rigor
- "make_difficult": Add complexity or require deeper analysis
- "make_easy": Reduce complexity while testing the same concept
- "new_distractors": Generate alternative wrong answer options
- "improve_explanation": Enhance the answer explanation
- "translate": Translate to a different language
- "change_type": Convert to a different question type
- "generate_similar": Create a similar but different question
- "expand_case_study": Expand into a case-study format

Respond in JSON format:
{
  "improved_content": "The improved question text",
  "improved_answer_options": [
    {"content": "Option text", "isCorrect": true/false, "explanation": "Why", "marks": 0}
  ],
  "explanation": "The improved explanation",
  "improvement_notes": "What was changed and why",
  "confidence_score": 0.0-1.0
}',
  '[
    {"name": "subject", "description": "The subject area", "required": true, "default": null},
    {"name": "topic", "description": "The topic within the subject", "required": true, "default": null},
    {"name": "improvement_type", "description": "Type of improvement (rewrite, simplify, make_difficult, make_easy, new_distractors, improve_explanation, translate, change_type, generate_similar, expand_case_study)", "required": true, "default": null},
    {"name": "question_content", "description": "The original question text", "required": true, "default": null},
    {"name": "answer_options", "description": "JSON array of original answer options", "required": false, "default": null},
    {"name": "difficulty", "description": "Current difficulty level", "required": false, "default": null},
    {"name": "target_difficulty", "description": "Target difficulty for make_difficult/make_easy", "required": false, "default": null},
    {"name": "custom_instructions", "description": "Additional improvement instructions", "required": false, "default": null}
  ]'::jsonb,
  true, true, 1, 3.00
);

-- Translation Template
INSERT INTO prompt_templates (
  name, description, prompt_type, language, system_prompt, user_prompt_template,
  variables, is_active, is_default, version, quality_score
) VALUES (
  'Question Translation - Default',
  'Translate questions and their answer options to a target language while preserving meaning and educational quality.',
  'translation',
  'en',
  'You are an expert educational translator. You translate questions and answer options between languages while preserving the exact meaning, educational intent, and difficulty level. Technical terms should be translated using the standard terminology for the target language in the educational context.',
  'Translate the following question from {{source_language}} to {{target_language}}:

Subject: {{subject}}
Topic: {{topic}}
Question: {{question_content}}
{{#answer_options}}Answer Options: {{answer_options}}{{/answer_options}}
{{#explanation}}Explanation: {{explanation}}{{/explanation}}

Requirements:
- Preserve the exact meaning and educational intent
- Use standard educational terminology in the target language
- Maintain the same difficulty level
- Keep the same structure (4 options, 1 correct)
- Technical/scientific terms should use accepted target-language equivalents

Respond in JSON format:
{
  "translated_content": "The translated question",
  "translated_answer_options": [
    {"content": "Translated option", "isCorrect": true/false, "explanation": "Translated explanation", "marks": 0}
  ],
  "translated_explanation": "The translated explanation",
  "translation_notes": "Any notes about terminology choices"
}',
  '[
    {"name": "subject", "description": "The subject area", "required": true, "default": null},
    {"name": "topic", "description": "The topic within the subject", "required": true, "default": null},
    {"name": "source_language", "description": "Source language (e.g., en)", "required": true, "default": null},
    {"name": "target_language", "description": "Target language (e.g., fr, yo, ha, ig)", "required": true, "default": null},
    {"name": "question_content", "description": "The question text to translate", "required": true, "default": null},
    {"name": "answer_options", "description": "JSON array of answer options", "required": false, "default": null},
    {"name": "explanation", "description": "The explanation to translate", "required": false, "default": null}
  ]'::jsonb,
  true, true, 1, 3.00
);

-- ============================================================================
-- 19. GRANT PERMISSIONS
-- ============================================================================
-- Grant appropriate permissions to application roles.
-- Assumes standard Supabase roles: anon, authenticated, service_role
-- ============================================================================

-- Authenticated users can read AI provider configs (active only)
GRANT SELECT ON ai_providers_config TO authenticated;

-- Prompt templates: read for authenticated, write for specific roles
GRANT SELECT ON prompt_templates TO authenticated;
GRANT INSERT ON prompt_templates TO authenticated;
GRANT UPDATE ON prompt_templates TO authenticated;

-- Generation requests: authenticated can create and read own
GRANT SELECT, INSERT, UPDATE ON ai_generation_requests TO authenticated;

-- Generated questions: authenticated can read and update
GRANT SELECT, INSERT, UPDATE ON ai_generated_questions TO authenticated;

-- Validation results: authenticated can read and insert
GRANT SELECT, INSERT, UPDATE ON ai_validation_results TO authenticated;

-- Question improvements: authenticated can read, create, and update
GRANT SELECT, INSERT, UPDATE ON ai_question_improvements TO authenticated;

-- Document uploads: authenticated can read own and create
GRANT SELECT, INSERT, UPDATE ON ai_document_uploads TO authenticated;

-- Generation queue: only service_role (system access)
GRANT ALL ON ai_generation_queue TO service_role;

-- Usage stats: read for authenticated (RLS controls visibility)
GRANT SELECT ON ai_usage_stats TO authenticated;

-- API keys: restricted access (RLS controls visibility)
GRANT SELECT ON ai_api_keys TO authenticated;

-- Curriculum mappings: read for authenticated
GRANT SELECT ON curriculum_mappings TO authenticated;

-- Service role has full access to all tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- ============================================================================
-- COMMIT
-- ============================================================================
COMMIT;

-- ============================================================================
-- END OF AI QUESTION GENERATION ENGINE SCHEMA
-- ============================================================================
-- Total tables created: 11
-- Total new enums created: 8
-- Total indexes created: 45+
-- Total RLS policies created: 20+
-- Total functions created: 6
-- Total triggers created: 7
-- Total seed prompt templates: 7
-- Total seed provider configs: 9
-- ============================================================================
