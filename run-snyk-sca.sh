#!/bin/bash
# Proper Snyk SCA scan script

echo "🔍 Running Snyk SCA scan..."

# Save current directory
ORIGINAL_DIR=$(pwd)

# Navigate to app directory
cd /home/moose/dev/pyconid-2025/simple-web-flask/app || exit 1

# Run Snyk scan
echo "Scanning from: $(pwd)"
snyk test --json --skip-unresolved > "$ORIGINAL_DIR/snyk-sca-results.json" 2>&1

# Return to original directory
cd "$ORIGINAL_DIR" || exit 1

# Check results
if [ -f "snyk-sca-results.json" ]; then
    echo "✅ Scan complete!"
    echo "📄 Results: snyk-sca-results.json"
    ls -lh snyk-sca-results.json

    # Show summary
    echo ""
    python3 << 'EOF'
import json
try:
    with open('snyk-sca-results.json', 'r') as f:
        data = json.load(f)

    if data.get('ok') == False:
        print(f"❌ Error: {data.get('error', 'Unknown error')}")
    else:
        vulns = data.get('vulnerabilities', [])
        print(f"📊 Found {len(vulns)} vulnerabilities")

        # Count by severity
        severities = {}
        for v in vulns:
            sev = v.get('severity', 'unknown')
            severities[sev] = severities.get(sev, 0) + 1

        for sev, count in sorted(severities.items()):
            print(f"   {sev.upper()}: {count}")
except Exception as e:
    print(f"Could not parse results: {e}")
EOF
else
    echo "❌ Scan failed - no output file created"
    exit 1
fi
