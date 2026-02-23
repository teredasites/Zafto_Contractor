"""
Wire t() title calls into dashboard pages that have useTranslation but no t() usage.
For each page:
1. Find the <h1> in the default export function (not sub-components)
2. Extract the hardcoded title text
3. Generate a translation key from the page path
4. Replace the hardcoded title with {t('section.title')}
5. Collect all new keys needed for en.json
"""
import re
import os
import json

base = os.path.join('src', 'app', 'dashboard')
new_keys = {}
modified = []
skipped = []

def path_to_key(filepath):
    """Convert file path to translation key prefix."""
    rel = filepath.replace(chr(92), '/').replace('src/app/dashboard/', '').replace('/page.tsx', '')
    parts = rel.split('/')
    parts = [p for p in parts if not p.startswith('[')]
    if not parts:
        return 'dashboard'
    result = parts[0]
    for p in parts[1:]:
        words = p.split('-')
        result += ''.join(w.capitalize() for w in words)
    words = result.split('-')
    result = words[0] + ''.join(w.capitalize() for w in words[1:])
    return result

for root, dirs, fnames in os.walk(base):
    for f in fnames:
        if f != 'page.tsx':
            continue
        fp = os.path.join(root, f).replace(chr(92), '/')

        with open(fp, 'r', encoding='utf-8') as fh:
            content = fh.read()

        if '{t(' in content:
            continue

        if 'useTranslation' not in content:
            continue

        export_match = re.search(r'export default function (\w+)', content)
        if not export_match:
            skipped.append(fp + ' (no default export)')
            continue

        export_start = export_match.start()

        func_starts = [(m.start(), m.group()) for m in re.finditer(r'(?:export default )?function \w+', content)]

        export_idx = next(i for i, (pos, _) in enumerate(func_starts) if pos == export_start)
        if export_idx + 1 < len(func_starts):
            export_end = func_starts[export_idx + 1][0]
        else:
            export_end = len(content)

        export_body = content[export_start:export_end]

        h1_pattern = re.compile(r'(<h1[^>]*>)\s*([^<{]+?)\s*(</h1>)')
        h1_matches = list(h1_pattern.finditer(export_body))

        if not h1_matches:
            h1_pattern = re.compile(r'(<h2[^>]*>)\s*([^<{]+?)\s*(</h2>)')
            h1_matches = list(h1_pattern.finditer(export_body))

        if not h1_matches:
            skipped.append(fp + ' (no h1/h2 with plain text)')
            continue

        m = h1_matches[0]
        title_text = m.group(2).strip()

        if not title_text or len(title_text) > 60:
            skipped.append(fp + ' (title too long or empty: "' + title_text[:40] + '")')
            continue

        key_prefix = path_to_key(fp)
        title_key = key_prefix + ".title"

        new_h1 = m.group(1) + "{t('" + title_key + "')}" + m.group(3)

        abs_start = export_start + m.start()
        abs_end = export_start + m.end()

        content = content[:abs_start] + new_h1 + content[abs_end:]

        with open(fp, 'w', encoding='utf-8') as fh:
            fh.write(content)

        new_keys[title_key] = title_text
        modified.append(fp)

print("Modified: " + str(len(modified)) + " files")
print("Skipped: " + str(len(skipped)) + " files")
for s in skipped[:30]:
    print("  SKIP: " + s)

if new_keys:
    with open('_new_title_keys.json', 'w', encoding='utf-8') as f:
        json.dump(new_keys, f, indent=2, ensure_ascii=False)
    print("\nNew keys written to _new_title_keys.json (" + str(len(new_keys)) + " keys)")
    for k, v in sorted(new_keys.items()):
        print("  " + k + ": " + v)
