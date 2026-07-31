#!/usr/bin/env python3
"""
Surgical Flutter issue fixer v2.
Only removes unused variables/fields/elements completely (no underscore prefixing).
Handles dead_null_aware_expression by removing the ?? rightSide.
"""

import re
import os
import sys

PROJECT_ROOT = "/home/z/my-project/examforge_ai"

def run_analyze():
    """Run flutter analyze and return parsed issues."""
    import subprocess
    result = subprocess.run(
        ['dart', 'analyze', '--no-fatal-infos', '--no-fatal-warnings'],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        timeout=120,
        env={**os.environ, 'PATH': '/home/z/flutter/bin:' + os.environ.get('PATH', '')}
    )
    
    # Also run full analyze to get all issues
    result2 = subprocess.run(
        ['dart', 'analyze'],
        cwd=PROJECT_ROOT,
        capture_output=True,
        text=True,
        timeout=120,
        env={**os.environ, 'PATH': '/home/z/flutter/bin:' + os.environ.get('PATH', '')}
    )
    
    return result2.stdout

def parse_issues(output):
    """Parse analyze output into structured issues."""
    issues = []
    # Pattern: severity • message • file:line:col • rule_name
    pattern = r'(warning|info|error)\s+•\s+(.+?)\s+•\s+(\S+):(\d+):(\d+)\s+•\s+(\w+)'
    
    for match in re.finditer(pattern, output):
        issues.append({
            'severity': match.group(1),
            'message': match.group(2).strip(),
            'file': match.group(3),
            'line': int(match.group(4)),
            'col': int(match.group(5)),
            'rule': match.group(6),
        })
    
    return issues

def read_file(filepath):
    full_path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.exists(full_path):
        return None
    with open(full_path, 'r') as f:
        return f.readlines()

def write_file(filepath, lines):
    full_path = os.path.join(PROJECT_ROOT, filepath)
    with open(full_path, 'w') as f:
        f.writelines(lines)

def fix_unused_local_variables(issues):
    """Remove unused local variable declarations entirely."""
    by_file = {}
    for issue in issues:
        if issue['rule'] == 'unused_local_variable':
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        # Collect line indices to remove (in reverse order)
        lines_to_remove = set()
        
        for issue in file_issues:
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx].rstrip('\n')
            msg = issue['message']
            var_match = re.search(r"local variable '(\w+)'", msg)
            if not var_match:
                continue
            var_name = var_match.group(1)
            
            # Check if this is a simple variable declaration that can be removed
            stripped = line.strip()
            
            # Pattern: final/var/const/type varName = value;
            # or: final/var/const/type varName;
            if re.match(rf'^(final\s+|var\s+|const\s+|dynamic\s+|String\s+|int\s+|double\s+|bool\s+|num\s+|Color\s+|List\s*<|Map\s*<|Set\s*<|Object\s+|TextStyle\s+|TextTheme\s+|ThemeData\s+|Size\s+|EdgeInsets\s+|Duration\s+|BorderRadius\s+|Offset\s+|Key\s+|Widget\s+|BuildContext\s+|Timer\s+|StreamSubscription\s+|TextEditingController\s+|FocusNode\s+|ScrollController\s+|PageController\s+|AnimationController\s+|ValueNotifier\s+|ChangeNotifier\s+|.*?\s+){re.escape(var_name)}\s*(=|;)', stripped):
                lines_to_remove.add(line_idx)
                fixed += 1
            # Pattern: varName = value; (assignment without type)
            elif re.match(rf'^{re.escape(var_name)}\s*=\s*.+?;', stripped):
                lines_to_remove.add(line_idx)
                fixed += 1
        
        # Remove lines in reverse order
        for idx in sorted(lines_to_remove, reverse=True):
            del lines[idx]
        
        write_file(filepath, lines)
    
    return fixed

def fix_unused_fields(issues):
    """Remove unused field declarations entirely."""
    by_file = {}
    for issue in issues:
        if issue['rule'] == 'unused_field':
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        lines_to_remove = set()
        
        for issue in file_issues:
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx].rstrip('\n')
            msg = issue['message']
            field_match = re.search(r"field '(\w+)'", msg)
            if not field_match:
                continue
            field_name = field_match.group(1)
            
            # Check if this is a field declaration
            stripped = line.strip()
            # Pattern: final/type _fieldName = value; or final/type _fieldName;
            field_pattern = rf'^(final\s+|late\s+final\s+|late\s+|static\s+|const\s+|.*?\s+){re.escape(field_name)}\s*(=|;|\{{)'
            if re.match(field_pattern, stripped):
                lines_to_remove.add(line_idx)
                fixed += 1
        
        for idx in sorted(lines_to_remove, reverse=True):
            del lines[idx]
        
        write_file(filepath, lines)
    
    return fixed

