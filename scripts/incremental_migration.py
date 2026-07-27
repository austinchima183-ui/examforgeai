#!/usr/bin/env python3
"""
Supabase Migration Executor v5 — splits SQL by logical sections.
Each section is executed separately, ensuring dependencies are resolved before moving on.
"""

import json
import os
import re
import sys
import time
import subprocess

SBP_TOKEN = "sbp_5cc634ccecae8e14221a8546ffb5607a66a2151e"
PROJECT_REF = "pzfnptrrnxkgodclyhft"
API_BASE = f"https://api.supabase.com/v1/projects/{PROJECT_REF}/database/query"
SQL_DIR = "/home/z/my-project/examforge_ai/supabase"

MIGRATION_FILE = sys.argv[1] if len(sys.argv) > 1 else "schema.sql"

def execute_sql(sql: str, timeout=300) -> dict:
    payload = json.dumps({"query": sql})
    with open("/tmp/supabase_query.json", 'w') as f:
        f.write(payload)
    cmd = ["curl", "-s", "-w", "\n%{http_code}", "-X", "POST",
           "-H", f"Authorization: Bearer {SBP_TOKEN}",
           "-H", "Content-Type: application/json",
           "-d", "@/tmp/supabase_query.json",
           "--max-time", str(timeout), API_BASE]
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout+60)
        output = result.stdout.strip()
        parts = output.rsplit("\n", 1)
        if len(parts) == 2:
            body, sc = parts[0], int(parts[1].strip())
        else:
            body, sc = output, 0
        try:
            data = json.loads(body)
        except:
            data = body
        if sc in [200, 201]:
            return {"status": sc, "result": data, "error": None}
        else:
            err = ""
            if isinstance(data, dict):
                err = data.get("message", str(data))
            else:
                err = str(data)[:500]
            return {"status": sc, "result": None, "error": err}
    except subprocess.TimeoutExpired:
        return {"status": 0, "result": None, "error": "Timeout"}
    except Exception as e:
        return {"status": 0, "result": None, "error": str(e)}

def strip_transaction_wrappers(sql: str) -> str:
    """Remove BEGIN; and COMMIT; but keep DO $$ BEGIN ... END $$ intact."""
    lines = sql.split('\n')
    cleaned = []
    for line in lines:
        stripped = line.strip()
        if stripped in ['BEGIN;', 'COMMIT;']:
            continue
        cleaned.append(line)
    return '\n'.join(cleaned)

def smart_split(sql: str) -> list:
    """Split SQL by section headers (===...===) into logical groups."""
    # Find section boundaries marked by === lines
    sections = []
    current_section = ""
    
    lines = sql.split('\n')
    section_start = False
    
    for line in lines:
        # Detect section headers: lines starting with -- === or containing numbered sections
        if re.match(r'^--\s*={3,}', line) or re.match(r'^--\s*\d+\.\s', line):
            # This is a section boundary
            if current_section.strip():
                sections.append(current_section)
            current_section = line + '\n'
            section_start = True
        else:
            current_section += line + '\n'
    
    if current_section.strip():
        sections.append(current_section)
    
    # If we didn find good section boundaries, split by DO $$ block boundaries
    if len(sections) <= 2 and len(sql) > 20000:
        # Split at DO $$ block boundaries and CREATE TABLE boundaries
        # This ensures each section is self-contained
        parts = []
        current = ""
        in_do_block = False
        
        for line in sql.split('\n'):
            if 'DO $$' in line:
                if current.strip():
                    parts.append(current)
                current = line + '\n'
                in_do_block = True
            elif in_do_block and 'END $$;' in line:
                current += line + '\n'
                parts.append(current)
                current = ""
                in_do_block = False
            elif line.strip().startswith('CREATE TABLE') or line.strip().startswith('CREATE OR REPLACE FUNCTION'):
                if current.strip():
                    parts.append(current)
                current = line + '\n'
            else:
                current += line + '\n'
        
        if current.strip():
            parts.append(current)
        
        # Merge small parts together (keep total < 40KB)
        merged = []
        current_merged = ""
        for part in parts:
            if len(current_merged) + len(part) > 40000 and current_merged.strip():
                merged.append(current_merged)
                current_merged = part
            else:
                current_merged += "\n" + part
        if current_merged.strip():
            merged.append(current_merged)
        
        return merged
    
    # Merge sections that are too small
    merged = []
    current_merged = ""
    for section in sections:
        if len(current_merged) + len(section) > 40000 and current_merged.strip():
            merged.append(current_merged)
            current_merged = section
        else:
            current_merged += "\n" + section
    if current_merged.strip():
        merged.append(current_merged)
    
    return merged

