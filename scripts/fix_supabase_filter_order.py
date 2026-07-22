#!/usr/bin/env python3
"""
Fix Supabase Postgrest query chain pattern in Dart datasource files.

Root cause: In supabase_flutter v2.15+, .select() returns PostgrestFilterBuilder.
  .order(), .range(), .limit() return PostgrestTransformBuilder.
  PostgrestTransformBuilder does NOT have .eq(), .gte(), .lte() etc.
  Filters must be applied BEFORE transforms.

This script finds and restructures code blocks in datasource files where
filter methods (.eq, .gte, .lte, etc.) are called AFTER transform methods (.order, .limit, .range).

Strategy: For each method block that has this pattern:
  var query = _supabase.from(X).select().order(...)
  ... conditional filter calls: query = query.eq/gte/lte(...)
  ... transform calls: query = query.range/limit(...)
  ... final: await query

Becomes:
  var filterQuery = _supabase.from(X).select()
  ... conditional filter calls: filterQuery = filterQuery.eq/gte/lte(...)
  var transformQuery = filterQuery.order(...)
  ... transform calls: transformQuery = transformQuery.range/limit(...)
  ... final: await transformQuery
"""

import sys
import re

FILTER_METHODS = ['eq', 'neq', 'gt', 'gte', 'lt', 'lte', 'inFilter', 'in', 'like', 'ilike', 'contains', 'containedBy', 'overlaps', 'startsWith', 'endsWith', 'match']
TRANSFORM_METHODS = ['order', 'range', 'limit', 'offset']

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    lines = content.split('\n')
    new_content = content
    
    # Find all query initialization lines that include .order() before filters
    # Pattern: var query = _supabase.from(X).select()[.eq(...)].order(...)
    
    # We need to process blocks. A block is:
    # 1. Init line with .order() 
    # 2. Filter lines (.eq, .gte, .lte) - either inside if blocks or standalone
    # 3. Transform lines (.range, .limit)
    # 4. Final line: await query
    
    # Simple approach: find init lines with .order(), extract the select+initial-filters part
    # and the order+transforms part, then reconstruct.
    
    i = 0
    blocks_fixed = 0
    while i < len(lines):
        line = lines[i]
        
        # Detect init line: var query = _supabase.from(X).select()... .order(...)
        if 'var query = _supabase' in line and '.select()' in line:
            # Check if .order() appears on this line (transform before filters)
            if '.order(' in line:
                # This block needs restructuring
                indent = re.match(r'^(\s*)', line).group(1)
                
                # Split the init line at the first .order()
                # Keep everything before .order() as the filter part
                # Keep .order() onwards as the transform part
                order_pos = line.find('.order(')
                
                filter_init = line[:order_pos].replace('var query = ', 'var filterQuery = ')
                # Remove trailing ; if present on filter_init (it was on the full line)
                filter_init = filter_init.rstrip(';')
                
                transform_part = line[order_pos:]
                # Remove 'var query = ' prefix from the start of the original line
                # transform_part starts with .order(... which we chain on filterQuery
                
                # Build the new lines
                new_init = f'{indent}{filter_init};'
                new_order = f'{indent}var transformQuery = filterQuery{transform_part}'
                
                # Now scan subsequent lines for filter and transform calls
                j = i + 1
                filter_lines = []
                transform_lines = []
                final_lines = []
                
                while j < len(lines):
                    next_line = lines[j]
                    
                    # Check if this is a filter call on query
                    if any(f'query = query.{m}(' in next_line for m in FILTER_METHODS):
                        filter_lines.append(next_line.replace('query = query.', 'filterQuery = filterQuery.'))
                        j += 1
                        continue
                    
                    # Check if this is an if block with a filter call inside
                    if 'if (filters.containsKey' in next_line:
                        # Look for the closing brace and inner filter call
                        # Could be:
                        #   if (filters.containsKey('X')) {
                        #     query = query.eq(...);
                        #   }
                        # Or single-line: if (filters.containsKey('X')) { query = query.eq(...); }
                        block_start = j
                        # Find closing brace
                        brace_count = 0
                        for k in range(j, min(j+10, len(lines))):
                            brace_count += lines[k].count('{') - lines[k].count('}')
                            if brace_count == 0:
                                block_end = k
                                break
                        
                        # Replace query -> filterQuery in the if block
                        block = lines[j:block_end+1]
                        replaced_block = [l.replace('query = query.', 'filterQuery = filterQuery.') for l in block]
                        filter_lines.extend(replaced_block)
                        j = block_end + 1
                        continue
                    
                    # Check if this is a transform call on query
                    if any(f'query = query.{m}(' in next_line for m in TRANSFORM_METHODS):
                        transform_lines.append(next_line.replace('query = query.', 'transformQuery = transformQuery.'))
                        j += 1
                        continue
                    
                    # Check if this is the final await query line
                    if 'await query' in next_line and not 'query.' in next_line:
                        final_lines.append(next_line.replace('await query', 'await transformQuery'))
                        j += 1
                        continue
                    
                    # Any other line - stop processing this block
                    break
                
                # Now reconstruct the block
                new_block = [new_init]
                new_block.extend(filter_lines)
                new_block.append(new_order)
                new_block.extend(transform_lines)
                new_block.extend(final_lines)
                
                # Replace in lines array
                # We need to replace lines[i:j] with new_block
                end_idx = j
                lines[i:end_idx] = new_block
                blocks_fixed += 1
                
                i += len(new_block)
                continue
        
        i += 1
    
    new_content = '\n'.join(lines)
    
    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        return True, blocks_fixed
    return False, 0

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python fix_supabase_filter_order.py <filepath>")
        sys.exit(1)
    
    filepath = sys.argv[1]
    changed, count = fix_file(filepath)
    print(f"File: {filepath}, Changed: {changed}, Blocks fixed: {count}")
