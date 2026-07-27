/// Barrel export for the core layer.
///
/// Import this single file instead of individual core modules:
/// ```dart
/// import 'package:examforge_ai/core/core.dart';
/// ```
library;

export 'constants/api_constants.dart';
// ─── Constants ──────────────────────────────────────────────────────────────
export 'constants/app_constants.dart';
// ─── Device ─────────────────────────────────────────────────────────────────
export 'device/device_service.dart';
// ─── Errors ─────────────────────────────────────────────────────────────────
export 'errors/exceptions.dart';
export 'errors/failures.dart';
// ─── Extensions ─────────────────────────────────────────────────────────────
export 'extensions/context_extensions.dart';
export 'extensions/datetime_extensions.dart';
export 'extensions/string_extensions.dart';
// ─── Network ────────────────────────────────────────────────────────────────
export 'network/api_client.dart';
export 'network/network_info.dart';
// ─── Themes ─────────────────────────────────────────────────────────────────
export 'themes/app_colors.dart';
export 'themes/app_theme.dart';
export 'themes/app_typography.dart';
export 'themes/spacings.dart';
export 'themes/theme_provider.dart';
// ─── Utils ──────────────────────────────────────────────────────────────────
export 'utils/helpers.dart';
export 'utils/input_validator.dart';
export 'utils/logger.dart';
export 'utils/result.dart';
