# Safety Scan + DefectDojo Integration Guide

This guide explains how to run Safety (SCA) scans and upload results to DefectDojo.

## Prerequisites

1. **Install Safety**:
   ```bash
   pip install safety
   ```

2. **Install requests library**:
   ```bash
   pip install requests
   ```

3. **DefectDojo Setup**:
   - DefectDojo instance running (URL)
   - API token (Get from: Profile → API Key)
   - Product and Engagement created in DefectDojo

## Files Overview

- **`upload_to_defectdojo.py`**: Core script to upload scan results to DefectDojo
- **`scan_and_upload.py`**: Automated script that runs Safety scan and uploads
- **`defectdojo_config.example.json`**: Configuration template

## Quick Start

### 1. Configure DefectDojo Settings

Copy the example config and fill in your details:

```bash
cp defectdojo_config.example.json defectdojo_config.json
```

Edit `defectdojo_config.json`:
```json
{
  "defectdojo_url": "https://your-defectdojo.com",
  "api_token": "your-api-token-here",
  "engagement_id": 123
}
```

### 2. Run Scan and Upload (Automated)

```bash
# Scan and upload in one command
python3 scan_and_upload.py -d ./simple-web-flask -c defectdojo_config.json

# Or provide config via command line
python3 scan_and_upload.py \
  -d ./simple-web-flask \
  -u https://your-defectdojo.com \
  -t YOUR_API_TOKEN \
  -e 123
```

### 3. Manual Process (Step by Step)

If you prefer manual control:

**Step 1: Run Safety Scan**
```bash
cd simple-web-flask
safety scan --output json --save-json safety-results.json
```

**Step 2: Upload to DefectDojo**
```bash
python3 upload_to_defectdojo.py \
  -f simple-web-flask/safety-results.json \
  -e 123 \
  -u https://your-defectdojo.com \
  -t YOUR_API_TOKEN
```

## Advanced Usage

### List Available Engagements

```bash
python3 upload_to_defectdojo.py \
  --list-engagements \
  -u https://your-defectdojo.com \
  -t YOUR_API_TOKEN
```

### Create New Engagement

```bash
python3 upload_to_defectdojo.py \
  --create-engagement \
  -p 5 \
  -n "Q4 2025 Security Scan" \
  -d "Quarterly security assessment" \
  -u https://your-defectdojo.com \
  -t YOUR_API_TOKEN
```

### Scan Only (No Upload)

```bash
python3 scan_and_upload.py -d ./simple-web-flask --scan-only
```

### Upload Existing Scan Results

```bash
python3 scan_and_upload.py --upload-only safety-results.json -c defectdojo_config.json
```

### Disable SSL Verification (for self-signed certs)

```bash
python3 scan_and_upload.py \
  -d ./simple-web-flask \
  -c defectdojo_config.json \
  --no-verify-ssl
```

## DefectDojo Setup Guide

### 1. Get API Token

1. Log into DefectDojo
2. Click your username → API Key
3. Copy the token

### 2. Create Product

1. Products → Add Product
2. Fill in:
   - Name: "Simple Web Flask"
   - Description: "Flask web application"
   - Product Type: Select appropriate type

### 3. Create Engagement

1. Go to your Product
2. Engagements → Add Engagement
3. Fill in:
   - Name: "SCA Scan - [Date]"
   - Target Start/End: Set dates
   - Status: "In Progress"
4. Note the Engagement ID from the URL

### 4. Verify Scanner Support

DefectDojo should have "Safety Scan" parser enabled. To verify:
- Go to Configuration → Tool Types
- Search for "Safety"

## Understanding Results

### Safety JSON Output

The Safety scan produces JSON with:
- **Dependencies analyzed**: All packages checked
- **Vulnerabilities**: CVEs found in dependencies
- **Severity levels**: Critical, High, Medium, Low
- **Remediation**: Recommended package versions

### DefectDojo Import

When uploaded, DefectDojo will:
- Parse the Safety JSON
- Create findings for each vulnerability
- Link to CVE databases
- Show remediation guidance
- Track finding status over time

## Troubleshooting

### "Safety command not found"
```bash
pip install safety --upgrade
```

### "Authentication failed"
- Verify API token is correct
- Check token hasn't expired
- Ensure user has permissions

### "Engagement not found"
- Verify engagement ID is correct
- Check you have access to the engagement
- Use `--list-engagements` to find correct ID

### "SSL verification failed"
For self-signed certificates:
```bash
python3 scan_and_upload.py --no-verify-ssl ...
```

### "Parser not found"
DefectDojo needs "Safety Scan" parser enabled. Contact your DefectDojo admin.

## Integration with CI/CD

### GitHub Actions Example

```yaml
name: Safety Scan

on: [push, pull_request]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install dependencies
        run: |
          pip install safety requests

      - name: Run Safety scan and upload to DefectDojo
        env:
          DD_URL: ${{ secrets.DEFECTDOJO_URL }}
          DD_TOKEN: ${{ secrets.DEFECTDOJO_TOKEN }}
          DD_ENGAGEMENT: ${{ secrets.DEFECTDOJO_ENGAGEMENT_ID }}
        run: |
          python3 scan_and_upload.py \
            -d ./simple-web-flask \
            -u $DD_URL \
            -t $DD_TOKEN \
            -e $DD_ENGAGEMENT
```

### GitLab CI Example

```yaml
safety-scan:
  stage: security
  script:
    - pip install safety requests
    - python3 scan_and_upload.py -d ./simple-web-flask -c defectdojo_config.json
  artifacts:
    paths:
      - safety-scan-results.json
    expire_in: 30 days
```

## Best Practices

1. **Run regularly**: Schedule scans weekly or on every release
2. **Track over time**: Use same engagement to see trends
3. **Automate**: Integrate into CI/CD pipeline
4. **Review findings**: Don't just scan, remediate vulnerabilities
5. **Version control**: Don't commit `defectdojo_config.json` with real credentials
6. **Use secrets**: Store credentials in environment variables or secret managers

## Additional Resources

- [DefectDojo Documentation](https://documentation.defectdojo.com/)
- [Safety Documentation](https://docs.pyup.io/docs/getting-started-with-safety-cli)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
