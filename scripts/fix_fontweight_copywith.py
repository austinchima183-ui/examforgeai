#!/usr/bin/env python3
"""
Sprint 2: Add FontWeight extension to provide copyWith as TextStyle.

Root cause: Code calls AppTypography.wSemiBold.copyWith(fontSize: 13) but
FontWeight doesn't have copyWith — that's a TextStyle method.

Fix approach: Add a FontWeight extension that converts to TextStyle and
provides copyWith. This is the minimal-change approach that:
1. Doesn't break any existing fontWeight: usages (1,771 occurrences)
2. Makes all .copyWith() calls work (249 occurrences)
3. Requires only one new file to be created
4. Requires only one import to be added to AppTypography

The extension method will:
- Convert FontWeight → TextStyle with that fontWeight
- Provide copyWith() that delegates to TextStyle.copyWith()
"""

import os

# Path to AppTypography file
TYPOGRAPHY_FILE = "/home/z/my-project/examforge_ai/lib/core/themes/app_typography.dart"

# Extension code to add at the end of the file
EXTENSION_CODE = '''

// ═══════════════════════════════════════════════════════════════════════════════
// FONTWEIGHT EXTENSION — Enables .copyWith() on FontWeight constants
// ═══════════════════════════════════════════════════════════════════════════════
//
// Code throughout the app calls AppTypography.wSemiBold.copyWith(fontSize: 13).
// FontWeight doesn't have copyWith — that's a TextStyle method. This extension
// converts the FontWeight to a TextStyle first, then provides copyWith().
//
// Usage:  AppTypography.wSemiBold.copyWith(fontSize: 13)
// Becomes: TextStyle(fontWeight: AppTypography.wSemiBold).copyWith(fontSize: 13)
// Which is: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)

/// Extension on [FontWeight] that provides [copyWith] by converting to [TextStyle].
///
/// This allows the common pattern:
/// ```dart
/// style: AppTypography.wSemiBold.copyWith(fontSize: 13, color: Colors.red)
/// ```
/// which is equivalent to:
/// ```dart
/// style: TextStyle(fontWeight: AppTypography.wSemiBold, fontSize: 13, color: Colors.red)
/// ```
extension FontWeightTextStyle on FontWeight {
  /// Converts this [FontWeight] to a [TextStyle] and calls [TextStyle.copyWith].
  ///
  /// All parameters are forwarded to [TextStyle.copyWith].
  TextStyle copyWith({
    bool? inherit,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    TextLeadingDistribution? leadingDistribution,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    List<FontVariation>? fontVariations,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    String? debugLabel,
    String? fontFamily,
    List<String>? fontFamilyFallback,
    String? package,
    TextOverflow? overflow,
  }) {
    return TextStyle(
      fontWeight: this,
      inherit: inherit,
      color: color,
      backgroundColor: backgroundColor,
      fontSize: fontSize,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      wordSpacing: wordSpacing,
      textBaseline: textBaseline,
      height: height,
      leadingDistribution: leadingDistribution,
      locale: locale,
      foreground: foreground,
      background: background,
      shadows: shadows,
      fontFeatures: fontFeatures,
      fontVariations: fontVariations,
      decoration: decoration,
      decorationColor: decorationColor,
      decorationStyle: decorationStyle,
      decorationThickness: decorationThickness,
      debugLabel: debugLabel,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      package: package,
      overflow: overflow,
    );
  }
}
'''

def main():
    # Read the existing file
    with open(TYPOGRAPHY_FILE, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if extension already added
    if 'FontWeightTextStyle' in content:
        print("Extension already exists in app_typography.dart")
        return
    
    # Append the extension code
    content += EXTENSION_CODE
    
    with open(TYPOGRAPHY_FILE, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("=== Sprint 2 Complete ===")
    print(f"Added FontWeightTextStyle extension to app_typography.dart")
    print(f"This enables FontWeight.copyWith() → TextStyle.copyWith() pattern")
    print(f"Expected error reduction: 249 FontWeight.copyWith errors")
    print(f"Files modified: 1")

if __name__ == '__main__':
    main()
