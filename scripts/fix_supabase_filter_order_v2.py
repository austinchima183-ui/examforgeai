#!/usr/bin/env python3
"""
Fix Supabase Postgrest query chain: ensure filters (.eq/.gte/.lte) 
are applied BEFORE transforms (.order/.range/.limit).

Strategy: For each code block in a datasource file:
1. Find query init lines: `var query = _supabase.from(X).select()...`
2. Find all subsequent `query = query.FILTER()` or `query = query.TRANSFORM()` calls
3. Restructure so all filter calls happen first (on PostgrestFilterBuilder)
   then transform calls happen (on PostgrestTransformBuilder)

This handles both patterns:
  P1: Init with .order() inline → split into filter init + order on new variable
  P2: Init with .select() only → retype query → use filterQuery + transformQuery  
"""

import re
import sys

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    original = content
    lines = content.split('\n')
    
    # Find blocks starting with `var query = _supabase.from(X).select()...`
    # that have filter/transform issues.
    
    # Strategy: Replace `var query` with `var filterQuery` for the init,
    # replace `query = query.FILTER` with `filterQuery = filterQuery.FILTER`,
    # then find where transforms begin and insert a `var transformQuery = filterQuery.ORDER/RANGE/LIMIT`
    # and replace `query = query.TRANSFORM` with `transformQuery = transformQuery.TRANSFORM`,
    # replace `await query` with `await transformQuery`.
    
    filter_methods = ['eq', 'neq', 'gt', 'gte', 'lt', 'lte', 'inFilter', 'in', 
                      'like', 'ilike', 'contains', 'containedBy', 'overlaps',
                      'startsWith', 'endsWith', 'match', 'is']
    transform_methods = ['order', 'range', 'limit', 'offset']
    
    i = 0
    blocks_fixed = 0
    
    while i < len(lines):
        # Look for query init on this line or multi-line init
        if 'var query = _supabase' in lines[i]:
            # This is a query init. Find the complete init (may span multiple lines)
            init_start = i
            init_end = i
            
            # Check if init spans multiple lines (ends with ; on same or later line)
            init_text = lines[i]
            j = i
            while ';' not in init_text and j < len(lines) - 1:
                j += 1
                init_text += ' ' + lines[j].strip()
                init_end = j
            
            # Now we have the complete init text
            # Determine if .order() is in the init (needs splitting)
            # or if the init is just .select() (clean start)
            
            has_order_in_init = '.order(' in init_text
            
            # Find the block end (where await query or similar occurs)
            block_end = init_end
            for k in range(init_end + 1, min(init_end + 80, len(lines))):
                if 'await query' in lines[k] and 'query.' not in lines[k]:
                    block_end = k
                    break
                # Also check for `final response = await query;`
                if re.search(r'await\s+query\s*;', lines[k]):
                    block_end = k
                    break
            
            # Collect all lines in the block
            block = lines[init_start:block_end+1]
            
            # Determine if this block needs fixing
            # It needs fixing if filter calls appear after transform calls
            needs_fix = False
            
            first_transform_line = None
            for k, line in enumerate(block):
                for tm in transform_methods:
                    if f'query = query.{tm}(' in line or f'query.{tm}(' in line:
                        if first_transform_line is None:
                            first_transform_line = k
                # Also check for inline .order().range() pattern
                if '.order(' in line and '.range(' in line:
                    if first_transform_line is None:
                        first_transform_line = k
                if '.order(' in line and '.limit(' in line:
                    if first_transform_line is None:
                        first_transform_line = k
            
            if first_transform_line is not None:
                # Check if there are filter calls AFTER the first transform
                for k in range(first_transform_line + 1, len(block)):
                    for fm in filter_methods:
                        if f'query = query.{fm}(' in block[k]:
                            needs_fix = True
                            break
            
            # Also needs fix if .order() is in init line (causing type mismatch)
            if has_order_in_init:
                needs_fix = True
            
            # Also needs fix if query = query.order().range() pattern exists
            # (assigning TransformBuilder to FilterBuilder-typed var)
            for line in block:
                if 'query = query.order(' in line and ('.range(' in line or '.limit(' in line):
                    needs_fix = True
            
            if not needs_fix:
                i = block_end + 1
                continue
            
            # Fix the block
            new_block = []
            
            # Handle init line
            if has_order_in_init:
                # Split init: filter part stays, order part moves to separate line
                # Find where .order() starts in the init
                # The init might be: var query = _supabase.from(X).select().eq(...).order(...)
                # or: var query = _supabase.from(X).select().order(...)
                
                # First, normalize the init text (remove line breaks)
                normalized_init = ' '.join(l.strip() for l in block[:init_end - init_start + 1])
                
                # Find .order() position
                order_pos = normalized_init.find('.order(')
                if order_pos == -1:
                    # No .order in init but still needs fix - skip
                    i = block_end + 1
                    continue
                
                filter_part = normalized_init[:order_pos].replace('var query = ', 'var filterQuery = ')
                transform_part = normalized_init[order_pos:]
                
                new_init_line = f'{re.match(r"^(\s*)", block[0]).group(1)}{filter_part};'
                new_order_line = f'{re.match(r"^(\s*)", block[0]).group(1)}var transformQuery = filterQuery{transform_part}'
                
                # Replace remaining init lines (multi-line) with just the new_init_line
                new_block.append(new_init_line)
                
                # Process remaining lines (after init)
                remaining_start = init_end - init_start + 1
                for k in range(remaining_start, len(block)):
                    line = block[k]
                    
                    # Replace filter calls
                    is_filter = False
                    for fm in filter_methods:
                        if f'query = query.{fm}(' in line:
                            line = line.replace('query = query.', 'filterQuery = filterQuery.')
                            is_filter = True
                            break
                    
                    # Handle if blocks containing filter calls
                    if 'if (filters.containsKey' in line or 'if (params.containsKey' in line:
                        # Check if block contains filter calls
                        block_content = line
                        # Find the complete if block
                        brace_depth = 0
                        block_lines_idx = []
                        for bl in range(k, len(block)):
                            brace_depth += block[bl].count('{') - block[bl].count('}')
                            block_lines_idx.append(bl)
                            if brace_depth <= 0:
                                break
                        
                        # Check if any inner line has filter call
                        has_filter_in_block = False
                        for bli in block_lines_idx:
                            for fm in filter_methods:
                                if f'query = query.{fm}(' in block[bli]:
                                    has_filter_in_block = True
                                    break
                        
                        if has_filter_in_block:
                            line = line.replace('query = query.', 'filterQuery = filterQuery.')
                    
                    # Replace transform calls
                    for tm in transform_methods:
                        if f'query = query.{tm}(' in line:
                            line = line.replace('query = query.', 'transformQuery = transformQuery.')
                            break
                    
                    # Handle query.order().range() and query.order().limit() patterns
                    if 'query = query.order(' in line and ('.range(' in line or '.limit(' in line):
                        line = line.replace('query = query.order(', 'transformQuery = filterQuery.order(')
                    
                    # Replace await query
                    if 'await query' in line and 'query.' not in line:
                        line = line.replace('await query', 'await transformQuery')
                    
                    new_block.append(line)
                
                # Insert order line after all filter calls
                # Find where to insert (after last filter call)
                last_filter_idx = 0
                for k in range(1, len(new_block)):
                    if 'filterQuery = filterQuery.' in new_block[k]:
                        last_filter_idx = k
                    if 'if (filters.containsKey' in new_block[k] or 'if (params.containsKey' in new_block[k]:
                        if 'filterQuery = filterQuery.' in new_block[k] or '{' in new_block[k]:
                            last_filter_idx = k
                
                new_block.insert(last_filter_idx + 1, new_order_line)
                
            else:
                # Init is just .select() - no order in init
                # Just rename query -> filterQuery for filter calls,
                # and introduce transformQuery for transform calls
                
                # Rename init
                new_block.append(block[0].replace('var query = ', 'var filterQuery = '))
                
                # Process remaining lines
                last_filter_idx = 0
                for k in range(1, len(block)):
                    line = block[k]
                    
                    # Check if this is a transform call
                    is_transform = False
                    for tm in transform_methods:
                        if f'query = query.{tm}(' in line:
                            line = line.replace('query = query.', 'transformQuery = transformQuery.')
                            is_transform = True
                            break
                    
                    # Handle query.order().range() or .order().limit() pattern
                    if 'query = query.order(' in line and ('.range(' in line or '.limit(' in line):
                        # Split into: transformQuery = filterQuery.order().range()
                        line = line.replace('query = query.order(', 'transformQuery = filterQuery.order(')
                        is_transform = True
                    
                    if not is_transform:
                        # Replace filter calls
                        for fm in filter_methods:
                            if f'query = query.{fm}(' in line:
                                line = line.replace('query = query.', 'filterQuery = filterQuery.')
                                last_filter_idx = k
                                break
                        
                        # Handle if blocks
                        if ('if (filters.containsKey' in line or 'if (params.containsKey' in line):
                            # Check inner lines for filter calls
                            if 'query = query.' in line:
                                for fm in filter_methods:
                                    if f'query = query.{fm}(' in line:
                                        line = line.replace('query = query.', 'filterQuery = filterQuery.')
                                        last_filter_idx = k
                                        break
                    
                    # Replace await query
                    if 'await query' in line and 'query.' not in line:
                        line = line.replace('await query', 'await transformQuery')
                    
                    new_block.append(line)
                
                # If no transform line was introduced yet, add one at the transition point
                has_transform_var = any('transformQuery = ' in l for l in new_block)
                if not has_transform_var:
                    # Need to add: var transformQuery = filterQuery.order(...)
                    # This shouldn't happen in practice but handle it
                    pass
            
            # Replace block in lines
            lines[init_start:block_end+1] = new_block
            blocks_fixed += 1
            i = init_start + len(new_block)
            continue
        
        i += 1
    
    new_content = '\n'.join(lines)
    if new_content != original:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True, blocks_fixed
    return False, 0

if __name__ == '__main__':
    filepath = sys.argv[1]
    changed, count = fix_file(filepath)
    print(f"Changed: {changed}, Blocks fixed: {count}")
