import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/themes/app_colors.dart';
import '../../../../../core/themes/app_typography.dart';
import '../../../../../core/themes/spacings.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../shared/widgets/app_card.dart';
import '../../../../../shared/widgets/app_empty_state.dart';
import '../../../../../shared/widgets/app_error_state.dart';
import '../../../../../shared/widgets/app_loading.dart';
import '../../../../../shared/widgets/app_search_bar.dart';
import '../../../../../shared/models/user_role.dart';
import '../../../../../shared/providers/auth_state_provider.dart';
import '../../../domain/entities/school_management_entities.dart';
import '../../providers/document_provider.dart';
import '../../../../../config/dependency_injection.dart';


// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT CENTER PAGE
// ═══════════════════════════════════════════════════════════════════════

/// Document center with type tabs, search, category filter.
///
/// Each document card shows: file icon by type, title, category, size,
/// upload date, download count, public/private badge.
/// Upload FAB, download button, delete action (admin).
class DocumentCenterPage extends ConsumerStatefulWidget {
  const DocumentCenterPage({super.key});

  @override
  ConsumerState<DocumentCenterPage> createState() =>
      _DocumentCenterPageState();
}

class _DocumentCenterPageState extends ConsumerState<DocumentCenterPage>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSearchMode = false;
  late TabController _tabController;
  String? _categoryFilter;

  /// Whether the current user has an admin role (superAdmin or schoolAdmin).
  bool get _isAdmin => ref.read(resolvedUserRoleProvider)?.isAdmin ?? false;

  static const _typeTabs = <DocumentType?>[
    null, // All
    DocumentType.studentDocument,
    DocumentType.schoolPolicy,
    DocumentType.curriculumFile,
    DocumentType.certificate,
    DocumentType.general,
  ];

  static const _tabLabels = [
    'All',
    'Student Docs',
    'Policies',
    'Curriculum',
    'Certificates',
    'General',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _typeTabs.length,
      vsync: this,
    );
    _tabController.addListener(_onTabChanged);
    _scrollController.addListener(_onScroll);

    Future.microtask(() {
      ref.read(documentListProvider.notifier).loadDocuments(
            schoolId: 'current-school',
          );
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final type = _typeTabs[_tabController.index];
      ref.read(documentListProvider.notifier).setTypeFilter(type);
      ref.read(documentListProvider.notifier).loadDocuments(
            schoolId: 'current-school',
            documentType: type,
            category: _categoryFilter,
          );
    }
  }

  void _onScroll() {
    // Future: pagination
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // ─── File icon helper ──────────────────────────────────────────────

  IconData _fileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file_outlined;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf_outlined;
    if (mimeType.contains('image')) return Icons.image_outlined;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return Icons.description_outlined;
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return Icons.table_chart_outlined;
    }
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) {
      return Icons.slideshow_outlined;
    }
    if (mimeType.contains('zip') || mimeType.contains('compressed')) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color _fileIconColor(String? mimeType) {
    if (mimeType == null) return AppColors.info;
    if (mimeType.contains('pdf')) return AppColors.error;
    if (mimeType.contains('image')) return AppColors.success;
    if (mimeType.contains('word') || mimeType.contains('document')) {
      return const Color(0xFF2B579A);
    }
    if (mimeType.contains('sheet') || mimeType.contains('excel')) {
      return AppColors.success;
    }
    return AppColors.info;
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '—';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  // ─── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final state = ref.watch(documentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearchMode
            ? null
            : Text(
                'Document Center',
                style: tt.titleLarge?.copyWith(
                  fontWeight: AppTypography.wSemiBold,
                  color: cs.onSurface,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearchMode ? Icons.close_rounded : Icons.search_rounded,
              color: cs.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() => _isSearchMode = !_isSearchMode);
              if (!_isSearchMode) {
                _searchController.clear();
                ref.read(documentListProvider.notifier).loadDocuments(
                      schoolId: 'current-school',
                    );
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104),
          child: Column(
            children: [
              if (_isSearchMode)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.lg,
                    vertical: Spacings.sm,
                  ),
                  child: AppSearchBar(
                    hint: 'Search documents...',
                    controller: _searchController,
                    onChanged: (query) {
                      if (query.isEmpty) {
                        ref.read(documentListProvider.notifier).loadDocuments(
                              schoolId: 'current-school',
                            );
                      } else {
                        ref.read(documentListProvider.notifier).setSearchQuery(query);
                        ref.read(documentListProvider.notifier).loadDocuments(
                              schoolId: 'current-school',
                              searchQuery: query,
                            );
                      }
                    },
                  ),
                ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: cs.primary,
                unselectedLabelColor: cs.onSurfaceVariant,
                indicatorColor: cs.primary,
                tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(documentListProvider.notifier).loadDocuments(
              schoolId: 'current-school',
            ),
        child: _buildBody(context, state),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to upload page
        },
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload'),
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
      ),
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, DocumentListState state) {
    if (state.isLoading && state.documents.isEmpty) {
      return const Center(
        child: AppLoadingSpinner(size: AppLoadingSpinnerSize.large),
      );
    }

    if (state.error != null && state.documents.isEmpty) {
      return AppErrorState.genericError(
        message: state.error,
        onRetry: () => ref.read(documentListProvider.notifier).loadDocuments(
              schoolId: 'current-school',
            ),
      );
    }

    if (state.documents.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          AppEmptyState(
            icon: Icons.folder_open_outlined,
            title: _isSearchMode ? 'No Matching Documents' : 'No Documents',
            subtitle: _isSearchMode
                ? 'Try adjusting your search or filters.'
                : 'Upload the first document to get started.',
            actionLabel: _isSearchMode ? null : 'Upload',
            onAction: _isSearchMode
                ? null
                : () {
                    // Navigate to upload page
                  },
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(Spacings.md),
      itemCount: state.documents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: Spacings.md),
          child: _DocumentCard(
            document: state.documents[index],
            fileIcon: _fileIcon,
            fileIconColor: _fileIconColor,
            formatFileSize: _formatFileSize,
            formatDate: _formatDate,
            isAdmin: _isAdmin,
            onDownload: () {
              ref.read(documentListProvider.notifier).downloadDocument(
                    state.documents[index].id,
                  );
            },
            onDelete: _isAdmin
                ? () {
                    _confirmDelete(context, state.documents[index].id);
                  }
                : null,
          ),
        );
      },
    );
  }

  // ─── Delete confirmation ───────────────────────────────────────────

  void _confirmDelete(BuildContext context, String documentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text(
          'Are you sure you want to delete this document? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(documentListProvider.notifier).deleteDocument(documentId);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// DOCUMENT CARD
// ═══════════════════════════════════════════════════════════════════════

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.fileIcon,
    required this.fileIconColor,
    required this.formatFileSize,
    required this.formatDate,
    this.isAdmin = false,
    this.onDownload,
    this.onDelete,
  });

  final DocumentEntity document;
  final IconData Function(String?) fileIcon;
  final Color Function(String?) fileIconColor;
  final String Function(int?) formatFileSize;
  final String Function(DateTime?) formatDate;
  final bool isAdmin;
  final VoidCallback? onDownload;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;
    final iconColor = fileIconColor(document.mimeType);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── File icon ─────────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(isDark ? 0.20 : 0.12),
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
            ),
            child: Icon(
              fileIcon(document.mimeType),
              color: iconColor,
              size: Spacings.lgIcon,
            ),
          ),
          const SizedBox(width: Spacings.md),
          // ─── Document details ──────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: AppTypography.wSemiBold,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Public/private badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacings.sm,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: (document.isPublic ? AppColors.success : AppColors.warning)
                            .withOpacity(isDark ? 0.20 : 0.12),
                        borderRadius: BorderRadius.circular(Spacings.fullRadius),
                      ),
                      child: Text(
                        document.isPublic ? 'Public' : 'Private',
                        style: tt.labelSmall?.copyWith(
                          color: document.isPublic ? AppColors.success : AppColors.warning,
                          fontWeight: AppTypography.wSemiBold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    if (document.category != null) ...[
                      Text(
                        document.category!,
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Text(
                        '·',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(width: Spacings.sm),
                    ],
                    Text(
                      formatFileSize(document.fileSize),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      '·',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(width: Spacings.sm),
                    Text(
                      formatDate(document.createdAt),
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.xs),
                Row(
                  children: [
                    Icon(Icons.download_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
                    const SizedBox(width: Spacings.xs),
                    Text(
                      '${document.downloadCount} downloads',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // ─── Action buttons ────────────────────────────────────────
          Column(
            children: [
              IconButton(
                onPressed: onDownload,
                icon: Icon(Icons.download_rounded, color: cs.primary),
                tooltip: 'Download',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(Spacings.sm),
              ),
              if (isAdmin)
                IconButton(
                  onPressed: onDelete,
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  tooltip: 'Delete',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(Spacings.sm),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
