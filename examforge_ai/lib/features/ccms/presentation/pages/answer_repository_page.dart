import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/core.dart';
import '../../../../../shared/widgets/widgets.dart';
import '../../domain/entities/ccms_entities.dart';
import '../providers/ccms_providers.dart';
import '../widgets/ccms_widgets.dart';

class AnswerRepositoryPage extends ConsumerStatefulWidget {
  const AnswerRepositoryPage({super.key});

  @override
  ConsumerState<AnswerRepositoryPage> createState() =>
      _AnswerRepositoryPageState();
}

class _AnswerRepositoryPageState
    extends ConsumerState<AnswerRepositoryPage> {
  String? _selectedContentItemId;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contentProvider.notifier).loadContentItems();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answerState = ref.watch(answerRepositoryProvider);
    final contentState = ref.watch(contentProvider);
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppAppBar(title: 'Answer Repository'),
      body: SingleChildScrollView(
        padding: Spacings.paddingScreen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Content Item Search/Selector ─────────────────────
            Text('Select Content Item',
                style: tt.titleMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface)),
            const SizedBox(height: Spacings.sm),
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Search content items…',
                border: const OutlineInputBorder(),
                suffixIcon: AppIconButton(
                  icon: Icons.search_rounded,
                  onPressed: () {
                    if (_searchCtrl.text.isNotEmpty) {
                      ref
                          .read(contentProvider.notifier)
                          .loadContentItems();
                    }
                  },
                ),
              ),
              onSubmitted: (_) {
                if (_searchCtrl.text.isNotEmpty) {
                  ref
                      .read(contentProvider.notifier)
                      .loadContentItems();
                }
              },
            ),
            const SizedBox(height: Spacings.md),
            if (contentState.contentItems.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedContentItemId,
                decoration: const InputDecoration(
                    labelText: 'Content Item',
                    border: OutlineInputBorder()),
                items: contentState.contentItems
                    .take(20)
                    .map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.title,
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedContentItemId = v);
                  if (v != null) {
                    ref
                        .read(answerRepositoryProvider.notifier)
                        .loadAnswer(v);
                  }
                },
              ),
            Spacings.sectionGap,

            // ── Answer Display ────────────────────────────────────
            if (answerState.isLoading)
              const Center(child: AppLoadingSpinner())
            else if (answerState.error != null)
              AppErrorState(
                message: answerState.error,
                onRetry: () {
                  if (_selectedContentItemId != null) {
                    ref
                        .read(answerRepositoryProvider.notifier)
                        .loadAnswer(_selectedContentItemId!);
                  }
                },
              )
            else if (answerState.answerEntry != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnswerDisplay(
                    entry: answerState.answerEntry!,
                    onVerify: () {
                      if (answerState.answerEntry != null) {
                        ref
                            .read(answerRepositoryProvider.notifier)
                            .verifyAnswer(
                              entryId: answerState.answerEntry!.id,
                              verifiedBy: 'current_user',
                            );
                      }
                    },
                    onEdit: () => _showEditAnswerDialog(
                        answerState.answerEntry!),
                  ),
                  Spacings.sectionGap,

                  // ── Step-by-Step Explanation ────────────────────
                  if (answerState.answerEntry!.stepByStepExplanation !=
                      null) ...[
                    _AnswerSection(
                      title: 'Step-by-Step Explanation',
                      icon: Icons.route_rounded,
                      content: answerState
                          .answerEntry!.stepByStepExplanation!,
                    ),
                    Spacings.sectionGap,
                  ],

                  // ── Marking Scheme ──────────────────────────────
                  if (answerState.answerEntry!.markingScheme !=
                      null) ...[
                    _AnswerSection(
                      title: 'Marking Scheme',
                      icon: Icons.grading_rounded,
                      content: answerState
                          .answerEntry!.markingScheme!,
                    ),
                    Spacings.sectionGap,
                  ],

                  // ── Common Mistakes ─────────────────────────────
                  if (answerState.answerEntry!.commonMistakes !=
                      null &&
                      answerState.answerEntry!.commonMistakes!
                          .isNotEmpty) ...[
                    Text('Common Mistakes',
                        style: tt.titleMedium?.copyWith(
                            fontWeight: AppTypography.wSemiBold,
                            color: cs.onSurface)),
                    const SizedBox(height: Spacings.sm),
                    ...answerState.answerEntry!.commonMistakes!
                        .asMap()
                        .entries
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(
                                  bottom: Spacings.sm),
                              child: AppCard(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding:
                                          const EdgeInsets.all(Spacings.xs),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            Spacings.borderRadiusSm,
                                      ),
                                      child: Text('${e.key + 1}',
                                          style: tt.labelSmall?.copyWith(
                                              color: AppColors.warning,
                                              fontWeight:
                                                  AppTypography.wSemiBold)),
                                    ),
                                    const SizedBox(width: Spacings.sm),
                                    Expanded(
                                      child: Text(e.value,
                                          style: tt.bodyMedium),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                    Spacings.sectionGap,
                  ],

                  // ── Action Buttons ──────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: answerState.answerEntry!.isVerified
                              ? 'Unverify'
                              : 'Verify',
                          onPressed: () {
                            if (answerState.answerEntry!.isVerified) {
                              // Unverify logic
                            } else {
                              ref
                                  .read(
                                      answerRepositoryProvider.notifier)
                                  .verifyAnswer(
                                    entryId:
                                        answerState.answerEntry!.id,
                                    verifiedBy: 'current_user',
                                  );
                            }
                          },
                          icon: answerState.answerEntry!.isVerified
                              ? Icons.verified_user_rounded
                              : Icons.verified_outlined,
                          variant: answerState.answerEntry!.isVerified
                              ? AppButtonVariant.tonal
                              : AppButtonVariant.elevated,
                        ),
                      ),
                      const SizedBox(width: Spacings.md),
                      Expanded(
                        child: AppButton(
                          label: 'Edit Answer',
                          onPressed: () => _showEditAnswerDialog(
                              answerState.answerEntry!),
                          variant: AppButtonVariant.outlined,
                          icon: Icons.edit_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              AppEmptyState.noData(
                  subtitle: 'Select a content item to view its answer'),
          ],
        ),
      ),
    );
  }

  void _showEditAnswerDialog(AnswerEntry entry) {
    final answerCtrl =
        TextEditingController(text: entry.correctAnswer);
    final explanationCtrl = TextEditingController(
        text: entry.stepByStepExplanation ?? '');
    final schemeCtrl =
        TextEditingController(text: entry.markingScheme ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Answer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: answerCtrl,
                decoration: const InputDecoration(
                    labelText: 'Correct Answer *',
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: explanationCtrl,
                decoration: const InputDecoration(
                    labelText: 'Step-by-Step Explanation',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                maxLines: 5,
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: schemeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Marking Scheme',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                maxLines: 4,
              ),
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
              ref.read(answerRepositoryProvider.notifier).updateAnswer(
                    AnswerEntry(
                      id: entry.id,
                      contentItemId: entry.contentItemId,
                      correctAnswer: answerCtrl.text,
                      stepByStepExplanation: explanationCtrl.text.isEmpty
                          ? null
                          : explanationCtrl.text,
                      markingScheme: schemeCtrl.text.isEmpty
                          ? null
                          : schemeCtrl.text,
                      commonMistakes: entry.commonMistakes,
                      isVerified: entry.isVerified,
                      verifiedBy: entry.verifiedBy,
                      verifiedAt: entry.verifiedAt,
                      createdAt: entry.createdAt,
                      updatedAt: DateTime.now(),
                    ),
                  );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}

class _AnswerSection extends StatelessWidget {
  const _AnswerSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final String content;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 16, color: cs.primary),
          const SizedBox(width: Spacings.xs),
          Text(title,
              style: tt.titleMedium?.copyWith(
                  fontWeight: AppTypography.wSemiBold, color: cs.primary)),
        ]),
        const SizedBox(height: Spacings.sm),
        Container(
          width: double.infinity,
          padding: Spacings.paddingCard,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: Spacings.borderRadiusMd,
          ),
          child: Text(content, style: tt.bodyMedium),
        ),
      ],
    );
  }
}
