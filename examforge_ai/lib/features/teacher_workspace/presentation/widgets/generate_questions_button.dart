import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../routing/route_names.dart';
import '../../domain/usecases/generate_questions_from_content_usecase.dart';
import '../providers/generate_questions_provider.dart';

/// The CRITICAL "Generate Questions" button that appears on every AI-generated
/// resource in the Teacher Workspace.
///
/// Sends content to the AI Question Generation Engine via
/// [GenerateQuestionsNotifier.generateFromContent]. While generating, the
/// button shows a loading spinner and disables interaction.
class GenerateQuestionsButton extends ConsumerWidget {
  /// The type of source resource (e.g., 'lesson_plan', 'worksheet').
  final String resourceType;

  /// The unique ID of the source resource.
  final String resourceId;

  /// Human-readable name of the resource (for display purposes).
  final String resourceName;

  /// Optional subject for context-aware question generation.
  final String? subject;

  /// Optional topic for context-aware question generation.
  final String? topic;

  const GenerateQuestionsButton({
    super.key,
    required this.resourceType,
    required this.resourceId,
    required this.resourceName,
    this.subject,
    this.topic,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(generateQuestionsProvider);
    final isGenerating =
        state.isGenerating && state.sourceResourceId == resourceId;

    return OutlinedButton.icon(
      onPressed: isGenerating ? null : () => _handleGenerate(context, ref),
      icon: isGenerating
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.quiz_rounded, size: 18),
      label: Text(isGenerating ? 'Generating...' : 'Generate Questions'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  /// Triggers AI question generation and navigates to the AI Generator
  /// review page.
  void _handleGenerate(BuildContext context, WidgetRef ref) {
    ref.read(generateQuestionsProvider.notifier).generateFromContent(
      GenerateQuestionsFromContentParams(
        resourceType: resourceType,
        resourceId: resourceId,
        questionCount: 10,
      ),
    );

    // Navigate to AI Generator review page
    context.go(
      '${RouteNames.aiGeneratorReview}?source=workspace&resourceType=$resourceType&resourceId=$resourceId',
    );
  }
}
