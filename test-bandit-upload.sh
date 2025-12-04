#!/bin/bash
# Test different upload approaches for Bandit findings

DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

echo "================================"
echo "Testing Bandit Upload Methods"
echo "================================"
echo ""

# Ensure we have a fresh scan
echo "1. Running fresh Bandit scan..."
bandit -r simple-web-flask/app/ -f json -o bandit-test.json 2>/dev/null
ISSUES=$(cat bandit-test.json | python3 -c "import json,sys; print(len(json.load(sys.stdin)['results']))")
echo "   Bandit found: $ISSUES issues"
echo ""

# Test 1: Without scan_date (let DefectDojo auto-generate)
echo "2. Test 1: Upload WITHOUT scan_date parameter"
RESPONSE1=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@bandit-test.json" \
  -F "scan_type=Bandit Scan" \
  -F "product_name=Trial-Tests" \
  -F "engagement_name=Bandit-Scan" \
  -F "active=true" \
  -F "minimum_severity=Low" \
  -F "lead=1" \
  -F "environment=Production")

HTTP_CODE1=$(echo "$RESPONSE1" | grep "HTTP_CODE:" | cut -d: -f2)
BODY1=$(echo "$RESPONSE1" | grep -v "HTTP_CODE:")

echo "   Status: $HTTP_CODE1"
if [ "$HTTP_CODE1" = "201" ] || [ "$HTTP_CODE1" = "200" ]; then
    TEST_ID1=$(echo "$BODY1" | python3 -c "import json,sys; print(json.load(sys.stdin).get('test', 'N/A'))")
    echo "   ✅ Success - Test ID: $TEST_ID1"
    
    # Check findings count
    sleep 2
    FINDINGS1=$(curl -s "${DD_URL}/api/v2/findings/?test=${TEST_ID1}" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; print(json.load(sys.stdin).get('count', 0))")
    echo "   Findings imported: $FINDINGS1"
else
    echo "   ❌ Failed"
    echo "   Response: $BODY1"
fi
echo ""

# Test 2: With verified=true
echo "3. Test 2: Upload WITH verified=true"
RESPONSE2=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@bandit-test.json" \
  -F "scan_type=Bandit Scan" \
  -F "product_name=Trial-Tests" \
  -F "engagement_name=Bandit-Scan" \
  -F "verified=true" \
  -F "active=true" \
  -F "minimum_severity=Low" \
  -F "lead=1" \
  -F "environment=Production")

HTTP_CODE2=$(echo "$RESPONSE2" | grep "HTTP_CODE:" | cut -d: -f2)
BODY2=$(echo "$RESPONSE2" | grep -v "HTTP_CODE:")

echo "   Status: $HTTP_CODE2"
if [ "$HTTP_CODE2" = "201" ] || [ "$HTTP_CODE2" = "200" ]; then
    TEST_ID2=$(echo "$BODY2" | python3 -c "import json,sys; print(json.load(sys.stdin).get('test', 'N/A'))")
    echo "   ✅ Success - Test ID: $TEST_ID2"
    
    sleep 2
    FINDINGS2=$(curl -s "${DD_URL}/api/v2/findings/?test=${TEST_ID2}" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; print(json.load(sys.stdin).get('count', 0))")
    echo "   Findings imported: $FINDINGS2"
else
    echo "   ❌ Failed"
    echo "   Response: $BODY2"
fi
echo ""

# Test 3: Minimal parameters
echo "4. Test 3: Upload with MINIMAL parameters"
RESPONSE3=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@bandit-test.json" \
  -F "scan_type=Bandit Scan" \
  -F "product_name=Trial-Tests" \
  -F "engagement_name=Bandit-Scan")

HTTP_CODE3=$(echo "$RESPONSE3" | grep "HTTP_CODE:" | cut -d: -f2)
BODY3=$(echo "$RESPONSE3" | grep -v "HTTP_CODE:")

echo "   Status: $HTTP_CODE3"
if [ "$HTTP_CODE3" = "201" ] || [ "$HTTP_CODE3" = "200" ]; then
    TEST_ID3=$(echo "$BODY3" | python3 -c "import json,sys; print(json.load(sys.stdin).get('test', 'N/A'))")
    echo "   ✅ Success - Test ID: $TEST_ID3"
    
    sleep 2
    FINDINGS3=$(curl -s "${DD_URL}/api/v2/findings/?test=${TEST_ID3}" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; print(json.load(sys.stdin).get('count', 0))")
    echo "   Findings imported: $FINDINGS3"
else
    echo "   ❌ Failed"
    echo "   Response: $BODY3"
fi
echo ""

echo "================================"
echo "Summary"
echo "================================"
echo "Bandit found: $ISSUES issues locally"
echo "Test 1 (no scan_date): ${FINDINGS1:-0} findings"
echo "Test 2 (verified=true): ${FINDINGS2:-0} findings"
echo "Test 3 (minimal params): ${FINDINGS3:-0} findings"
echo ""
echo "Check DefectDojo Bandit-Scan engagement for all test results"

