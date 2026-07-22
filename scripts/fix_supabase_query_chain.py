#!/usr/bin/env python3
"""
Fix Supabase Postgrest query chain pattern:
  WRONG:  .from(t).select().order().eq()  -- filters after transforms
  RIGHT:  .from(t).select().eq().order()  -- filters before transforms

The root cause: In Supabase Flutter v2+, .select() returns PostgrestFilterBuilder.
  .order(), .range(), .limit() return PostgrestTransformBuilder.
  PostgrestTransformBuilder does NOT have .eq(), .gte(), .lte() etc.
  Filters must be applied BEFORE transforms.

Strategy: Find all methods in datasource files that use the pattern:
  var query = _supabase.from(X).select().order(...)
  ... filter .eq() calls on query ...
  
  And restructure to:
  var filterQuery = _supabase.from(X).select()
  ... filter .eq() calls on filterQuery ...
  var transformQuery = filterQuery.order(...)
  ... .range() calls on transformQuery ...
"""

import re
import os

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    
    # Pattern: var query = _supabase.from(X).select().order(...) or .select().eq(...).order(...)
    # followed by conditional filter calls like query.eq() or query.gte()/lte()
    # then transform calls like query.range() or query.limit()
    
    # We need to find blocks of code in try{} clauses that have this pattern
    # and restructure them.
    
    # Strategy: Find all instances where .order() or .range() is called
    # on a query variable, then filter methods (.eq, .gte, .lte, .neq, .in, .like, .ilike)
    # are called on the same variable AFTER the transform.
    
    # General approach: Use regex to find query variable names, then
    # restructure the code block.
    
    # Actually, a simpler approach: Find lines where .order() is called on a var
    # that later has .eq()/.gte()/.lte() called on it.
    # Replace the pattern systematically.
    
    # Since this is complex, let me find the specific patterns in each file
    # and fix them individually.
    
    # Pattern 1: var query = ... .select().order(...);
    #   then query.eq(...); etc
    #   then query = query.range(...); or query.limit(...)
    #
    # Fix: var filterQuery = ... .select();
    #   filterQuery = filterQuery.eq(...); etc
    #   var transformQuery = filterQuery.order(...);
    #   transformQuery = transformQuery.range(...); or .limit(...)
    
    # Pattern 2: var query = ... .select().eq(...).order(...);
    #   then query.eq(...); etc (additional filters after order)
    #
    # Fix: var filterQuery = ... .select().eq(...);
    #   filterQuery = filterQuery.eq(...); etc (additional filters)
    #   var transformQuery = filterQuery.order(...);
    #   ...
    
    # Pattern 3: var query = ... .select().eq(...).order(...).order(...);
    #   then query = query.eq(...); (filter after double-order)
    #
    # Fix: var filterQuery = ... .select().eq(...);
    #   filterQuery = filterQuery.eq(...); etc
    #   var transformQuery = filterQuery.order(...).order(...);
    #   ...
    
    lines = content.split('\n')
    new_lines = lines.copy()
    
    # Find all 'var query = _supabase.from(X).select()...' lines
    # and the subsequent filter/transform calls
    
    i = 0
    while i < len(new_lines):
        line = new_lines[i]
        
        # Look for query initialization that includes .order() before filters
        # Pattern: var query = _supabase.from(X).select()[.eq(...)].order(...)
        match = re.match(r'^(\s*)var query = _supabase\.from\(\w+\)\.select\(\)(.*)\.order\(', line)
        if match:
            indent = match.group(1)
            after_select = match.group(2)  # could be empty or .eq(...)
            
            # Find the complete order chain (may span multiple lines or have multiple .order())
            # Collect everything from .select() to end of statement
            full_init = line
            
            # Check if the line has trailing .order() or more transforms
            # We need to split: select [+ initial filters] -> order [+ transforms]
            
            # Find where .order() starts in the initialization
            select_part = '_supabase.from(' + re.search(r'from\((\w+)\)', line).group(1) + ').select()'
            if after_select:
                select_part += after_select
            
            # Get the rest (from .order onwards)
            order_match = re.search(r'\.order\([^)]*\)(.*)', line)
            order_part = order_match.group(0) if order_match else ''
            remaining_on_line = order_match.group(1) if order_match else ''
            
            # Check for additional .order() calls on the same line
            additional_orders = ''
            while re.search(r'\.order\([^)]*\)', remaining_on_line):
                m = re.search(r'\.order\([^)]*\)', remaining_on_line)
                additional_orders += m.group(0)
                remaining_on_line = remaining_on_line[m.end():]
            
            # Now restructure:
            # var filterQuery = _supabase.from(X).select()[+ initial eq filters];
            # var transformQuery = filterQuery.order(...)[+ additional orders];
            
            new_init = f'{indent}var filterQuery = {select_part};'
            new_order = f'{indent}var transformQuery = filterQuery{order_part}{additional_orders};'
            
            new_lines[i] = new_init
            
            # Find subsequent filter calls (query.eq, query.gte, query.lte) and change them
            j = i + 1
            filter_calls = []
            while j < len(new_lines):
                filter_line = new_lines[j]
                # Match: query = query.eq(...), query.gte(...), query.lte(...), etc
                fm = re.match(r'^(\s*)(if \(filters\.containsKey.*\)\s*\{|query = query\.(eq|gte|lte|neq|inFilter|like|ilike|contains|containedBy)\()', filter_line)
                if fm:
                    # Change 'query' to 'filterQuery' in this block
                    # This might be a single line or an if block
                    if 'if (filters.containsKey' in filter_line:
                        # It's an if block, need to find the closing }
                        # Change query -> filterQuery in the block
                        new_lines[j] = filter_line.replace('query = query.', 'filterQuery = filterQuery.')
                        j += 1
                        # Also change the inner line
                        if j < len(new_lines):
                            inner = new_lines[j]
                            new_lines[j] = inner.replace('query = query.', 'filterQuery = filterQuery.')
                    else:
                        new_lines[j] = filter_line.replace('query = query.', 'filterQuery = filterQuery.')
                    j += 1
                else:
                    break
            
            # Now find transform calls (query = query.range, query.limit, final response = await query)
            while j < len(new_lines):
                transform_line = new_lines[j]
                tm = re.match(r'^(\s*)query = query\.(range|limit)\(', transform_line)
                if tm:
                    new_lines[j] = transform_line.replace('query = query.', 'transformQuery = transformQuery.')
                    j += 1
                elif 'await query' in transform_line:
                    new_lines[j] = transform_line.replace('await query', 'await transformQuery')
                    j += 1
                else:
                    break
            
            # Insert the order line after all filter calls
            # Find where filters end (j points to first non-filter line)
            insert_pos = j
            if insert_pos <= len(new_lines):
                new_lines.insert(insert_pos, new_order)
            
            i = j + 1
            continue
        
        i += 1
    
    result = '\n'.join(new_lines)
    if result != original:
        with open(filepath, 'w') as f:
            f.write(result)
        return True
    return False

