#!/usr/bin/env python3
"""
Sprint 5: Remove duplicate top-level provider definitions from dependency_injection.dart.

Root cause: The file was appended to multiple times, creating duplicate 
declarations of the same provider. Dart doesn't allow duplicate top-level
names. The compiler reports these as "is already declared in this scope".

Fix: For each duplicate, keep the LAST definition and comment out earlier ones.
"""

import re

FILEPATH = "/home/z/my-project/examforge_ai/lib/config/dependency_injection.dart"

def main():
    with open(FILEPATH, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Find all top-level provider declarations
    # Pattern: "final providerName = ..."
    provider_pattern = re.compile(r'^final\s+(\w+(?:Provider|Provider))\s*=')
    
    seen = {}  # provider_name -> list of line indices (0-based)
    
    for i, line in enumerate(lines):
        match = provider_pattern.match(line.strip())
        if match:
            name = match.group(1)
            if name not in seen:
                seen[name] = []
            seen[name].append(i)
    
    # Find duplicates
    duplicates = {name: indices for name, indices in seen.items() if len(indices) > 1}
    
    print(f"Found {len(duplicates)} duplicate provider names:")
    for name, indices in sorted(duplicates.items()):
        print(f"  {name}: defined at lines {', '.join(str(i+1) for i in indices)}")
    
    # For each duplicate, comment out all but the last definition
    # We need to find the full extent of each definition (could be multi-line)
    lines_to_comment = set()
    
    for name, indices in duplicates.items():
        # Keep the last definition, comment out the rest
        for idx in indices[:-1]:
            # Find the extent of this definition
            # A provider definition ends with a closing ); or similar
            # We'll find the end by looking for the next top-level declaration
            # or the end of the current statement
            
            # Start from the line with `final`
            start = idx
            end = idx
            
            # Find the end of the statement (look for closing paren + semicolon)
            depth = 0
            for j in range(idx, min(idx + 50, len(lines))):
                line = lines[j]
                depth += line.count('(') - line.count(')')
                if depth <= 0 and (';' in line or j > idx + 30):
                    end = j
                    break
            
            for j in range(start, end + 1):
                lines_to_comment.add(j)
    
    # Comment out the duplicate lines
    for j in sorted(lines_to_comment):
        lines[j] = '// [DUPLICATE REMOVED] ' + lines[j]
    
    with open(FILEPATH, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print(f"\nCommented out {len(lines_to_comment)} lines from {len(duplicates)} duplicate providers")

if __name__ == '__main__':
    main()
