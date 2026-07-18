---
Task ID: 1
Agent: Main Agent
Task: Build complete School Management & Academic Administration System for ExamForge AI

Work Log:
- Explored existing codebase to understand architecture patterns (Clean Architecture, Riverpod, GoRouter, Supabase)
- Analyzed existing CBT module as reference for code patterns (entities, models, datasources, repositories, use cases, providers, pages)
- Read existing schema.sql to identify existing tables and avoid duplication
- Created directory structure: lib/features/school_management/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/{providers,widgets,pages/{admin,student,teacher,parent,class_group,subject,timetable,attendance,homework,announcement,document,report}}}
- Created database schema: supabase/migrations/school_management_schema.sql with 20 tables, 11 custom enum types, indexes, triggers, RLS policies, and Realtime subscriptions
- Created domain entities: school_management_entities.dart with 21 entity classes and 11 enums
- Created repository contract: school_management_repository.dart with 98 abstract methods
- Created 10 use case files covering all sub-modules
- Created data models: school_management_models.dart with 21 model classes
- Created remote datasource: school_management_remote_datasource.dart with abstract class + Supabase implementation
- Created repository implementation: school_management_repository_impl.dart with exception-to-failure mapping
- Created 13 provider/state notifier files for all sub-modules
- Created 11 shared widget files for reusable UI components
- Created 36 UI pages across admin, student, teacher, parent, class, subject, timetable, attendance, homework, announcement, document, and report modules
- Updated route_names.dart with 35 new route constants + schoolManagementRoutes set
- Updated app_router.dart with 35 GoRoute entries for all school management pages
- Updated dependency_injection.dart with full provider chain (datasource → repository → 60+ use case providers)

Stage Summary:
- Complete School Management & Academic Administration System built with full Clean Architecture
- 20 database tables with comprehensive RLS policies, triggers, and indexes
- Multi-school architecture with logical multi-tenant data isolation
- 21 domain entities, 21 data models, 98 repository methods, 60+ use cases
- 13 state management providers with proper error handling
- 36 production-ready UI pages following Material 3 design
- Full routing and DI wiring integrated with existing modules
- Integration points with CBT Engine (exams reference classes/subjects), Results & Analytics, and Question Bank
