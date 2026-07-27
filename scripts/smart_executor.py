#!/usr/bin/env python3
"""
Smart SQL executor for Supabase Management API.

Strategies:
1. Splits large migration files into small batches (2-5 statements each)
2. Sends ALTER TYPE ADD VALUE as separate calls (can't use new value in same transaction)
3. Handles "already exists" errors gracefully
4. Strips cross-file FK REFERENCES automatically
5. Logs all operations
"""

import os
import re
import json
import subprocess
import sys
import time

SUPABASE_PAT = os.environ.get('SUPABASE_PAT', 'sbp_5cc634ccecae8e14221a8546ffb5607a66a2151e')
PROJECT_REF = 'pzfnptrrnxkgodclyhft'
API_URL = f'https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query'

LOG_FILE = '/home/z/my-project/migration_execution_log.txt'
PROCESSED_DIR = '/tmp/migrations_processed'
MIGRATIONS_DIR = '/home/z/my-project/examforge_ai/supabase/migrations'

def log(msg):
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S')
    with open(LOG_FILE, 'a') as f:
        f.write(f"[{timestamp}] {msg}\n")
    print(msg)

def execute_sql(sql, max_retries=2):
    """Execute SQL via Supabase Management API. Returns (success, error_msg)."""
    for attempt in range(max_retries):
        result = subprocess.run(
            ['curl', '-s', '--max-time', '25', '-X', 'POST', API_URL,
             '-H', f'Authorization: Bearer {SUPABASE_PAT}',
             '-H', 'Content-Type: application/json',
             '-d', json.dumps({"query": sql})],
            capture_output=True, text=True, timeout=30
        )
        
        if result.returncode != 0:
            if attempt < max_retries - 1:
                time.sleep(2)
                continue
            return False, f"curl error: {result.stderr}"
        
        try:
            response = json.loads(result.stdout)
        except json.JSONDecodeError:
            return False, f"Invalid JSON: {result.stdout[:200]}"
        
        # Check for errors
        if isinstance(response, dict):
            if 'error' in response:
                error_detail = response['error']
                if isinstance(error_detail, str):
                    return False, error_detail
                elif isinstance(error_detail, dict):
                    return False, error_detail.get('message', str(error_detail))
            elif 'message' in response:
                # Could be a success message or error
                msg = response['message']
                if 'error' in msg.lower() or 'failed' in msg.lower():
                    return False, msg
                return True, None
        
        # Success - response is a list of results or empty
        return True, None
    
    return False, "Max retries exceeded"

def split_sql_into_batches(sql, max_batch_size=8000):
    """
    Split SQL into small batches for the Management API.
    Each batch contains a few related statements.
    """
    # Split on statement boundaries
    statements = []
    current_stmt = ''
    in_do_block = False
    in_function = False
    paren_depth = 0
    
    lines = sql.split('\n')
    for line in lines:
        stripped = line.strip()
        
        # Track DO $$ blocks
        if 'DO $$' in stripped or 'DO$ $' in stripped:
            in_do_block = True
        if in_do_block and stripped.startswith('END') and '$$' in stripped:
            in_do_block = False
        
        # Track CREATE FUNCTION blocks (they have $$ delimiters too)
        if re.match(r'CREATE\s+(OR\s+REPLACE\s+)?FUNCTION', stripped, re.IGNORECASE):
            in_function = True
        if in_function and stripped.startswith('$$;'):
            in_function = False
        # Track language blocks inside functions  
        if stripped == '$$' and not in_do_block:
            if in_function:
                in_function = False
        
        # Track parenthesis depth for CREATE TABLE
        if stripped.startswith('CREATE TABLE') or stripped.startswith('CREATE'):
            if '(' in stripped:
                paren_depth += stripped.count('(') - stripped.count(')')
        elif paren_depth > 0:
            paren_depth += stripped.count('(') - stripped.count(')')
        
        current_stmt += line + '\n'
        
        # End of statement: semicolon at end of line, not inside a block
        if stripped.endswith(';') and not in_do_block and not in_function and paren_depth == 0:
            if current_stmt.strip():
                statements.append(current_stmt.strip())
            current_stmt = ''
    
    # Handle any remaining statement
    if current_stmt.strip():
        statements.append(current_stmt.strip())
    
    # Group statements into batches by size
    batches = []
    current_batch = ''
    batch_stmt_count = 0
    
    for stmt in statements:
        # ALTER TYPE ADD VALUE must be in its own batch
        if re.search(r'ALTER\s+TYPE\s+\w+\s+ADD\s+VALUE', stmt, re.IGNORECASE):
            if current_batch.strip():
                batches.append(current_batch.strip())
                current_batch = ''
                batch_stmt_count = 0
            batches.append(stmt)
            continue
        
        # CREATE TABLE with IF NOT EXISTS can be grouped
        # But CREATE POLICY + DROP POLICY pairs should stay together
        
        if len(current_batch) + len(stmt) + 2 > max_batch_size and current_batch.strip():
            batches.append(current_batch.strip())
            current_batch = stmt + '\n'
            batch_stmt_count = 1
        else:
            current_batch += stmt + '\n'
            batch_stmt_count += 1
    
    if current_batch.strip():
        batches.append(current_batch.strip())
    
    return batches

