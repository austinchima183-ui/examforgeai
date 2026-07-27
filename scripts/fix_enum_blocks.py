#!/usr/bin/env python3
"""
Fix billing_schema.sql: Convert DO $$ enum block to individual CREATE TYPE statements
using create_enum_if_not_exists helper function, and fix other issues.
"""
import re

filepath = '/tmp/migrations_processed/billing_schema.sql'
with open(filepath) as f:
    sql = f.read()

# 1. Replace the DO $$ block that creates enums with individual calls to create_enum_if_not_exists
# Find the DO $$ BEGIN block
enum_block_pattern = re.compile(
    r'DO\s+\$\$\s+BEGIN\s+(.*?)EXCEPTION\s+WHEN\s+duplicate_object\s+THEN\s+NULL;\s+END\s+\$\$;',
    re.DOTALL
)

enum_block_match = enum_block_pattern.search(sql)
if enum_block_match:
    enum_block = enum_block_match.group(1)
    
    # Extract each CREATE TYPE statement
    create_type_pattern = re.compile(
        r'CREATE\s+TYPE\s+(\w+)\s+AS\s+ENUM\s*\((.*?)\)',
        re.DOTALL
    )
    
    replacement = ""
    for match in create_type_pattern.finditer(enum_block):
        enum_name = match.group(1)
        enum_values_str = match.group(2)
        # Parse the values
        values = re.findall(r"'(\w+)'", enum_values_str)
        values_array = "[" + ", ".join(f"'{v}'" for v in values) + "]"
        replacement += f"SELECT public.create_enum_if_not_exists('{enum_name}', ARRAY{values_array});\n"
    
    sql = enum_block_pattern.sub(replacement, sql)

# 2. Remove any remaining EXCEPTION WHEN blocks
exception_pattern = re.compile(r'EXCEPTION\s+WHEN\s+\w+\s+THEN\s+NULL;\s*', re.IGNORECASE)
sql = exception_pattern.sub('', sql)

# 3. Fix "EXCEPTION WHEN others THEN NULL" in functions
# The Management API doesn't support EXCEPTION blocks in certain contexts
# Replace with simpler error handling or remove

# 4. Strip BEGIN;/COMMIT; (already done in preprocessing)

with open(filepath, 'w') as f:
    f.write(sql)

print(f"Fixed billing_schema.sql ({len(sql)} chars)")

# Also fix any other files that have the same pattern
import os
MIGRATIONS_DIR = '/tmp/migrations_processed'
for filename in os.listdir(MIGRATIONS_DIR):
    if filename.endswith('.sql') and filename != 'billing_schema.sql':
        filepath2 = os.path.join(MIGRATIONS_DIR, filename)
        with open(filepath2) as f:
            sql2 = f.read()
        
        # Check if it has EXCEPTION WHEN duplicate_object THEN NULL pattern
        if 'EXCEPTION WHEN duplicate_object THEN NULL' in sql2:
            # Apply the same fix
            enum_block_match2 = enum_block_pattern.search(sql2)
            if enum_block_match2:
                enum_block2 = enum_block_match2.group(1)
                replacement2 = ""
                for match in create_type_pattern.finditer(enum_block2):
                    enum_name = match.group(1)
                    enum_values_str = match.group(2)
                    values = re.findall(r"'(\w+)'", enum_values_str)
                    values_array = "[" + ", ".join(f"'{v}'" for v in values) + "]"
                    replacement2 += f"SELECT public.create_enum_if_not_exists('{enum_name}', ARRAY{values_array});\n"
                sql2 = enum_block_pattern.sub(replacement2, sql2)
                
                # Also remove remaining EXCEPTION WHEN blocks
                sql2 = exception_pattern.sub('', sql2)
                
                with open(filepath2, 'w') as f:
                    f.write(sql2)
                print(f"Fixed {filename} ({len(sql2)} chars)")
