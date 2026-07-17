import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/student_portal_entities.dart';
import '../../domain/usecases/student_portal_usecases.dart';
import 'student_dashboard_provider.dart';

// ═══════════════════════════════════════════════════════════════════════
// FLASHCARD STATE
// ═══════════════════════════════════════════════════════════════════════

/// Immutable state snapshot for the Flashcard feature.
///
/// Tracks flashcard decks, the currently open deck with its cards,
/// study session state (current card, answer visibility, score),
/// loading flags, and errors.
class FlashcardState {
  const FlashcardState({
    this.decks = const [],
    this.currentDeck,
    this.currentCards = const [],
    this.currentCard,
    this.currentCardIndex = 0,
    this.isShowingAnswer = false,
    this.isLoading = false,
    this.isStudying = false,
    this.error,
    this.cardsStudied = 0,
    this.cardsCorrect = 0,
    this._currentPage = 1,
    this.hasMoreDecks = true,
  });

  /// All flashcard decks for the current student.
  final List<FlashcardDeckEntity> decks;

  /// The currently selected deck, or `null`.
  final FlashcardDeckEntity? currentDeck;

  /// Cards in the currently selected deck (or due cards during study).
  final List<FlashcardEntity> currentCards;

  /// The currently displayed flashcard during study, or `null`.
  final FlashcardEntity? currentCard;

  /// The index of the current card being studied (0-based).
  final int currentCardIndex;

  /// Whether the answer side of the current card is visible.
  final bool isShowingAnswer;

  /// Whether the initial deck list load is in progress.
  final bool isLoading;

  /// Whether a study session is active.
  final bool isStudying;

  /// The most recent error message, or `null`.
  final String? error;

  /// Number of cards studied in the current session.
  final int cardsStudied;

  /// Number of cards answered correctly in the current session.
  final int cardsCorrect;

  /// Current page number for deck pagination (1-based).
  // ignore: unused_field
  final int _currentPage;

  /// Whether there are more deck pages to load.
  final bool hasMoreDecks;

  /// Current page number for deck pagination.
  int get currentPage => _currentPage;

  /// Whether any async operation is in progress.
  bool get isBusy => isLoading;

  /// Number of decks currently loaded.
  int get deckCount => decks.length;

  /// Total number of cards in the current deck.
  int get totalCards => currentCards.length;

  /// Whether there are more cards to study.
  bool get hasMoreCards =>
      isStudying && currentCardIndex < currentCards.length - 1;

  /// Accuracy percentage for the current study session.
  double get studyAccuracy =>
      cardsStudied == 0 ? 0 : (cardsCorrect / cardsStudied) * 100;

  /// Whether the study session is complete (all cards reviewed).
  bool get isStudyComplete =>
      isStudying && currentCardIndex >= currentCards.length;

  /// Creates a copy of this state with the given fields replaced.
  FlashcardState copyWith({
    List<FlashcardDeckEntity>? decks,
    FlashcardDeckEntity? currentDeck,
    List<FlashcardEntity>? currentCards,
    FlashcardEntity? currentCard,
    int? currentCardIndex,
    bool? isShowingAnswer,
    bool? isLoading,
    bool? isStudying,
    String? error,
    int? cardsStudied,
    int? cardsCorrect,
    int? currentPage,
    bool? hasMoreDecks,
    bool clearCurrentDeck = false,
    bool clearCurrentCard = false,
  }) {
    return FlashcardState(
      decks: decks ?? this.decks,
      currentDeck: clearCurrentDeck
          ? null
          : (currentDeck ?? this.currentDeck),
      currentCards: currentCards ?? this.currentCards,
      currentCard: clearCurrentCard
          ? null
          : (currentCard ?? this.currentCard),
      currentCardIndex: currentCardIndex ?? this.currentCardIndex,
      isShowingAnswer: isShowingAnswer ?? this.isShowingAnswer,
      isLoading: isLoading ?? this.isLoading,
      isStudying: isStudying ?? this.isStudying,
      error: error,
      cardsStudied: cardsStudied ?? this.cardsStudied,
      cardsCorrect: cardsCorrect ?? this.cardsCorrect,
      _currentPage: currentPage ?? _currentPage,
      hasMoreDecks: hasMoreDecks ?? this.hasMoreDecks,
    );
  }

  /// Clears the current error message.
  FlashcardState clearError() => copyWith(error: null);
}

