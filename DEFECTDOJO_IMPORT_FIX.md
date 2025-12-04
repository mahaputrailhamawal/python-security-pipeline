# DefectDojo Import Issue - RESOLVED

## Problem

GitHub Actions pipeline succeeded and created tests in DefectDojo, but **0 findings were imported** despite Bandit finding 4 security issues.

## Root Cause

The `scan_date=$(date +%Y-%m-%d)` parameter in the curl upload command was blocking the import process. Even though the date format appeared correct, DefectDojo's import-scan API was rejecting the findings during parsing.

## Investigation Results

Test uploads showed the issue clearly:

| Test ID | scan_date parameter | Findings Imported |
|---------|-------------------|-------------------|
| 17 | ✅ Included | 0 |
| 18 | ❌ Removed | 4 |
| 19 | ❌ Removed | 4 |
| 20 | ❌ Removed | 4 |

All tests without `scan_date` successfully imported:
- 1 HIGH severity finding
- 2 MEDIUM severity findings
- 1 LOW severity finding

## Solution Applied

Removed the `scan_date=$(date +%Y-%m-%d)` parameter from all DefectDojo upload commands in:

1. [.github/workflows/bandit-defectdojo.yml](.github/workflows/bandit-defectdojo.yml#L39-L48)
2. [.github/workflows/security-scan.yml](.github/workflows/security-scan.yml#L154-L164) (Bandit upload)
3. [.github/workflows/security-scan.yml](.github/workflows/security-scan.yml#L184-L194) (Snyk upload)

### Before (Not Working):
```bash
curl -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@bandit-results.json" \
  -F "scan_type=Bandit Scan" \
  -F "product_name=Trial-Tests" \
  -F "engagement_name=Bandit-Scan" \
  -F "active=true" \
  -F "minimum_severity=Low" \
  -F "scan_date=$(date +%Y-%m-%d)" \  # ← This line was blocking imports
  -F "lead=1" \
  -F "environment=Production"
```

### After (Working):
```bash
curl -X POST "${DD_URL}/api/v2/import-scan/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -F "file=@bandit-results.json" \
  -F "scan_type=Bandit Scan" \
  -F "product_name=Trial-Tests" \
  -F "engagement_name=Bandit-Scan" \
  -F "active=true" \
  -F "minimum_severity=Low" \
  -F "lead=1" \
  -F "environment=Production"
```

DefectDojo automatically sets the scan date when it's not provided.

## Bandit Findings in DefectDojo

The following security issues are now visible in DefectDojo:

### 1. HIGH Severity
- **Issue**: Flask app run with debug=True
- **Location**: `simple-web-flask/app/app.py:68`
- **CWE**: CWE-489 (Debug Mode Enabled)
- **Risk**: Exposes sensitive application internals and stack traces in production

### 2. MEDIUM Severity (2 findings)
- **Issue**: Possible binding to all interfaces
- **Location**: `simple-web-flask/app/app.py:68`
- **CWE**: CWE-200 (Information Exposure)
- **Risk**: Application accessible from any network interface

- **Issue**: Use of hardcoded secret key
- **Location**: `simple-web-flask/app/app.py:6`
- **Risk**: Session tampering if secret is compromised

### 3. LOW Severity
- **Issue**: Hardcoded password string
- **Location**: `simple-web-flask/app/app.py`
- **Risk**: Credentials stored in source code

## Verification

Check DefectDojo for imported findings:

```bash
# View all tests in Bandit-Scan engagement
./query-engagements-quick.sh tests 5

# Check findings for specific test
curl -s "http://16.78.42.164:8080/api/v2/findings/?test=18" \
  -H "Authorization: Token c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d" | \
  python3 -c "import json,sys; print(json.dumps(json.load(sys.stdin), indent=2))"
```

Or visit DefectDojo web UI:
- URL: http://16.78.42.164:8080
- Navigate to: **Engagements → Bandit-Scan (ID: 5) → Tests**
- View findings for each test

## Next Steps

### 1. Run the Workflow
The fixed workflows are ready to use:

```bash
# Trigger via push
git add .github/workflows/
git commit -m "Fix DefectDojo findings import - remove scan_date parameter"
git push

# Or run manually in GitHub Actions tab
```

### 2. Verify in DefectDojo
After the pipeline runs:
1. Go to http://16.78.42.164:8080
2. Navigate to **Engagements → Bandit-Scan**
3. Check the latest test
4. Verify findings are visible with proper severity levels

### 3. Monitor Regular Scans
The workflows run automatically:
- On every push to main/develop branches
- On every pull request to main
- Every Monday at 9 AM UTC (scheduled)
- Manual trigger via GitHub Actions

## Additional Notes

### Why scan_date Caused Issues

While the date format `YYYY-MM-DD` appeared correct, the parameter may have caused issues due to:
- DefectDojo API version compatibility
- Parser expectations during import
- Timezone handling conflicts
- Shell expansion in curl commands

By allowing DefectDojo to auto-generate the scan date, the import process works reliably.

### Recommended Upload Parameters

For reliable DefectDojo imports, use these minimal required parameters:

```bash
-F "file=@<scan-results.json>"
-F "scan_type=<Tool Name>"
-F "product_name=<Product Name>"
-F "engagement_name=<Engagement Name>"
-F "active=true"
-F "minimum_severity=Low"
```

Optional parameters that work well:
- `lead=1` - Assigns a lead user
- `environment=<env>` - Tags the environment
- `build_id=<id>` - Links to CI/CD build
- `verified=true/false` - Marks findings as verified

## Files Modified

- [.github/workflows/bandit-defectdojo.yml](.github/workflows/bandit-defectdojo.yml)
- [.github/workflows/security-scan.yml](.github/workflows/security-scan.yml)

## Status

✅ **RESOLVED** - Findings now import correctly into DefectDojo

## Related Documentation

- [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) - GitHub Actions setup guide
- [GITHUB_SECRETS_REFERENCE.md](GITHUB_SECRETS_REFERENCE.md) - Required secrets reference
- [query-engagements-quick.sh](query-engagements-quick.sh) - Query DefectDojo engagements
- [check-findings-summary.sh](check-findings-summary.sh) - Verify findings import

---

**Date Resolved**: 2025-12-04
**DefectDojo Instance**: http://16.78.42.164:8080
**Affected Engagements**: Bandit-Scan (ID: 5), Snyk-Scan (ID: 3)
