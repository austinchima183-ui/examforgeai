import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class CurriculaManagementPage extends ConsumerStatefulWidget {
  const CurriculaManagementPage({super.key});

  @override
  ConsumerState<CurriculaManagementPage> createState() =>
      _CurriculaManagementPageState();
}

class _CurriculaManagementPageState
    extends ConsumerState<CurriculaManagementPage> {
  Curriculum? _selectedCurriculum;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(curriculumProvider.notifier).loadCurricula();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(curriculumProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final filtered = state.curricula.where((c) {
      if (_searchQuery.isNotEmpty &&
          !c.name.toLowerCase().contains(_searchQuery.toLowerCase()) &&
          !c.code.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppAppBar(
        title: 'Curricula Management',
        isSearchMode: _searchQuery.isNotEmpty,
        searchHint: 'Search curricula…',
        onSearchToggle: () => setState(() => _searchQuery = ''),
        onSearchChanged: (q) => setState(() => _searchQuery = q),
        actions: [
          AppIconButton(
            icon: Icons.add_rounded,
            onPressed: () => _showCreateDialog(),
            tooltip: 'Create Curriculum',
          ),
        ],
      ),
      body: state.isLoading && state.curricula.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null
              ? AppErrorState(
                  message: state.error,
                  onRetry: () =>
                      ref.read(curriculumProvider.notifier).loadCurricula(),
                )
              : state.curricula.isEmpty
                  ? AppEmptyState.noData(
                      subtitle: 'No curricula found',
                      actionLabel: 'Create Curriculum',
                      onAction: () => _showCreateDialog(),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(curriculumProvider.notifier)
                          .loadCurricula(),
                      child: ListView.builder(
                        padding: Spacings.paddingScreen,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final curriculum = filtered[index];
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: Spacings.md),
                            child: AppCard(
                              onTap: () =>
                                  _showCurriculumDetail(curriculum),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          curriculum.name,
                                          style: tt.titleSmall?.copyWith(
                                            fontWeight: AppTypography.wSemiBold,
                                            color: cs.onSurface,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      CurriculumTypeBadge(
                                          type: curriculum.curriculumType),
                                      const SizedBox(width: Spacings.sm),
                                      Switch(
                                        value: curriculum.isActive,
                                        onChanged: (v) {
                                          ref
                                              .read(
                                                  curriculumProvider.notifier)
                                              .updateCurriculum(Curriculum(
                                                id: curriculum.id,
                                                name: curriculum.name,
                                                code: curriculum.code,
                                                curriculumType:
                                                    curriculum.curriculumType,
                                                countryCode:
                                                    curriculum.countryCode,
                                                isActive: v,
                                                description:
                                                    curriculum.description,
                                                publisher:
                                                    curriculum.publisher,
                                                edition: curriculum.edition,
                                                createdAt:
                                                    curriculum.createdAt,
                                                updatedAt: DateTime.now(),
                                              ));
                                        },
                                        activeColor: cs.primary,
                                      ),
                                    ],
                                  ),
                                  if (curriculum.description != null &&
                                      curriculum.description!.isNotEmpty) ...[
                                    const SizedBox(height: Spacings.xs),
                                    Text(
                                      curriculum.description!,
                                      style: tt.bodySmall?.copyWith(
                                          color: cs.onSurfaceVariant),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const SizedBox(height: Spacings.sm),
                                  Row(
                                    children: [
                                      Icon(Icons.flag_rounded,
                                          size: 14,
                                          color: cs.onSurfaceVariant),
                                      const SizedBox(width: Spacings.xs),
                                      Text(curriculum.countryCode,
                                          style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant)),
                                      if (curriculum.edition != null) ...[
                                        const SizedBox(width: Spacings.md),
                                        Icon(Icons.bookmark_outline_rounded,
                                            size: 14,
                                            color: cs.onSurfaceVariant),
                                        const SizedBox(width: Spacings.xs),
                                        Text('Ed: ${curriculum.edition}',
                                            style: tt.bodySmall?.copyWith(
                                                color: cs.onSurfaceVariant)),
                                      ],
                                      const Spacer(),
                                      Text(
                                          _formatDate(curriculum.createdAt),
                                          style: tt.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant)),
                                    ],
                                  ),
                                  const SizedBox(height: Spacings.sm),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      AppIconButton(
                                        icon: Icons.edit_outlined,
                                        onPressed: () =>
                                            _showEditDialog(curriculum),
                                        variant:
                                            AppIconButtonVariant.standard,
                                        size: AppButtonSize.small,
                                        tooltip: 'Edit',
                                      ),
                                      AppIconButton(
                                        icon: Icons.delete_outline_rounded,
                                        onPressed: () =>
                                            _confirmDelete(curriculum),
                                        variant:
                                            AppIconButtonVariant.standard,
                                        size: AppButtonSize.small,
                                        tooltip: 'Delete',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showCurriculumDetail(Curriculum curriculum) {
    ref.read(curriculumProvider.notifier).loadVersions(curriculum.id);
    ref.read(curriculumProvider.notifier).loadLevelMappings(curriculum.id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, controller) {
          final versionState = ref.watch(curriculumProvider);
          return SingleChildScrollView(
            controller: controller,
            padding: Spacings.paddingScreen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(curriculum.name,
                          style: context.textTheme.headlineSmall?.copyWith(
                              fontWeight: AppTypography.wSemiBold)),
                    ),
                    AppIconButton(
                      icon: Icons.close_rounded,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: Spacings.sm),
                Row(
                  children: [
                    CurriculumTypeBadge(type: curriculum.curriculumType),
                    const SizedBox(width: Spacings.sm),
                    Text('Code: ${curriculum.code}',
                        style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant)),
                    if (curriculum.publisher != null) ...[
                      const SizedBox(width: Spacings.md),
                      Text('Publisher: ${curriculum.publisher}',
                          style: context.textTheme.bodySmall?.copyWith(
                              color:
                                  context.colorScheme.onSurfaceVariant)),
                    ],
                    if (curriculum.edition != null) ...[
                      const SizedBox(width: Spacings.md),
                      Text('Edition: ${curriculum.edition}',
                          style: context.textTheme.bodySmall?.copyWith(
                              color:
                                  context.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
                const SizedBox(height: Spacings.xl),

                // Versions
                Text('Versions',
                    style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: context.colorScheme.primary)),
                const SizedBox(height: Spacings.sm),
                if (versionState.versions.isEmpty)
                  Text('No versions available',
                      style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant))
                else
                  ...versionState.versions.map((v) => Card(
                        child: ListTile(
                          title: Text('v${v.versionNumber}'),
                          subtitle: Text(v.changeSummary),
                          trailing: v.isCurrent
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: Spacings.sm,
                                      vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.success
                                        .withValues(alpha: 0.15),
                                    borderRadius:
                                        Spacings.borderRadiusSm,
                                  ),
                                  child: Text('Current',
                                      style: AppTypography.labelSmall
                                          .copyWith(
                                              color: AppColors.success,
                                              fontWeight:
                                                  AppTypography
                                                      .wSemiBold)),
                                )
                              : null,
                          dense: true,
                        ),
                      )),
                const SizedBox(height: Spacings.xl),

                // Level Mappings
                Text('Level Mappings',
                    style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: AppTypography.wSemiBold,
                        color: context.colorScheme.primary)),
                const SizedBox(height: Spacings.sm),
                if (versionState.levelMappings.isEmpty)
                  Text('No level mappings',
                      style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant))
                else
                  ...versionState.levelMappings.map((m) => Card(
                        child: SwitchListTile(
                          value: m.isApplicable,
                          onChanged: (_) {},
                          title: Text('Level: ${m.educationalLevelId}'),
                          subtitle: m.notes != null
                              ? Text(m.notes!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis)
                              : null,
                          dense: true,
                        ),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    var type = CurriculumType.nerdc;
    final countryCtrl = TextEditingController(text: 'NG');
    final descCtrl = TextEditingController();
    final publisherCtrl = TextEditingController();
    final editionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Curriculum'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Code',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<CurriculumType>(
                  value: type,
                  decoration: const InputDecoration(
                      labelText: 'Type *', border: OutlineInputBorder()),
                  items: CurriculumType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: publisherCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Publisher',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: editionCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Edition',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: countryCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Country Code',
                        border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            AppButton(
              label: 'Create',
              onPressed: () {
                ref.read(curriculumProvider.notifier).createCurriculum(
                  Curriculum(
                    id: '',
                    name: nameCtrl.text,
                    code: codeCtrl.text.isEmpty
                        ? nameCtrl.text.toUpperCase().replaceAll(' ', '_')
                        : codeCtrl.text,
                    curriculumType: type,
                    countryCode: countryCtrl.text,
                    isActive: true,
                    description: descCtrl.text.isEmpty ? null : descCtrl.text,
                    publisher:
                        publisherCtrl.text.isEmpty ? null : publisherCtrl.text,
                    edition:
                        editionCtrl.text.isEmpty ? null : editionCtrl.text,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Curriculum curriculum) {
    final nameCtrl = TextEditingController(text: curriculum.name);
    final codeCtrl = TextEditingController(text: curriculum.code);
    var type = curriculum.curriculumType;
    final countryCtrl =
        TextEditingController(text: curriculum.countryCode);
    final descCtrl =
        TextEditingController(text: curriculum.description ?? '');
    final publisherCtrl =
        TextEditingController(text: curriculum.publisher ?? '');
    final editionCtrl =
        TextEditingController(text: curriculum.edition ?? '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Curriculum'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Name *',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                DropdownButtonFormField<CurriculumType>(
                  value: type,
                  decoration: const InputDecoration(
                      labelText: 'Type', border: OutlineInputBorder()),
                  items: CurriculumType.values
                      .map((t) =>
                          DropdownMenuItem(value: t, child: Text(t.label)))
                      .toList(),
                  onChanged: (v) => setState(() => type = v!),
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: publisherCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Publisher',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: editionCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Edition',
                        border: OutlineInputBorder())),
                const SizedBox(height: Spacings.md),
                TextField(
                    controller: countryCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Country Code',
                        border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            AppButton(
              label: 'Save',
              onPressed: () {
                ref.read(curriculumProvider.notifier).updateCurriculum(
                  Curriculum(
                    id: curriculum.id,
                    name: nameCtrl.text,
                    code: codeCtrl.text,
                    curriculumType: type,
                    countryCode: countryCtrl.text,
                    isActive: curriculum.isActive,
                    description:
                        descCtrl.text.isEmpty ? null : descCtrl.text,
                    publisher: publisherCtrl.text.isEmpty
                        ? null
                        : publisherCtrl.text,
                    edition:
                        editionCtrl.text.isEmpty ? null : editionCtrl.text,
                    parentCurriculumId: curriculum.parentCurriculumId,
                    metadata: curriculum.metadata,
                    createdBy: curriculum.createdBy,
                    createdAt: curriculum.createdAt,
                    updatedAt: DateTime.now(),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Curriculum curriculum) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Curriculum'),
        content: Text(
            'Are you sure you want to delete "${curriculum.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          AppButton(
            label: 'Delete',
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