// ═══════════════════════════════════════════════════════════════════════
// FLASHCARD NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Riverpod [StateNotifier] that manages the Flashcard feature's state.
///
/// All flashcard operations flow through this notifier, which:
/// 1. Sets the appropriate loading flag before each async operation
/// 2. Delegates to the appropriate use case
/// 3. Updates decks, cards, study session state on success
/// 4. Sets [error] on failure
class FlashcardNotifier extends StateNotifier<FlashcardState> {
  FlashcardNotifier({
    required GetFlashcardDecksUseCase getFlashcardDecks,
    required CreateFlashcardDeckUseCase createFlashcardDeck,
    required GetFlashcardsUseCase getFlashcards,
    required CreateFlashcardUseCase createFlashcard,
    required RateFlashcardUseCase rateFlashcard,
    required GenerateFlashcardsUseCase generateFlashcards,
    required DeleteFlashcardDeckUseCase deleteFlashcardDeck,
    required String? studentId,
    required String? schoolId,
  })  : _getFlashcardDecks = getFlashcardDecks,
        _createFlashcardDeck = createFlashcardDeck,
        _getFlashcards = getFlashcards,
        _createFlashcard = createFlashcard,
        _rateFlashcard = rateFlashcard,
        _generateFlashcards = generateFlashcards,
        _deleteFlashcardDeck = deleteFlashcardDeck,
        _studentId = studentId,
        _schoolId = schoolId,
        super(const FlashcardState());

  final GetFlashcardDecksUseCase _getFlashcardDecks;
  final CreateFlashcardDeckUseCase _createFlashcardDeck;
  final GetFlashcardsUseCase _getFlashcards;
  final CreateFlashcardUseCase _createFlashcard;
  final RateFlashcardUseCase _rateFlashcard;
  final GenerateFlashcardsUseCase _generateFlashcards;
  final DeleteFlashcardDeckUseCase _deleteFlashcardDeck;
  final String? _studentId;
  final String? _schoolId;

  static const int _pageSize = 20;

  // ─── Load Decks (first page) ───────────────────────────────────────

  /// Loads the first page of flashcard decks for the current student.
  Future<void> loadDecks() async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _getFlashcardDecks(
      studentId: _studentId!,
      page: 1,
      pageSize: _pageSize,
    );

