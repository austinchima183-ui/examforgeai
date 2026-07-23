import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/themes/app_typography.dart';
import '../../core/themes/spacings.dart';

// ─── AppSearchBar ─────────────────────────────────────────────────────────────

/// A full-featured search bar widget with debounced search, recent searches
/// display, clear button, and focus management.
///
/// ```dart
/// AppSearchBar(
///   hint: 'Search exams…',
///   onChanged: (query) => performSearch(query),
///   onSubmitted: (query) => submitSearch(query),
///   suggestions: ['Math', 'Science', 'History'],
/// )
/// ```
class AppSearchBar extends StatefulWidget {
  const AppSearchBar({
    super.key,
    this.hint,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.debounceTime = const Duration(milliseconds: 300),
    this.suggestions = const [],
    this.onSuggestionTap,
    this.recentSearches = const [],
    this.onRecentSearchTap,
    this.onClearRecentSearches,
    this.showRecentSearches = true,
    this.maxRecentSearches = 5,
    this.autofocus = false,
    this.focusNode,
    this.elevation,
    this.backgroundColor,
    this.shape,
  });

  /// Hint text inside the search bar.
  final String? hint;

  /// Debounced callback fired when the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback fired when the user submits the search (enter key).
  final ValueChanged<String>? onSubmitted;

  /// Optional external text controller.
  final TextEditingController? controller;

  /// Debounce duration before [onChanged] fires. Defaults to 300 ms.
  final Duration debounceTime;

  /// List of suggestion items displayed below the search bar.
  final List<String> suggestions;

  /// Called when a suggestion is tapped.
  final ValueChanged<String>? onSuggestionTap;

  /// List of recent search strings.
  final List<String> recentSearches;

  /// Called when a recent search item is tapped.
  final ValueChanged<String>? onRecentSearchTap;

  /// Called when the user requests to clear recent searches.
  final VoidCallback? onClearRecentSearches;

  /// Whether to show the recent searches section.
  final bool showRecentSearches;

  /// Maximum number of recent searches to display.
  final int maxRecentSearches;

  /// Whether to auto-focus the search bar.
  final bool autofocus;

  /// Optional focus node.
  final FocusNode? focusNode;

  /// Elevation of the search bar card.
  final double? elevation;

  /// Background colour override.
  final Color? backgroundColor;

  /// Custom shape for the search bar container.
  final OutlinedBorder? shape;

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounce;
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChange);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant AppSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _controller.removeListener(_onTextChange);
      if (oldWidget.controller == null) {
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_onTextChange);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _focusNode.removeListener(_onFocusChange);
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onTextChange);
    _focusNode.removeListener(_onFocusChange);
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }

    // Debounced onChanged
    _debounce?.cancel();
    _debounce = Timer(widget.debounceTime, () {
      widget.onChanged?.call(_controller.text);
    });
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _clear() {
    _controller.clear();
    _debounce?.cancel();
    widget.onChanged?.call('');
  }

  void _submit(String value) {
    if (value.trim().isNotEmpty) {
      widget.onSubmitted?.call(value.trim());
    }
  }

  List<String> get _visibleRecentSearches {
    return widget.recentSearches.take(widget.maxRecentSearches).toList();
  }

  bool get _showDropdown =>
      _isFocused &&
      ((_hasText && widget.suggestions.isNotEmpty) ||
          (!_hasText && widget.showRecentSearches && _visibleRecentSearches.isNotEmpty));

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Search Input ────────────────────────────────────────────────
        Material(
          elevation: widget.elevation ?? 0,
          color: widget.backgroundColor ?? cs.surfaceContainerHigh,
          shape: widget.shape ??
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.lgRadius),
                side: BorderSide(
                  color: _isFocused
                      ? cs.primary
                      : cs.outlineVariant.withValues(alpha: 0.5),
                  width: _isFocused ? 2.0 : 1.0,
                ),
              ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: Spacings.lg),
                child: Icon(
                  Icons.search_rounded,
                  color: cs.onSurfaceVariant,
                  size: Spacings.mdIcon,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autofocus,
                  style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                  textInputAction: TextInputAction.search,
                  onSubmitted: _submit,
                  decoration: InputDecoration(
                    hintText: widget.hint ?? 'Search…',
                    hintStyle: tt.bodyLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: Spacings.md,
                      vertical: Spacings.md,
                    ),
                    isDense: true,
                  ),
                ),
              ),
              if (_hasText)
                IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: cs.onSurfaceVariant,
                    size: Spacings.mdIcon,
                  ),
                  onPressed: _clear,
                  tooltip: 'Clear',
                  splashRadius: Spacings.lg,
                ),
            ],
          ),
        ),

        // ── Suggestions / Recent Searches Dropdown ─────────────────────
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.only(top: Spacings.xs),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(Spacings.mdRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Recent searches (shown when no text is entered)
                if (!_hasText &&
                    widget.showRecentSearches &&
                    _visibleRecentSearches.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacings.lg,
                      Spacings.md,
                      Spacings.lg,
                      Spacings.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent',
                          style: tt.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: AppTypography.wSemiBold,
                          ),
                        ),
                        if (widget.onClearRecentSearches != null)
                          TextButton(
                            onPressed: widget.onClearRecentSearches,
                            style: TextButton.styleFrom(
                              minimumSize: Size.zero,
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacings.sm,
                                vertical: Spacings.xs,
                              ),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Clear',
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ..._visibleRecentSearches.map((item) => _SearchListItem(
                        icon: Icons.history_rounded,
                        text: item,
                        onTap: () {
                          _controller.text = item;
                          widget.onRecentSearchTap?.call(item);
                          widget.onChanged?.call(item);
                          _focusNode.unfocus();
                        },
                      ),),
                ],

                // Suggestions (shown when text is entered)
                if (_hasText && widget.suggestions.isNotEmpty) ...[
                  ...widget.suggestions.map((item) => _SearchListItem(
                        icon: Icons.search_rounded,
                        text: item,
                        query: _controller.text,
                        onTap: () {
                          _controller.text = item;
                          widget.onSuggestionTap?.call(item);
                          widget.onChanged?.call(item);
                          _submit(item);
                          _focusNode.unfocus();
                        },
                      ),),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Private Helper: Search List Item ─────────────────────────────────────────

class _SearchListItem extends StatelessWidget {
  const _SearchListItem({
    required this.icon,
    required this.text,
    required this.onTap,
    this.query,
  });

  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final String? query;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    // Highlight matching portion of the suggestion
    TextSpan buildTextSpan() {
      if (query != null && query!.isNotEmpty) {
        final lowerText = text.toLowerCase();
        final lowerQuery = query!.toLowerCase();
        final matchIndex = lowerText.indexOf(lowerQuery);

        if (matchIndex >= 0) {
          return TextSpan(
            children: [
              TextSpan(
                text: text.substring(0, matchIndex),
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              TextSpan(
                text: text.substring(matchIndex, matchIndex + query!.length),
                style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: AppTypography.wSemiBold,
                ),
              ),
              TextSpan(
                text: text.substring(matchIndex + query!.length),
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          );
        }
      }
      return TextSpan(
        text: text,
        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacings.lg,
          vertical: Spacings.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: Spacings.mdIcon, color: cs.onSurfaceVariant),
            const SizedBox(width: Spacings.md),
            Expanded(
              child: RichText(text: buildTextSpan()),
            ),
          ],
        ),
      ),
    );
  }
}
