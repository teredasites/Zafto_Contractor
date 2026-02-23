"""
Round 8 MEGA: Extract ALL remaining >Text</Tag> strings that don't have translation keys yet,
generate camelCase keys, add to en.json, then wire them into the pages.
"""
import json, os, re

TRANS_DIR = os.path.join('src', 'lib', 'translations')
DASHBOARD_DIR = os.path.join('src', 'app', 'dashboard')

with open(os.path.join(TRANS_DIR, 'en.json'), encoding='utf-8') as f:
    en = json.load(f)

# Flatten existing text values
existing_texts = set()
def flatten(d):
    for k, v in d.items():
        if isinstance(v, dict):
            flatten(v)
        elif isinstance(v, str):
            existing_texts.add(v)
flatten(en)

# Map page paths to namespace names
def path_to_namespace(rel_path):
    """Convert page path to translation namespace."""
    parts = rel_path.replace('/page.tsx', '').split('/')
    # Map common directory patterns
    mappings = {
        'settings': 'settings',
        'settings/phone': 'settingsPhone',
        'settings/import': 'settingsImport',
        'settings/tpa-programs': 'settingsTpa',
        'settings/walkthrough-workflows': 'settingsWorkflows',
        'estimates': 'estimates',
        'estimates/[id]': 'estimates',
        'estimates/import': 'estimatesImport',
        'estimates/pricing': 'estimatesPricing',
        'leads': 'leads',
        'jobs': 'jobs',
        'jobs/[id]': 'jobs',
        'jobs/new': 'jobs',
        'jobs/[id]/documentation': 'jobsDocs',
        'jobs/[id]/equipment': 'jobsEquipment',
        'jobs/[id]/moisture': 'jobsMoisture',
        'automations': 'automations',
        'books': 'books',
        'books/accounts': 'booksAccounts',
        'books/banking': 'booksBanking',
        'books/branches': 'booksBranches',
        'books/budgets': 'booksBudgets',
        'books/construction': 'booksConstruction',
        'books/cpa-export': 'booksCpa',
        'books/expenses': 'booksExpenses',
        'books/periods': 'booksPeriods',
        'books/reconciliation': 'booksRecon',
        'books/recurring': 'booksRecurring',
        'books/reports': 'booksReports',
        'books/tax-settings': 'booksTax',
        'books/vendor-payments': 'booksVendorPay',
        'books/vendors': 'booksVendors',
        'email': 'email',
        'inventory': 'inventory',
        'drying-logs': 'dryingLogs',
        'zdocs': 'zdocs',
        'growth': 'growth',
        'subcontractors': 'subcontractors',
        'tool-checkout': 'toolCheckout',
        'warranty-intelligence': 'warrantyIntel',
        'fire-restoration': 'fireRestoration',
        'moisture-readings': 'moistureReadings',
        'sketch-engine': 'sketchEngine',
        'service-agreements': 'serviceAgreements',
        'walkthroughs': 'walkthroughs',
        'walkthroughs/[id]': 'walkthroughs',
        'walkthroughs/[id]/bid': 'walkthroughsBid',
        'change-orders': 'changeOrders',
        'job-cost-radar': 'jobCostRadar',
        'job-intelligence': 'jobIntel',
        'job-intelligence/[jobId]': 'jobIntel',
        'job-intelligence/adjustments': 'jobIntelAdj',
        'scheduling': 'scheduling',
        'scheduling/[id]': 'scheduling',
        'scheduling/[id]/baselines': 'schedulingBaselines',
        'scheduling/[id]/resources': 'schedulingResources',
        'scheduling/portfolio': 'schedulingPortfolio',
        'marketplace': 'marketplace',
        'customers': 'customers',
        'customers/[id]': 'customers',
        'customers/new': 'customers',
        'reports': 'reports',
        'payroll': 'payroll',
        'phone/fax': 'phoneFax',
        'phone/sms': 'phoneSms',
        'properties': 'properties',
        'properties/[id]': 'properties',
        'properties/new': 'properties',
        'properties/assets': 'propertyAssets',
        'properties/inspections': 'propertyInspections',
        'properties/leases': 'propertyLeases',
        'properties/leases/[id]': 'propertyLeases',
        'properties/maintenance': 'propertyMaint',
        'properties/rent': 'propertyRent',
        'properties/tenants': 'propertyTenants',
        'properties/tenants/[id]': 'propertyTenants',
        'properties/turns': 'propertyTurns',
        'properties/units': 'propertyUnits',
        'properties/units/[id]': 'propertyUnits',
        'properties/[id]/equipment-insights': 'propertyEquipment',
        'inspections': 'inspections',
        'inspections/[id]': 'inspections',
        'inspections/templates': 'inspectionTemplates',
        'insurance': 'insurance',
        'insurance/[id]': 'insurance',
        'invoices': 'invoices',
        'invoices/[id]': 'invoices',
        'invoices/new': 'invoices',
        'bids': 'bids',
        'bids/[id]': 'bids',
        'bids/[id]/optimize': 'bidsOptimize',
        'bids/new': 'bids',
        'tpa': 'tpa',
        'tpa/assignments': 'tpaAssignments',
        'tpa/assignments/[id]': 'tpaAssignments',
        'tpa/scorecards': 'tpaScorecards',
        'warranties': 'warranties',
        'certifications': 'certifications',
        'communications': 'communications',
        'compliance': 'compliance',
        'compliance/ce-tracking': 'complianceCe',
        'compliance/packets': 'compliancePackets',
        'recon': 'recon',
        'recon/[id]': 'recon',
        'recon/area-scans': 'reconScans',
        'recon/area-scans/[id]': 'reconScans',
        'recon/area-scans/new': 'reconScans',
        'permits': 'permits',
        'permits/[jobId]': 'permits',
        'permits/jurisdictions': 'permitsJurisdictions',
        'lien-protection': 'lienProtection',
        'lien-protection/[jobId]': 'lienProtection',
        'lien-protection/rules': 'lienRules',
        'maintenance-pipeline': 'maintenancePipeline',
        'purchase-orders': 'purchaseOrders',
        'price-book': 'priceBook',
        'pricing-analytics': 'pricingAnalytics',
        'pricing-settings': 'pricingSettings',
        'reviews': 'reviews',
        'revenue-insights': 'revenueInsights',
        'site-surveys': 'siteSurveys',
        'vendors': 'vendors',
        'hiring': 'hiring',
        'osha-standards': 'osha',
        'inspection-engine': 'inspectionEngine',
        'keyboard-shortcuts': 'keyboardShortcuts',
        'legal-acknowledgment': 'legal',
        'meetings/async-videos': 'meetingsAsync',
        'meetings/booking-types': 'meetingsBooking',
        'meetings/room': 'meetingsRoom',
    }
    key = '/'.join(parts)
    return mappings.get(key, 'common')


