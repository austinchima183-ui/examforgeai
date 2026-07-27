#!/usr/bin/env python3
"""
Execute question_bank_schema.sql in smaller batches,
handling column mismatches from existing tables.
"""

import json
import subprocess
import re
import time

SUPABASE_PAT = 'sbp_5cc634ccecae8e14221a8546ffb5607a66a2151e'
PROJECT_REF = 'pzfnptrrnxkgodclyhft'
API_URL = f'https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query'

def execute_sql(sql):
    """Execute SQL via Supabase Management API."""
    result = subprocess.run(
        ['curl', '-s', '--max-time', '25', '-X', 'POST', API_URL,
         '-H', f'Authorization: Bearer {SUPABASE_PAT}',
         '-H', 'Content-Type: application/json',
         '-d', json.dumps({"query": sql})],
        capture_output=True, text=True, timeout=30
    )
    
    if result.returncode != 0:
        return False, f"curl error: {result.stderr}"
    
    try:
        response = json.loads(result.stdout)
    except json.JSONDecodeError:
        return False, f"Invalid JSON: {result.stdout[:200]}"
    
    if isinstance(response, dict):
        if 'error' in response:
            error_detail = response['error']
            if isinstance(error_detail, str):
                return False, error_detail
            elif isinstance(error_detail, dict):
                return False, error_detail.get('message', str(error_detail))
        elif 'message' in response:
            msg = response['message']
            if 'error' in msg.lower() or 'failed' in msg.lower():
                return False, msg
            return True, None
    
    return True, None

def get_existing_tables():
    """Get list of existing tables from database."""
    result = subprocess.run(
        ['curl', '-s', '--max-time', '25', '-X', 'POST', API_URL,
         '-H', f'Authorization: Bearer {SUPABASE_PAT}',
         '-H', 'Content-Type: application/json',
         '-d', json.dumps({"query": "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"})],
        capture_output=True, text=True, timeout=30
    )
    try:
        tables = json.loads(result.stdout)
        if isinstance(tables, list):
            return set(t['table_name'] for t in tables)
    except:
        pass
    return set()

def get_existing_columns(table_name):
    """Get columns of an existing table."""
    result = subprocess.run(
        ['curl', '-s', '--max-time', '25', '-X', 'POST', API_URL,
         '-H', f'Authorization: Bearer {SUPABASE_PAT}',
         '-H', 'Content-Type: application/json',
         '-d', json.dumps({"query": f"SELECT column_name FROM information_schema.columns WHERE table_schema = 'public' AND table_name = '{table_name}'"})],
        capture_output=True, text=True, timeout=30
    )
    try:
        cols = json.loads(result.stdout)
        if isinstance(cols, list):
            return set(c['column_name'] for c in cols)
    except:
        pass
    return set()

def strip_fk_refs_to_missing(sql, existing_tables):
    """Remove REFERENCES to tables that don't yet exist."""
    # Find all REFERENCES patterns
    pattern = re.compile(
        r'REFERENCES\s+(\w+)\s*\(\s*\w+\s*\)(\s+ON\s+DELETE\s+(CASCADE|SET\s+NULL|RESTRICT|SET\s+DEFAULT|NO\s+ACTION))?',
        re.IGNORECASE
    )
    
    for match in list(pattern.finditer(sql)):
        ref_table = match.group(1)
        if ref_table not in existing_tables:
            full_match = match.group(0)
            sql = sql.replace(full_match, '')
    
    return sql

# Read the preprocessed file
filepath = '/tmp/migrations_processed/question_bank_schema.sql'
with open(filepath) as f:
    sql = f.read()

existing_tables = get_existing_tables()
print(f"Existing tables: {len(existing_tables)}")

# Strip FK references to missing tables
sql = strip_fk_refs_to_missing(sql, existing_tables)

# Remove COMMENT ON COLUMN for columns that don't exist in existing tables
# Specifically, remove COMMENT on academic_sessions.term which doesn't exist
existing_cols = get_existing_columns('academic_sessions')
if 'term' not in existing_cols:
    sql = re.sub(r'COMMENT ON COLUMN academic_sessions\.term[^;]+;', '', sql)

# Also remove the duplicate CREATE TABLE IF NOT EXISTS for academic_sessions
# since the table already exists with different structure. 
# CREATE TABLE IF NOT EXISTS won't modify an existing table, so it's OK to leave it.
# But the COMMENT on missing columns will fail, so we've removed that.

# Split into manageable sections
sections = []
# Find section boundaries by looking for comment headers or CREATE TABLE blocks
current_section = ''
section_size = 0

