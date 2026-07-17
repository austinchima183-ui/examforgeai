import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/themes/spacings.dart';
import '../../core/extensions/context_extensions.dart';

// ─── AppTextField ─────────────────────────────────────────────────────────────

/// A fully-featured text field following Material 3 [InputDecoration] styling
/// with support for validation, icons, obscure text, form integration, and
/// character counting.
///
/// ```dart
/// AppTextField(
///   label: 'Email',
///   hint: 'you@example.com',
///   prefixIcon: Icons.email_outlined,
///   keyboardType: TextInputType.emailAddress,
///   isRequired: true,
///   validator: (v) => v!.isEmpty ? 'Required' : null,
/// )
/// ```
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.controller,
    this.focusNode,
    this.keyboardType,
    this.textInputAction,
    this.errorText,
    this.isRequired = false,
    this.inputFormatters,
    this.autofillHints,
    this.autocorrect = true,
    this.textCapitalization = TextCapitalization.none,
    this.onTap,
    this.enableSuggestions = true,
  });

  /// Floating label text.
  final String? label;

  /// Hint text shown when the field is empty.
  final String? hint;

  /// Icon displayed before the text.
  final IconData? prefixIcon;

  /// Widget displayed after the text.
  final Widget? suffixIcon;

  /// Whether to hide the text (e.g. passwords).
  final bool obscureText;

  /// Whether the field is enabled.
  final bool enabled;

  /// Whether the field is read-only.
  final bool readOnly;

  /// Maximum number of lines.
  final int maxLines;

  /// Minimum number of lines.
  final int? minLines;

  /// Maximum character count.
  final int? maxLength;

  /// Form field validator.
  final FormFieldValidator<String>? validator;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onFieldSubmitted;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Focus node.
  final FocusNode? focusNode;

  /// Keyboard type.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// External error text.
  final String? errorText;

  /// When `true`, appends an asterisk to the label.
  final bool isRequired;

  /// Input formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Autofill hints.
  final Iterable<String>? autofillHints;

  /// Whether to enable autocorrect.
  final bool autocorrect;

  /// Text capitalization strategy.
  final TextCapitalization textCapitalization;

  /// Called when the field is tapped.
  final GestureTapCallback? onTap;

  /// Whether to enable suggestions.
  final bool enableSuggestions;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    final effectiveLabel = isRequired && label != null ? '$label *' : label;

    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      inputFormatters: inputFormatters,
      autofillHints: autofillHints,
      autocorrect: autocorrect,
      textCapitalization: textCapitalization,
      onTap: onTap,
      enableSuggestions: enableSuggestions,
      style: context.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        labelText: effectiveLabel,
        hintText: hint,
        errorText: errorText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: Spacings.mdIcon)
            : null,
        suffixIcon: suffixIcon,
        counterStyle: context.textTheme.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── AppPasswordField ─────────────────────────────────────────────────────────

/// A password text field with a visibility toggle button.
///
/// ```dart
/// AppPasswordField(
///   label: 'Password',
///   controller: _passwordCtrl,
///   validator: (v) => v!.length < 8 ? 'Too short' : null,
/// )
/// ```
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.isEnabled = true,
    this.isRequired = false,
    this.errorText,
    this.textInputAction,
    this.autofillHints,
  });

  /// Floating label text.
  final String? label;

  /// Hint text.
  final String? hint;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Focus node.
  final FocusNode? focusNode;

  /// Form field validator.
  final FormFieldValidator<String>? validator;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onFieldSubmitted;

  /// Whether the field is enabled.
  final bool isEnabled;

  /// When `true`, appends an asterisk to the label.
  final bool isRequired;

  /// External error text.
  final String? errorText;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Autofill hints for password fields.
  final Iterable<String>? autofillHints;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return AppTextField(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      focusNode: widget.focusNode,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onFieldSubmitted,
      enabled: widget.isEnabled,
      isRequired: widget.isRequired,
      errorText: widget.errorText,
      obscureText: _obscured,
      prefixIcon: Icons.lock_outline,
      suffixIcon: IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          size: Spacings.mdIcon,
          color: cs.onSurfaceVariant,
        ),
        onPressed: () => setState(() => _obscured = !_obscured),
        tooltip: _obscured ? 'Show password' : 'Hide password',
      ),
      textInputAction: widget.textInputAction ?? TextInputAction.done,
      autofillHints: widget.autofillHints ??
          const [AutofillHints.password],
      keyboardType: TextInputType.visiblePassword,
    );
  }
}

// ─── AppSearchField ───────────────────────────────────────────────────────────

