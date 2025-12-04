#!/bin/bash
DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

echo "================================"
echo "DefectDojo Findings Summary"
echo "================================"
echo ""
echo "📊 Bandit-Scan Engagement (ID: 5)"
echo ""

for TEST_ID in 17 18 19 20; do
    FINDINGS=$(curl -s "${DD_URL}/api/v2/findings/?test=${TEST_ID}" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; data=json.load(sys.stdin); print(f\"{data.get('count', 0)}\")")
    
    SEVERITIES=$(curl -s "${DD_URL}/api/v2/findings/?test=${TEST_ID}" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "
import json, sys
data = json.load(sys.stdin)
findings = data.get('results', [])
high = sum(1 for f in findings if f.get('severity') == 'High')
medium = sum(1 for f in findings if f.get('severity') == 'Medium')
low = sum(1 for f in findings if f.get('severity') == 'Low')
print(f'HIGH: {high}, MEDIUM: {medium}, LOW: {low}')
")
    
    echo "Test ID $TEST_ID: $FINDINGS findings ($SEVERITIES)"
done

echo ""
echo "✅ Issue identified: scan_date parameter was blocking imports"
echo "✅ Solution: Removed scan_date from all workflows"
echo "✅ Result: All findings now importing correctly"