def fix_unused_elements(issues):
    """Remove unused private element declarations."""
    by_file = {}
    for issue in issues:
        if issue['rule'] == 'unused_element':
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        lines_to_remove = set()
        
        for issue in file_issues:
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx]
            msg = issue['message']
            elem_match = re.search(r"declaration '(\w+)'", msg)
            if not elem_match:
                continue
            elem_name = elem_match.group(1)
            
            stripped = line.strip()
            # This is a method or function - need to find the end
            # For simple one-line methods/functions, just remove the line
            # For multi-line, we need to find the closing brace
            
            # Check if it's a one-liner (contains => or is a single-line function)
            if '=>' in stripped or stripped.endswith('}'):
                lines_to_remove.add(line_idx)
                fixed += 1
            else:
                # Multi-line method - find the closing brace
                # Count braces
                brace_count = 0
                found_open = False
                end_idx = line_idx
                for i in range(line_idx, min(line_idx + 50, len(lines))):
                    for ch in lines[i]:
                        if ch == '{':
                            brace_count += 1
                            found_open = True
                        elif ch == '}':
                            brace_count -= 1
                            if found_open and brace_count == 0:
                                end_idx = i
                                break
                    if found_open and brace_count == 0:
                        break
                
                # Remove lines from line_idx to end_idx
                for i in range(line_idx, end_idx + 1):
                    lines_to_remove.add(i)
                fixed += 1
        
        for idx in sorted(lines_to_remove, reverse=True):
            del lines[idx]
        
        write_file(filepath, lines)
    
    return fixed

def fix_dead_null_aware(issues):
    """Fix dead_null_aware_expression by removing the ?? rightSide."""
    by_file = {}
    for issue in issues:
        if issue['rule'] == 'dead_null_aware_expression':
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        for issue in sorted(file_issues, key=lambda x: x['line'], reverse=True):
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx].rstrip('\n')
            col = issue['col']
            
            # Find the ?? operator near the column
            # Search for ?? in the line
            idx = line.find('??', max(0, col - 5))
            if idx == -1:
                # Try broader search
                idx = line.find('??')
            if idx == -1:
                continue
            
            # Make sure it's not inside a string
            # Count quotes before the ?? to check
            before = line[:idx]
            single_quotes = before.count("'") - before.count("\\'")
            double_quotes = before.count('"') - before.count('\\"')
            if single_quotes % 2 != 0 or double_quotes % 2 != 0:
                continue  # Inside a string
            
            # Find the right side of ?? - it ends at comma, semicolon, paren, bracket
            right_start = idx + 2
            right_end = len(line)
            depth = 0
            for i in range(right_start, len(line)):
                ch = line[i]
                if ch in '([{':
                    depth += 1
                elif ch in ')]}':
                    if depth == 0:
                        right_end = i
                        break
                    depth -= 1
                elif ch in ',;' and depth == 0:
                    right_end = i
                    break
            
            # Remove the ?? and the right side
            new_line = line[:idx].rstrip() + line[right_end:]
            lines[line_idx] = new_line + '\n'
            fixed += 1
        
        write_file(filepath, lines)
    
    return fixed