/// A search text field with a search icon, clear button, and optional
/// submit handling.
///
/// ```dart
/// AppSearchField(
///   hint: 'Search exams…',
///   onChanged: (query) => performSearch(query),
///   onSubmitted: (query) => submitSearch(query),
/// )
/// ```
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  /// Hint text.
  final String? hint;

  /// Text editing controller.
  final TextEditingController? controller;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the search.
  final ValueChanged<String>? onSubmitted;

  /// Focus node.
  final FocusNode? focusNode;

  /// Whether to auto-focus the field.
  final bool autofocus;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChange);
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    // Note: onChanged is already triggered by the controller listener.
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;

    return AppTextField(
      controller: _controller,
      focusNode: widget.focusNode,
      hint: widget.hint ?? 'Search…',
      prefixIcon: Icons.search,
      suffixIcon: _hasText
          ? IconButton(
              icon: Icon(
                Icons.clear,
                size: Spacings.mdIcon,
                color: cs.onSurfaceVariant,
              ),
              onPressed: _clear,
              tooltip: 'Clear',
            )
          : null,
      onChanged: (_) {}, // handled by controller listener
      onFieldSubmitted: widget.onSubmitted,
      autofocus: widget.autofocus,
      textInputAction: TextInputAction.search,
      keyboardType: TextInputType.text,
    );
  }
}

// ─── AppDropdownField<T> ─────────────────────────────────────────────────────

/// A dropdown form field following Material 3 styling with optional label,
/// icon, and validation.
///
/// ```dart
/// AppDropdownField<String>(
///   label: 'Subject',
///   items: ['Math', 'Science', 'History'],
///   selectedItem: 'Math',
///   onChanged: (v) => selectSubject(v),
///   itemLabel: (v) => v,
/// )
/// ```
class AppDropdownField<T> extends StatelessWidget {
  const AppDropdownField({
    super.key,
    this.label,
    this.hint,
    required this.items,
    this.selectedItem,
    required this.onChanged,
    required this.itemLabel,
    this.prefixIcon,
    this.validator,
    this.isEnabled = true,
    this.isRequired = false,
    this.itemBuilder,
  });

  /// Floating label text.
  final String? label;

  /// Hint text.
  final String? hint;

  /// List of dropdown items.
  final List<T> items;

  /// Currently selected item.
  final T? selectedItem;

  /// Called when an item is selected.
  final ValueChanged<T?> onChanged;

  /// Maps an item to its display label.
  final String Function(T) itemLabel;

  /// Optional prefix icon.
  final IconData? prefixIcon;

  /// Form field validator.
  final FormFieldValidator<T>? validator;

  /// Whether the field is enabled.
  final bool isEnabled;

  /// When `true`, appends an asterisk to the label.
  final bool isRequired;

  /// Optional custom item builder for rich dropdown items.
  final DropdownMenuItem<T> Function(T)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final tt = context.textTheme;

    final effectiveLabel = isRequired && label != null ? '$label *' : label;

    return DropdownButtonFormField<T>(
      value: selectedItem,
      items: itemBuilder != null
          ? items.map(itemBuilder!).toList()
          : items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(
                      itemLabel(item),
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    ),
                  ))
              .toList(),
      onChanged: isEnabled ? onChanged : null,
      validator: validator,
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      icon: Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
      decoration: InputDecoration(
        labelText: effectiveLabel,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: Spacings.mdIcon)
            : null,
      ),
      dropdownColor: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(Spacings.mdRadius),
      menuMaxHeight: 300,
    );
  }
}

// ─── AppDateField ─────────────────────────────────────────────────────────────

/// A date picker field that shows a [DatePickerDialog] when tapped and
/// displays the selected date in the text field.
///
/// ```dart
/// AppDateField(
///   label: 'Exam Date',
///   selectedDate: DateTime.now(),
///   onDateSelected: (date) => setDate(date),
/// )
/// ```
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    this.label,
    this.hint,
    this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
    this.isEnabled = true,
    this.isRequired = false,
    this.dateFormat,
    this.prefixIcon,
    this.validator,
  });

  /// Floating label text.
  final String? label;

  /// Hint text.
  final String? hint;

  /// Currently selected date.
  final DateTime? selectedDate;

  /// Called when a date is selected.
  final ValueChanged<DateTime> onDateSelected;

  /// First selectable date.
  final DateTime? firstDate;

  /// Last selectable date.
  final DateTime? lastDate;

  /// Whether the field is enabled.
  final bool isEnabled;

  /// When `true`, appends an asterisk to the label.
  final bool isRequired;

  /// Date format pattern. Defaults to `MMM dd, yyyy`.
  final String? dateFormat;

  /// Optional prefix icon.
  final IconData? prefixIcon;

  /// Form field validator.
  final FormFieldValidator<DateTime>? validator;

  String _formatDate(DateTime date) {
    // Simple date formatting without intl dependency
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Spacings.lgRadius),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onDateSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final effectiveLabel = isRequired && label != null ? '$label *' : label;
    final displayText = selectedDate != null ? _formatDate(selectedDate!) : null;

    return GestureDetector(
      onTap: isEnabled ? () => _pickDate(context) : null,
      child: AbsorbPointer(
        child: AppTextField(
          label: effectiveLabel,
          hint: hint ?? 'Select a date',
          controller: displayText != null
              ? TextEditingController(text: displayText)
              : null,
          prefixIcon: prefixIcon ?? Icons.calendar_today_outlined,
          suffixIcon: Icon(
            Icons.arrow_drop_down_rounded,
            color: cs.onSurfaceVariant,
          ),
          enabled: isEnabled,
          readOnly: true,
          onTap: isEnabled ? () => _pickDate(context) : null,
        ),
      ),
    );
  }
}
