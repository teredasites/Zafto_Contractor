"""
Inject useTranslation() hooks into functions that have hardcoded strings but no hook,
then wire the strings. Also handles functions that already have the hook but have
remaining unwired strings (e.g. from string-literal false positives in previous rounds).
"""
import json, os, re

TRANS_DIR = os.path.join('src', 'lib', 'translations')
DASHBOARD_DIR = os.path.join('src', 'app', 'dashboard')

with open(os.path.join(TRANS_DIR, 'en.json'), encoding='utf-8') as f:
    en = json.load(f)

# Flatten to get all existing text->key mappings
text_to_key = {}
def flatten(d, prefix=''):
    for k, v in d.items():
        path = f'{prefix}{k}' if prefix else k
        if isinstance(v, dict):
            flatten(v, path + '.')
        else:
            if isinstance(v, str):
                text_to_key[v] = path
flatten(en)

# Pattern: >Text</Tag — hardcoded strings in JSX
STRING_PATTERN = re.compile(r'>([A-Z][a-zA-Z &/\x27#\$\.\-]+)</([a-zA-Z][a-zA-Z0-9]*)')

def text_to_camel(text):
    clean = re.sub(r'[^a-zA-Z0-9 ]', '', text)
    words = clean.split()
    if not words:
        return None
    result = words[0].lower()
    for w in words[1:]:
        result += w.capitalize()
    if len(result) > 50:
        result = result[:50]
    return result

def path_to_namespace(rel_path):
    parts = rel_path.replace('/page.tsx', '').replace('\\page.tsx', '').split('/')
    key = '/'.join(parts)
    # First part is usually enough, with special cases
    mappings = {
        'settings': 'settings',
        'settings/phone': 'settingsPhone',
        'settings/import': 'settingsImport',
        'settings/tpa-programs': 'settingsTpa',
        'settings/walkthrough-workflows': 'settingsWorkflows',
    }
    if key in mappings:
        return mappings[key]
    # Default: use first directory
    first = parts[0] if parts else 'common'
    # Convert kebab-case to camelCase
    words = first.split('-')
    result = words[0]
    for w in words[1:]:
        result += w.capitalize()
    return result


def find_all_functions(content):
    """Find ALL function declarations (not just those with useTranslation)."""
    lines = content.split('\n')
    functions = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        is_func = (
            stripped.startswith('export default function') or
            stripped.startswith('export function') or
            re.match(r'^function\s+[A-Z]', stripped)
        )
        if is_func:
            func_name_match = re.search(r'function\s+(\w+)', stripped)
            func_name = func_name_match.group(1) if func_name_match else 'Unknown'
            paren_count = 0
            found_paren = False
            brace_count = 0
            body_started = False
            func_end = i
            for j in range(i, len(lines)):
                for ch in lines[j]:
                    if not found_paren:
                        if ch == '(':
                            paren_count += 1
                            found_paren = True
                    elif paren_count > 0:
                        if ch == '(':
                            paren_count += 1
                        elif ch == ')':
                            paren_count -= 1
                    else:
                        if ch == '{':
                            brace_count += 1
                            body_started = True
                        elif ch == '}':
                            brace_count -= 1
                            if body_started and brace_count == 0:
                                func_end = j
                                break
                if body_started and brace_count == 0:
                    break
            body = '\n'.join(lines[i:func_end + 1])
            has_hook = bool(re.search(r'const\s+\{.*\}\s*=\s*useTranslation\(\)', body))
            uses_tr = 'const { t: tr }' in body
            # Check if there's a t variable conflict
            has_t_conflict = bool(re.search(r'\.\w+\(\s*t\s*=>', body)) or bool(re.search(r'\.\w+\(\s*\(\s*t\s*[\),]', body))
            functions.append({
                'name': func_name,
                'start': i,
                'end': func_end,
                'has_hook': has_hook,
                'uses_tr': uses_tr,
                'has_t_conflict': has_t_conflict,
            })
            i = func_end + 1
            continue
        i += 1
    return functions