def text_to_camel(text):
    """Convert English text to camelCase key."""
    # Remove special chars
    clean = re.sub(r'[^a-zA-Z0-9 ]', '', text)
    words = clean.split()
    if not words:
        return None
    # First word lowercase, rest title case
    result = words[0].lower()
    for w in words[1:]:
        result += w.capitalize()
    # Truncate very long keys
    if len(result) > 50:
        result = result[:50]
    return result


# Pattern to find hardcoded strings
pattern = re.compile(r'>([A-Z][a-zA-Z &/\x27#\$\.\-]+)</([a-zA-Z][a-zA-Z0-9]*)')

# Collect all needed new keys, organized by namespace
new_keys = {}  # namespace -> {camelKey: englishText}
# Track which texts to wire
all_texts_to_key = {}  # englishText -> full.key.path

for root, dirs, files in os.walk(DASHBOARD_DIR):
    for fname in files:
        if fname != 'page.tsx':
            continue
        filepath = os.path.join(root, fname)
        with open(filepath, encoding='utf-8') as f:
            content = f.read()
        if 'useTranslation' not in content:
            continue
        matches = pattern.findall(content)
        rel = os.path.relpath(filepath, DASHBOARD_DIR).replace(os.sep, '/')
        ns = path_to_namespace(rel)
        for text, tag in matches:
            text = text.strip()
            if text in existing_texts:
                continue
            if len(text) < 3 or len(text) > 80:
                continue
            camel = text_to_camel(text)
            if not camel:
                continue
            if ns not in new_keys:
                new_keys[ns] = {}
            new_keys[ns][camel] = text
            all_texts_to_key[text] = f"{ns}.{camel}"

# Add new keys to en.json
added = 0
for ns, keys in new_keys.items():
    if ns not in en:
        en[ns] = {}
    for k, v in keys.items():
        if k not in en[ns]:
            en[ns][k] = v
            added += 1

with open(os.path.join(TRANS_DIR, 'en.json'), 'w', encoding='utf-8') as f:
    json.dump(en, f, ensure_ascii=False, indent=2)
    f.write('\n')

print(f"Added {added} new keys across {len(new_keys)} namespaces")

# Now build replacement patterns and wire them
REPLACEMENTS = []
for text, key in all_texts_to_key.items():
    escaped = re.escape(text)
    p = re.compile(f'>({escaped})</([a-zA-Z][a-zA-Z0-9]*)')
    r = f">{{t('{key}')}}</\\2"
    REPLACEMENTS.append((p, r, text))

# Sort by text length descending
REPLACEMENTS.sort(key=lambda x: -len(x[2]))


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
        # Skip replacements inside string literals (JS template strings)
        for pat, rep, text in REPLACEMENTS:
            matches = pat.findall(body)
            if matches:
                actual_rep = rep.replace("t('", "tr('") if uses_tr else rep
                # Check each match isn't inside a string literal
                new_body = body
                for m in matches:
                    # Simple check: verify the match is in JSX context, not inside quotes
                    idx = new_body.find(f'>{m[0]}</')
                    if idx >= 0:
                        # Check if this position is likely inside a string literal
                        # by counting unmatched quotes before it
                        before = new_body[:idx]
                        single_q = before.count("'") - before.count("\\'")
                        double_q = before.count('"') - before.count('\\"')
                        backtick = before.count('`')
                        # If we're inside a string (odd count), skip
                        in_string = (single_q % 2 == 1) or (double_q % 2 == 1) or (backtick % 2 == 1)
                        if in_string:
                            continue
                new_body = pat.sub(actual_rep, new_body)
                if new_body != body:
                    body = new_body
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

print(f"\nWired {grand_total} strings across {len(modified)} files")
for f, c in sorted(modified, key=lambda x: -x[1]):
    print(f"  {c:3d}  {f}")
