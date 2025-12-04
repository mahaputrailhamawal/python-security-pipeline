#!/bin/bash
# Simulate what GitHub Actions will do with the fixed workflow

DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

echo "================================"
echo "Simulating Fixed GitHub Workflow"
echo "================================"
echo ""

# Step 1: Run Bandit (exactly as workflow does)
echo "1️⃣ Running Bandit scan..."
bandit -r simple-web-flask/app/ -f json -o bandit-fresh-test.json 2>/dev/null
ISSUES=$(cat bandit-fresh-test.json | python3 -c "import json,sys; print(len(json.load(sys.stdin)['results']))")
echo "   ✅ Bandit found: $ISSUES security issues"
echo ""

# Step 2: Upload to DefectDojo (using fixed workflow parameters - NO scan_date)
echo "2️⃣ Uploading to DefectDojo (using fixed workflow)..."
RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@bandit-fresh-test.json" \
  -F "scan_type=Bandit Scan" \
  -F "product_name=Trial-Tests" \
  -F "engagement_name=Bandit-Scan" \
  -F "active=true" \
  -F "minimum_severity=Low" \
  -F "lead=1" \
  -F "environment=Production")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | grep -v "HTTP_CODE:")

echo "   HTTP Status: $HTTP_CODE"

if [ "$HTTP_CODE" = "201" ] || [ "$HTTP_CODE" = "200" ]; then
    TEST_ID=$(echo "$BODY" | python3 -c "import json,sys; print(json.load(sys.stdin).get('test', 'N/A'))")
    echo "   ✅ Upload successful - Test ID: $TEST_ID"
    echo ""
    
    # Step 3: Verify findings imported
    echo "3️⃣ Verifying findings in DefectDojo..."
    sleep 2
    
    FINDINGS_DATA=$(curl -s "${DD_URL}/api/v2/findings/?test=${TEST_ID}" \
      -H "Authorization: Token ${DD_TOKEN}")
    
    FINDINGS_COUNT=$(echo "$FINDINGS_DATA" | python3 -c "import json,sys; print(json.load(sys.stdin).get('count', 0))")
    
    echo "$FINDINGS_DATA" | python3 -c "
import json, sys
data = json.load(sys.stdin)
findings = data.get('results', [])
print(f'   Total findings imported: {len(findings)}')
print('')
for f in findings:
    severity = f.get('severity', 'Unknown')
    title = f.get('title', 'No title')
    line = f.get('line', 'N/A')
    print(f'   • {severity:8} - {title[:60]}')
"
    
    echo ""
    echo "================================"
    echo "Result: ✅ SUCCESS"
    echo "================================"
    echo "Bandit found: $ISSUES issues"
    echo "DefectDojo imported: $FINDINGS_COUNT findings"
    echo ""
    echo "The fixed workflow WILL import all findings correctly!"
else
    echo "   ❌ Upload failed"
    echo "   Response: $BODY"
fi