def process_file(filepath, rel_path):
    with open(filepath, encoding='utf-8') as f:
        content = f.read()

    # Must have at least useTranslation imported
    has_import = 'useTranslation' in content
    functions = find_all_functions(content)
    if not functions:
        return 0

    ns = path_to_namespace(rel_path)
    lines = content.split('\n')
    total_changes = 0
    hooks_added = 0

    # Process in reverse order to preserve line numbers
    for func in sorted(functions, key=lambda f: -f['start']):
        start = func['start']
        end = func['end']
        body = '\n'.join(lines[start:end + 1])

        # Find hardcoded strings in this function
        matches = STRING_PATTERN.findall(body)
        hardcoded = []
        for text, tag in matches:
            text = text.strip()
            if len(text) < 3 or len(text) > 80:
                continue
            hardcoded.append(text)

        if not hardcoded:
            continue

        # If function doesn't have useTranslation hook, inject it
        if not func['has_hook']:
            if not has_import:
                continue  # Can't add hook if useTranslation not imported
            # Find the opening brace of the function body
            body_lines = body.split('\n')
            # Find the line with the opening brace
            brace_line = -1
            paren_count = 0
            found_paren = False
            for li, line in enumerate(body_lines):
                for ch in line:
                    if not found_paren:
                        if ch == '(':
                            paren_count += 1
                            found_paren = True
                    elif paren_count > 0:
                        if ch == '(':
                            paren_count += 1
                        elif ch == ')':
                            paren_count -= 1
                    else:
                        if ch == '{':
                            brace_line = li
                            break
                if brace_line >= 0:
                    break
            if brace_line >= 0:
                # Determine if there's a t conflict
                has_t_conflict = func['has_t_conflict']
                if has_t_conflict:
                    hook_line = "  const { t: tr } = useTranslation();"
                    func['uses_tr'] = True
                else:
                    hook_line = "  const { t } = useTranslation();"
                # Insert after the opening brace line
                body_lines.insert(brace_line + 1, hook_line)
                body = '\n'.join(body_lines)
                func['has_hook'] = True
                hooks_added += 1

        if not func['has_hook']:
            continue

        uses_tr = func['uses_tr']
        changes = 0

        for text in hardcoded:
            # Get or create translation key
            if text in text_to_key:
                key = text_to_key[text]
            else:
                camel = text_to_camel(text)
                if not camel:
                    continue
                key = f"{ns}.{camel}"
                # Add to en.json
                parts = key.split('.')
                d = en
                for p in parts[:-1]:
                    if p not in d:
                        d[p] = {}
                    d = d[p]
                if parts[-1] not in d:
                    d[parts[-1]] = text
                text_to_key[text] = key

            escaped = re.escape(text)
            pattern = re.compile(f'>({escaped})</([a-zA-Z][a-zA-Z0-9]*)')
            t_func = "tr" if uses_tr else "t"
            replacement = f">{{{t_func}('{key}')}}</\\2"

            # Check we're not replacing inside a string literal
            new_body = pattern.sub(replacement, body)
            if new_body != body:
                body = new_body
                changes += 1

        if changes > 0:
            new_lines = body.split('\n')
            lines[start:end + 1] = new_lines
            total_changes += changes

    if total_changes > 0 or hooks_added > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))

    return total_changes


# Save en.json at the end
grand_total = 0
modified = []
hooks_total = 0

for root, dirs, files in os.walk(DASHBOARD_DIR):
    for fname in files:
        if fname != 'page.tsx':
            continue
        filepath = os.path.join(root, fname)
        rel = os.path.relpath(filepath, DASHBOARD_DIR).replace(os.sep, '/')
        changes = process_file(filepath, rel)
        if changes > 0:
            modified.append((rel, changes))
            grand_total += changes

# Save updated en.json
with open(os.path.join(TRANS_DIR, 'en.json'), 'w', encoding='utf-8') as f:
    json.dump(en, f, ensure_ascii=False, indent=2)
    f.write('\n')

print(f"Wired {grand_total} strings across {len(modified)} files")
for f, c in sorted(modified, key=lambda x: -x[1]):
    print(f"  {c:3d}  {f}")
