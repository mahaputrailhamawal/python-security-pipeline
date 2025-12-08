# Quality Gate Implementation

## Overview
Pipeline kini memiliki **Quality Gate** yang query DefectDojo API untuk memvalidasi security posture sebelum deploy.

## Quality Gate Rules

| Rule | Threshold | Action | Description |
|------|-----------|--------|-------------|
| **Rule 1** | `MAX_CRITICAL=0` | ❌ FAIL | Tidak boleh ada critical vulnerabilities |
| **Rule 2** | `MAX_HIGH=3` | ❌ FAIL | Maximum 3 high severity findings |
| **Rule 3** | `MAX_TOTAL=50` | ⚠️ WARN | Total findings warning (tidak fail) |

## How It Works

### Step 1: Query DefectDojo
```bash
# Get engagement ID
GET /api/v2/engagements/?name=Bandit-Scan&product__name=MyProduct

# Get active findings in engagement
GET /api/v2/findings/?test__engagement=42&active=true&limit=1000
```

### Step 2: Count by Severity
```python
critical = len([f for f in findings if f.get('severity')=='Critical'])
high = len([f for f in findings if f.get('severity')=='High'])
medium = len([f for f in findings if f.get('severity')=='Medium'])
low = len([f for f in findings if f.get('severity')=='Low'])
```

### Step 3: Apply Rules
```bash
if [ "$CRITICAL" -gt 0 ]; then
  echo "❌ FAILED: Critical vulnerabilities found"
  exit 1
fi

if [ "$HIGH" -gt 3 ]; then
  echo "❌ FAILED: Too many high severity findings"
  exit 1
fi
```

## Pipeline Output

### ✅ Quality Gate PASSED
```
==========================================
🎯 Quality Gate - Snyk Scan
==========================================

🔍 Querying DefectDojo for active findings...
✅ Found Engagement ID: 42

Active Findings in Snyk Engagement:
  ├─ Critical: 0 (max: 0)
  ├─ High: 2 (max: 3)
  ├─ Medium: 4
  ├─ Low: 3
  ├─ Info: 1
  └─ Total: 10 (max: 50)

✅ Rule 1 PASSED: Critical vulnerabilities within limit
✅ Rule 2 PASSED: High vulnerabilities within limit
✅ Rule 3 PASSED: Total findings within limit

==========================================
✅ QUALITY GATE PASSED - Snyk
==========================================
```

### ❌ Quality Gate FAILED
```
==========================================
🎯 Quality Gate - Snyk Scan
==========================================

🔍 Querying DefectDojo for active findings...
✅ Found Engagement ID: 42

Active Findings in Snyk Engagement:
  ├─ Critical: 2 (max: 0)
  ├─ High: 5 (max: 3)
  ├─ Medium: 8
  ├─ Low: 12
  ├─ Info: 3
  └─ Total: 30 (max: 50)

❌ Rule 1 FAILED: 2 critical vulnerabilities (max: 0)
❌ Rule 2 FAILED: 5 high vulnerabilities (max: 3)
✅ Rule 3 PASSED: Total findings within limit

==========================================
❌ QUALITY GATE FAILED - Snyk
==========================================

Pipeline FAILED due to security findings threshold exceeded.
Please review and fix vulnerabilities in DefectDojo:
http://your-defectdojo/engagement/42
```

## Workflow Integration

```yaml
jobs:
  security-scan:
    steps:
      # 1. Run security scans
      - name: Run Bandit Scan
      - name: Upload Bandit to DefectDojo

      # 2. Quality Gate (blocks deployment if failed)
      - name: Quality Gate - Bandit
        env:
          DD_URL: ${{ secrets.DEFECTDOJO_URL }}
          DD_TOKEN: ${{ secrets.DEFECTDOJO_TOKEN }}
        run: |
          # Query DefectDojo
          # Count findings
          # Check thresholds
          # Exit 1 if failed

      # 3. Continue only if quality gate passed
      - name: Deploy (only if security checks passed)
```

## Customizing Thresholds

Edit thresholds in `.github/workflows/security-scan.yml`:

```bash
# Quality Gate Thresholds
MAX_CRITICAL=0    # Change to allow critical (not recommended!)
MAX_HIGH=3        # Adjust based on your risk appetite
MAX_TOTAL=50      # Warning threshold for total findings
```

## Benefits

### 1. **Prevent Vulnerable Deployments**
- Pipeline fails if thresholds exceeded
- Forces teams to fix security issues before deployment
- Automated enforcement of security standards

### 2. **Clear Visibility**
- Shows exact count of findings by severity
- Direct link to DefectDojo for remediation
- Easy to understand pass/fail criteria

### 3. **Risk-Based Approach**
- Different thresholds for different severities
- Can customize per project/engagement
- Warning-only mode for lower severities

### 4. **Integration with DefectDojo**
- Single source of truth for findings
- Tracks findings across all scans
- Automatic de-duplication (via reimport)

## Troubleshooting

