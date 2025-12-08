# DefectDojo Reimport Implementation

## Overview
Pipeline sekarang menggunakan **reimport strategy** untuk menghindari duplicate findings di DefectDojo.

## How It Works

### First Run (No existing test)
```
🔍 Step 1: Get Engagement ID...
✅ Found Engagement ID: 42

🔍 Step 2: Check for existing Bandit test...

📝 Step 3a: No existing test found - Creating NEW test with import-scan...
✅ Created NEW Test ID: 123
✅ Findings: Total: 4, Critical: 0, High: 2, Medium: 1, Low: 1
```

### Subsequent Runs (Test exists)
```
🔍 Step 1: Get Engagement ID...
✅ Found Engagement ID: 42

🔍 Step 2: Check for existing Bandit test...

🔄 Step 3b: Found existing Test ID 123 - Using REIMPORT to avoid duplicates...
✅ Reimported to Test ID: 123
✅ Current Findings: Total: 6, Critical: 0, High: 3, Medium: 2, Low: 1
✅ Changes: Δ Total: +2, Δ Critical: +0, Δ High: +1, Δ Medium: +1, Δ Low: +0 (+ = new findings, - = closed/fixed)
```

## Benefits

### 1. No Duplicates
- **Before**: Test #1, Test #2, Test #3... (every scan creates new test)
- **After**: Test #123 gets updated (same test, updated findings)

### 2. Auto-Close Fixed Issues
- Parameter: `close_old_findings=true`
- Findings yang tidak muncul di scan baru otomatis di-close
- Artinya: Issue sudah fixed!

### 3. Track Changes (Delta)
- `Δ Total: +2` → 2 new findings
- `Δ High: -1` → 1 high severity finding fixed
- `Δ Medium: +3` → 3 new medium findings

### 4. Clean Dashboard
- Hanya **1 test per scan type** di setiap engagement
- Tidak ada ratusan duplicate tests

### 5. No JIRA Spam
- Parameter: `push_to_jira=false`
- Hindari create duplicate JIRA tickets

## API Endpoints Used

### `/api/v2/engagements/`
- **Purpose**: Get engagement ID by name
- **Method**: GET
- **Query**: `?name=Bandit-Scan&product__name=MyProduct`

### `/api/v2/tests/`
- **Purpose**: Check if test already exists
- **Method**: GET
- **Query**: `?engagement=42&scan_type=Bandit Scan`

### `/api/v2/import-scan/` (First run)
- **Purpose**: Create new test
- **Method**: POST
- **Parameters**:
  - `file`: Scan results JSON
  - `scan_type`: "Bandit Scan" / "Snyk Scan"
  - `engagement_name`: Engagement name
  - `close_old_findings`: false (first run)
  - `push_to_jira`: false

### `/api/v2/reimport-scan/` (Subsequent runs)
- **Purpose**: Update existing test
- **Method**: POST
- **Parameters**:
  - `file`: Scan results JSON
  - `scan_type`: "Bandit Scan" / "Snyk Scan"
  - `test`: Test ID to update
  - `close_old_findings`: true (auto-close fixed issues)
  - `push_to_jira`: false

## Example Workflow

### Week 1 - First Scan
```
Pipeline Run #1:
- Bandit finds 4 issues
- DefectDojo: Creates Test #123
- Result: 4 active findings
```

### Week 2 - Fixed 1 Issue, Found 2 New
```
Pipeline Run #2:
- Bandit finds 5 issues (3 old + 2 new)
- DefectDojo: Updates Test #123
- Auto-closes 1 old finding (fixed!)
- Adds 2 new findings
- Result: 5 active findings
- Delta: Δ Total: +1 (5 - 4)
```

### Week 3 - Fixed 2 Issues
```
Pipeline Run #3:
- Bandit finds 3 issues
- DefectDojo: Updates Test #123
- Auto-closes 2 findings (fixed!)
- Result: 3 active findings
- Delta: Δ Total: -2 (3 - 5)
```

## Statistics Breakdown

### After Stats (Current State)
```json
{
  "total": 6,
  "critical": 0,
  "high": 3,
  "medium": 2,
  "low": 1
}
```

### Delta Stats (Changes from Previous)
```json
{
  "total": +2,    // 2 net new findings
  "critical": +0,
  "high": +1,     // 1 new high severity
  "medium": +1,   // 1 new medium severity
  "low": +0
}
```

Positive delta (+) = new findings
Negative delta (-) = closed/fixed findings

## Troubleshooting

### Error: "Engagement not found"
- **Cause**: Engagement name tidak match
- **Fix**: Check `ENGAGEMENT_BANDIT` / `ENGAGEMENT_SNYK` secrets

### Error: "Reimport failed (HTTP 400)"
- **Cause**: Test ID tidak valid atau scan type tidak match
- **Fix**: Check test ID exists dan scan_type benar

### Multiple Tests Created
- **Cause**: Engagement ID query tidak ketemu test lama
- **Fix**: Manually delete duplicate tests di DefectDojo, pipeline akan detect yang terbaru

## Best Practices

1. **Jangan manual create tests** - Biarkan pipeline yang handle
2. **Satu engagement per scan type** - Bandit-Scan, Snyk-Scan terpisah
3. **Review delta statistics** - Track progress fix issues
4. **Monitor closed findings** - Verify issues actually fixed

## Configuration

### GitHub Secrets Required
- `DEFECTDOJO_URL`: http://your-defectdojo-instance
- `DEFECTDOJO_TOKEN`: API token
- `PRODUCT_NAME`: Product name di DefectDojo
- `ENGAGEMENT_BANDIT`: Engagement name untuk Bandit (e.g., "Bandit-Scan")
- `ENGAGEMENT_SNYK`: Engagement name untuk Snyk (e.g., "Snyk-Scan")

### Scan Types
- **Bandit**: `scan_type=Bandit Scan`
- **Snyk**: `scan_type=Snyk Scan`

⚠️ **Important**: Scan type harus exact match dengan yang ada di DefectDojo!
