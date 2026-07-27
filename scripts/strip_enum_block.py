import re

with open('/tmp/migrations_processed/rls_role_fix.sql') as f:
    sql = f.read()

# Remove the DO block for adding parent enum value
pattern = r"DO\s+\$\$\s*\nBEGIN\s*\n\s*-- Add parent role\s*\n\s*IF NOT EXISTS\s*\(\s*\n\s*SELECT\s+1\s+FROM\s+pg_enum\s+e\s*\n\s*JOIN\s+pg_type\s+t\s+ON\s+t\.oid\s+=\s+e\.enumtypid\s*\n\s*WHERE\s+t\.typname\s+=\s+'user_role'\s+AND\s+e\.enumlabel\s+=\s+'parent'\s*\n\s*\)\s+THEN\s*\n\s*ALTER\s+TYPE\s+user_role\s+ADD\s+VALUE\s+'parent';\s*\n\s*END\s+IF;\s*\nEND\s+\$\$;"

sql = re.sub(pattern, '', sql, flags=re.DOTALL)

with open('/tmp/rls_role_fix_noenum.sql', 'w') as f:
    f.write(sql)

print(f"Saved {len(sql)} chars")
