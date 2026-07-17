# Task: QB Pages - 4 Remaining Page Files

## Summary
Created 4 complete, production-ready page files for the Question Bank module:

1. **question_import_page.dart** - Import page with file upload drop zone, format selection (segmented buttons), template download, mapping configuration (subject/class/topic dropdowns), import options (difficulty, exam type, auto-publish), preview table, progress tracking, result summary with expandable error list
2. **question_export_page.dart** - Export page with format cards (PDF/DOCX/Excel/CSV/JSON), filter section (scope selection + subject/difficulty/type dropdowns + date range), include options (5 checkboxes), layout selection (3 options), progress/download/error states
3. **collections_page.dart** - Collections management with AppAppBar + TabBar, search bar, grid (1/2/3 columns responsive), create dialog with shared toggle, long-press bottom sheet for options, edit/delete actions
4. **collection_detail_page.dart** - Collection detail with branded header (badges), reorderable question list with drag handles, Dismissible swipe-to-remove, add questions dialog with search/select, edit bottom sheet, share dialog with permissions

## Key Decisions
- Used global providers (`importExportProvider`, `collectionProvider`) from `dependency_injection.dart` instead of local placeholder providers
- Used `AppAppBar` consistently across all pages
- Used `AppDialog.showConfirm` for delete confirmations instead of raw AlertDialog
- Used `AppFloatingActionButton` for the collections page FAB
- Used `AppButton`, `AppCard`, `AppTextField`, `AppDropdownField` throughout
- Used context extensions (`context.colorScheme`, `context.textTheme`, `context.isMobile`, etc.)
- Followed existing project patterns from `question_list_page.dart`
- Used `SliverReorderableList` for drag-reordering in collection detail
