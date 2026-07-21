import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:formz/formz.dart';

// ═══════════════════════════════════════════════════════════════════════
// FORM INPUT FIELDS
// ═══════════════════════════════════════════════════════════════════════

/// Formz input for email validation.
class EmailInput extends FormzInput<String, EmailValidationError> {
  const EmailInput.pure() : super.pure('');
  const EmailInput.dirty([super.value = '']) : super.dirty();

  static final _emailRegex = RegExp(
    r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]"
    r'(?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
  );

  @override
  EmailValidationError? validator(String value) {
    if (value.trim().isEmpty) return EmailValidationError.empty;
    if (!_emailRegex.hasMatch(value.trim())) {
      return EmailValidationError.invalid;
    }
    return null;
  }
}

enum EmailValidationError { empty, invalid }

/// Formz input for password validation.
class PasswordInput extends FormzInput<String, PasswordValidationError> {
  const PasswordInput.pure() : super.pure('');
  const PasswordInput.dirty([super.value = '']) : super.dirty();

  @override
  PasswordValidationError? validator(String value) {
    if (value.isEmpty) return PasswordValidationError.empty;
    if (value.length < 8) return PasswordValidationError.tooShort;
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return PasswordValidationError.noUppercase;
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return PasswordValidationError.noLowercase;
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return PasswordValidationError.noDigit;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/~`]').hasMatch(value)) {
      return PasswordValidationError.noSpecialChar;
    }
    return null;
  }
}

enum PasswordValidationError {
  empty,
  tooShort,
  noUppercase,
  noLowercase,
  noDigit,
  noSpecialChar,
}

/// Formz input for confirm-password validation.
class ConfirmPasswordInput
    extends FormzInput<String, ConfirmPasswordValidationError> {
  const ConfirmPasswordInput.pure({String password = ''})
      : _password = password,
        super.pure('');
  const ConfirmPasswordInput.dirty(
      {required String password, String value = ''})
      : _password = password,
        super.dirty(value);

  final String _password;

  @override
  ConfirmPasswordValidationError? validator(String value) {
    if (value.isEmpty) return ConfirmPasswordValidationError.empty;
    if (value != _password) return ConfirmPasswordValidationError.mismatch;
    return null;
  }
}

enum ConfirmPasswordValidationError { empty, mismatch }

/// Formz input for name validation.
class NameInput extends FormzInput<String, NameValidationError> {
  const NameInput.pure() : super.pure('');
  const NameInput.dirty([super.value = '']) : super.dirty();

  @override
  NameValidationError? validator(String value) {
    if (value.trim().isEmpty) return NameValidationError.empty;
    if (value.trim().length < 2) return NameValidationError.tooShort;
    return null;
  }
}

enum NameValidationError { empty, tooShort }

// ═══════════════════════════════════════════════════════════════════════
// AUTH FORM STATE
// ═══════════════════════════════════════════════════════════════════════

/// Complete form state for all auth-related forms.
///
/// Holds individual [FormzInput] field states and tracks whether
/// the form has been submitted (to trigger validation error display).
class AuthFormState {
  const AuthFormState({
    this.email = const EmailInput.pure(),
    this.password = const PasswordInput.pure(),
    this.confirmPassword = const ConfirmPasswordInput.pure(),
    this.name = const NameInput.pure(),
    this.isFormSubmitted = false,
  });

  final EmailInput email;
  final PasswordInput password;
  final ConfirmPasswordInput confirmPassword;
  final NameInput name;
  final bool isFormSubmitted;

  /// Whether the entire form is valid.
  bool get isValid =>
      email.isValid &&
      password.isValid &&
      confirmPassword.isValid &&
      name.isValid;

  /// Whether the login form (email + password only) is valid.
  bool get isLoginValid => email.isValid && password.isValid;

  /// Whether the forgot-password form (email only) is valid.
  bool get isForgotPasswordValid => email.isValid;

  /// Whether the reset-password form (password + confirm) is valid.
  bool get isResetPasswordValid =>
      password.isValid && confirmPassword.isValid;

  /// Creates a copy with updated fields.
  AuthFormState copyWith({
    EmailInput? email,
    PasswordInput? password,
    ConfirmPasswordInput? confirmPassword,
    NameInput? name,
    bool? isFormSubmitted,
  }) {
    return AuthFormState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      name: name ?? this.name,
      isFormSubmitted: isFormSubmitted ?? this.isFormSubmitted,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// AUTH FORM NOTIFIER
// ═══════════════════════════════════════════════════════════════════════

/// Manages form validation state for auth screens.
///
/// Each field change triggers a re-validation via [Formz]. The overall
/// form validity is computed from the individual field states.
class AuthFormNotifier extends StateNotifier<AuthFormState> {
  AuthFormNotifier() : super(const AuthFormState());

  // ─── Email ──────────────────────────────────────────────────────

  /// Called when the email field value changes.
  void onEmailChanged(String value) {
    state = state.copyWith(
      email: EmailInput.dirty(value),
    );
  }

  // ─── Password ───────────────────────────────────────────────────

  /// Called when the password field value changes.
  void onPasswordChanged(String value) {
    state = state.copyWith(
      password: PasswordInput.dirty(value),
      confirmPassword: ConfirmPasswordInput.dirty(
        password: value,
        value: state.confirmPassword.value,
      ),
    );
  }

  // ─── Confirm Password ──────────────────────────────────────────

  /// Called when the confirm-password field value changes.
  void onConfirmPasswordChanged(String value) {
    state = state.copyWith(
      confirmPassword: ConfirmPasswordInput.dirty(
        password: state.password.value,
        value: value,
      ),
    );
  }

  // ─── Name ───────────────────────────────────────────────────────

  /// Called when the name field value changes.
  void onNameChanged(String value) {
    state = state.copyWith(
      name: NameInput.dirty(value),
    );
  }

  // ─── Form Submission ────────────────────────────────────────────

  /// Marks the form as submitted, which triggers all fields to show
  /// their validation errors.
  void markSubmitted() {
    state = state.copyWith(isFormSubmitted: true);
  }

  // ─── Reset ──────────────────────────────────────────────────────

  /// Resets the form to its initial state.
  void reset() {
    state = const AuthFormState();
  }

  // ─── Email Error Message ────────────────────────────────────────

  /// Returns the current email error message, or `null` if valid.
  String? get emailError {
    if (!state.email.isPure && state.email.isNotValid) {
      return switch (state.email.error) {
        EmailValidationError.empty => 'Email is required',
        EmailValidationError.invalid => 'Enter a valid email address',
        _ => null,
      };
    }
    return null;
  }

  // ─── Password Error Message ─────────────────────────────────────

  /// Returns the current password error message, or `null` if valid.
  String? get passwordError {
    if (!state.password.isPure && state.password.isNotValid) {
      return switch (state.password.error) {
        PasswordValidationError.empty => 'Password is required',
        PasswordValidationError.tooShort =>
          'Password must be at least 8 characters',
        PasswordValidationError.noUppercase =>
          'Password must contain at least one uppercase letter',
        PasswordValidationError.noLowercase =>
          'Password must contain at least one lowercase letter',
        PasswordValidationError.noDigit =>
          'Password must contain at least one digit',
        PasswordValidationError.noSpecialChar =>
          'Password must contain at least one special character',
        _ => null,
      };
    }
    return null;
  }

  // ─── Confirm Password Error Message ─────────────────────────────

  /// Returns the current confirm-password error message, or `null` if valid.
  String? get confirmPasswordError {
    if (!state.confirmPassword.isPure && state.confirmPassword.isNotValid) {
      return switch (state.confirmPassword.error) {
        ConfirmPasswordValidationError.empty => 'Please confirm your password',
        ConfirmPasswordValidationError.mismatch => 'Passwords do not match',
        _ => null,
      };
    }
    return null;
  }

  // ─── Name Error Message ─────────────────────────────────────────

  /// Returns the current name error message, or `null` if valid.
  String? get nameError {
    if (!state.name.isPure && state.name.isNotValid) {
      return switch (state.name.error) {
        NameValidationError.empty => 'Name is required',
        NameValidationError.tooShort =>
          'Name must be at least 2 characters',
        _ => null,
      };
    }
    return null;
  }
}
