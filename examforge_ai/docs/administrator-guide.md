# ExamForge AI — Administrator Guide

> **Guide for School Administrators and Super Administrators**
> Complete reference for configuring and managing the CCMS & Nigerian Curriculum Module.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Configuring Educational Levels for Your School](#configuring-educational-levels-for-your-school)
3. [Managing Curricula](#managing-curricula)
4. [Subject Management](#subject-management)
5. [Topic and Subtopic Organization](#topic-and-subtopic-organization)
6. [Content Management Workflow](#content-management-workflow)
7. [Bulk Import Procedures](#bulk-import-procedures)
8. [Content Collections](#content-collections)
9. [AI Curriculum Engine Configuration](#ai-curriculum-engine-configuration)
10. [Answer Repository Management](#answer-repository-management)
11. [User Management](#user-management)
12. [Security Features](#security-features)
13. [Monitoring and Alerts](#monitoring-and-alerts)
14. [Billing and Subscription Management](#billing-and-subscription-management)

---

## Getting Started

### Accessing the Admin Dashboard

After logging in with your administrator account, you will be redirected to the **Admin Dashboard**. The dashboard provides:

- **Quick Stats**: Total content, subjects, pending reviews, and quality scores
- **Recent Activity**: Latest content changes and reviews
- **Quick Actions**: Create content, manage subjects, run imports
- **System Alerts**: Any active monitoring alerts or security events

### Role-Based Access

| Role | Dashboard | Capabilities |
|------|-----------|-------------|
| Super Admin | Super Admin Dashboard | All platform operations, cross-school access, security, monitoring |
| School Admin | School Admin Dashboard | School-scoped operations, user management, curriculum setup |

### Navigation

The main navigation sidebar provides access to all CCMS sections:

- **Dashboard** — Overview statistics and quick actions
- **Educational Levels** — Configure levels for your school
- **Curricula** — Manage curriculum definitions
- **Subjects** — Add, edit, and organize subjects
- **Topics** — Manage topic hierarchy
- **Content Library** — Browse, create, and review content
- **Import** — Bulk import content from files
- **Collections** — Organize content into collections
- **AI Engine** — Configure AI content generation
- **Audit Trail** — View system audit log (Super Admin)
- **Security** — MFA, API keys, security events (Super Admin)

---

## Configuring Educational Levels for Your School

### Understanding Educational Levels

ExamForge AI supports the full Nigerian educational system:

| Category | Levels | Typical Age Range |
|----------|--------|-------------------|
| Early Childhood | Nursery, Kindergarten | 2-6 years |
| Primary | Primary 1-6 | 5-12 years |
| Junior Secondary | JSS 1-3 | 10-15 years |
| Senior Secondary | SS 1-3 | 13-18 years |
| Technical | Technical Year 1-3 | 13-18 years |
| Tertiary College | College of Education Year 1-3 | 16-22 years |
| Tertiary University | University 100-600 Level | 16-25 years |

### Enabling Levels for Your School

Not all schools offer all levels. You can enable only the levels your school provides:

1. Navigate to **Educational Levels** in the sidebar
2. You will see a list of all available levels with their current status
3. Toggle the **Enabled** switch for each level your school offers
4. Optionally set a **Custom Name** (e.g., rename "Primary 1" to "Grade 1")
5. Configure **Academic Year** dates (start and end dates)
6. Set **Max Students per Class** for each level
7. Click **Save Configuration**

### Level Configuration Details

For each enabled level, you can configure:

| Setting | Description | Default |
|---------|-------------|---------|
| Custom Name | Override the default level name | System default |
| Academic Year Start | First day of the academic year | September 1 |
| Academic Year End | Last day of the academic year | July 31 |
| Max Students per Class | Maximum students in a class | 40 |
| Grading System | JSONB config for grading scales | `{}` |
| Additional Configuration | Custom JSONB settings | `{}` |

### Grading System Configuration

The grading system field allows you to define custom grading scales:

```json
{
  "scale": [
    {"grade": "A", "min_score": 70, "max_score": 100, "remark": "Excellent"},
    {"grade": "B", "min_score": 60, "max_score": 69, "remark": "Very Good"},
    {"grade": "C", "min_score": 50, "max_score": 59, "remark": "Good"},
    {"grade": "D", "min_score": 45, "max_score": 49, "remark": "Fair"},
    {"grade": "E", "min_score": 40, "max_score": 44, "remark": "Poor"},
    {"grade": "F", "min_score": 0, "max_score": 39, "remark": "Fail"}
  ],
  "pass_mark": 50,
  "system": "nigerian_6_point"
}
```

---

## Managing Curricula

### Supported Curriculum Types

| Type | Code | Description |
|------|------|-------------|
| NERDC | `nerdc` | Nigerian Educational Research and Development Council |
| WAEC | `waec` | West African Examinations Council |
| NECO | `neco` | National Examinations Council |
| NABTEB | `nabteb` | National Business and Technical Examinations Board |
| Custom | `custom` | School-defined curriculum |
| International | `international` | IGCSE, IB, or other international curricula |

### Creating a Curriculum

1. Navigate to **Curricula** in the sidebar
2. Click **Add Curriculum**
3. Fill in the required fields:
   - **Name**: e.g., "NERDC Senior Secondary 2023"
   - **Code**: e.g., "NERDC-SS-2023" (must be unique)
   - **Type**: Select from the dropdown
   - **Country Code**: Default "NG" for Nigeria
   - **Description**: Brief description
   - **Publisher**: Optional publisher name
   - **Edition**: e.g., "2023 Edition"
   - **Effective Date**: When this curriculum takes effect
   - **Expiry Date**: When this curriculum is superseded
4. Click **Create**

### Curriculum Versioning

Each curriculum can have multiple versions:

1. Open a curriculum and navigate to the **Versions** tab
2. Click **Add Version**
3. Enter the version number, change summary, and changelog
4. Mark the version as **Current** when it becomes the active version
5. Previous versions are retained for historical reference

### Mapping Curricula to Educational Levels

After creating a curriculum, map it to the educational levels it applies to:

1. Open the curriculum and navigate to the **Level Mappings** tab
2. Click **Map Level**
3. Select an educational level from the dropdown
4. Mark as **Applicable** or **Not Applicable**
5. Add notes if needed
6. Click **Save**

---

## Subject Management

### Default Subjects

The system comes pre-loaded with Nigerian curriculum subjects for all levels:

**Primary Level (16 subjects):**
- English Studies, Mathematics, Basic Science, Basic Technology, Civic Education, Social Studies, Cultural & Creative Arts, Computer Studies, Agricultural Science, Home Economics, Physical & Health Education, Security Education, French, Yoruba, Hausa, Igbo

**Junior Secondary (19 subjects):**
- All primary subjects plus Business Studies, Christian Religious Studies, Islamic Religious Studies

**Senior Secondary (34 subjects):**
- English Language, General Mathematics, Physics, Chemistry, Biology, Agricultural Science, Further Mathematics, Technical Drawing, Computer Studies, Literature in English, Government, History, Economics, Commerce, Accounting, Geography, Civic Education, Christian Religious Studies, Islamic Religious Studies, French, Yoruba, Hausa, Igbo, Visual Arts, Music, Physical Education, Food & Nutrition, Clothing & Textile, Data Processing, Animal Husbandry, Fisheries, Tourism, Marketing, Insurance

### Adding Custom Subjects

1. Navigate to **Subjects** in the sidebar
2. Click **Add Subject**
3. Fill in the form:
   - **Name**: Subject name
   - **Code**: Unique code (e.g., "SS-AI" for Artificial Intelligence)
   - **Subject Group**: language, mathematics, science, technology, social_studies, commercial, arts, vocational, religious, physical
   - **Educational Level**: Which level this subject applies to
   - **Curriculum**: Which curriculum it belongs to
   - **Core/Elective/Vocational**: Classification
   - **Language of Instruction**: Default "English"
   - **Description**: Subject description
   - **Icon URL**: Optional icon
   - **Color Code**: Optional display color (hex)
   - **Sort Order**: Position in the subject list
   - **Is Custom**: Checked automatically for school-created subjects
4. Click **Create**

### Subject Classification

| Classification | Description | Example |
|---------------|-------------|---------|
| Core | Mandatory for all students | English Language, Mathematics |
| Elective | Optional, student-chosen | Literature in English, Physics |
| Vocational | Trade/skill-oriented | Food & Nutrition, Fisheries |

---

## Topic and Subtopic Organization

### Topic Hierarchy

The CCMS supports a three-level hierarchy:

```
Subject → Topic → Subtopic → Learning Objectives
```

Topics can also be nested (parent/child topics) for deeper organization:

```
Mathematics
├── Number and Numeration
│   ├── Place Value
│   │   ├── LO: Identify place values up to billions
│   │   └── LO: Compare numbers using place value
│   └── Basic Operations
│       ├── LO: Add whole numbers
│       └── LO: Subtract whole numbers
├── Algebraic Processes
│   ├── Simple Equations
│   └── Sequences
```

### Creating Topics

1. Navigate to **Topics** in the sidebar
2. Select the **Subject** from the dropdown filter
3. Click **Add Topic**
4. Fill in:
   - **Title**: Topic name
   - **Code**: Optional topic code (e.g., "MATH-01")
   - **Description**: What this topic covers
   - **Sort Order**: Position within the subject
   - **Estimated Duration**: Time in minutes
   - **Parent Topic**: Select for nested topics (optional)
   - **Educational Level**: Which level this topic applies to
   - **Curriculum**: Which curriculum alignment
5. Click **Create**

### Creating Subtopics

1. Open a topic and click **Add Subtopic**
2. Fill in the subtopic details
3. Learning objectives can be attached to either topics or subtopics

### Learning Objectives

Learning objectives define what students should know or be able to do:

1. Each objective has a **Bloom's Taxonomy level**: Remember, Understand, Apply, Analyze, Evaluate, Create
2. Objectives marked **Assessable** can be linked to content items
3. Each objective has a unique **Code** for tracking and alignment

---

## Content Management Workflow

### Content Lifecycle

```
Draft → Review → Published → Archived → Deprecated
```

| Status | Description | Who Can See |
|--------|-------------|-------------|
| Draft | Work in progress | Creator and school admins |
| Review | Submitted for quality review | Creator, reviewers, admins |
| Published | Live and available to all users | All authenticated users |
| Archived | No longer active but preserved | Admins only |
| Deprecated | Superseded content | Admins only |

### Creating Content

1. Navigate to **Content Library** and click **Create Content**
2. Select the **Content Type**:
   - Question, Explanation, Marking Scheme, Teacher Note
   - Lesson Note, Worksheet, Practical Guide
   - Reading Material, Video Script, Assessment Rubric
3. Fill in the content form:
   - **Title**: Descriptive title
   - **Subject**: Which subject
   - **Educational Level**: Which level
   - **Topic/Subtopic**: Topic association
   - **Curriculum**: Curriculum alignment
   - **Difficulty Level**: Beginner, Elementary, Intermediate, Advanced, Expert
   - **Bloom's Taxonomy**: Remember, Understand, Apply, Analyze, Evaluate, Create
   - **Body**: Main content text
   - **Options** (for questions): Multiple choice options
   - **Correct Answer**: The correct answer(s)
   - **Step-by-Step Explanation**: Detailed solution walkthrough
   - **Marking Scheme**: How marks are allocated
   - **Teacher Notes**: Additional notes for teachers
   - **Tags**: Keywords for search and filtering
   - **Past Question**: Flag if from a past exam
   - **Past Exam Year/Body**: Year and examining body
4. Click **Save as Draft** or **Submit for Review**

### Reviewing Content

When content is submitted for review:

1. Reviewers see the content in their **Review Queue**
2. Score the content across four dimensions (1-5 each):
   - **Quality Score**: Overall quality of writing and formatting
   - **Accuracy Score**: Factual correctness
   - **Relevance Score**: Alignment with the topic and level
   - **Curriculum Alignment Score**: Match with curriculum objectives
3. Add comments with specific feedback
4. Choose **Approve** (status → Published) or **Request Changes** (status → Draft)

### Content Versioning

Every change to a content item creates a new version automatically:

- The previous version is preserved in the `content_versions` table
- You can view the full version history for any content item
- Changes are tracked with a change summary and changed fields list

---

## Bulk Import Procedures

### Supported File Formats

| Format | Extension | Max Size | Description |
|--------|-----------|----------|-------------|
| CSV | `.csv` | 100 MB | Comma-separated values |
| Excel | `.xlsx` | 100 MB | Microsoft Excel workbook |
| JSON | `.json` | 100 MB | JSON array of content objects |

### Import Process

1. Navigate to **Import** in the sidebar
2. Click **New Import**
3. Select the **Subject** and **Educational Level** for imported content
4. Upload your file
5. Map columns from your file to ExamForge fields:
   - Title → `title`
   - Content → `body`
   - Difficulty → `difficulty_level`
   - Bloom's Level → `bloom_level`
   - Answer → `correct_answer`
   - Explanation → `step_by_step_explanation`
6. Declare **Licensing Rights**: Confirm you have the right to import this content
7. Provide **License Details** if applicable
8. Click **Start Import**

### Import Tracking

The import process is tracked in real-time:

| Field | Description |
|-------|-------------|
| Total Items | Total rows in the import file |
| Processed Items | Rows that have been processed |
| Successful Items | Rows imported successfully |
| Failed Items | Rows that failed with error messages |
| Status | Pending → Processing → Completed / Partially Completed / Failed |

### CSV Template

```csv
title,content_type,question_category,difficulty_level,bloom_level,body,options,correct_answer,explanation,marks_allocated,tags
"2+2=?","question","objective","beginner","remember","What is 2+2?","[{""label"":""A"",""text"":""3""},{""label"":""B"",""text"":""4""},{""label"":""C"",""text"":""5""}]","{""label"":""B""}","Add the two numbers together",1,"mathematics;addition"
```

---

## Content Collections

Collections allow you to organize content into curated groups for specific purposes (e.g., "Term 1 Exam Questions", "JSS 3 Revision Pack").

### Creating a Collection

1. Navigate to **Collections** and click **New Collection**
2. Fill in:
   - **Name**: e.g., "JSS 3 Mathematics Mid-Term Exam"
   - **Description**: Purpose of the collection
   - **Type**: exam, homework, revision, lesson_plan, custom
   - **Subject**: Optional subject association
   - **Educational Level**: Optional level association
   - **Public**: Whether other teachers can see this collection
3. Click **Create**

### Adding Items to a Collection

1. Open the collection
2. Click **Add Content**
3. Search or browse for content items
4. Select items and click **Add to Collection**
5. Reorder items using drag-and-drop

---

## AI Curriculum Engine Configuration

### Understanding the AI Curriculum Engine

The AI Curriculum Engine generates educational content automatically based on your school's curriculum, subject requirements, and educational level. It uses the configured rules to ensure content is age-appropriate, culturally relevant, and aligned with Nigerian curriculum standards.

### Configuring AI Generation

1. Navigate to **AI Engine** in the sidebar
2. Select **Subject** and **Educational Level**
3. Configure the following settings:

| Setting | Description | Default |
|---------|-------------|---------|
| Preferred Difficulty | Default difficulty for generated content | Intermediate |
| Preferred Bloom's Levels | Which cognitive levels to target | Remember, Understand, Apply |
| Question Type Distribution | Mix of objective/theory/practical | Balanced |
| Language Style | Tone of generated content | Age-appropriate |
| Include Explanations | Auto-generate step-by-step explanations | Yes |
| Include Marking Schemes | Auto-generate marking schemes | Yes |
| Include Teacher Notes | Auto-generate teacher notes | No |
| Content Tone | Academic, conversational, or formal | Academic |
| Cultural Context | Nigerian context embedding | Nigerian |
| Max Questions per Generation | Limit per batch | 10 |
| Quality Threshold | Minimum quality score to auto-approve | 3.50 |
| Auto-Approve Threshold | Score above which content is auto-published | 4.50 |
| Topic Coverage Preference | balanced, sequential, or random | Balanced |

### AI Generation Rules

Rules define level-specific constraints for AI-generated content:

1. Navigate to **AI Engine → Rules**
2. Rules can be defined per educational level and subject
3. Rule types include:
   - **Vocabulary Level**: Maximum word complexity
   - **Sentence Length**: Maximum words per sentence
   - **Content Scope**: Topic coverage boundaries
   - **Cultural Sensitivity**: Nigerian cultural considerations
   - **Assessment Format**: Question format requirements

### Reviewing AI-Generated Content

Content generated by the AI engine is always created in **Draft** status:

1. Navigate to **Content Library** and filter by `is_ai_generated = true`
2. Review the content for accuracy, appropriateness, and alignment
3. Use the review scoring system (Quality, Accuracy, Relevance, Curriculum Alignment)
4. Approve or request changes as with manually created content

---

## Answer Repository Management

The Answer Repository stores enhanced answer data linked to content items:

### Answer Repository Fields

| Field | Description |
|-------|-------------|
| Correct Answers | All accepted correct answers (for questions with multiple valid answers) |
| Step-by-Step Explanation | Detailed walkthrough of the solution |
| Rich Explanation | Formatted explanation with images/diagrams |
| Marking Scheme | Detailed marking allocation |
| Alternative Answers | Other acceptable answer forms |
| Common Mistakes | Typical student errors and how to address them |
| Teacher Notes | Additional guidance for teachers |
| Curriculum References | Links to specific curriculum objectives |
| Difficulty Justification | Why this difficulty level was assigned |

### Verification Process

Answers should be verified by experienced teachers:

1. Open the Answer Repository entry
2. Review all answer fields for correctness
3. Click **Verify** to mark the entry as verified
4. Verified entries show a green badge in the content library

---

## User Management

### User Roles

| Role | Create Content | Review Content | Manage Users | System Settings |
|------|---------------|---------------|-------------|-----------------|
| Super Admin | Yes | Yes | All schools | Yes |
| School Admin | Yes | Yes | Own school | Limited |
| Teacher | Yes | Yes (assigned) | No | No |
| Student | Read only | No | No | No |
| Parent | Read only | No | No | No |

### Inviting Users

1. Navigate to **User Management** in the sidebar
2. Click **Invite User**
3. Enter the email address and select a role
4. The user receives an invitation email with a registration link
5. Upon registration, they are automatically assigned to your school

### Managing User Access

- **Suspend**: Temporarily disable a user's access
- **Reactivate**: Restore a suspended user
- **Change Role**: Update a user's role within your school
- **Remove**: Remove a user from your school

---

## Security Features

### Multi-Factor Authentication (MFA)

MFA adds an extra layer of security to user accounts:

1. Navigate to **Security → MFA**
2. Users can enable MFA using:
   - **SMS**: Verification code sent to phone
   - **Email**: Verification code sent to email
   - **Authenticator App**: TOTP code from Google Authenticator, Authy, etc.
   - **Hardware Key**: FIDO2/WebAuthn hardware security key
3. MFA can be enforced for specific roles via school policy

### API Keys

API keys allow programmatic access to the CCMS:

1. Navigate to **Security → API Keys**
2. Click **Create API Key**
3. Fill in:
   - **Name**: Descriptive name (e.g., "Integration - School Portal")
   - **Scopes**: List of permitted operations
   - **Rate Limit Override**: Custom rate limit (optional)
   - **Expires At**: Expiration date (optional)
4. The key is displayed once — store it securely
5. Keys can be revoked at any time

### Audit Trail

The audit trail records all significant actions on the platform:

1. Navigate to **Security → Audit Trail** (Super Admin only)
2. Filter by:
   - User, School, Action type, Resource type, Date range
3. Each entry shows:
   - Who performed the action
   - What was changed (old values → new values)
   - When (timestamp)
   - From where (IP address, device, session)
4. Audit trail is retained for 365 days by default

### Session Management

Users can view and manage their active sessions:

1. Navigate to **Security → Sessions**
2. View all active sessions with device and IP information
3. Invalidate specific sessions or all other sessions
4. Sessions are automatically invalidated on password change or MFA enable

---

## Monitoring and Alerts

### Dashboard Overview

The monitoring dashboard shows real-time platform health:

- **System Metrics**: API response times, error rates, active users
- **Content Metrics**: Creation rate, review queue, quality scores
- **Security Events**: Failed logins, MFA challenges, suspicious activity
- **Alerts**: Active and recent alert incidents

### Alert Configuration

Super admins can configure automated alerts:

1. Navigate to **Monitoring → Alert Rules**
2. Click **Create Alert Rule**
3. Configure:
   - **Name**: Alert name
   - **Metric**: Which metric to monitor
   - **Condition**: >, <, >=, <=, !=
   - **Threshold**: Value that triggers the alert
   - **Duration**: How long the condition must persist
   - **Severity**: Info, Warning, Critical, Emergency
   - **Notification Channels**: Email, SMS, webhook
4. Click **Create**

### Responding to Alerts

When an alert fires:

1. You receive a notification via the configured channels
2. Navigate to **Monitoring → Alert Incidents**
3. Click **Acknowledge** to indicate you are investigating
4. Investigate the root cause using the audit trail and metrics
5. Click **Resolve** and enter resolution notes

---

## Billing and Subscription Management

### Subscription Plans

| Plan | Schools | Users | Content Items | AI Generations/mo | Price |
|------|---------|-------|---------------|-------------------|-------|
| Starter | 1 | 50 | 5,000 | 100 | ₦15,000/mo |
| Professional | 1 | 200 | 25,000 | 1,000 | ₦45,000/mo |
| Enterprise | 5 | Unlimited | Unlimited | 10,000 | ₦150,000/mo |
| Unlimited | Unlimited | Unlimited | Unlimited | Unlimited | Custom |

### Managing Subscriptions

1. Navigate to **Billing → Subscription** in the sidebar
2. View current plan, usage, and renewal date
3. Upgrade or downgrade your plan
4. View billing history and download invoices

### Payment Methods

Payments are processed via **Flutterwave**, supporting:

- Bank transfers (Nigerian banks)
- Debit/credit cards (Visa, Mastercard)
- USSD payments
- Mobile money

### AI Credits

AI content generation uses credits:

- Each generation batch consumes credits based on the number of items
- Credits are included in your plan and can be purchased additionally
- Unused credits roll over for one billing period

### License Management

For schools requiring software licenses:

1. Navigate to **Billing → Licenses**
2. View active licenses and expiration dates
3. Generate license keys for on-premise deployments
4. Manage license allocations across schools
