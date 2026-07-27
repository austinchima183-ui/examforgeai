#!/usr/bin/env python3
"""
Build FK restoration SQL from the stripped FK constraints JSON.
Since the regex in preprocess couldn't find the source tables (REFERENCES already stripped),
we need to manually map each FK to its source table based on the schema structure.
"""

import json
import os
import re

FK_CONSTRAINTS = json.load(open('/home/z/my-project/download/stripped_fk_constraints.json'))

MIGRATIONS_DIR = '/home/z/my-project/examforge_ai/supabase/migrations'

def find_source_table_for_fk(fk):
    """
    Read the ORIGINAL (unstripped) SQL file to find which CREATE TABLE 
    contains this FK column. We read from the git repo or the original files
    in the migrations directory.
    """
    filename = fk['file']
    col = fk['column']
    ref_table = fk['ref_table']
    ref_col = fk['ref_col']
    on_delete = fk.get('on_delete')
    
    filepath = os.path.join(MIGRATIONS_DIR, filename)
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Strategy: find the column definition within a CREATE TABLE block
    # The column will appear as: col UUID [NOT NULL] [REFERENCES ref_table(ref_col)]
    # But REFERENCES may already be stripped in our preprocessed files.
    # Instead, look for the column name and trace back to find the CREATE TABLE header.
    
    # Find all CREATE TABLE blocks
    tables_in_file = []
    create_pattern = re.compile(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(\w+)\s*\(', re.IGNORECASE)
    for match in create_pattern.finditer(content):
        tables_in_file.append(match.group(1))
    
    # For each table, find the block of its definition
    for table_name in tables_in_file:
        # Find the CREATE TABLE statement for this table
        table_start_pattern = re.compile(
            rf'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?{table_name}\s*\(',
            re.IGNORECASE
        )
        start_match = table_start_pattern.search(content)
        if not start_match:
            continue
        
        # Find the matching closing parenthesis
        # This is complex because of nested parentheses in CHECK constraints etc.
        # Simple approach: find next CREATE TABLE or end of significant block
        start_pos = start_match.end()
        
        # Look for the column in the definition area
        # We'll search up to 5000 chars after the CREATE TABLE start
        block = content[start_pos:start_pos + 10000]
        
        # Check if this column name appears in this table's definition
        # Look for patterns like: col UUID or col type
        col_pattern = re.compile(rf'\b{col}\b\s+(?:UUID|TEXT|INT|NUMERIC|TIMESTAMPTZ|BOOLEAN|JSONB)', re.IGNORECASE)
        if col_pattern.search(block):
            return table_name
    
    return None

# Build the restoration SQL
sql_parts = []
sql_parts.append("-- ============================================================================")
sql_parts.append("-- EXAMFORGE AI — FK Constraint Restoration")
sql_parts.append("-- ============================================================================")
sql_parts.append("-- Restores all 73 cross-file foreign key constraints that were stripped")
sql_parts.append("-- from CREATE TABLE statements during preprocessing.")
sql_parts.append("-- These must be applied AFTER all referenced tables exist.")
sql_parts.append("-- ============================================================================")
sql_parts.append("")

found_count = 0
missing = []

# Group by file for organized output
from collections import defaultdict
fk_by_file = defaultdict(list)
for fk in FK_CONSTRAINTS:
    fk_by_file[fk['file']].append(fk)

for filename, fks in fk_by_file.items():
    sql_parts.append(f"-- FK constraints from {filename}")
    
    for fk in fks:
        source_table = find_source_table_for_fk(fk)
        col = fk['column']
        ref_table = fk['ref_table']
        ref_col = fk['ref_col']
        on_delete = fk.get('on_delete')
        
        if source_table:
            constraint_name = f'fk_{source_table}_{col}'
            # Ensure unique constraint names by adding ref_table if needed
            if len([f for f in fks if f['column'] == col]) > 1:
                constraint_name = f'fk_{source_table}_{col}_{ref_table}'
            
            on_delete_clause = f' ON DELETE {on_delete}' if on_delete else ''
            stmt = (
                f"DO $$ BEGIN\n"
                f"  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = '{constraint_name}') THEN\n"
                f"    ALTER TABLE {source_table} ADD CONSTRAINT {constraint_name}\n"
                f"    FOREIGN KEY ({col}) REFERENCES {ref_table}({ref_col}){on_delete_clause};\n"
                f"  END IF;\n"
                f"END $$;"
            )
            sql_parts.append(stmt)
            found_count += 1
        else:
            missing.append(fk)
            sql_parts.append(f"-- WARNING: Could not determine source table for FK: {col} -> {ref_table}.{ref_col}")

sql_parts.append("")
sql_parts.append(f"-- Total FK constraints restored: {found_count}")
sql_parts.append(f"-- Missing: {len(missing)}")

output_path = '/tmp/migrations_processed/restore_fk_constraints.sql'
with open(output_path, 'w') as f:
    f.write('\n'.join(sql_parts))

print(f"FK restoration SQL saved to: {output_path}")
print(f"Found: {found_count}/{len(FK_CONSTRAINTS)}")
print(f"Missing: {len(missing)}")

if missing:
    print("\nMissing FKs (need manual mapping):")
    for m in missing:
        print(f"  {m['column']} -> {m['ref_table']}.{m['ref_col']} in {m['file']}")
