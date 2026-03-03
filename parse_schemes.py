import csv, re, os, sys

CSV_PATH = r"c:\CIVIC VOICE AI FOR BHARAT\civic_voice\updated_data.csv"
OUT_PATH  = r"c:\CIVIC VOICE AI FOR BHARAT\civic_voice\lib\data\mock\services_data.dart"

CATEGORY_MAP = {
    'Agriculture': 'agriculture',
    'Banking': 'finance',
    'Business': 'business',
    'Education': 'education',
    'Health': 'health',
    'Housing': 'welfare',
    'Science': 'business',
    'Skills': 'employment',
    'Social welfare': 'welfare',
    'Transport': 'transport',
    'Travel': 'business',
    'Women': 'welfare',
    'Utility': 'welfare',
    'Legal': 'identity',
}

EMOJI_MAP = {
    'agriculture': '🌾',
    'finance':     '💰',
    'business':    '🏢',
    'education':   '📚',
    'health':      '🏥',
    'welfare':     '🤝',
    'transport':   '🚗',
    'employment':  '💼',
    'identity':    '🪪',
    'property':    '🏠',
}

def slugify(name):
    s = re.sub(r'[^a-z0-9]+', '_', name.lower().strip())
    return s[:50].strip('_')

def esc(s):
    if not s:
        return ''
    s = str(s)
    s = s.replace('\\', '\\\\').replace("'", "\\'")
    s = s.replace('\r\n', ' ').replace('\n', ' ').replace('\r', ' ')
    s = re.sub(r' {2,}', ' ', s)
    return s.strip()

CATEGORY_QUOTAS = {
    'welfare':     20,
    'education':   14,
    'business':    14,
    'agriculture': 14,
    'health':      10,
    'employment':  10,
    'finance':      8,
    'identity':     4,
    'transport':    4,
}

category_counts = {}
selected = []
seen = set()

with open(CSV_PATH, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    for row in reader:
        name = (row.get('scheme_name') or '').strip().strip('"')
        if not name or name in seen:
            continue
        raw_cat = (row.get('schemeCategory') or row.get('schemeCategory ') or '').strip().strip('"')
        cat = 'welfare'
        for k, v in CATEGORY_MAP.items():
            if k.lower() in raw_cat.lower():
                cat = v
                break
        quota = CATEGORY_QUOTAS.get(cat, 4)
        if category_counts.get(cat, 0) >= quota:
            continue
        details = row.get('details') or ''
        eligibility = row.get('eligibility') or ''
        if len(details) < 40 or len(eligibility) < 15:
            continue
        seen.add(name)
        selected.append((cat, row))
        category_counts[cat] = category_counts.get(cat, 0) + 1
        if sum(category_counts.values()) >= 90:
            break

dart_services = []
all_vars = []

for idx, (cat, row) in enumerate(selected):
    name_en = esc(row.get('scheme_name', ''))[:100]
    if not name_en:
        continue

    sid = slugify(row.get('scheme_name', ''))
    var = f"s{idx:04d}"
    emoji = EMOJI_MAP.get(cat, '📋')

    details  = esc(row.get('details', ''))[:400]
    benefits = esc(row.get('benefits', ''))[:200]
    desc = (details + (' Benefits: ' + benefits if benefits else ''))[:500]

    elig_raw = esc(row.get('eligibility', ''))
    elig_parts = re.split(r'(?<=[.!?]) +(?=[A-Z])', elig_raw)
    elig_parts = [p.strip() for p in elig_parts if len(p.strip()) > 10][:4]
    if not elig_parts:
        elig_parts = [elig_raw[:200]]

    docs_raw = esc(row.get('documents', ''))
    docs_parts = re.split(r'(?<=[a-z])\. +(?=[A-Z])|(?<=[a-z])\n(?=[A-Z])', docs_raw)
    docs_parts = [p.strip().rstrip('.') for p in docs_parts if 5 < len(p.strip()) < 110][:5]
    if not docs_parts:
        docs_parts = ['Aadhaar Card', 'Proof of Identity', 'Bank Account Details']

    app_raw = esc(row.get('application', ''))
    step_matches = re.findall(r'Step\s*\d+[:.]\s*([^.]{15,200}?\.)', app_raw, re.IGNORECASE)
    if not step_matches:
        step_matches = ['Visit the official government portal and register.', 
                        'Fill the application form with required details.',
                        'Submit with documents and await verification.']
    step_matches = step_matches[:4]

    popular = 'true' if any(k in name_en.lower() for k in ['pm kisan','ayushman','mudra','scholarship','atal pension','bpl','mnrega']) else 'false'

    lines = [f"  static const ServiceModel {var} = ServiceModel("]
    lines.append(f"    id: '{sid[:60]}',")
    lines.append(f"    iconEmoji: '{emoji}',")
    lines.append(f"    category: ServiceCategory.{cat},")
    lines.append(f"    isPopular: {popular},")
    lines.append(f"    name: {{'en': '{name_en}'}},")
    lines.append(f"    description: {{'en': '{desc[:490]}'}},")
    lines.append(f"    eligibilityCriteria: [")
    for e in elig_parts:
        lines.append(f"      '{e[:199]}',")
    lines.append(f"    ],")
    lines.append(f"    requiredDocuments: [")
    for d in docs_parts:
        dn = d[:99].replace("'", "\\'")
        lines.append(f"      DocumentItem(name: '{dn}', description: ''),")
    lines.append(f"    ],")
    lines.append(f"    steps: [")
    for si, st in enumerate(step_matches):
        st_esc = st[:199].replace("'", "\\'")
        lines.append(f"      StepItem(number: {si+1}, title: 'Step {si+1}', description: '{st_esc}'),")
    lines.append(f"    ],")
    lines.append(f"    estimatedTimeline: '15-30 working days',")
    lines.append(f"    fees: 'Free / As applicable',")
    lines.append(f"    officialLink: 'https://www.india.gov.in',")
    lines.append(f"    helplineNumber: '1800-11-1555',")
    lines.append(f"  );")

    all_vars.append(var)
    dart_services.append('\n'.join(lines))

getters = '\n'.join(f'        {v},' for v in all_vars)
defs = '\n\n'.join(dart_services)

output = f"""import '../../models/service_model.dart';

/// Government schemes from updated_data.csv — {len(all_vars)} real schemes.
class MockServicesData {{
  MockServicesData._();

  static List<ServiceModel> get all => [
{getters}
  ];

{defs}
}}
"""

with open(OUT_PATH, 'w', encoding='utf-8') as f:
    f.write(output)

print(f"Generated {len(all_vars)} services.")
for k, v in sorted(category_counts.items()):
    print(f"  {k}: {v}")
