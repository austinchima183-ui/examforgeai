#!/usr/bin/env python3
"""
Fix named parameters starting with underscore.
In Dart 3.5, named parameters can't start with an underscore.
Rename _paramName to paramName (remove leading underscore).
"""

import re
import os

PROJECT_DIR = "/home/z/my-project/examforge_ai/lib"

files_to_fix = [
    "features/admission_hub/presentation/providers/admission_hub_provider.dart",
    "features/ai_coach/presentation/providers/ai_coach_provider.dart",
    "features/student_portal/presentation/providers/ai_tutor_provider.dart",
    "features/student_portal/presentation/providers/assignment_provider.dart",
    "features/student_portal/presentation/providers/document_chat_provider.dart",
    "features/student_portal/presentation/providers/flashcard_provider.dart",
    "features/student_portal/presentation/providers/practice_provider.dart",
    "features/student_portal/presentation/providers/resource_provider.dart",
    "features/student_portal/presentation/providers/student_notification_provider.dart",
    "features/student_portal/presentation/providers/study_planner_provider.dart",
]

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original = content
    changes = 0
    
    # Pattern: named parameter starting with underscore
    # this._name = value  OR  this._name,  OR  required this._name,
    # We need to rename _name to name everywhere
    
    # Find all underscore named parameters
    params = re.findall(r'this\.(_\w+)', content)
    for param in set(params):
        new_name = param[1:]  # Remove leading underscore
        # Replace this._param with this.param in constructor
        content = content.replace(f'this.{param}', f'this.{new_name}')
        # Replace field declaration: final Type _param; → final Type param;
        content = re.sub(rf'\b{param}\b', new_name, content)
        changes += 1
    
    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return changes
    return 0

def main():
    total = 0
    for rel_path in files_to_fix:
        filepath = os.path.join(PROJECT_DIR, rel_path)
        if os.path.exists(filepath):
            changes = fix_file(filepath)
            if changes > 0:
                total += changes
                print(f"Fixed: {rel_path} ({changes} params)")
    
    print(f"\nTotal: {total} parameters renamed")

if __name__ == '__main__':
    main()