    result.fold(
      onSuccess: (decks) {
        state = state.copyWith(
          isLoading: false,
          decks: decks,
          currentPage: 1,
          hasMoreDecks: decks.length >= _pageSize,
          error: null,
        );
        AppLogger.info('Loaded ${decks.length} flashcard decks (page 1)');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to load flashcard decks: $failure');
      },
    );
  }

  // ─── Open Deck ─────────────────────────────────────────────────────

  /// Opens a flashcard deck, loading all its cards.
  Future<void> openDeck(String deckId) async {
    state = state.copyWith(isLoading: true, error: null);

    final cardsResult = await _getFlashcards(deckId: deckId);

    // Also update the deck in state if it's in the list.
    final deck = state.decks.where((d) => d.id == deckId).firstOrNull;

    cardsResult.fold(
      onSuccess: (cards) {
        state = state.copyWith(
          isLoading: false,
          currentDeck: deck,
          currentCards: cards,
          currentCard: cards.isNotEmpty ? cards.first : null,
          currentCardIndex: 0,
          isShowingAnswer: false,
          isStudying: false,
          error: null,
        );
        AppLogger.info(
          'Opened deck: $deckId with ${cards.length} cards',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to open deck: $failure');
      },
    );
  }

  // ─── Create Deck ───────────────────────────────────────────────────

  /// Creates a new flashcard deck with the given parameters.
  Future<void> createDeck({
    required String title,
    String? subjectId,
    String? topicId,
    String? description,
    String sourceType = 'manual',
    String? sourceId,
    List<String> tags = const [],
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _createFlashcardDeck(
      studentId: _studentId!,
      schoolId: _schoolId,
      subjectId: subjectId,
      topicId: topicId,
      title: title,
      description: description,
      sourceType: sourceType,
      sourceId: sourceId,
      tags: tags,
    );

    result.fold(
      onSuccess: (deck) {
        final updatedList = [deck, ...state.decks];
        state = state.copyWith(
          isLoading: false,
          decks: updatedList,
          currentDeck: deck,
          error: null,
        );
        AppLogger.info('Created flashcard deck: ${deck.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create deck: $failure');
      },
    );
  }

  // ─── Delete Deck ───────────────────────────────────────────────────

  /// Deletes a flashcard deck by ID.
  Future<void> deleteDeck(String deckId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _deleteFlashcardDeck(deckId: deckId);

    result.fold(
      onSuccess: (_) {
        final updatedList =
            state.decks.where((d) => d.id != deckId).toList();
        state = state.copyWith(
          isLoading: false,
          decks: updatedList,
          currentDeck: state.currentDeck?.id == deckId
              ? null
              : state.currentDeck,
          currentCards: state.currentDeck?.id == deckId
              ? const []
              : state.currentCards,
          currentCard: state.currentDeck?.id == deckId
              ? null
              : state.currentCard,
          isStudying: state.currentDeck?.id == deckId
              ? false
              : state.isStudying,
          error: null,
        );
        AppLogger.info('Deleted flashcard deck: $deckId');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to delete deck: $failure');
      },
    );
  }

  // ─── Toggle Favorite ───────────────────────────────────────────────

  /// Toggles the favorite status of a flashcard deck.
  Future<void> toggleFavorite(String deckId) async {
    final deck = state.decks.where((d) => d.id == deckId).firstOrNull;
    if (deck == null) return;

    final updatedDeck = deck.copyWith(isFavorite: !deck.isFavorite);
    final updatedList = state.decks
        .map((d) => d.id == deckId ? updatedDeck : d)
        .toList();

    state = state.copyWith(
      decks: updatedList,
      currentDeck: state.currentDeck?.id == deckId
          ? updatedDeck
          : state.currentDeck,
    );
    AppLogger.info(
      'Toggled favorite for deck $deckId: ${updatedDeck.isFavorite}',
    );
  }

  // ─── Start Study Session ───────────────────────────────────────────

  /// Starts a study session for the given deck, loading due cards.
  Future<void> startStudySession(String deckId) async {
    state = state.copyWith(isLoading: true, error: null);

    final result = await _getFlashcards(deckId: deckId, dueOnly: true);

    result.fold(
      onSuccess: (dueCards) {
        if (dueCards.isEmpty) {
          state = state.copyWith(
            isLoading: false,
            error: 'No cards due for review in this deck.',
          );
          AppLogger.info('No due cards for deck: $deckId');
          return;
        }

        final deck = state.decks.where((d) => d.id == deckId).firstOrNull;

        state = state.copyWith(
          isLoading: false,
          currentDeck: deck,
          currentCards: dueCards,
          currentCard: dueCards.first,
          currentCardIndex: 0,
          isShowingAnswer: false,
          isStudying: true,
          cardsStudied: 0,
          cardsCorrect: 0,
          error: null,
        );
        AppLogger.info(
          'Started study session for deck: $deckId (${dueCards.length} due cards)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to start study session: $failure');
      },
    );
  }

  // ─── Show Answer ───────────────────────────────────────────────────

  /// Flips the current card to reveal the answer side.
  void showAnswer() {
    state = state.copyWith(isShowingAnswer: true);
  }

  // ─── Rate Card ─────────────────────────────────────────────────────

  /// Rates the current card using SM-2 spaced repetition and moves
  /// to the next card.
  Future<void> rateCard(FlashcardRating rating) async {
    final card = state.currentCard;
    if (card == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _rateFlashcard(
      cardId: card.id,
      rating: rating,
    );

    result.fold(
      onSuccess: (updatedCard) {
        final isCorrect =
            rating == FlashcardRating.good || rating == FlashcardRating.easy;
        final newCardsStudied = state.cardsStudied + 1;
        final newCardsCorrect =
            state.cardsCorrect + (isCorrect ? 1 : 0);

        // Update the card in the list.
        final updatedCards = state.currentCards
            .map((c) => c.id == updatedCard.id ? updatedCard : c)
            .toList();

        // Move to next card.
        final nextIndex = state.currentCardIndex + 1;
        final hasNext = nextIndex < state.currentCards.length;

        state = state.copyWith(
          isLoading: false,
          currentCards: updatedCards,
          currentCard: hasNext ? updatedCards[nextIndex] : null,
          currentCardIndex: nextIndex,
          isShowingAnswer: false,
          cardsStudied: newCardsStudied,
          cardsCorrect: newCardsCorrect,
          isStudying: hasNext || state.isStudying,
          error: null,
        );
        AppLogger.info(
          'Rated card ${card.id} as ${rating.label} '
          '(studied: $newCardsStudied, correct: $newCardsCorrect)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to rate card: $failure');
      },
    );
  }

  // ─── Next Card ─────────────────────────────────────────────────────

  /// Moves to the next card in the study session.
  void nextCard() {
    if (!state.hasMoreCards) return;
    final nextIndex = state.currentCardIndex + 1;
    state = state.copyWith(
      currentCardIndex: nextIndex,
      currentCard: state.currentCards[nextIndex],
      isShowingAnswer: false,
    );
  }

  // ─── End Study Session ─────────────────────────────────────────────

  /// Ends the current study session and returns to the deck view.
  void endStudySession() {
    state = state.copyWith(
      isStudying: false,
      isShowingAnswer: false,
      clearCurrentCard: true,
      currentCardIndex: 0,
    );
    AppLogger.info(
      'Ended study session '
      '(studied: ${state.cardsStudied}, correct: ${state.cardsCorrect}, '
      'accuracy: ${state.studyAccuracy.toStringAsFixed(1)}%)',
    );
  }

  // ─── Create Flashcard ──────────────────────────────────────────────

  /// Creates a new flashcard in the current deck.
  Future<void> createFlashcard({
    required String frontContent,
    required String backContent,
    String? hint,
    String? imageUrl,
    String difficulty = 'medium',
  }) async {
    final deck = state.currentDeck;
    if (deck == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _createFlashcard(
      deckId: deck.id,
      frontContent: frontContent,
      backContent: backContent,
      hint: hint,
      imageUrl: imageUrl,
      difficulty: difficulty,
    );

    result.fold(
      onSuccess: (card) {
        final updatedCards = [...state.currentCards, card];
        final updatedDeck = deck.copyWith(
          cardCount: deck.cardCount + 1,
        );
        final updatedDecks = state.decks
            .map((d) => d.id == deck.id ? updatedDeck : d)
            .toList();

        state = state.copyWith(
          isLoading: false,
          currentCards: updatedCards,
          currentDeck: updatedDeck,
          decks: updatedDecks,
          error: null,
        );
        AppLogger.info('Created flashcard: ${card.id}');
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to create flashcard: $failure');
      },
    );
  }

  // ─── Delete Flashcard ──────────────────────────────────────────────

  /// Removes a flashcard from the current deck's local list.
  void deleteFlashcard(String cardId) {
    final updatedCards =
        state.currentCards.where((c) => c.id != cardId).toList();
    final deck = state.currentDeck;

    FlashcardDeckEntity? updatedDeck;
    if (deck != null) {
      updatedDeck = deck.copyWith(
        cardCount: deck.cardCount > 0 ? deck.cardCount - 1 : 0,
      );
    }

    final updatedDecks = updatedDeck != null
        ? state.decks.map((d) => d.id == updatedDeck!.id ? updatedDeck : d).toList()
        : state.decks;

    state = state.copyWith(
      currentCards: updatedCards,
      currentDeck: updatedDeck,
      decks: updatedDecks,
      currentCard: state.currentCard?.id == cardId
          ? null
          : state.currentCard,
    );
    AppLogger.info('Removed flashcard: $cardId');
  }

  // ─── Generate Flashcards ───────────────────────────────────────────

  /// Generates flashcards from content using AI.
  Future<void> generateFlashcards({
    required String title,
    required String sourceContent,
    String? subjectId,
    String? topicId,
    String sourceType = 'ai_generated',
    int cardCount = 10,
  }) async {
    if (_studentId == null) return;

    state = state.copyWith(isLoading: true, error: null);

    final result = await _generateFlashcards(
      studentId: _studentId!,
      schoolId: _schoolId,
      title: title,
      subjectId: subjectId,
      topicId: topicId,
      sourceContent: sourceContent,
      sourceType: sourceType,
      cardCount: cardCount,
    );

    result.fold(
      onSuccess: (deck) {
        final updatedList = [deck, ...state.decks];
        state = state.copyWith(
          isLoading: false,
          decks: updatedList,
          currentDeck: deck,
          error: null,
        );
        AppLogger.info(
          'Generated flashcard deck: ${deck.id} (${deck.cardCount} cards)',
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          isLoading: false,
          error: _mapFailureToMessage(failure),
        );
        AppLogger.warning('Failed to generate flashcards: $failure');
      },
    );
  }

  // ─── Clear Error ───────────────────────────────────────────────────

  /// Clears the current error message from the state.
  void clearError() {
    state = state.clearError();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════

  /// Maps a [Failure] to a user-friendly error message.
  String _mapFailureToMessage(Failure failure) {
    return failure.when(
      server: (message, _, __) => message,
      cache: (message) => message,
      auth: (message, _) => message,
      network: (message) => message,
      validation: (message, _) => message,
      notFound: (message) => message,
      unauthorized: (message) => message,
      forbidden: (message) => message,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FLASHCARD PROVIDER
// ═══════════════════════════════════════════════════════════════════════

/// Provides the [FlashcardNotifier] with all required use cases.
final flashcardProvider =
    StateNotifierProvider<FlashcardNotifier, FlashcardState>((ref) {
  return FlashcardNotifier(
    getFlashcardDecks: ref.watch(getFlashcardDecksUseCaseProvider),
    createFlashcardDeck: ref.watch(createFlashcardDeckUseCaseProvider),
    getFlashcards: ref.watch(getFlashcardsUseCaseProvider),
    createFlashcard: ref.watch(createFlashcardUseCaseProvider),
    rateFlashcard: ref.watch(rateFlashcardUseCaseProvider),
    generateFlashcards: ref.watch(generateFlashcardsUseCaseProvider),
    deleteFlashcardDeck: ref.watch(deleteFlashcardDeckUseCaseProvider),
    studentId: ref.watch(currentStudentIdProvider),
    schoolId: ref.watch(studentSchoolIdProvider),
  );
});
