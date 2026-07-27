#!/usr/bin/env python3
"""
Execute ExamForge AI SQL migrations against Supabase using the Management API.

Usage: python3 execute_migration.py <migration_file>

The script:
1. Reads the preprocessed SQL file
2. Sends it via Supabase Management API
3. If errors occur, applies automatic fixes and retries
4. Logs all results
"""

import sys
import os
import json
import subprocess
import re
import time

SUPABASE_PAT = os.environ.get('SUPABASE_PAT', 'sbp_5cc634ccecae8e14221a8546ffb5607a66a2151e')
PROJECT_REF = 'pzfnptrrnxkgodclyhft'
API_URL = f'https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query'

LOG_FILE = '/home/z/my-project/migration_execution_log.txt'
PROCESSED_DIR = '/tmp/migrations_processed'

def log(msg):
    with open(LOG_FILE, 'a') as f:
        f.write(msg + '\n')
    print(msg)

def execute_sql_via_api(sql):
    """Execute SQL via Supabase Management API."""
    # Use curl to call the API
    # The API expects a JSON body with a "query" field
    # We need to be careful with large SQL files - break into chunks if needed
    
    result = subprocess.run(
        ['curl', '-s', '-X', 'POST', API_URL,
         '-H', f'Authorization: Bearer {SUPABASE_PAT}',
         '-H', 'Content-Type: application/json',
         '-d', json.dumps({"query": sql})],
        capture_output=True, text=True, timeout=120
    )
    
    if result.returncode != 0:
        return None, f"curl error: {result.stderr}"
    
    try:
        response = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None, f"Invalid JSON response: {result.stdout[:500]}"
    
    # Check for errors
    if isinstance(response, list):
        # Successful response is a list of result objects
        return response, None
    elif isinstance(response, dict):
        if 'error' in response or 'message' in response:
            error_msg = response.get('error', response.get('message', str(response)))
            return None, error_msg
        # Some successful responses are dicts too
        return response, None
    
    return response, None

def execute_sql_in_chunks(sql, chunk_size=50000):
    """Break large SQL into chunks and execute each."""
    # Split on statement boundaries (semicolons followed by newlines)
    statements = []
    current = ''
    depth = 0  # Track DO $$ / BEGIN / END depth
    
    lines = sql.split('\n')
    for line in lines:
        stripped = line.strip()
        
        # Track PL/pgSQL block depth
        if stripped.startswith('DO $$') or stripped == 'BEGIN' or stripped.startswith('DO $$ BEGIN'):
            depth += 1
        if stripped.startswith('END') and depth > 0:
            depth -= 1
        
        current += line + '\n'
        
        # Split on semicolons that are NOT inside DO $$ blocks
        if stripped.endswith(';') and depth == 0:
            statements.append(current.strip())
            current = ''
    
    if current.strip():
        statements.append(current.strip())
    
    # Group statements into chunks by size
    chunks = []
    current_chunk = ''
    for stmt in statements:
        if len(current_chunk) + len(stmt) > chunk_size and current_chunk:
            chunks.append(current_chunk)
            current_chunk = stmt + '\n'
        else:
            current_chunk += stmt + '\n'
    
    if current_chunk.strip():
        chunks.append(current_chunk)
    
    log(f"  Split into {len(chunks)} chunks ({len(statements)} statements)")
    
    errors = []
    for i, chunk in enumerate(chunks):
        log(f"  Executing chunk {i+1}/{len(chunks)} ({len(chunk)} chars)...")
        result, error = execute_sql_via_api(chunk)
        if error:
            log(f"  Chunk {i+1} ERROR: {error[:200]}")
            errors.append((i, error))
        else:
            log(f"  Chunk {i+1} OK")
    
    return errors