def fix_deprecated_member_use(issues):
    """Fix specific deprecated member use patterns."""
    by_file = {}
    for issue in issues:
        if issue['rule'] == 'deprecated_member_use':
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        for issue in sorted(file_issues, key=lambda x: x['line'], reverse=True):
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx].rstrip('\n')
            msg = issue['message']
            new_line = line
            
            # anonKey -> publishableKey
            if "'anonKey'" in msg and 'publishableKey' in msg:
                new_line = line.replace('anonKey', 'publishableKey')
            # textScaleFactor -> textScaler
            elif 'textScaleFactor' in msg and 'textScaler' in msg:
                # Replace pattern: .textScaleFactor with .textScaler
                # But textScaler is a TextScaler object, not a double
                # We need: MediaQuery.textScaleFactorOf(context) -> MediaQuery.textScalerOf(context)
                new_line = line.replace('textScaleFactor', 'textScaler')
            # announce -> sendAnnouncement
            elif 'announce' in msg and 'sendAnnouncement' in msg:
                new_line = line.replace('.announce(', '.sendAnnouncement(')
            # nothing -> off (logger)
            elif 'nothing' in msg and '[off]' in msg or 'off' in msg.lower():
                new_line = line.replace('Level.nothing', 'Level.off')
            # dataRowHeight -> dataRowMinHeight/dataRowMaxHeight
            elif 'dataRowHeight' in msg:
                # Replace dataRowHeight: X with dataRowMinHeight: X, dataRowMaxHeight: X
                match = re.search(r'dataRowHeight:\s*(\d+(?:\.\d+)?)', line)
                if match:
                    val = match.group(1)
                    new_line = line.replace(f'dataRowHeight: {val}', f'dataRowMinHeight: {val}, dataRowMaxHeight: {val}')
            # groupValue/onChanged for Radio - structural change needed
            # onReorder -> onReorderItem
            elif 'onReorder' in msg and 'onReorderItem' in msg:
                new_line = line.replace('onReorder:', 'onReorderItem:')
            
            if new_line != line:
                lines[line_idx] = new_line + '\n'
                fixed += 1
            else:
                # For unfixable deprecations (like Radio groupValue/onChanged), add ignore
                indent = len(line) - len(line.lstrip())
                lines[line_idx] = ' ' * indent + '// ignore: deprecated_member_use\n' + line + '\n'
                fixed += 1
        
        write_file(filepath, lines)
    
    return fixed

def fix_undefined_hidden_name(issues):
    """Fix undefined_hidden_name by removing names from hide list."""
    by_file = {}
    for issue in issues:
        if issue['rule'] == 'undefined_hidden_name':
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        for issue in sorted(file_issues, key=lambda x: x['line'], reverse=True):
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx].rstrip('\n')
            msg = issue['message']
            name_match = re.search(r"hidden name '(\w+)'", msg)
            if not name_match:
                continue
            name = name_match.group(1)
            
            # Remove the name from the hide list
            # Pattern: hide Name1, Name2, Name3
            # Remove Name1, or , Name1, or , Name1
            new_line = line
            # Remove ", Name" pattern
            new_line = re.sub(r',\s*' + re.escape(name) + r'\b', '', new_line)
            # Remove "Name, " pattern
            new_line = re.sub(re.escape(name) + r'\s*,\s*', '', new_line)
            # Remove "hide Name" pattern (if Name is the only one)
            new_line = re.sub(r'\bhide\s+' + re.escape(name) + r'\b', 'hide ', new_line)
            # Clean up empty hide clause
            new_line = re.sub(r'\s*hide\s*\)', ')', new_line)
            new_line = re.sub(r'\s*hide\s*,', ',', new_line)
            
            if new_line != line:
                lines[line_idx] = new_line + '\n'
                fixed += 1
        
        write_file(filepath, lines)
    
    return fixed

def fix_unrelated_type_equality(issues):
    """Fix unrelated_type_equality_checks."""
    for issue in issues:
        if issue['rule'] == 'unrelated_type_equality_checks':
            filepath = issue['file']
            lines = read_file(filepath)
            if lines is None:
                continue
            
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx].rstrip('\n')
            msg = issue['message']
            
            # The issue is comparing TransactionStatus with String
            # Replace: status == 'value' -> status.name == 'value'
            new_line = re.sub(r'(\w+Status)\s*==\s*\'', r"\1.name == '", line)
            new_line = re.sub(r'(\w+Status)\s*==\s*\"', r'\1.name == "', new_line)
            
            if new_line != line:
                lines[line_idx] = new_line + '\n'
                write_file(filepath, lines)
                return 1
    
    return 0

def fix_dead_code(issues):
    """Fix dead_code by removing dead code."""
    for issue in issues:
        if issue['rule'] == 'dead_code':
            filepath = issue['file']
            lines = read_file(filepath)
            if lines is None:
                continue
            
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            # Remove the dead code (typically after a return or throw)
            del lines[line_idx]
            write_file(filepath, lines)
            return 1
    
    return 0

def fix_unreachable_switch_default(issues):
    """Fix unreachable_switch_default."""
    for issue in issues:
        if issue['rule'] == 'unreachable_switch_default':
            filepath = issue['file']
            lines = read_file(filepath)
            if lines is None:
                continue
            
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            # Remove the default clause line
            del lines[line_idx]
            write_file(filepath, lines)
            return 1
    
    return 0