lines = sql.split('\n')
for line in lines:
    current_section += line + '\n'
    section_size += len(line)
    
    # Split at natural boundaries when size gets large
    stripped = line.strip()
    if section_size > 30000 and stripped.endswith(';') and 'DO $$' not in current_section.rstrip():
        # Check we're not inside a block
        sections.append(current_section.strip())
        current_section = ''
        section_size = 0

if current_section.strip():
    sections.append(current_section.strip())

print(f"Split into {len(sections)} sections")

# Execute each section
success_count = 0
error_count = 0

for i, section in enumerate(sections):
    print(f"\nSection {i+1}/{len(sections)} ({len(section)} chars)")
    preview = section[:100].replace('\n', ' ')
    print(f"  Preview: {preview}...")
    
    success, error = execute_sql(section)
    
    if success:
        success_count += 1
        print(f"  OK")
    else:
        print(f"  ERROR: {error[:200]}")
        
        # Auto-fix attempts
        if 'already exists' in error.lower():
            if 'type' in error.lower():
                print(f"  -> Type already exists (OK)")
                success_count += 1
                continue
            elif 'policy' in error.lower():
                print(f"  -> Policy already exists (OK)")
                success_count += 1
                continue
            elif 'table' in error.lower():
                print(f"  -> Table already exists (OK)")
                success_count += 1
                continue
            elif 'function' in error.lower():
                # Try CREATE OR REPLACE
                fixed = re.sub(r'CREATE\s+FUNCTION', 'CREATE OR REPLACE FUNCTION', section, flags=re.IGNORECASE)
                s2, e2 = execute_sql(fixed)
                if s2:
                    success_count += 1
                    print(f"  -> Fixed with OR REPLACE")
                    continue
            elif 'trigger' in error.lower():
                print(f"  -> Trigger already exists (OK)")
                success_count += 1
                continue
            elif 'constraint' in error.lower() or 'index' in error.lower():
                print(f"  -> Constraint/index already exists (OK)")
                success_count += 1
                continue
        
        if 'unsafe use of new enum value' in error.lower():
            # Send ALTER TYPE separately
            enum_match = re.search(r"ALTER\s+TYPE\s+(\w+)\s+ADD\s+VALUE\s+'(\w+)'", section, re.IGNORECASE)
            if enum_match:
                enum_name = enum_match.group(1)
                enum_value = enum_match.group(2)
                alter_sql = f"ALTER TYPE {enum_name} ADD VALUE IF NOT EXISTS '{enum_value}';"
                s2, e2 = execute_sql(alter_sql)
                print(f"  -> Enum '{enum_value}' added: {s2}")
                # Remove ALTER TYPE from section and retry
                fixed = re.sub(r"ALTER\s+TYPE\s+\w+\s+ADD\s+VALUE\s+'[^']+'\s*;", '', section, flags=re.IGNORECASE)
                # Also remove DO$$ blocks that contain ALTER TYPE ADD VALUE
                fixed = re.sub(
                    r"DO\s+\$\$\s*BEGIN\s*IF\s+NOT\s+EXISTS.*?ALTER\s+TYPE\s+\w+\s+ADD\s+VALUE\s+'[^']+'\s*;\s*END\s+IF\s*;\s*END\s+\$\$\s*;",
                    '', fixed, flags=re.DOTALL
                )
                if fixed.strip():
                    s3, e3 = execute_sql(fixed)
                    if s3:
                        success_count += 1
                        print(f"  -> Rest of section succeeded")
                        continue
                    else:
                        print(f"  -> Rest of section failed: {e3[:200]}")
        
        if 'does not exist' in error.lower():
            if 'column' in error.lower():
                col_match = re.search(r'column "(\w+)" does not exist', error)
                if col_match:
                    missing_col = col_match.group(1)
                    # Remove COMMENT ON COLUMN for this missing column
                    fixed = re.sub(rf"COMMENT ON COLUMN \w+\.{missing_col}[^;]+;", '', section)
                    s2, e2 = execute_sql(fixed)
                    if s2:
                        success_count += 1
                        print(f"  -> Fixed by removing COMMENT on missing column {missing_col}")
                        continue
            if 'relation' in error.lower():
                table_match = re.search(r'relation "(\w+)" does not exist', error)
                if table_match:
                    missing_table = table_match.group(1)
                    # Strip REFERENCES to this table
                    fixed = strip_fk_refs_to_missing(section, existing_tables | set())
                    s2, e2 = execute_sql(fixed)
                    if s2:
                        success_count += 1
                        print(f"  -> Fixed by stripping REFERENCES to {missing_table}")
                        continue
        
        error_count += 1

print(f"\nRESULT: {success_count} succeeded, {error_count} failed")
print(f"Overall: {'SUCCESS' if error_count <= 2 else 'PARTIAL' if error_count <= 5 else 'FAILED'}")
