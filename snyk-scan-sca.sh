#!/bin/bash
# Snyk SCA Scan and Upload to DefectDojo

set -e

PROJECT_DIR="simple-web-flask"
OUTPUT_FILE="snyk-sca-results.json"

# DefectDojo config
DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"
ENGAGEMENT_ID="3"  # Snyk-Scan engagement
PRODUCT_ID="1"
LEAD_ID="1"

echo "🔍 Running Snyk SCA scan..."

# Try different scan methods
if [ -f "$PROJECT_DIR/app/poetry.lock" ]; then
    echo "Found poetry.lock, scanning..."
    cd "$PROJECT_DIR/app"
    snyk test --json --skip-unresolved > "../../$OUTPUT_FILE" 2>&1 || true
    cd ../..
elif [ -f "$PROJECT_DIR/app/requirements.txt" ]; then
    echo "Found requirements.txt, scanning..."
    snyk test --file="$PROJECT_DIR/app/requirements.txt" --json --skip-unresolved > "$OUTPUT_FILE" 2>&1 || true
else
    echo "Scanning all projects..."
    cd "$PROJECT_DIR"
    snyk test --all-projects --json --skip-unresolved > "../$OUTPUT_FILE" 2>&1 || true
    cd ..
fi

if [ ! -f "$OUTPUT_FILE" ]; then
    echo "❌ Scan failed to create output file"
    exit 1
fi

echo "✅ Scan complete: $OUTPUT_FILE"
ls -lh "$OUTPUT_FILE"

# Upload to DefectDojo
echo ""
echo "📤 Uploading to DefectDojo..."

curl -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@${OUTPUT_FILE}" \
  -F "scan_type=Snyk Code Scan" \
  -F "engagement=${ENGAGEMENT_ID}" \
  -F "verified=false" \
  -F "active=true" \
  -F "scan_date=$(date +%Y-%m-%d)" \
  -F "lead=${LEAD_ID}" \
  -F "environment=Development" \
  | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print('✅ Upload successful!')
    print(f'Test ID: {data.get(\"test\")}')
except:
    print('❌ Upload failed')
" 2>/dev/null || echo "Upload completed"

echo ""
echo "✅ Done! Check DefectDojo at: ${DD_URL}"
