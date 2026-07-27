import '../constants/app_constants.dart';

/// Static form-field validation helpers.
///
/// Each method accepts a nullable [String] and returns `null` when the
/// value is valid, or a human-readable error message otherwise —
/// matching the `FormFieldValidator<String>` contract used by Flutter
/// form widgets.
class InputValidator {
  InputValidator._();

  // ─── Email ─────────────────────────────────────────────────────────

  /// Returns an error message if [value] is not a valid email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final regex = RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}"
      r'[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}'
      r'[a-zA-Z0-9])?)*$',
    );
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // ─── Password ──────────────────────────────────────────────────────

  /// Returns an error message if [value] does not meet password strength
  /// requirements (length, uppercase, lowercase, digit, special char).
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (value.length > AppConstants.maxPasswordLength) {
      return 'Password must be at most ${AppConstants.maxPasswordLength} characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must contain at least one digit';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(value)) {
      return 'Password must contain at least one special character';
    }
    return null;
  }

  // ─── Confirm Password ──────────────────────────────────────────────

  /// Returns an error message if [value] does not match [password].
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Name ──────────────────────────────────────────────────────────

  /// Returns an error message if [value] is empty or shorter than 2 chars.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Name must be at most 100 characters';
    }
    return null;
  }

  // ─── Phone ─────────────────────────────────────────────────────────

  /// Returns an error message if [value] is not a valid phone number.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final regex = RegExp(r'^\+?[\d\s\-().]{7,15}$');
    if (!regex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  // ─── OTP ───────────────────────────────────────────────────────────

  /// Returns an error message if [value] is not exactly the expected
  /// number of digits (defined by [AppConstants.otpLength]).
  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    final digitsOnly = RegExp(r'^\d+$');
    if (!digitsOnly.hasMatch(value.trim())) {
      return 'OTP must contain only digits';
    }
    if (value.trim().length != AppConstants.otpLength) {
      return 'OTP must be ${AppConstants.otpLength} digits';
    }
    return null;
  }

  // ─── Required Field ────────────────────────────────────────────────

  /// Returns an error message if [value] is null or empty.
  /// Uses [fieldName] in the message for context.
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // ─── School Code ───────────────────────────────────────────────────

  /// Returns an error message if [value] does not match the expected
  /// school code format (uppercase alphanumeric, 4-12 chars).
  static String? validateSchoolCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'School code is required';
    }
    final regex = RegExp(r'^[A-Z0-9]{4,12}$');
    if (!regex.hasMatch(value.trim().toUpperCase())) {
      return 'School code must be 4-12 uppercase alphanumeric characters';
    }
    return null;
  }
}
