import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/themes/app_typography.dart';
import '../../../../core/themes/spacings.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/entities/question_entities.dart';

// ─── OrderingItemRow ──────────────────────────────────────────────────────────

/// A single editable ordering item displayed within [OrderingItemsEditor].
class _OrderingItemRow extends StatelessWidget {
  const _OrderingItemRow({
    required this.index,
    required this.item,
    required this.onContentChanged,
    required this.onMediaUrlChanged,
    required this.onDelete,
    this.canDelete = true,
  });

  final int index;
  final OrderingItemEntity item;
  final ValueChanged<String> onContentChanged;
  final ValueChanged<String> onMediaUrlChanged;
  final VoidCallback? onDelete;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;
    final isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacings.md,
        vertical: Spacings.sm,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(Spacings.mdRadius),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Drag handle
          Icon(
            Icons.drag_indicator_rounded,
            size: Spacings.mdIcon,
            color: cs.onSurfaceVariant.withValues(alpha: 0.4),
          ),

          const SizedBox(width: Spacings.sm),

          // Correct position number badge
          Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: isDark ? 0.25 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${item.correctPosition}',
                style: tt.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: AppTypography.wBold,
                ),
              ),
            ),
          ),

          const SizedBox(width: Spacings.sm),

          // Content field
          Expanded(
            child: TextFormField(
              initialValue: item.content,
              onChanged: onContentChanged,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
              maxLines: 1,
              decoration: InputDecoration(
                hintText: 'Item ${index + 1} content…',
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
                    color: cs.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Spacings.smRadius),
                  borderSide: BorderSide(color: cs.primary, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(width: Spacings.sm),

          // Media URL icon button
          SizedBox(
            width: 36.0,
            height: 36.0,
            child: IconButton(
              icon: Icon(
                item.mediaUrl != null && item.mediaUrl!.isNotEmpty
                    ? Icons.link_rounded
                    : Icons.link_off_rounded,
                size: Spacings.smIcon,
                color: item.mediaUrl != null && item.mediaUrl!.isNotEmpty
                    ? cs.primary
                    : cs.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              onPressed: () => _showMediaUrlDialog(context),
              tooltip: 'Media URL',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ),

          // Delete button
          if (canDelete && onDelete != null)
            SizedBox(
              width: 36.0,
              height: 36.0,
              child: IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: Spacings.smIcon,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                onPressed: onDelete,
                tooltip: 'Remove item',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showMediaUrlDialog(BuildContext context) async {
    final controller = TextEditingController(text: item.mediaUrl ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Media URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter media URL…',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null) {
      onMediaUrlChanged(result);
    }
  }
}

// ─── OrderingItemsEditor ──────────────────────────────────────────────────────

/// An editor widget for ordering-type questions with a reorderable list of
/// items, each showing its correct position number. Includes drag handles
/// for reordering, add/remove buttons, and a minimum of 3 items.
///
/// ```dart
/// OrderingItemsEditor(
///   items: myItems,
///   onItemsChanged: (newItems) => updateState(newItems),
/// )
/// ```
class OrderingItemsEditor extends StatefulWidget {
  const OrderingItemsEditor({
    super.key,
    required this.items,
    this.onItemsChanged,
    this.isEnabled = true,
  });

  /// The current list of ordering items.
  final List<OrderingItemEntity> items;

  /// Called when the items list changes.
  final ValueChanged<List<OrderingItemEntity>>? onItemsChanged;

  /// Whether the editor is interactive.
  final bool isEnabled;

  @override
  State<OrderingItemsEditor> createState() => _OrderingItemsEditorState();
}

class _OrderingItemsEditorState extends State<OrderingItemsEditor> {
  late List<OrderingItemEntity> _items;
  static const int _minItems = 3;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant OrderingItemsEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _items = List.from(widget.items);
    }
  }

  void _notifyChanged() {
    widget.onItemsChanged?.call(List.from(_items));
  }

  void _addItem() {
    final now = DateTime.now();
    final newItem = OrderingItemEntity(
      id: 'new_${DateTime.now().millisecondsSinceEpoch}',
      questionId: '',
      content: '',
      correctPosition: _items.length + 1,
      createdAt: now,
    );
    setState(() {
      _items.add(newItem);
    });
    _notifyChanged();
  }

  void _removeItem(int index) {
    if (_items.length <= _minItems) return;
    setState(() {
      _items.removeAt(index);
      // Re-index correct positions
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(correctPosition: i + 1);
      }
    });
    _notifyChanged();
  }

  void _updateContent(int index, String content) {
    _items[index] = _items[index].copyWith(content: content);
    _notifyChanged();
  }

  void _updateMediaUrl(int index, String url) {
    _items[index] = _items[index].copyWith(mediaUrl: url.isEmpty ? null : url);
    _notifyChanged();
  }

  void _reorderItems(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      // Re-index correct positions after reorder
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _items[i].copyWith(correctPosition: i + 1);
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
              Icons.reorder_rounded,
              size: Spacings.mdIcon,
              color: cs.primary,
            ),
            const SizedBox(width: Spacings.sm),
            Text(
              'Ordering Items',
              style: tt.titleSmall?.copyWith(
                fontWeight: AppTypography.wSemiBold,
                color: cs.onSurface,
              ),
            ),
            const Spacer(),
            Text(
              '${_items.length} items',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),

        const SizedBox(height: Spacings.xs),
        Text(
          'Arrange items in the correct order. The number shows the correct position.',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),

        const SizedBox(height: Spacings.md),

        // ── Items List (Reorderable) ──────────────────────────────
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          onReorder: widget.isEnabled ? _reorderItems : (_, __) {},
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
            final item = _items[index];
            return Padding(
              key: ValueKey(item.id),
              padding: const EdgeInsets.only(bottom: Spacings.sm),
              child: _OrderingItemRow(
                index: index,
                item: item,
                onContentChanged: widget.isEnabled
                    ? (v) => _updateContent(index, v)
                    : (_) {},
                onMediaUrlChanged: widget.isEnabled
                    ? (v) => _updateMediaUrl(index, v)
                    : (_) {},
                onDelete: widget.isEnabled && _items.length > _minItems
                    ? () => _removeItem(index)
                    : null,
                canDelete: _items.length > _minItems,
              ),
            );
          },
        ),

        const SizedBox(height: Spacings.sm),

        // ── Add Item Button ───────────────────────────────────────
        if (widget.isEnabled)
          Center(
            child: AppButton(
              label: 'Add Item',
              onPressed: _addItem,
              variant: AppButtonVariant.outlined,
              icon: Icons.add_rounded,
              size: AppButtonSize.small,
            ),
          ),

        const SizedBox(height: Spacings.sm),
        Text(
          'Minimum $_minItems items required. Drag items to reorder.',
          style: tt.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