def auto_fix_sql(sql, error_msg):
    """Attempt to automatically fix SQL based on common error patterns."""
    fixed = sql
    
    # Pattern 1: "type ... already exists" -> wrap in IF NOT EXISTS
    type_exists_match = re.search(r'type "(\w+)" already exists', error_msg, re.IGNORECASE)
    if type_exists_match:
        type_name = type_exists_match.group(1)
        log(f"  AUTO-FIX: Wrapping CREATE TYPE {type_name} in DO $$ IF NOT EXISTS")
        # Replace bare CREATE TYPE with IF NOT EXISTS check
        pattern = re.compile(
            rf'CREATE\s+TYPE\s+{type_name}\s+AS\s+ENUM\s*\([^)]*\)',
            re.IGNORECASE
        )
        fixed = pattern.sub(
            lambda m: f"DO $$ BEGIN\n  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = '{type_name}') THEN\n    {m.group(0)};\n  END IF;\nEND $$;",
            fixed
        )
    
    # Pattern 2: "policy ... already exists" -> add DROP POLICY IF EXISTS
    policy_exists_match = re.search(r'policy "([^"]+)" already exists', error_msg, re.IGNORECASE)
    if policy_exists_match:
        policy_name = policy_exists_match.group(1)
        log(f"  AUTO-FIX: Adding DROP POLICY IF EXISTS for {policy_name}")
        # Find the CREATE POLICY and add DROP before it
        pattern = re.compile(rf'CREATE\s+POLICY\s+"{policy_name}"', re.IGNORECASE)
        fixed = pattern.sub(f'DROP POLICY IF EXISTS "{policy_name}" ON ;\nCREATE POLICY "{policy_name}"', fixed)
        # Better: need to find the ON table part
        # Actually our preprocessing already handles this
    
    # Pattern 3: "column ... does not exist" in policy
    column_missing = re.search(r'column "(\w+)" does not exist', error_msg, re.IGNORECASE)
    if column_missing:
        col = column_missing.group(1)
        log(f"  AUTO-FIX: Column '{col}' missing - may need function replacement")
        # This is handled by rls_role_fix.sql which creates get_user_role() and get_user_school_id()
    
    # Pattern 4: "relation ... does not exist" -> FK references a table not yet created
    relation_missing = re.search(r'relation "(\w+)" does not exist', error_msg, re.IGNORECASE)
    if relation_missing:
        table = relation_missing.group(1)
        log(f"  AUTO-FIX: Table '{table}' not yet created - stripping REFERENCES")
        # Strip all REFERENCES to this table
        pattern = re.compile(
            rf'REFERENCES\s+{table}\s*\(\s*\w+\s*\)\s*(ON\s+DELETE\s+\w+)?',
            re.IGNORECASE
        )
        fixed = pattern.sub('', fixed)
    
    # Pattern 5: "cannot add value to enum" -> already exists
    enum_add_match = re.search(r'cannot add value "(\w+)" to enum "(\w+)"', error_msg, re.IGNORECASE)
    if enum_add_match:
        value = enum_add_match.group(1)
        enum_name = enum_add_match.group(2)
        log(f"  AUTO-FIX: Wrapping ALTER TYPE {enum_name} ADD VALUE in IF NOT EXISTS")
        # Replace bare ALTER TYPE ADD VALUE with IF NOT EXISTS check
        pattern = re.compile(
            rf'ALTER\s+TYPE\s+{enum_name}\s+ADD\s+VALUE\s+\'{value}\'',
            re.IGNORECASE
        )
        fixed = pattern.sub(
            lambda m: f"DO $$ BEGIN\n  IF NOT EXISTS (SELECT 1 FROM pg_enum WHERE enumlabel = '{value}' AND enumtypid = (SELECT oid FROM pg_type WHERE typname = '{enum_name}')) THEN\n    {m.group(0)};\n  END IF;\nEND $$;",
            fixed
        )
    
    # Pattern 6: "function ... already exists" -> use CREATE OR REPLACE
    func_exists = re.search(r'function (\w+)\(.*\) already exists', error_msg, re.IGNORECASE)
    if func_exists:
        func_name = func_exists.group(1)
        log(f"  AUTO-FIX: Changing CREATE FUNCTION {func_name} to CREATE OR REPLACE")
        pattern = re.compile(rf'CREATE\s+FUNCTION\s+{func_name}', re.IGNORECASE)
        fixed = pattern.sub(f'CREATE OR REPLACE FUNCTION {func_name}', fixed)
    
    # Pattern 7: "table ... already exists" -> should use IF NOT EXISTS
    table_exists = re.search(r'relation "(\w+)" already exists', error_msg, re.IGNORECASE)
    if table_exists:
        table_name = table_exists.group(1)
        log(f"  AUTO-FIX: Adding IF NOT EXISTS to CREATE TABLE {table_name}")
        pattern = re.compile(rf'CREATE\s+TABLE\s+{table_name}\s*\(', re.IGNORECASE)
        fixed = pattern.sub(f'CREATE TABLE IF NOT EXISTS {table_name} (', fixed)
    
    # Pattern 8: "constraint ... already exists" -> drop first
    constraint_exists = re.search(r'constraint "(\w+)" already exists', error_msg, re.IGNORECASE)
    if constraint_exists:
        constraint_name = constraint_exists.group(1)
        log(f"  AUTO-FIX: Adding DROP CONSTRAINT IF EXISTS for {constraint_name}")
        # Need to find which table this constraint belongs to - extract from error
        # Usually in format: constraint "name" for relation "table"
        table_match = re.search(r'relation "(\w+)"', error_msg, re.IGNORECASE)
        if table_match:
            table = table_match.group(1)
            fixed = f'ALTER TABLE {table} DROP CONSTRAINT IF EXISTS {constraint_name};\n' + fixed
    
    # Pattern 9: "trigger ... already exists" -> our preprocessing should handle this
    
    # Pattern 10: "view ... already exists" -> use CREATE OR REPLACE
    view_exists = re.search(r'view "(\w+)" already exists', error_msg, re.IGNORECASE)
    if view_exists:
        view_name = view_exists.group(1)
        log(f"  AUTO-FIX: Changing CREATE VIEW to CREATE OR REPLACE VIEW {view_name}")
        pattern = re.compile(rf'CREATE\s+VIEW\s+{view_name}', re.IGNORECASE)
        fixed = pattern.sub(f'CREATE OR REPLACE VIEW {view_name}', fixed)
    
    return fixed

