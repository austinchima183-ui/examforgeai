#!/usr/bin/env python3
"""Fix incorrect relative import paths in deeply nested Dart files.

The problem: Many feature pages are nested in subdirectories like
  lib/features/X/presentation/pages/student/some_page.dart
but their imports assume they're one level shallower:
  ../../../../core/themes/spacings.dart  (4 levels up = lib/features/X/presentation/)
When they actually need:
  ../../../../../core/themes/spacings.dart  (5 levels up = lib/)

This script:
1. Scans all .dart files
2. For each file, calculates the correct relative path to lib/core/ and lib/shared/
3. Replaces incorrect import paths
"""

import os
import re

ROOT = '/home/z/my-project/examforge_ai/lib'

# Target directories and their expected relative paths from lib/
TARGETS = [
    'core/themes/spacings.dart',
    'core/themes/app_typography.dart',
    'core/themes/app_colors.dart',
    'core/extensions/context_extensions.dart',
    'core/errors/exceptions.dart',
    'core/errors/failures.dart',
    'core/utils/logger.dart',
    'core/utils/result.dart',
    'core/utils/helpers.dart',
    'core/utils/input_validator.dart',
    'core/constants/api_constants.dart',
    'core/constants/app_constants.dart',
    'core/themes/app_theme.dart',
    'core/themes/theme_provider.dart',
    'shared/widgets/app_button.dart',
    'shared/widgets/app_card.dart',
    'shared/widgets/app_text_field.dart',
    'shared/widgets/app_loading.dart',
    'shared/widgets/app_dialog.dart',
    'shared/widgets/app_search_bar.dart',
    'shared/widgets/app_error_state.dart',
    'shared/widgets/app_empty_state.dart',
    'shared/widgets/app_app_bar.dart',
    'shared/widgets/app_bottom_nav.dart',
    'shared/widgets/app_navigation_drawer.dart',
    'shared/widgets/app_stat_card.dart',
    'shared/models/user_role.dart',
    'shared/providers/auth_state_provider.dart',
    'routing/route_names.dart',
    'routing/route_guards.dart',
]

def count_levels_to_lib(filepath):
    """Count how many directory levels from this file to reach lib/"""
    rel = os.path.relpath(filepath, ROOT)
    return rel.count(os.sep)

def fix_imports(filepath):
    """Fix incorrect relative imports in a single file."""
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    levels = count_levels_to_lib(filepath)
    # The correct prefix to reach lib/ from this file
    correct_prefix = '../' * levels
    
    for target in TARGETS:
        correct_import = f"'{correct_prefix}{target}'"
        # Also handle double-quoted imports
        correct_import_dq = f'"{correct_prefix}{target}"'
        
        # Find all relative imports that target this file
        # Pattern: any number of ../ followed by the target
        pattern = f"'([^']*?/{os.path.basename(target)})'"
        
        def replace_import(m):
            full_path = m.group(1)
            # Check if this import actually targets our target file
            if full_path.endswith(target):
                return correct_import
            return m.group(0)
        
        content = re.sub(pattern, replace_import, content)
        
        # Same for double-quoted
        pattern_dq = f'"([^"]*?/{os.path.basename(target)})"'
        def replace_import_dq(m):
            full_path = m.group(1)
            if full_path.endswith(target):
                return correct_import_dq
            return m.group(0)
        content = re.sub(pattern_dq, replace_import_dq, content)
    
    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False

fixed_count = 0
for dirpath, dirnames, filenames in os.walk(ROOT):
    for filename in filenames:
        if filename.endswith('.dart'):
            filepath = os.path.join(dirpath, filename)
            if fix_imports(filepath):
                fixed_count += 1

print(f"Fixed import paths in {fixed_count} files")