### Quality Gate Fails Due to Old Findings

**Problem**: Pipeline fails because of old unresolved findings

**Solution**:
1. Go to DefectDojo engagement
2. Review old findings
3. Either:
   - Fix the issues (findings auto-close on next scan)
   - Mark as false positive
   - Mark as accepted risk (with justification)

### Quality Gate Too Strict

**Problem**: Can't deploy due to unavoidable findings

**Options**:
1. **Increase threshold** (short-term):
   ```bash
   MAX_HIGH=5  # Was 3
   ```

2. **Mark findings as accepted risk** in DefectDojo:
   - Add risk acceptance with business justification
   - Set expiration date
   - Track in security backlog

3. **Use continue-on-error** (NOT recommended):
   ```yaml
   - name: Quality Gate
     continue-on-error: true  # Gates won't block deployment
   ```

### Quality Gate Always Passes (Even with Findings)

**Debug checklist**:
1. Check engagement name matches:
   ```bash
   echo $ENGAGEMENT_BANDIT  # Should match DefectDojo
   ```

2. Check findings are active:
   ```bash
   # In DefectDojo, verify findings are Active=true
   ```

3. Check API query limit:
   ```bash
   --data-urlencode "limit=1000"  # Increase if you have more
   ```

4. Check severity matching:
   ```python
   # Ensure DefectDojo severities are: Critical, High, Medium, Low, Info
   # (case-insensitive matching in code)
   ```

## Advanced: Multi-Stage Quality Gates

For different environments:

```yaml
# Development: Lenient
- name: Quality Gate - Dev
  if: github.ref == 'refs/heads/develop'
  env:
    MAX_CRITICAL: 0
    MAX_HIGH: 10     # More lenient
    MAX_TOTAL: 100

# Production: Strict
- name: Quality Gate - Prod
  if: github.ref == 'refs/heads/main'
  env:
    MAX_CRITICAL: 0
    MAX_HIGH: 0      # Zero tolerance!
    MAX_TOTAL: 20
```

## Advanced: CVSS-Based Quality Gate

For more granular control based on CVSS scores:

```bash
# Query findings with CVSS >= 9.0
FINDINGS_RESPONSE=$(curl -s -X GET "${DD_URL}/api/v2/findings/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -G --data-urlencode "test__engagement=${ENGAGEMENT_ID}" \
  --data-urlencode "active=true" \
  --data-urlencode "cvssv3_score__gte=9.0")

COUNT=$(echo "$FINDINGS_RESPONSE" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('results',[])))")

if [ "$COUNT" -gt 0 ]; then
  echo "❌ FAILED: ${COUNT} findings with CVSS >= 9.0"
  exit 1
fi
```

## Advanced: Age-Based Quality Gate

Fail if findings older than 30 days:

```bash
# Get findings older than 30 days
CUTOFF_DATE=$(date -d '30 days ago' -Iseconds)

FINDINGS_RESPONSE=$(curl -s -X GET "${DD_URL}/api/v2/findings/" \
  -H "Authorization: Token ${DD_TOKEN}" \
  -G --data-urlencode "test__engagement=${ENGAGEMENT_ID}" \
  --data-urlencode "active=true" \
  --data-urlencode "date__lte=${CUTOFF_DATE}")

OLD_COUNT=$(echo "$FINDINGS_RESPONSE" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('results',[])))")

if [ "$OLD_COUNT" -gt 5 ]; then
  echo "❌ FAILED: ${OLD_COUNT} findings older than 30 days"
  exit 1
fi
```

## Metrics & Reporting

Track quality gate pass/fail rates:

```bash
# In your pipeline
if [ "$GATE_FAILED" -eq 1 ]; then
  # Send metrics to monitoring system
  curl -X POST "https://metrics.example.com/quality-gate" \
    -d '{"status":"failed","engagement":"Snyk-Scan","critical":'$CRITICAL',"high":'$HIGH'}'
fi
```

## Best Practices

1. ✅ **Start lenient, gradually tighten**
   - Begin with high thresholds
   - Reduce as team fixes findings
   - Track progress over time

2. ✅ **Document risk acceptances**
   - Use DefectDojo risk acceptance feature
   - Require business justification
   - Set expiration dates

3. ✅ **Review findings regularly**
   - Weekly triage sessions
   - Assign owners to findings
   - Track time-to-remediation

4. ✅ **Use quality gates in all environments**
   - Dev: Lenient (catch early)
   - Staging: Moderate
   - Production: Strict (enforce quality)

5. ❌ **Don't bypass quality gates**
   - Avoid `continue-on-error`
   - Don't merge if gates fail
   - Fix issues, don't hide them

## Related Documentation

- [DefectDojo Reimport Implementation](DEFECTDOJO_REIMPORT.md)
- [DefectDojo API Documentation](https://demo.defectdojo.org/api/v2/doc/)
- [OWASP Severity Ratings](https://owasp.org/www-project-risk-assessment-framework/)