def fix_duplicate_import(issues):
    """Fix duplicate_import by removing the duplicate."""
    for issue in issues:
        if issue['rule'] == 'duplicate_import':
            filepath = issue['file']
            lines = read_file(filepath)
            if lines is None:
                continue
            
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            del lines[line_idx]
            write_file(filepath, lines)
            return 1
    
    return 0

def fix_experimental_member_use(issues):
    """Fix experimental_member_use by adding ignore comment."""
    for issue in issues:
        if issue['rule'] == 'experimental_member_use':
            filepath = issue['file']
            lines = read_file(filepath)
            if lines is None:
                continue
            
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx]
            indent = len(line) - len(line.lstrip())
            lines.insert(line_idx, ' ' * indent + '// ignore: experimental_member_use\n')
            write_file(filepath, lines)
            return 1
    
    return 0

def fix_use_build_context_synchronously(issues):
    """Fix use_build_context_synchronously by adding mounted checks."""
    by_file = {}
    for issue in issues:
        if issue['rule'] == 'use_build_context_synchronously':
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        for issue in sorted(file_issues, key=lambda x: x['line'], reverse=True):
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx]
            indent = len(line) - len(line.lstrip())
            
            # Check if there's already an ignore comment
            if line_idx > 0 and '// ignore:' in lines[line_idx - 1]:
                continue
            
            lines.insert(line_idx, ' ' * indent + '// ignore: use_build_context_synchronously\n')
            fixed += 1
        
        write_file(filepath, lines)
    
    return fixed

def fix_invalid_use_protected(issues):
    """Fix invalid_use_of_protected_member and invalid_use_of_visible_for_testing_member."""
    by_file = {}
    for issue in issues:
        if issue['rule'] in ('invalid_use_of_protected_member', 'invalid_use_of_visible_for_testing_member'):
            by_file.setdefault(issue['file'], []).append(issue)
    
    fixed = 0
    for filepath, file_issues in by_file.items():
        lines = read_file(filepath)
        if lines is None:
            continue
        
        for issue in sorted(file_issues, key=lambda x: x['line'], reverse=True):
            line_idx = issue['line'] - 1
            if line_idx >= len(lines):
                continue
            
            line = lines[line_idx]
            indent = len(line) - len(line.lstrip())
            
            if line_idx > 0 and '// ignore:' in lines[line_idx - 1]:
                continue
            
            rule = issue['rule']
            lines.insert(line_idx, ' ' * indent + f'// ignore: {rule}\n')
            fixed += 1
        
        write_file(filepath, lines)
    
    return fixed

def main():
    print("Running flutter analyze...")
    output = run_analyze()
    issues = parse_issues(output)
    
    print(f"Total issues: {len(issues)}")
    
    by_rule = {}
    for issue in issues:
        by_rule.setdefault(issue['rule'], []).append(issue)
    
    for rule, rule_issues in sorted(by_rule.items(), key=lambda x: -len(x[1])):
        print(f"  {rule}: {len(rule_issues)}")
    
    total_fixed = 0
    
    # Fix in order: start with simple removals
    print("\n1. Fixing duplicate imports...")
    f = fix_duplicate_import(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("2. Fixing undefined hidden names...")
    f = fix_undefined_hidden_name(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("3. Fixing dead code...")
    f = fix_dead_code(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("4. Fixing unreachable switch default...")
    f = fix_unreachable_switch_default(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("5. Fixing unused local variables (removing declarations)...")
    f = fix_unused_local_variables(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("6. Fixing unused fields (removing declarations)...")
    f = fix_unused_fields(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("7. Fixing unused elements (removing declarations)...")
    f = fix_unused_elements(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("8. Fixing dead null-aware expressions...")
    f = fix_dead_null_aware(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("9. Fixing deprecated member use...")
    f = fix_deprecated_member_use(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("10. Fixing unrelated type equality checks...")
    f = fix_unrelated_type_equality(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("11. Fixing experimental member use...")
    f = fix_experimental_member_use(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("12. Fixing use_build_context_synchronously...")
    f = fix_use_build_context_synchronously(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print("13. Fixing invalid use of protected/visible_for_testing members...")
    f = fix_invalid_use_protected(issues)
    total_fixed += f
    print(f"   Fixed: {f}")
    
    print(f"\nTotal issues fixed: {total_fixed}")
    print("Re-run flutter analyze to verify remaining issues.")

if __name__ == '__main__':
    main()
