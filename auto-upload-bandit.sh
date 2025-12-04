#!/bin/bash
# Automated Bandit scan and upload to DefectDojo

set -e

# Configuration
DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"
ENGAGEMENT_ID="1"
PRODUCT_ID="1"
LEAD_ID="1"
ENVIRONMENT="Development"
PROJECT_DIR="simple-web-flask/app"
OUTPUT_FILE="bandit-result.json"

echo "🔍 Running Bandit scan..."
bandit -r "$PROJECT_DIR" -f json -o "$OUTPUT_FILE"

echo "📤 Uploading to DefectDojo..."
curl -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@${OUTPUT_FILE}" \
  -F "scan_type=Bandit Scan" \
  -F "engagement=${ENGAGEMENT_ID}" \
  -F "verified=false" \
  -F "active=true" \
  -F "minimum_severity=Low" \
  -F "scan_date=$(date +%Y-%m-%d)" \
  -F "lead=${LEAD_ID}" \
  -F "environment=${ENVIRONMENT}" \
  | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print('✅ Upload successful!')
    print(f'Test ID: {data.get(\"test\")}')
except:
    print('❌ Upload failed')
"

echo ""
echo "Done! Check DefectDojo at: ${DD_URL}"