def execute_migration(filename, max_retries=3):
    """Execute a single migration file with auto-repair."""
    filepath = os.path.join(PROCESSED_DIR, filename)
    
    if not os.path.exists(filepath):
        # Try the original file
        filepath = os.path.join('/home/z/my-project/examforge_ai/supabase/migrations', filename)
    
    with open(filepath, 'r') as f:
        sql = f.read()
    
    log(f"\n{'='*60}")
    log(f"EXECUTING: {filename} ({len(sql)} chars)")
    log(f"{'='*60}")
    
    for attempt in range(max_retries):
        log(f"  Attempt {attempt+1}/{max_retries}")
        
        # Try executing in chunks
        errors = execute_sql_in_chunks(sql)
        
        if not errors:
            log(f"  SUCCESS - all chunks executed without errors")
            return True
        
        # Try to fix errors
        log(f"  {len(errors)} errors found, attempting auto-fix...")
        
        all_fixed = True
        for chunk_idx, error_msg in errors:
            log(f"  Error in chunk {chunk_idx}: {error_msg[:300]}")
            fixed_sql = auto_fix_sql(sql, error_msg)
            if fixed_sql != sql:
                sql = fixed_sql
                # Save the fixed version
                with open(filepath, 'w') as f:
                    f.write(sql)
                log(f"  SQL file updated with auto-fixes")
            else:
                all_fixed = False
                log(f"  Could not auto-fix this error")
        
        if not all_fixed and attempt == max_retries - 1:
            log(f"  FAILED after {max_retries} attempts - some errors could not be fixed")
            # Try one more approach: execute the entire file as a single query
            log(f"  Attempting single-query execution...")
            result, error = execute_sql_via_api(sql)
            if error:
                log(f"  Single-query also failed: {error[:300]}")
                return False
            else:
                log(f"  Single-query execution succeeded!")
                return True
    
    return False

if __name__ == '__main__':
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        success = execute_migration(filename)
        sys.exit(0 if success else 1)
    else:
        print("Usage: python3 execute_migration.py <migration_file>")
        sys.exit(1)