def read_file(filename: str) -> str:
    filepath = os.path.join(SQL_DIR, "migrations", filename)
    if filename == "schema.sql":
        filepath = os.path.join(SQL_DIR, "schema.sql")
    if not os.path.exists(filepath):
        return ""
    with open(filepath, 'r') as f:
        return f.read()

def main():
    print(f"Migration: {MIGRATION_FILE}")
    
    sql = read_file(MIGRATION_FILE)
    if not sql:
        print("SKIPPED: File not found")
        sys.exit(2)
    
    print(f"Original: {len(sql):,} chars")
    
    # Strip transaction wrappers
    sql = strip_transaction_wrappers(sql)
    print(f"After strip: {len(sql):,} chars")
    
    # Smart split by logical sections
    sections = smart_split(sql)
    print(f"Sections: {len(sections)}")
    
    success = 0
    errors = []
    
    for si, section in enumerate(sections):
        if not section.strip():
            continue
        
        print(f"\n  Section {si+1}/{len(sections)} ({len(section):,} chars):")
        
        # Show first line for identification
        first_lines = section.strip().split('\n')[:3]
        for fl in first_lines:
            print(f"    {fl[:80]}")
        
        for attempt in range(3):
            resp = execute_sql(section, timeout=180)
            
            if resp["status"] in [200, 201]:
                success += 1
                print(f"    Result: OK")
                break
            
            err = str(resp.get("error", ""))
            
            # Handle "already exists" as success
            if "already exists" in err.lower():
                success += 1
                print(f"    Result: Already exists - OK")
                break
            
            # Handle specific errors
            if "column" in err.lower() and "does not exist" in err.lower():
                # This might be a forward reference - try removing the problematic statement
                print(f"    Error: {err[:100]}")
                if attempt < 2:
                    # Try splitting this section further
                    print(f"    Retrying...")
                    time.sleep(2)
                else:
                    errors.append(f"Section {si+1}: {err[:150]}")
                    print(f"    FAILED after retries")
            
            elif attempt < 2:
                print(f"    FAILED (attempt {attempt+1}): {err[:80]}")
                time.sleep(2)
            else:
                errors.append(f"Section {si+1}: {err[:150]}")
                print(f"    FAILED")
        
        time.sleep(1)
    
    # Verify
    resp = execute_sql("SELECT count(*) as cnt FROM pg_tables WHERE schemaname = 'public'", timeout=30)
    if resp["status"] in [200, 201]:
        print(f"\nPublic tables: {resp['result'][0]['cnt']}")
    
    # List tables
    resp = execute_sql("SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename", timeout=30)
    if resp["status"] in [200, 201]:
        tables = [r["tablename"] for r in resp["result"]]
        print(f"Tables: {', '.join(tables[:10])}{'...' if len(tables) > 10 else ''}")
    
    print(f"\nResult: {success}/{len(sections)} sections OK, {len(errors)} errors")
    
    if errors:
        for e in errors[:5]:
            print(f"  ERROR: {e[:120]}")
    
    sys.exit(0 if len(errors) == 0 else 1)

if __name__ == "__main__":
    main()
