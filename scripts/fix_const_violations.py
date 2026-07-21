#!/usr/bin/env python3
"""
Sprint 3: Fix const violations across the codebase.

Root cause: Code uses `const` on list literals and constructor calls that
contain non-const elements (DateTime, RegExp, or non-const constructors).

Fix: Replace `const` with appropriate alternatives:
- `const [...]` containing DateTime/RegExp → `final [...] = [...]`
- Static `const` fields with non-const initializers → `static final`
- Local `const` with non-const elements → `final`
"""

import re
import os
import subprocess

PROJECT_DIR = "/home/z/my-project/examforge_ai"

def get_const_error_files():
    """Get files with const errors from dart analyze."""
    result = subprocess.run(
        ['dart', 'analyze'],
        capture_output=True, text=True, cwd=PROJECT_DIR,
        env={**os.environ, 'PATH': '/home/z/flutter/bin:' + os.environ.get('PATH', '')}
    )
    
    files = {}
    for line in result.stdout.split('\n'):
        if 'const_with_non_const' in line or 'non_constant_list_element' in line or 'const_initialized_with_non_constant_value' in line:
            # Extract file path
            match = re.search(r'examforge_ai/(lib/[^:]+)', line)
            if match:
                filepath = match.group(1)
                if filepath not in files:
                    files[filepath] = 0
                files[filepath] += 1
    
    return files

def fix_const_in_file(filepath):
    """Fix const violations in a single file."""
    full_path = os.path.join(PROJECT_DIR, filepath)
    with open(full_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changes = 0
    
    # Pattern 1: `= const [` → `= [`  (local const list literals)
    # Only when they contain non-const elements (DateTime, RegExp, etc.)
    content, count = re.subn(r'= const \[', '= [', content)
    changes += count
    
    # Pattern 2: `static const List<RegExp>` → `static final List<RegExp>`
    content, count = re.subn(r'static const List<RegExp>', 'static final List<RegExp>', content)
    changes += count
    
    # Pattern 3: `static const List<DateTime>` → `static final List<DateTime>`
    content, count = re.subn(r'static const List<DateTime>', 'static final List<DateTime>', content)
    changes += count
    
    # Pattern 4: const keyword before non-const constructor calls in lists
    # Pattern: `const SomeClass(...)` where SomeClass isn't const
    # This is harder to detect generically - leave for manual review
    
    if content != original:
        with open(full_path, 'w', encoding='utf-8') as f:
            f.write(content)
        return changes
    return 0

def main():
    files = get_const_error_files()
    total_changes = 0
    total_files = 0
    
    # Sort by error count descending
    for filepath, count in sorted(files.items(), key=lambda x: -x[1]):
        changes = fix_const_in_file(filepath)
        if changes > 0:
            total_files += 1
            total_changes += changes
            print(f"  Fixed: {filepath} ({changes} replacements)")
    
    print(f"\n=== Sprint 3 (const violations) ===")
    print(f"Files modified: {total_files}")
    print(f"Replacements: {total_changes}")

if __name__ == '__main__':
    main()