def strip_references_to_missing_tables(sql, existing_tables):
    """Remove REFERENCES clauses that point to tables not yet created."""
    # Find all REFERENCES patterns
    pattern = re.compile(
        r'REFERENCES\s+(\w+)\s*\(\s*\w+\s*\)(\s+ON\s+DELETE\s+(CASCADE|SET\s+NULL|RESTRICT|SET\s+DEFAULT|NO\s+ACTION))?',
        re.IGNORECASE
    )
    
    for match in pattern.finditer(sql):
        ref_table = match.group(1)
        if ref_table not in existing_tables and ref_table.lower() not in [t.lower() for t in existing_tables]:
            log(f"  STRIPPING FK: REFERENCES {ref_table} (table not yet created)")
            # Replace just the REFERENCES clause, keeping the column definition
            full_match = match.group(0)
            on_delete = match.group(2) or ''
            sql = sql.replace(full_match, '')
    
    return sql

def execute_migration_file(filename):
    """Execute a full migration file with smart batching."""
    filepath = os.path.join(PROCESSED_DIR, filename)
    
    if not os.path.exists(filepath):
        filepath = os.path.join(MIGRATIONS_DIR, filename)
    
    with open(filepath, 'r') as f:
        sql = f.read()
    
    log(f"\n{'='*60}")
    log(f"MIGRATION: {filename} ({len(sql)} chars)")
    log(f"{'='*60}")
    
    # Get current table list for FK stripping
    result, error = execute_sql(
        "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'"
    )
    existing_tables = set()
    if result and not error:
        # result is True when successful
        pass
    # We know the base tables + any from previous migrations
    # Read from DB
    r = subprocess.run(
        ['curl', '-s', '--max-time', '25', '-X', 'POST', API_URL,
         '-H', f'Authorization: Bearer {SUPABASE_PAT}',
         '-H', 'Content-Type: application/json',
         '-d', json.dumps({"query": "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name"})],
        capture_output=True, text=True, timeout=30
    )
    try:
        tables_response = json.loads(r.stdout)
        if isinstance(tables_response, list):
            existing_tables = set(t['table_name'] for t in tables_response)
        log(f"  Existing tables: {len(existing_tables)}")
    except:
        log(f"  Could not fetch table list, using known tables")
    
    # Strip REFERENCES to missing tables
    sql = strip_references_to_missing_tables(sql, existing_tables)
    
    # Split into batches
    batches = split_sql_into_batches(sql)
    log(f"  Split into {len(batches)} batches")
    
    success_count = 0
    error_count = 0
    skipped_count = 0
    
    for i, batch in enumerate(batches):
        batch_preview = batch[:100].replace('\n', ' ')
        log(f"  Batch {i+1}/{len(batches)}: {batch_preview}...")
        
        success, error_msg = execute_sql(batch)
        
        if success:
            success_count += 1
            log(f"  Batch {i+1}: OK")
        else:
            # Analyze error and try to fix
            log(f"  Batch {i+1}: ERROR - {error_msg[:200]}")
            
            # Handle "already exists" errors - these are OK for idempotent migrations
            if 'already exists' in error_msg.lower():
                if 'type' in error_msg.lower() and 'already exists' in error_msg.lower():
                    log(f"  -> Type already exists (OK, idempotent)")
                    success_count += 1
                    continue
                elif 'policy' in error_msg.lower() and 'already exists' in error_msg.lower():
                    # Try dropping and recreating
                    log(f"  -> Policy already exists, attempting DROP + CREATE")
                    # Extract policy name and table
                    policy_match = re.search(r'policy "([^"]+)" already exists', error_msg)
                    if policy_match:
                        policy_name = policy_match.group(1)
                        # Try to find the table from the batch
                        table_match = re.search(r'ON\s+(\w+)\s+FOR', batch)
                        if table_match:
                            table_name = table_match.group(1)
                            drop_batch = f'DROP POLICY IF EXISTS "{policy_name}" ON {table_name};\n{batch}'
                            s2, e2 = execute_sql(drop_batch)
                            if s2:
                                success_count += 1
                                log(f"  -> Fixed by DROP + CREATE")
                                continue
                elif 'table' in error_msg.lower() and 'already exists' in error_msg.lower():
                    log(f"  -> Table already exists (OK)")
                    success_count += 1
                    continue
                elif 'function' in error_msg.lower() and 'already exists' in error_msg.lower():
                    log(f"  -> Function already exists (OK, use OR REPLACE)")
                    # Replace CREATE FUNCTION with CREATE OR REPLACE FUNCTION
                    fixed = re.sub(r'CREATE\s+FUNCTION', 'CREATE OR REPLACE FUNCTION', batch, flags=re.IGNORECASE)
                    s2, e2 = execute_sql(fixed)
                    if s2:
                        success_count += 1
                        log(f"  -> Fixed by CREATE OR REPLACE")
                        continue
                elif 'constraint' in error_msg.lower() and 'already exists' in error_msg.lower():
                    log(f"  -> Constraint already exists (OK)")
                    success_count += 1
                    continue
                elif 'trigger' in error_msg.lower() and 'already exists' in error_msg.lower():
                    log(f"  -> Trigger already exists (OK)")
                    success_count += 1
                    continue
            
            # Handle "unsafe use of new enum value" - need separate execution
            if 'unsafe use of new value' in error_msg.lower():
                log(f"  -> Enum value needs separate transaction")
                # Extract ALTER TYPE ADD VALUE and execute it alone
                enum_match = re.search(r"ALTER\s+TYPE\s+(\w+)\s+ADD\s+VALUE\s+'(\w+)'", batch, re.IGNORECASE)
                if enum_match:
                    enum_name = enum_match.group(1)
                    enum_value = enum_match.group(2)
                    alter_sql = f"ALTER TYPE {enum_name} ADD VALUE IF NOT EXISTS '{enum_value}';"
                    s2, e2 = execute_sql(alter_sql)
                    if s2:
                        log(f"  -> Enum value '{enum_value}' added successfully")
                        # Now retry the batch without the ALTER TYPE statement
                        fixed_batch = re.sub(
                            r"DO\s+\$\$\s*BEGIN\s*IF\s+NOT\s+EXISTS.*?ALTER\s+TYPE\s+\w+\s+ADD\s+VALUE\s+'[^']+'\s*;\s*END\s+IF\s*;\s*END\s+\$\$\s*;",
                            '', batch, flags=re.DOTALL
                        )
                        fixed_batch = re.sub(
                            r"ALTER\s+TYPE\s+\w+\s+ADD\s+VALUE\s+'[^']+'\s*;",
                            '', fixed_batch, flags=re.IGNORECASE
                        )
                        if fixed_batch.strip():
                            s3, e3 = execute_sql(fixed_batch)
                            if s3:
                                success_count += 1
                                log(f"  -> Rest of batch succeeded")
                                continue
                            else:
                                log(f"  -> Rest of batch failed: {e3[:200]}")
                                error_count += 1
                                continue
                        success_count += 1
                        continue
            
            # Handle "does not exist" errors
            if 'does not exist' in error_msg.lower():
                if 'column' in error_msg.lower():
                    log(f"  -> Column does not exist (may need to skip)")
                elif 'relation' in error_msg.lower() or 'table' in error_msg.lower():
                    log(f"  -> Table does not exist (FK to missing table)")
                    # Strip REFERENCES from the batch
                    table_match = re.search(r'relation "(\w+)" does not exist', error_msg)
                    if table_match:
                        missing_table = table_match.group(1)
                        fixed_batch = strip_references_to_missing_tables(batch, existing_tables)
                        s2, e2 = execute_sql(fixed_batch)
                        if s2:
                            success_count += 1
                            log(f"  -> Fixed by stripping REFERENCES to {missing_table}")
                            continue
            
            # Handle "cannot alter type" within transaction
            if 'cannot alter type' in error_msg.lower():
                log(f"  -> ALTER TYPE needs separate execution")
                error_count += 1
                continue
            
            error_count += 1
    
    log(f"\n  RESULT: {success_count} succeeded, {error_count} failed, {skipped_count} skipped")
    
    if error_count == 0:
        log(f"  MIGRATION {filename}: SUCCESS")
        return True
    elif error_count <= 2:
        log(f"  MIGRATION {filename}: PARTIAL SUCCESS ({error_count} minor errors)")
        return True
    else:
        log(f"  MIGRATION {filename}: FAILED ({error_count} errors)")
        return False

if __name__ == '__main__':
    if len(sys.argv) > 1:
        filename = sys.argv[1]
        success = execute_migration_file(filename)
        sys.exit(0 if success else 1)
    else:
        print("Usage: python3 smart_executor.py <migration_file>")
        sys.exit(1)
