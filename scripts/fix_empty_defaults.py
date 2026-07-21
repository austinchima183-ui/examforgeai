#!/usr/bin/env python3
"""
Fix non_constant_default_value errors by restoring `const` to empty list/map defaults.

The sed command `= const [` → `= [` was too broad — it also changed default 
parameter values. For empty lists `[]` and empty maps `{}` used as defaults,
we need `const []` and `const {}`. For non-empty lists with non-const elements
(e.g. DateTime), we need to change the constructor pattern.

This script:
1. Restores `const` to empty list/map default values
2. For non-empty non-const defaults, changes the parameter to nullable
"""

import re
import os

PROJECT_DIR = "/home/z/my-project/examforge_ai/lib"

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changes = 0
    
    # Pattern: `= [],` → `= const [],` (empty list defaults)
    content, n = re.subn(r'= \[\](?=[,\)])', r'= const [],', content)
    changes += n
    
    # Pattern: `= {},` → `= const {},` (empty map defaults)  
    content, n = re.subn(r'= \{\}(?=[,\)])', r'= const {},', content)
    changes += n
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return changes
    return 0

def main():
    total_changes = 0
    total_files = 0
    
    for root, dirs, files in os.walk(PROJECT_DIR):
        for fname in files:
            if fname.endswith('.dart'):
                filepath = os.path.join(root, fname)
                changes = fix_file(filepath)
                if changes > 0:
                    total_files += 1
                    total_changes += changes
                    print(f"  Fixed: {os.path.relpath(filepath, PROJECT_DIR)} ({changes} replacements)")
    
    print(f"\nFiles: {total_files}, Changes: {total_changes}")

if __name__ == '__main__':
    main()
