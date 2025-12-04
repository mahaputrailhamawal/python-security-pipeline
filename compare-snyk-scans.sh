#!/bin/bash
# Compare different Snyk scanning methods

echo "================================================"
echo "Snyk Scan Comparison"
echo "================================================"
echo ""

cd /home/moose/dev/pyconid-2025/simple-web-flask/app || exit 1

# Method 1: Auto-detect (default behavior)
echo "1️⃣  Method 1: Auto-detect (no flags)"
echo "Command: snyk test"
echo "---"
snyk test --dry-run 2>&1 | grep -E "(Testing|Tested)" | head -5
echo ""

# Method 2: All projects
echo "2️⃣  Method 2: --all-projects"
echo "Command: snyk test --all-projects"
cd ..
snyk test --all-projects --dry-run 2>&1 | grep -E "(Testing|Tested)" | head -10
echo ""

# Method 3: Specific file
echo "3️⃣  Method 3: --file (specific manifest)"
echo "Command: snyk test --file=app/requirements.txt"
snyk test --file=app/requirements.txt --dry-run 2>&1 | grep -E "(Testing|Tested)" | head -5
echo ""

echo "================================================"
echo "Summary:"
echo "================================================"
echo "✅ Use --all-projects to scan EVERYTHING"
echo "✅ Default (no flags) auto-detects in current dir"
echo "⚠️  Use --file only for specific manifest"
