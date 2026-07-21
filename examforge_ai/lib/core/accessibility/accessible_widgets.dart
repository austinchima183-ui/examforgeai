// ============================================================================
// ExamForge AI — Accessibility Widgets Library
// ============================================================================
// Production-ready accessible widget wrappers that enforce:
//   - Proper Semantics for screen readers
//   - Screen reader labels on all interactive elements
//   - Logical focus order
//   - Keyboard navigation support
//   - Minimum 44×44 touch targets (WCAG 2.2 AA)
//   - Accessible dialogs with focus trapping
//   - Accessible forms with error announcements
//   - Accessible loading states
//   - Accessible error states
//
// These widgets are designed to be drop-in replacements for standard
// Flutter widgets with accessibility built in by default.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// ═══════════════════════════════════════════════════════════════════════
// MINIMUM TOUCH TARGET SIZE (WCAG 2.2 AA: 44×44 logical pixels)
// ═══════════════════════════════════════════════════════════════════════

const double kMinTouchTarget = 44.0;

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE BUTTON
// ═══════════════════════════════════════════════════════════════════════

/// A button that meets WCAG 2.2 AA accessibility requirements:
/// - Minimum 44×44 touch target
/// - Semantic label for screen readers
/// - Focus indicator for keyboard navigation
/// - Tooltip for mouse hover
/// - Enabled/disabled state announced to screen readers
class AccessiblyButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final bool isLoading;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;

  const AccessiblyButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.isLoading = false,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final isDisabled = effectiveOnPressed == null;

    return Semantics(
      button: true,
      enabled: !isDisabled && !isLoading,
      label: semanticLabel,
      child: Tooltip(
        message: tooltip ?? semanticLabel ?? '',
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinTouchTarget,
            minHeight: kMinTouchTarget,
          ),
          child: ElevatedButton(
            onPressed: effectiveOnPressed,
            focusNode: focusNode,
            autofocus: autofocus,
            style: (style ?? ElevatedButton.styleFrom()).merge(
              ElevatedButton.styleFrom(
                minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
                // Ensure visible focus indicator
                visualDensity: VisualDensity.standard,
              ),
            ),
            child: isLoading
                ? Semantics(
                    label: 'Loading',
                    liveRegion: true,
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                : child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE TEXT FIELD
// ═══════════════════════════════════════════════════════════════════════

/// A text field that meets WCAG 2.2 AA accessibility requirements:
/// - Semantic label for screen readers (via decoration)
/// - Error messages announced to screen readers (live region)
/// - Minimum touch target height
/// - Focus indicator
/// - Keyboard navigation support
class AccessiblyTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? semanticLabel;
  final String? errorMessage;
  final bool obscureText;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onTap;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final bool enabled;

  const AccessiblyTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.semanticLabel,
    this.errorMessage,
    this.obscureText = false,
    this.keyboardType,
    this.focusNode,
    this.onChanged,
    this.validator,
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.textInputAction,
    this.onFieldSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? label;
    final hasError = errorMessage != null && errorMessage!.isNotEmpty;

    return Semantics(
      label: effectiveLabel,
      textField: true,
      enabled: enabled,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: kMinTouchTarget,
            ),
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onChanged: onChanged,
              validator: validator,
              onTap: onTap,
              readOnly: readOnly,
              autofocus: autofocus,
              maxLines: maxLines,
              enabled: enabled,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: prefixIcon,
                suffixIcon: suffixIcon,
                errorText: errorMessage,
                // Ensure minimum height for touch target
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          // Announce errors to screen readers via live region
          if (hasError)
            Semantics(
              liveRegion: true,
              label: 'Error: $errorMessage',
              child: Padding(
                padding: const EdgeInsets.only(top: 4, left: 16),
                child: Text(
                  errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE CARD (for dashboard metric cards, etc.)
// ═══════════════════════════════════════════════════════════════════════

/// A card with proper accessibility semantics for screen readers.
class AccessiblyCard extends StatelessWidget {
  final Widget child;
  final String? semanticLabel;
  final String? semanticHint;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const AccessiblyCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.semanticHint,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      hint: semanticHint,
      child: Card(
        margin: margin ?? const EdgeInsets.all(8),
        color: color,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          // Ensure minimum touch target
          child: ConstrainedBox(
            constraints: onTap != null
                ? const BoxConstraints(minHeight: kMinTouchTarget)
                : const BoxConstraints(),
            child: Padding(
              padding: padding ?? const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE LOADING INDICATOR
// ═══════════════════════════════════════════════════════════════════════

/// A loading indicator that announces its state to screen readers.
class AccessiblyLoading extends StatelessWidget {
  final String message;
  final bool showProgress;
  final double? progress;

  const AccessiblyLoading({
    super.key,
    this.message = 'Loading',
    this.showProgress = false,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message,
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgress && progress != null)
            CircularProgressIndicator(value: progress)
          else
            const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE ERROR STATE
// ═══════════════════════════════════════════════════════════════════════

/// An error state widget that announces the error to screen readers.
class AccessiblyError extends StatelessWidget {
  final String title;
  final String? message;
  final String? retryLabel;
  final VoidCallback? onRetry;
  final IconData icon;

  const AccessiblyError({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.retryLabel = 'Retry',
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Error: $title${message != null ? '. $message' : ''}',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AccessiblyButton(
                onPressed: onRetry,
                semanticLabel: retryLabel,
                child: Text(retryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE DIALOG
// ═══════════════════════════════════════════════════════════════════════

/// Shows an accessible dialog that:
/// - Traps focus within the dialog
/// - Announces the dialog title to screen readers
/// - Supports keyboard navigation (Escape to close)
/// - Returns focus to the triggering element on close
Future<T?> showAccessiblyDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  required String semanticLabel,
  bool barrierDismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) {
      return Semantics(
        label: semanticLabel,
        scopesRoute: true,
        explicitChildNodes: true,
        child: builder(context),
      );
    },
  );
}

/// Shows an accessible confirmation dialog.
Future<bool> showAccessiblyConfirm({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) async {
  final result = await showAccessiblyDialog<bool>(
    context: context,
    semanticLabel: '$title. $message',
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Semantics(
        liveRegion: true,
        child: Text(message),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );

  return result ?? false;
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE STATUS INDICATOR
// ═══════════════════════════════════════════════════════════════════════

/// A status indicator that uses both color AND text/icons for accessibility.
/// Color-blind users can still understand the status from the text label.
class AccessiblyStatusIndicator extends StatelessWidget {
  final String label;
  final StatusType type;

  const AccessiblyStatusIndicator({
    super.key,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _getStatusStyle(context);

    return Semantics(
      label: '${type.name}: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  (Color, IconData) _getStatusStyle(BuildContext context) {
    return switch (type) {
      StatusType.success => (Colors.green, Icons.check_circle),
      StatusType.warning => (Colors.orange, Icons.warning),
      StatusType.error => (Theme.of(context).colorScheme.error, Icons.error),
      StatusType.info => (Colors.blue, Icons.info),
      StatusType.loading => (Colors.grey, Icons.hourglass_empty),
    };
  }
}

enum StatusType { success, warning, error, info, loading }

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE SECTION HEADING
// ═══════════════════════════════════════════════════════════════════════

/// A section heading that is properly announced as a header by screen readers.
class AccessiblyHeading extends StatelessWidget {
  final String text;
  final HeadingLevel level;
  final TextStyle? style;

  const AccessiblyHeading({
    super.key,
    required this.text,
    this.level = HeadingLevel.h2,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        switch (level) {
          HeadingLevel.h1 => Theme.of(context).textTheme.headlineLarge,
          HeadingLevel.h2 => Theme.of(context).textTheme.headlineMedium,
          HeadingLevel.h3 => Theme.of(context).textTheme.headlineSmall,
        };

    return Semantics(
      header: true,
      headingLevel: level._toSemanticsLevel,
      child: Text(text, style: effectiveStyle),
    );
  }
}

enum HeadingLevel { h1, h2, h3 }

extension on HeadingLevel {
  int get _toSemanticsLevel => switch (this) {
        HeadingLevel.h1 => 1,
        HeadingLevel.h2 => 2,
        HeadingLevel.h3 => 3,
      };
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE TIMER DISPLAY (for CBT exam)
// ═══════════════════════════════════════════════════════════════════════

/// A timer display that announces time changes to screen readers.
/// Critical for CBT exam accessibility — visually impaired students
/// must be able to track remaining time.
class AccessiblyTimerDisplay extends StatefulWidget {
  final Duration remaining;
  final bool isWarning;
  final bool isCritical;
  final VoidCallback? onTimeUp;

  const AccessiblyTimerDisplay({
    super.key,
    required this.remaining,
    this.isWarning = false,
    this.isCritical = false,
    this.onTimeUp,
  });

  @override
  State<AccessiblyTimerDisplay> createState() => _AccessiblyTimerDisplayState();
}

class _AccessiblyTimerDisplayState extends State<AccessiblyTimerDisplay> {
  Duration? _lastAnnounced;
  String _lastLiveRegionText = '';

  @override
  Widget build(BuildContext context) {
    final timeText = _formatDuration(widget.remaining);

    // Determine announcement frequency based on urgency
    final shouldAnnounce = _shouldAnnounceTime(widget.remaining);

    if (shouldAnnounce) {
      _lastAnnounced = widget.remaining;
      _lastLiveRegionText = _getAnnouncementText(timeText);
    }

    final textColor = widget.isCritical
        ? Theme.of(context).colorScheme.error
        : widget.isWarning
            ? Colors.orange
            : Theme.of(context).colorScheme.onSurface;

    return Semantics(
      label: 'Time remaining: $timeText',
      liveRegion: true,
      value: _lastLiveRegionText,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isCritical
              ? Theme.of(context).colorScheme.error.withOpacity(0.1)
              : widget.isWarning
                  ? Colors.orange.withOpacity(0.1)
                  : null,
          borderRadius: BorderRadius.circular(8),
          border: widget.isCritical
              ? Border.all(color: Theme.of(context).colorScheme.error)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.timer,
              size: 20,
              color: textColor,
              semanticLabel: 'Timer icon',
            ),
            const SizedBox(width: 8),
            Text(
              timeText,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (widget.isCritical)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  'URGENT',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _shouldAnnounceTime(Duration remaining) {
    if (_lastAnnounced == null) return true;

    // Always announce when entering warning zone
    if (widget.isCritical && !_wasCritical()) return true;
    if (widget.isWarning && !_wasWarning()) return true;

    // Announce every minute during normal time
    if (remaining.inMinutes != _lastAnnounced!.inMinutes) return true;

    // Announce every 10 seconds in critical zone
    if (widget.isCritical) {
      final secondsBucket = (remaining.inSeconds / 10).floor();
      final lastBucket = (_lastAnnounced!.inSeconds / 10).floor();
      if (secondsBucket != lastBucket) return true;
    }

    return false;
  }

  bool _wasCritical() {
    return _lastAnnounced != null && _lastAnnounced!.inMinutes < 5;
  }

  bool _wasWarning() {
    return _lastAnnounced != null && _lastAnnounced!.inMinutes < 15;
  }

  String _getAnnouncementText(String timeText) {
    if (widget.isCritical) {
      return 'Warning: Only $timeText remaining!';
    }
    if (widget.isWarning) {
      return 'Time remaining: $timeText';
    }
    return 'Time remaining: $timeText';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

// ═══════════════════════════════════════════════════════════════════════
// ACCESSIBLE QUESTION NAVIGATOR (for CBT exam)
// ═══════════════════════════════════════════════════════════════════════

/// A question navigator that is fully accessible to screen readers.
/// Each question button announces its status (answered/unanswered/flagged).
class AccessiblyQuestionNavigator extends StatelessWidget {
  final int totalQuestions;
  final int currentQuestion;
  final Set<int> answeredQuestions;
  final Set<int> flaggedQuestions;
  final ValueChanged<int> onQuestionTap;

  const AccessiblyQuestionNavigator({
    super.key,
    required this.totalQuestions,
    required this.currentQuestion,
    required this.answeredQuestions,
    required this.flaggedQuestions,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Question navigator. $totalQuestions questions total. '
          '${answeredQuestions.length} answered. '
          '${flaggedQuestions.length} flagged for review. '
          'Currently on question ${currentQuestion + 1}',
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: List.generate(totalQuestions, (index) {
          final isAnswered = answeredQuestions.contains(index);
          final isFlagged = flaggedQuestions.contains(index);
          final isCurrent = index == currentQuestion;

          return _QuestionButton(
            index: index,
            isAnswered: isAnswered,
            isFlagged: isFlagged,
            isCurrent: isCurrent,
            onTap: () => onQuestionTap(index),
          );
        }),
      ),
    );
  }
}

class _QuestionButton extends StatelessWidget {
  final int index;
  final bool isAnswered;
  final bool isFlagged;
  final bool isCurrent;
  final VoidCallback onTap;

  const _QuestionButton({
    required this.index,
    required this.isAnswered,
    required this.isFlagged,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final semanticLabel = _buildSemanticLabel();

    return Semantics(
      button: true,
      label: semanticLabel,
      selected: isCurrent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: kMinTouchTarget,
            minHeight: kMinTouchTarget,
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getBackgroundColor(context),
              borderRadius: BorderRadius.circular(8),
              border: isCurrent
                  ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
                  : isFlagged
                      ? Border.all(color: Colors.orange, width: 2)
                      : null,
            ),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isFlagged)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Semantics(
                        label: 'Flagged',
                        child: Icon(Icons.flag, size: 10, color: Colors.orange),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>['Question ${index + 1}'];
    if (isCurrent) parts.add('current');
    if (isAnswered) parts.add('answered');
    if (isFlagged) parts.add('flagged for review');
    if (!isAnswered && !isCurrent) parts.add('not answered');
    return parts.join(', ');
  }

  Color? _getBackgroundColor(BuildContext context) {
    if (isCurrent) return Theme.of(context).colorScheme.primary.withOpacity(0.2);
    if (isFlagged) return Colors.orange.withOpacity(0.1);
    if (isAnswered) return Colors.green.withOpacity(0.1);
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SCREEN READER ANNOUNCEMENT UTILITY
// ═══════════════════════════════════════════════════════════════════════

/// Announces a message to screen readers using the LiveRegion semantics.
class ScreenReaderAnnouncer {
  static void announce(BuildContext context, String message) {
    // Use the semantics system to make an announcement
    SemanticsService.announce(message, TextDirection.ltr);
  }
}
