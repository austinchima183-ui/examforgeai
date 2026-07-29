import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/question_entities.dart';

// ─── MatchingPairItem ─────────────────────────────────────────────────────────

/// A single editable matching pair displayed within [MatchingPairsEditor].
class _MatchingPairItem extends StatelessWidget {
  const _MatchingPairItem({
    required this.index,
    required this.pair,
    required this.onLeftChanged,
    required this.onRightChanged,
    required this.onLeftMediaChanged,
    required this.onRightMediaChanged,
    required this.onDelete,
    this.canDelete = true,
  });

  final int index;
  final MatchingPairEntity pair;
  final ValueChanged<String> onLeftChanged;
  final ValueChanged<String> onRightChanged;
  final ValueChanged<String> onLeftMediaChanged;
  final ValueChanged<String> onRightMediaChanged;
  final VoidCallback? onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(Spacings.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ────────────────────────────────────────────
          Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                size: Spacings.mdIcon,
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(width: Spacings.sm),
              Text(
                'Pair ${index + 1}',
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              const Spacer(),
              if (canDelete && onDelete != null)
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    size: Spacings.mdIcon,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  onPressed: onDelete,
                  tooltip: 'Remove pair',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
            ],
          ),

          const SizedBox(height: Spacings.md),

          // ── Two Column Layout ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left item
              Expanded(
                child: _PairSideEditor(
                  label: 'Left Item',
                  value: pair.leftContent,
                  mediaUrl: pair.leftMediaUrl,
                  accentColor: const Color(0xFF2563EB),
                  onContentChanged: onLeftChanged,
                  onMediaChanged: onLeftMediaChanged,
                ),
              ),

