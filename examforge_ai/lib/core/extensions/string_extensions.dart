/// Common [String] transformations and validations used across the app.
extension StringExtensions on String {
  /// Capitalize only the first character: `'hello' → 'Hello'`.
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize the first letter of every word: `'hello world' → 'Hello World'`.
  String get titleCase => split(' ').map((w) => w.capitalize).join(' ');

  /// Basic RFC-5322-ish email validation.
  bool get isEmail {
    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&\'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}'
      r'[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}'
      r'[a-zA-Z0-9])?)*$',
    );
    return regex.hasMatch(this);
  }

  /// Accepts common international phone formats.
  bool get isPhone {
    final regex = RegExp(r'^\+?[\d\s\-().]{7,15}$');
    return regex.hasMatch(this);
  }

  /// Checks that the string contains at least:
  /// - 8 characters
  /// - 1 uppercase letter
  /// - 1 lowercase letter
  /// - 1 digit
  /// - 1 special character
  bool get isStrongPassword {
    if (length < 8) return false;
    if (!RegExp(r'[A-Z]').hasMatch(this)) return false;
    if (!RegExp(r'[a-z]').hasMatch(this)) return false;
    if (!RegExp(r'\d').hasMatch(this)) return false;
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(this)) {
      return false;
    }
    return true;
  }

  /// Parses the string into a [DateTime] or returns `null` on failure.
  DateTime? get toDateTime => DateTime.tryParse(this);

  /// Truncates the string to [max] characters and appends '…' if needed.
  String truncate(int max) {
    if (length <= max) return this;
    return '${substring(0, max)}…';
  }

  /// Removes all whitespace characters.
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Masks an email address: `john.doe@gmail.com → j******@gmail.com`.
  String get maskEmail {
    final parts = split('@');
    if (parts.length != 2 || parts[0].isEmpty) return this;
    final local = parts[0];
    final domain = parts[1];
    final masked =
        '${local[0]}${'*' * (local.length > 1 ? local.length - 1 : 0)}';
    return '$masked@$domain';
  }

  /// Masks a phone number showing only the last 4 digits: `+1234567890 → *******7890`.
  String get maskPhone {
    if (length <= 4) return this;
    return '${'*' * (length - 4)}${substring(length - 4)}';
  }
}
