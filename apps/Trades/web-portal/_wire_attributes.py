"""
Wire attribute-based strings: label="Text", placeholder="Text", title="Text".
Replaces them with label={t('key')} etc.
Only replaces within functions that have useTranslation().
"""
import json, os, re

TRANS_DIR = os.path.join('src', 'lib', 'translations')
DASHBOARD_DIR = os.path.join('src', 'app', 'dashboard')

with open(os.path.join(TRANS_DIR, 'en.json'), encoding='utf-8') as f:
    en = json.load(f)

# Build reverse map: English text -> key path
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

# Build attribute replacements for text that has existing keys
# Patterns: label="Text" -> label={t('key')}
#           placeholder="Text" -> placeholder={t('key')}
#           title="Text" -> title={t('key')}
ATTR_REPLACEMENTS = []
for text, key in text_to_key.items():
    if len(text) < 2 or len(text) > 80:
        continue
    escaped = re.escape(text)
    for attr in ['label', 'placeholder', 'title']:
        pattern = re.compile(f'{attr}="({escaped})"')
        replacement = f"{attr}={{t('{key}')}}"
        ATTR_REPLACEMENTS.append((pattern, replacement))

# Sort by text length (longest first) to avoid partial matches
ATTR_REPLACEMENTS.sort(key=lambda x: -len(x[0].pattern))


def find_all_translation_scopes(content):
    lines = content.split('\n')
    scopes = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        is_func = (
            stripped.startswith('export default function') or
            stripped.startswith('export function') or
            re.match(r'^function\s+[A-Z]', stripped)
        )
        if is_func:
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
            if has_hook:
                uses_tr = 'const { t: tr }' in body
                scopes.append({
                    'start': i,
                    'end': func_end,
                    'uses_tr': uses_tr,
                })
            i = func_end + 1
            continue
        i += 1
    return scopes


def process_file(filepath):
    with open(filepath, encoding='utf-8') as f:
        content = f.read()
    if 'useTranslation' not in content:
        return 0
    scopes = find_all_translation_scopes(content)
    if not scopes:
        return 0
    lines = content.split('\n')
    total_changes = 0
    for scope in sorted(scopes, key=lambda s: -s['start']):
        start = scope['start']
        end = scope['end']
        uses_tr = scope['uses_tr']
        body = '\n'.join(lines[start:end + 1])
        changes = 0
        for pattern, replacement in ATTR_REPLACEMENTS:
            matches = pattern.findall(body)
            if matches:
                actual_rep = replacement.replace("t('", "tr('") if uses_tr else replacement
                body = pattern.sub(actual_rep, body)
                changes += len(matches)
        if changes > 0:
            new_lines = body.split('\n')
            lines[start:end + 1] = new_lines
            total_changes += changes
    if total_changes > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines))
    return total_changes


grand_total = 0
modified = []
for root, dirs, files in os.walk(DASHBOARD_DIR):
    for fname in files:
        if fname != 'page.tsx':
            continue
        filepath = os.path.join(root, fname)
        changes = process_file(filepath)
        if changes > 0:
            rel = os.path.relpath(filepath, DASHBOARD_DIR).replace(os.sep, '/')
            modified.append((rel, changes))
            grand_total += changes

print(f"Modified {len(modified)} files with {grand_total} total attribute replacements")
for f, c in sorted(modified, key=lambda x: -x[1]):
    print(f"  {c:3d}  {f}")