# Actually, this approach is too complex for regex. Let me use a simpler,
# more reliable method: just find the exact patterns we know exist and 
# fix them mechanically.

# For each file, we know the patterns from the error output. Let me 
# just read each file, find the pattern blocks, and fix them.

def fix_datasource_file(filepath):
    """Fix Supabase query chain pattern in a datasource file.
    
    The pattern to fix:
    var query = _supabase.from(X).select().order(...)  [or .select().eq().order()]
    ... conditional filter calls: query = query.eq/gte/lte(...)
    ... transform calls: query = query.range/limit(...)
    ... final: await query
    
    Becomes:
    var filterQuery = _supabase.from(X).select()  [or .select().eq()]
    ... conditional filter calls: filterQuery = filterQuery.eq/gte/lte(...)
    var transformQuery = filterQuery.order(...)
    ... transform calls: transformQuery = transformQuery.range/limit(...)
    ... final: await transformQuery
    """
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Simple regex-based approach:
    # Find blocks where .order() appears in query initialization
    # and .eq/.gte/.lte appear after
    
    # Step 1: Replace query variable names
    # Pattern: "var query = _supabase.from(X).select()" followed by ".order" on same line
    # This means the init line has both select and order
    
    lines = content.split('\n')
    
    # Find blocks that need restructuring
    # A "block" starts with "var query = _supabase.from(X).select()" and ends with "await query"
    
    blocks_to_fix = []
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if 'var query = _supabase' in line and '.select()' in line and '.order(' in line:
            # This is a block that needs fixing
            # Find the start and end
            start = i
            # Find where this block ends (await query or final response)
            end = i
            for j in range(i, min(i+50, len(lines))):
                if 'await query' in lines[j] or 'await transformQuery' in lines[j]:
                    end = j
                    break
            blocks_to_fix.append((start, end))
            i = end + 1
        else:
            i += 1
    
    if not blocks_to_fix:
        return False
    
    # For each block, restructure
    for start, end in blocks_to_fix:
        block_lines = lines[start:end+1]
        
        # Find the initialization line
        init_line = block_lines[0]
        
        # Split into select part and order part
        # Find where .order( first appears
        select_prefix_match = re.match(
            r'(\s*)var query = _supabase\.from\(\w+\)\.select\(\)',
            init_line
        )
        if not select_prefix_match:
            continue
        
        indent = select_prefix_match.group(1)
        
        # Find if there are .eq() calls between .select() and .order()
        # Pattern: .select().eq('is_active', true).order(...)
        between_select_order = re.search(
            r'\.select\(\)(.*?)\.order\(',
            init_line
        )
        initial_filters = between_select_order.group(1) if between_select_order else ''
        
        # Find everything from .order() onward on the init line
        order_onwards_match = re.search(r'\.order\(.+', init_line)
        order_chain = order_onwards_match.group(0) if order_onwards_match else '.order()'
        
        # Check for .eq() right after .select() that stays as filter
        # e.g., .select().eq('is_active', true) -> stays on filterQuery
        # then .order() -> moves to transformQuery
        
        # Build new init line: var filterQuery = ... .select()[+ initial filters];
        select_part = init_line.split('.order(')[0].replace('var query = ', 'var filterQuery = ')
        
        # Build order line: var transformQuery = filterQuery.order(...);
        order_part = '.order(' + init_line.split('.order(')[1]
        # If the init line ends with ;, the order part already has it
        order_line = f'{indent}var transformQuery = filterQuery{order_part}'
        
        # Replace remaining lines in block
        new_block = [select_part.rstrip(';') + ';']
        
        for line in block_lines[1:]:
            # Replace query -> filterQuery for filter calls
            # Replace query -> transformQuery for transform calls
            if 'query = query.' in line:
                method = re.search(r'query = query\.(eq|gte|lte|neq|inFilter|like|ilike|contains|containedBy)\(', line)
                if method:
                    new_line = line.replace('query = query.', 'filterQuery = filterQuery.')
                    new_block.append(new_line)
                    continue
            
            if 'query = query.range(' in line or 'query = query.limit(' in line:
                new_line = line.replace('query = query.', 'transformQuery = transformQuery.')
                new_block.append(new_line)
                continue
            
            if 'await query' in line:
                new_line = line.replace('await query', 'await transformQuery')
                new_block.append(new_line)
                continue
            
            new_block.append(line)
        
        # Insert order line after all filter calls
        # Find where filter calls end (first line that's not a filter call)
        filter_end = 1  # first line after init
        for j in range(1, len(new_block)):
            if 'filterQuery = filterQuery.' not in new_block[j]:
                if 'if (filters.containsKey' not in new_block[j]:
                    filter_end = j
                    break
        
        # Insert order line at filter_end
        new_block.insert(filter_end, order_line)
        
        # Replace in original lines
        for j, new_line in enumerate(new_block):
            lines[start + j] = new_line
    
    result = '\n'.join(lines)
    with open(filepath, 'w') as f:
        f.write(result)
    return True

# Process all datasource files
datasource_files = [
    '/home/z/my-project/examforge_ai/lib/features/parent_portal/data/datasources/parent_portal_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/communication/data/datasources/communication_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/super_admin/data/datasources/super_admin_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/question_bank/data/datasources/question_bank_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/admission_hub/data/datasources/admission_hub_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/results/data/datasources/results_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/cbt_engine/data/datasources/cbt_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/cbt_engine/data/datasources/exam_template_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/ai_coach/data/datasources/ai_coach_remote_datasource.dart',
    '/home/z/my-project/examforge_ai/lib/features/marketplace/data/datasources/marketplace_remote_datasource.dart',
]

for f in datasource_files:
    if os.path.exists(f):
        try:
            changed = fix_datasource_file(f)
            print(f'{f}: changed={changed}')
        except Exception as e:
            print(f'{f}: ERROR - {e}')
    else:
        print(f'{f}: NOT FOUND')
