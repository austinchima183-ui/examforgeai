#!/usr/bin/env python3
"""
Sprint 1: Replace Color.withValues(alpha: X) → Color.withOpacity(X)

Root cause: `Color.withValues()` is a Flutter 3.27+ API that doesn't exist
in Flutter 3.24.5 (our SDK). All usages in this codebase only use the
`alpha:` parameter, so the equivalent is `Color.withOpacity(alpha_value)`.

This script performs a safe, mechanical replacement across all .dart files
in the project. It handles both single-line and multi-line withValues calls.
"""

import re
import os
import sys

PROJECT_DIR = "/home/z/my-project/examforge_ai/lib"

def fix_with_values_in_file(filepath):
    """Replace .withValues(alpha: X) with .withOpacity(X) in a single file."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    
    # Pattern 1: Single-line .withValues(alpha: VALUE)
    # Handles: .withValues(alpha: 0.5), .withValues(alpha: 0.12),
    # .withValues(alpha: isDark ? 0.20 : 0.12),
    # .withValues(alpha: context.isDarkMode ? 0.20 : 0.12),
    content = re.sub(
        r'\.withValues\(\s*alpha:\s*',
        '.withOpacity(',
        content
    )
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        # Count how many replacements were made
        count = len(re.findall(r'\.withOpacity\(', content)) - len(re.findall(r'\.withOpacity\(', original))
        return max(count, 1)
    return 0

def main():
    total_files = 0
    total_replacements = 0
    
    for root, dirs, files in os.walk(PROJECT_DIR):
        for fname in files:
            if fname.endswith('.dart'):
                filepath = os.path.join(root, fname)
                count = fix_with_values_in_file(filepath)
                if count > 0:
                    total_files += 1
                    total_replacements += count
                    print(f"  Fixed: {os.path.relpath(filepath, PROJECT_DIR)} ({count} replacements)")
    
    print(f"\n=== Sprint 1 Complete ===")
    print(f"Files modified: {total_files}")
    print(f"Replacements made: {total_replacements}")
    print(f"Root cause: Color.withValues() is Flutter 3.27+ API, not available in Flutter 3.24.5")
    print(f"Fix: .withValues(alpha: X) → .withOpacity(X)")

if __name__ == '__main__':
    main()
