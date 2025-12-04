#!/bin/bash
# Debug why findings are not showing in DefectDojo

DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

echo "🔍 Debugging DefectDojo Findings"
echo "================================"
echo ""

# Step 1: Check recent tests
echo "Step 1: Recent Tests in Bandit-Scan Engagement"
echo "-----------------------------------------------"
curl -s "${DD_URL}/api/v2/tests/?limit=20" \
  -H "Authorization: Token ${DD_TOKEN}" | \
  python3 -c "
import json, sys
from datetime import datetime

data = json.load(sys.stdin)
tests = data.get('results', [])

# Filter for recent tests
print('Recent tests (last 10):')
for t in tests[:10]:
    eng = t.get('engagement', 'N/A')
    print(f'  Test ID: {t[\"id\"]:3} | Type: {t.get(\"test_type_name\", \"N/A\"):25} | Engagement: {eng} | Findings: {t.get(\"finding_count\", 0)}')
"

echo ""
echo ""

# Step 2: Check findings for latest test
echo "Step 2: Check Findings in Latest Tests"
echo "---------------------------------------"
LATEST_TEST=$(curl -s "${DD_URL}/api/v2/tests/?limit=1" \
  -H "Authorization: Token ${DD_TOKEN}" | \
  python3 -c "import json,sys; data=json.load(sys.stdin); print(data['results'][0]['id'] if data.get('results') else '')")

if [ ! -z "$LATEST_TEST" ]; then
    echo "Latest test ID: $LATEST_TEST"
    echo ""

    curl -s "${DD_URL}/api/v2/findings/?test=${LATEST_TEST}&limit=5" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "
import json, sys
data = json.load(sys.stdin)
findings = data.get('results', [])

print(f'Findings in test {$LATEST_TEST}: {data.get(\"count\", 0)}')
print()

if findings:
    for f in findings[:5]:
        print(f'  - {f.get(\"title\", \"N/A\")[:60]}')
        print(f'    Severity: {f.get(\"severity\", \"N/A\")} | Active: {f.get(\"active\", False)}')
        print()
else:
    print('  No findings found')
"
fi

echo ""
echo ""

# Step 3: Check all findings in Bandit-Scan engagement
echo "Step 3: All Findings (All Statuses)"
echo "------------------------------------"
curl -s "${DD_URL}/api/v2/findings/?engagement__name=Bandit-Scan" \
  -H "Authorization: Token ${DD_TOKEN}" | \
  python3 -c "
import json, sys
data = json.load(sys.stdin)
total = data.get('count', 0)
findings = data.get('results', [])

print(f'Total findings: {total}')
print()

if total > 0:
    # Count by status
    active = sum(1 for f in findings if f.get('active'))
    inactive = sum(1 for f in findings if not f.get('active'))
    verified = sum(1 for f in findings if f.get('verified'))

    print(f'  Active: {active}')
    print(f'  Inactive: {inactive}')
    print(f'  Verified: {verified}')
    print()

    # Show first few
    print('First 5 findings:')
    for f in findings[:5]:
        print(f'  - {f.get(\"title\", \"N/A\")[:60]}')
        print(f'    Severity: {f.get(\"severity\", \"N/A\")} | Active: {f.get(\"active\")} | Test: {f.get(\"test\")}')
else:
    print('  No findings at all!')
    print()
    print('Possible reasons:')
    print('  1. Bandit scan found no issues')
    print('  2. Parser failed to parse the JSON')
    print('  3. Wrong engagement name')
    print('  4. Findings were deduplicated')
"

echo ""
echo ""

# Step 4: Check bandit-results.json
echo "Step 4: Check Bandit Scan Results File"
echo "---------------------------------------"
if [ -f "bandit-results.json" ]; then
    python3 -c "
import json
with open('bandit-results.json', 'r') as f:
    data = json.load(f)

results = data.get('results', [])
print(f'Bandit found {len(results)} issue(s) in the scan')
print()

if results:
    for r in results[:3]:
        print(f'  - {r.get(\"issue_text\", \"N/A\")[:60]}')
        print(f'    Severity: {r.get(\"issue_severity\", \"N/A\")} | File: {r.get(\"filename\", \"N/A\")}')
        print()
else:
    print('Bandit scan found NO issues - that\\'s why there are no findings!')
"
else
    echo "❌ bandit-results.json not found locally"
    echo "   Run: bandit -r simple-web-flask/app/ -f json -o bandit-results.json"
fi

echo ""
echo "================================"
echo "✅ Debug complete"