              // Connection indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacings.sm),
                child: Column(
                  children: [
                    const SizedBox(height: 24.0),
                    Container(
                      padding: const EdgeInsets.all(Spacings.sm),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: isDark ? 0.20 : 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        size: Spacings.mdIcon,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Right item
              Expanded(
                child: _PairSideEditor(
                  label: 'Right Item',
                  value: pair.rightContent,
                  mediaUrl: pair.rightMediaUrl,
                  accentColor: const Color(0xFF059669),
                  onContentChanged: onRightChanged,
                  onMediaChanged: onRightMediaChanged,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Pair Side Editor ─────────────────────────────────────────────────────────

class _PairSideEditor extends StatelessWidget {
  const _PairSideEditor({
    required this.label,
    required this.value,
    this.mediaUrl,
    required this.accentColor,
    required this.onContentChanged,
    required this.onMediaChanged,
  });

  final String label;
  final String value;
  final String? mediaUrl;
  final Color accentColor;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<String> onMediaChanged;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: tt.labelSmall?.copyWith(
            color: accentColor,
            fontWeight: AppTypography.wSemiBold,
          ),
        ),
        const SizedBox(height: Spacings.xs),

        // Content field
        TextFormField(
          initialValue: value,
          onChanged: onContentChanged,
          style: tt.bodySmall?.copyWith(color: cs.onSurface),
          maxLines: 2,
          minLines: 1,
          decoration: InputDecoration(
            hintText: 'Enter content…',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacings.md,
              vertical: Spacings.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(
                color: accentColor.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(color: accentColor, width: 1.5),
            ),
          ),
        ),

        const SizedBox(height: Spacings.xs),

        // Media URL field
        TextFormField(
          initialValue: mediaUrl ?? '',
          onChanged: onMediaChanged,
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          maxLines: 1,
          decoration: InputDecoration(
            hintText: 'Media URL (optional)',
            prefixIcon: Icon(Icons.link_rounded, size: Spacings.smIcon, color: cs.onSurfaceVariant),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: Spacings.sm,
              vertical: Spacings.xs,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Spacings.smRadius),
              borderSide: BorderSide(color: cs.primary, width: 1.0),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── MatchingPairsEditor ──────────────────────────────────────────────────────

/// An editor widget for matching-type questions with two columns (left items
/// and right items), add/remove buttons, drag handles for reordering, and
/// optional media URLs for each side.
///
/// Minimum 2 pairs required.
///
/// ```dart
/// MatchingPairsEditor(
///   pairs: myPairs,
///   onPairsChanged: (newPairs) => updateState(newPairs),
/// )
/// ```
class MatchingPairsEditor extends StatefulWidget {
  const MatchingPairsEditor({
    super.key,
    required this.pairs,
    this.onPairsChanged,
    this.isEnabled = true,
  });

  /// The current list of matching pairs.
  final List<MatchingPairEntity> pairs;

  /// Called when the pairs list changes.
  final ValueChanged<List<MatchingPairEntity>>? onPairsChanged;

  /// Whether the editor is interactive.
  final bool isEnabled;

  @override
  State<MatchingPairsEditor> createState() => _MatchingPairsEditorState();
}

class _MatchingPairsEditorState extends State<MatchingPairsEditor> {
  late List<MatchingPairEntity> _pairs;
  static const int _minPairs = 2;

  @override
  void initState() {
    super.initState();
    _pairs = List.from(widget.pairs);
  }

  @override
  void didUpdateWidget(covariant MatchingPairsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pairs != widget.pairs) {
      _pairs = List.from(widget.pairs);
    }
  }

  void _notifyChanged() {
    widget.onPairsChanged?.call(List.from(_pairs));
  }

  void _addPair() {
    final now = DateTime.now();
    final newPair = MatchingPairEntity(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      questionId: '',
      leftContent: '',
      rightContent: '',
      sortOrder: _pairs.length,
      createdAt: now,
    );
    setState(() {
      _pairs.add(newPair);
    });
    _notifyChanged();
  }

  void _removePair(int index) {
    if (_pairs.length <= _minPairs) return;
    setState(() {
      _pairs.removeAt(index);
      for (var i = 0; i < _pairs.length; i++) {
        _pairs[i] = _pairs[i].copyWith(sortOrder: i);
      }
    });
    _notifyChanged();
  }

  void _updateLeftContent(int index, String content) {
    _pairs[index] = _pairs[index].copyWith(leftContent: content);
    _notifyChanged();
  }

  void _updateRightContent(int index, String content) {
    _pairs[index] = _pairs[index].copyWith(rightContent: content);
    _notifyChanged();
  }

  void _updateLeftMedia(int index, String url) {
    _pairs[index] = _pairs[index].copyWith(leftMediaUrl: url.isEmpty ? null : url);
    _notifyChanged();
  }

  void _updateRightMedia(int index, String url) {
    _pairs[index] = _pairs[index].copyWith(rightMediaUrl: url.isEmpty ? null : url);
    _notifyChanged();
  }

  void _reorderPairs(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _pairs.removeAt(oldIndex);
      _pairs.insert(newIndex, item);
      for (var i = 0; i < _pairs.length; i++) {
        _pairs[i] = _pairs[i].copyWith(sortOrder: i);
      }
    });
    _notifyChanged();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Header ────────────────────────────────────────────────
        Row(
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Matching Pairs',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_pairs.length} pairs',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),

        const SizedBox(height: Spacings.md),

        // ── Column Headers ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacings.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Left Items',
                  style: tt.labelSmall?.copyWith(
                    color: const Color(0xFF2563EB),
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
              const SizedBox(width: 48.0), // Space for arrow icon
              Expanded(
                child: Text(
                  'Right Items',
                  style: tt.labelSmall?.copyWith(
                    color: const Color(0xFF059669),
                    fontWeight: AppTypography.wSemiBold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: Spacings.sm),

        // ── Pairs List (Reorderable) ──────────────────────────────
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pairs.length,
          onReorder: widget.isEnabled ? _reorderPairs : (_, __) {},
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, _) {
                final t = Curves.easeInOut.transform(animation.value);
                return Transform.scale(
                  scale: 1.0 + (0.02 * t),
                  child: Opacity(
                    opacity: 0.85,
                    child: Material(
                      elevation: Spacings.elevationMd * t,
                      borderRadius: BorderRadius.circular(Spacings.mdRadius),
                      child: child,
                    ),
                  ),
                );
              },
            );
          },
          itemBuilder: (context, index) {
            final pair = _pairs[index];
            return Padding(
              key: ValueKey(pair.id),
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: _MatchingPairItem(
                index: index,
                pair: pair,
                onLeftChanged: widget.isEnabled
                    ? (v) => _updateLeftContent(index, v)
                    : (_) {},
                onRightChanged: widget.isEnabled
                    ? (v) => _updateRightContent(index, v)
                    : (_) {},
                onLeftMediaChanged: widget.isEnabled
                    ? (v) => _updateLeftMedia(index, v)
                    : (_) {},
                onRightMediaChanged: widget.isEnabled
                    ? (v) => _updateRightMedia(index, v)
                    : (_) {},
                onDelete: widget.isEnabled && _pairs.length > _minPairs
                    ? () => _removePair(index)
                    : null,
                canDelete: _pairs.length > _minPairs,
              ),
            );
          },
        ),

        const SizedBox(height: Spacings.sm),

        // ── Add Pair Button ───────────────────────────────────────
        if (widget.isEnabled)
          Center(
            child: AppButton(
              label: 'Add Pair',
              onPressed: _addPair,
              variant: AppButtonVariant.outlined,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ),

        const SizedBox(height: Spacings.sm),
        Text(
          'Minimum $_minPairs pairs required. Drag to reorder.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
