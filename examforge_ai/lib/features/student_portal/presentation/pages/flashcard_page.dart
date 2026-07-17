import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/themes/app_colors.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../providers/student_portal_providers.dart';
import '../../domain/entities/student_portal_entities.dart';

/// Flashcard study interface page.
///
/// Features:
/// - Deck list with: Title, Card count, Due count, Subject, Favorite toggle, Study button
/// - Create deck dialog
/// - Study mode: Card flip animation, Hint button, Rating buttons, Progress, Session summary
/// - Deck detail: Card list, Add card button, Edit card, Delete card
/// - Generate flashcards from content dialog
class FlashcardPage extends ConsumerStatefulWidget {
  const FlashcardPage({super.key});

  @override
  ConsumerState<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends ConsumerState<FlashcardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flashcardProvider.notifier).loadDecks();
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flashcardState = ref.watch(flashcardProvider);

    if (flashcardState.isStudying && flashcardState.currentCard != null) {
      return _buildStudyMode(context, flashcardState);
    }

    if (flashcardState.currentDeck != null && !flashcardState.isStudying) {
      return _buildDeckDetail(context, flashcardState);
    }

    return _buildDeckList(context, flashcardState);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DECK LIST
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDeckList(BuildContext context, FlashcardState state) {
    final cs = context.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: state.isLoading && state.decks.isEmpty
          ? const Center(child: AppLoadingSpinner())
          : state.error != null && state.decks.isEmpty
              ? AppErrorState(
                  icon: Icons.error_outline_rounded,
                  title: 'Failed to Load Decks',
                  message: state.error,
                  onRetry: () =>
                      ref.read(flashcardProvider.notifier).loadDecks(),
                )
              : state.decks.isEmpty
                  ? AppEmptyState(
                      icon: Icons.style_outlined,
                      title: 'No Flashcard Decks',
                      subtitle:
                          'Create a deck to start studying with spaced repetition.',
                      actionLabel: 'Create Deck',
                      onAction: () => _showCreateDeckDialog(context),
                    )
                  : GridView.builder(
                      padding: Spacings.paddingScreen,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: context.isMobile ? 1 : 2,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: Spacings.md,
                        mainAxisSpacing: Spacings.md,
                      ),
                      itemCount: state.decks.length,
                      itemBuilder: (context, index) {
                        final deck = state.decks[index];
                        return _DeckCard(
                          deck: deck,
                          onStudy: () {
                            ref
                                .read(flashcardProvider.notifier)
                                .startStudySession(deck.id);
                          },
                          onTap: () {
                            ref
                                .read(flashcardProvider.notifier)
                                .openDeck(deck.id);
                          },
                          onFavorite: () {
                            ref
                                .read(flashcardProvider.notifier)
                                .toggleFavorite(deck.id);
                          },
                        );
                      },
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDeckDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // DECK DETAIL
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDeckDetail(BuildContext context, FlashcardState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final deck = state.currentDeck!;

    return Scaffold(
      appBar: AppBar(
        title: Text(deck.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: () => _showGenerateDialog(context),
            tooltip: 'Generate Flashcards',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              ref.read(flashcardProvider.notifier).deleteDeck(deck.id);
            },
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: AppLoadingSpinner())
          : state.currentCards.isEmpty
              ? AppEmptyState(
                  icon: Icons.style_outlined,
                  title: 'No Cards Yet',
                  subtitle:
                      'Add cards manually or generate them with AI.',
                  actionLabel: 'Add Card',
                  onAction: () => _showAddCardDialog(context),
                )
              : ListView.builder(
                  padding: Spacings.paddingScreen,
                  itemCount: state.currentCards.length,
                  itemBuilder: (context, index) {
                    final card = state.currentCards[index];
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: Spacings.md),
                      child: _FlashcardListItem(
                        card: card,
                        onDelete: () {
                          ref
                              .read(flashcardProvider.notifier)
                              .deleteFlashcard(card.id);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCardDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Card'),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STUDY MODE
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildStudyMode(BuildContext context, FlashcardState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final card = state.currentCard!;

    if (state.isStudyComplete) {
      return _buildSessionSummary(context, state);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.currentDeck?.title ?? 'Study'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(flashcardProvider.notifier).endStudySession();
            },
            child: const Text('End Session'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: state.totalCards > 0
                ? state.currentCardIndex / state.totalCards
                : 0,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacings.lg,
              vertical: Spacings.md,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${state.currentCardIndex + 1} / ${state.totalCards}',
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                ),
                Text(
                  '${state.cardsStudied} studied · ${state.cardsCorrect} correct',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Flashcard
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacings.xl),
              child: GestureDetector(
                onTap: () {
                  if (!state.isShowingAnswer) {
                    ref.read(flashcardProvider.notifier).showAnswer();
                    _flipController.forward();
                  }
                },
                child: AnimatedBuilder(
                  animation: _flipController,
                  builder: (context, child) {
                    final angle = _flipController.value * 3.14159;
                    final isFront = _flipController.value <= 0.5;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isFront
                              ? cs.surfaceContainerLow
                              : cs.primaryContainer,
                          borderRadius:
                              BorderRadius.circular(Spacings.xlRadius),
                          boxShadow: [
                            BoxShadow(
                              color: cs.shadow.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(Spacings.xxl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isFront ? 'QUESTION' : 'ANSWER',
                                style: tt.labelMedium?.copyWith(
                                  color: isFront
                                      ? cs.onSurfaceVariant
                                      : cs.onPrimaryContainer,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: Spacings.lg),
                              Text(
                                isFront
                                    ? card.frontContent
                                    : card.backContent,
                                style: tt.headlineSmall?.copyWith(
                                  fontWeight: AppTypography.wSemiBold,
                                  color: isFront
                                      ? cs.onSurface
                                      : cs.onPrimaryContainer,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (!isFront && card.hint != null) ...[
                                const SizedBox(height: Spacings.lg),
                                Text(
                                  'Hint: ${card.hint}',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onPrimaryContainer
                                        .withValues(alpha: 0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Rating buttons (shown after flip)
          if (state.isShowingAnswer)
            Padding(
              padding: const EdgeInsets.all(Spacings.lg),
              child: Column(
                children: [
                  Text(
                    'How well did you know this?',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                  Row(
                    children: [
                      Expanded(
                        child: _RatingButton(
                          label: 'Again',
                          color: AppColors.error,
                          onPressed: () => _rateCard(FlashcardRating.again),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: _RatingButton(
                          label: 'Hard',
                          color: AppColors.warning,
                          onPressed: () => _rateCard(FlashcardRating.hard),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: _RatingButton(
                          label: 'Good',
                          color: AppColors.success,
                          onPressed: () => _rateCard(FlashcardRating.good),
                        ),
                      ),
                      const SizedBox(width: Spacings.sm),
                      Expanded(
                        child: _RatingButton(
                          label: 'Easy',
                          color: AppColors.info,
                          onPressed: () => _rateCard(FlashcardRating.easy),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(Spacings.xl),
              child: Text(
                'Tap the card to reveal the answer',
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // SESSION SUMMARY
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildSessionSummary(BuildContext context, FlashcardState state) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacings.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.emoji_events_rounded,
                size: 64,
                color: AppColors.warning,
              ),
              const SizedBox(height: Spacings.xl),
              Text(
                'Session Complete! 🎉',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: AppTypography.wBold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: Spacings.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SummaryStat(
                    label: 'Studied',
                    value: '${state.cardsStudied}',
                    color: AppColors.info,
                  ),
                  _SummaryStat(
                    label: 'Correct',
                    value: '${state.cardsCorrect}',
                    color: AppColors.success,
                  ),
                  _SummaryStat(
                    label: 'Accuracy',
                    value:
                        '${state.studyAccuracy.toStringAsFixed(0)}%',
                    color: state.studyAccuracy >= 70
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: Spacings.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    ref
                        .read(flashcardProvider.notifier)
                        .endStudySession();
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Actions ────────────────────────────────────────────────────────

  void _rateCard(FlashcardRating rating) {
    _flipController.reverse().then((_) {
      ref.read(flashcardProvider.notifier).rateCard(rating);
    });
  }

  void _showCreateDeckDialog(BuildContext context) {
    final titleController = TextEditingController();
    String? selectedSubject;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Create Deck'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Deck Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacings.md),
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    decoration: const InputDecoration(
                      labelText: 'Subject (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'math', child: Text('Mathematics')),
                      DropdownMenuItem(
                          value: 'english', child: Text('English')),
                      DropdownMenuItem(
                          value: 'biology', child: Text('Biology')),
                      DropdownMenuItem(
                          value: 'physics', child: Text('Physics')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => selectedSubject = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    ref.read(flashcardProvider.notifier).createDeck(
                      title: titleController.text.trim().isEmpty
                          ? 'New Deck'
                          : titleController.text.trim(),
                      subjectId: selectedSubject,
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCardDialog(BuildContext context) {
    final frontController = TextEditingController();
    final backController = TextEditingController();
    final hintController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Card'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: frontController,
                decoration: const InputDecoration(
                  labelText: 'Front (Question)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: backController,
                decoration: const InputDecoration(
                  labelText: 'Back (Answer)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: Spacings.md),
              TextField(
                controller: hintController,
                decoration: const InputDecoration(
                  labelText: 'Hint (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(flashcardProvider.notifier).createFlashcard(
                  frontContent: frontController.text.trim(),
                  backContent: backController.text.trim(),
                  hint: hintController.text.trim().isEmpty
                      ? null
                      : hintController.text.trim(),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showGenerateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generate Flashcards'),
          content: SizedBox(
            width: context.isMobile ? double.maxFinite : 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Deck Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: Spacings.md),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content to Generate From',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 6,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                ref.read(flashcardProvider.notifier).generateFlashcards(
                  title: titleController.text.trim().isEmpty
                      ? 'Generated Deck'
                      : titleController.text.trim(),
                  sourceContent: contentController.text.trim(),
                );
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _DeckCard extends StatelessWidget {
  const _DeckCard({
    required this.deck,
    required this.onStudy,
    required this.onTap,
    required this.onFavorite,
  });

  final FlashcardDeckEntity deck;
  final VoidCallback onStudy;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  deck.title,
                  style: tt.titleSmall?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(
                  deck.isFavorite
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: deck.isFavorite ? AppColors.error : null,
                  size: 20,
                ),
                onPressed: onFavorite,
              ),
            ],
          ),
          const SizedBox(height: Spacings.sm),
          Row(
            children: [
              if (deck.subjectName != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacings.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius:
                        BorderRadius.circular(Spacings.fullRadius),
                  ),
                  child: Text(
                    deck.subjectName!,
                    style: tt.labelSmall?.copyWith(
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
              const Spacer(),
              Icon(
                Icons.style_outlined,
                size: Spacings.smIcon,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: Spacings.xs),
              Text(
                '${deck.cardCount}',
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (deck.dueCount > 0) ...[
                const SizedBox(width: Spacings.md),
                Icon(
                  Icons.notifications_active_outlined,
                  size: Spacings.smIcon,
                  color: AppColors.warning,
                ),
                const SizedBox(width: Spacings.xs),
                Text(
                  '${deck.dueCount} due',
                  style: tt.bodySmall?.copyWith(
                    color: AppColors.warning,
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: Spacings.md),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: deck.dueCount > 0 ? onStudy : null,
              child: Text(
                deck.dueCount > 0 ? 'Study Now' : 'No Cards Due',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FlashcardListItem extends StatelessWidget {
  const _FlashcardListItem({
    required this.card,
    required this.onDelete,
  });

  final FlashcardEntity card;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.frontContent,
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: AppTypography.wSemiBold,
                    color: cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: Spacings.xs),
                Text(
                  card.backContent,
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: Spacings.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Spacings.mdRadius),
        ),
      ),
      child: Text(
        label,
        style: tt.labelSmall?.copyWith(
          fontWeight: AppTypography.wSemiBold,
        ),
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = context.textTheme;

    return Column(
      children: [
        Text(
          value,
          style: tt.headlineMedium?.copyWith(
            fontWeight: AppTypography.wBold,
            color: color,
          ),
        ),
        Text(
          label,
          style: tt.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
