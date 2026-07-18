# Task: AI Teacher Workspace Expansion - 7 New Page Files

## Agent: Main Developer
## Date: 2026-03-04

## Summary

Created 7 production-ready Flutter page files for the ExamForge AI Teacher Workspace expansion. All pages follow the exact code style of existing pages in the project.

## Files Created

All files are located under:
`/home/z/my-project/examforge_ai/lib/features/teacher_workspace/presentation/pages/`

### 1. `rubric_generator_page.dart`
- **Class**: `RubricGeneratorPage` (ConsumerStatefulWidget)
- **Features**: 
  - Subject dropdown, Class dropdown, Topic text field, Criteria count slider (2-8), Total points input, Custom instructions
  - AI generation via `ref.read(rubricProvider.notifier).generateRubric()`
  - Generated result: Preview card, DataTable grid (criteria × levels: Beginning, Developing, Proficient, Exemplary), Editable cells, Add/Remove criteria buttons, Use as Template toggle
  - Action buttons: Save as Draft, Save & Publish, Export (PDF/DOCX bottom sheet), Share with Colleagues
  - Loading spinner state, Reset functionality

### 2. `rubric_list_page.dart`
- **Class**: `RubricListPage` (ConsumerStatefulWidget)
- **Features**:
  - Search bar, Filter chips (All, My Rubrics, Templates, Published)
  - Rubric cards with: Title, Description, Total points, Criteria count badge, Subject/class badges, AI-generated badge, Template badge, Published status badge
  - Edit, Delete, Duplicate, Export buttons per card
  - FAB for new rubric, Empty state, Loading shimmer, Error state
  - Delete confirmation dialog

### 3. `oral_question_generator_page.dart`
- **Class**: `OralQuestionGeneratorPage` (ConsumerStatefulWidget)
- **Features**:
  - Subject dropdown, Class dropdown, Topic text field, Question count slider (5-30), Difficulty dropdown (StudentLevel), Curriculum dropdown (CurriculumType), Duration input, Custom instructions
  - AI generation via `ref.read(oralQuestionProvider.notifier).generateOralQuestions()`
  - Preview card with question count, total marks, duration
  - Expandable question cards with: Question text, Expected answer, Marks, Difficulty, Bloom's level, Edit mode, Delete button
  - Add Question button, Save as Draft / Save & Publish, Export (PDF), Share with Colleagues, Generate Questions for CBT button
  - Private `_OralQuestionCard` widget for expandable question items

### 4. `oral_question_list_page.dart`
- **Class**: `OralQuestionListPage` (ConsumerStatefulWidget)
- **Features**:
  - Search bar, Filter by Subject and Difficulty (with bottom sheet picker)
  - Oral question set cards: Title, Question count, Total marks, Duration, Subject/difficulty badges, Published status
  - Edit, Delete, Export buttons per card
  - FAB, Empty state, Loading shimmer, Error state, Delete confirmation

### 5. `practical_assessment_generator_page.dart`
- **Class**: `PracticalAssessmentGeneratorPage` (ConsumerStatefulWidget)
- **Features**:
  - Subject dropdown, Class dropdown, Topic text field, Difficulty dropdown, Duration input, Custom instructions
  - AI generation via `ref.read(practicalAssessmentProvider.notifier).generatePracticalAssessment()`
  - Preview card with objectives count, materials count, steps count
  - Expandable sections: Objectives (editable add/remove), Materials Needed (editable), Procedure Steps (numbered, reorderable, editable), Safety Precautions (editable), Expected Results (text area), Assessment Criteria table with linked rubric selector
  - Rubric selector dropdown populated from `ref.watch(rubricProvider)`
  - Edit toggle, Save as Draft / Save & Publish, Export (PDF/DOCX), Share with Colleagues

### 6. `practical_assessment_list_page.dart`
- **Class**: `PracticalAssessmentListPage` (ConsumerStatefulWidget)
- **Features**:
  - Search bar, Filter by Subject and Difficulty
  - Assessment cards: Title, Description, Objectives count, Duration, Materials count, Subject/difficulty badges, Published status
  - Edit, Delete, Export buttons per card
  - FAB, Empty state, Loading shimmer, Error state, Delete confirmation

### 7. `shared_resources_page.dart`
- **Class**: `SharedResourcesPage` (ConsumerStatefulWidget with SingleTickerProviderStateMixin)
- **Features**:
  - TabController with 3 tabs: Shared With Me, Shared By Me, Pending
  - Shared resource cards: Resource type icon + label, Shared by/with name, Message, Permissions badges (View, Edit, Comment, Download), Date shared
  - For pending: Accept / Decline buttons
  - For accepted: Open Resource, Add Comment buttons
  - Pull-to-refresh, Empty state per tab, Loading shimmer, Error state
  - Resource type icon mapping (lesson_plan, worksheet, rubric, oral_question, practical_assessment, etc.)

## Code Style Compliance

All pages follow the existing project patterns:
- `ConsumerStatefulWidget` with private state class
- `AppAppBar`, `AppCard`, `AppButton`, `AppTextField`, `AppLoading`, `AppEmptyState`, `AppErrorState` shared widgets
- `Spacings`, `AppTypography` design tokens
- `context.colorScheme`, `context.textTheme`, `context.isDarkMode` extensions
- `ref.watch(provider)` for reading state, `ref.read(provider.notifier)` for mutations
- `_listenForMessages()` / `_showSnackBar()` helper pattern
- `_formatDate()` helper for consistent date formatting
- `_buildLoadingShimmer()` / `_buildEmptyState()` / `_buildErrorState()` for state handling
- Section comment headers matching existing style (`// ─── Section ─────`)
- Divider headers (`// ═════════════════════════════════════════════════════════`)
