# GitHub Actions Security Scanning Setup Guide

This guide explains how to set up the automated security scanning workflow with Snyk, Bandit, and DefectDojo.

## 📋 Prerequisites

1. GitHub repository with the code
2. DefectDojo instance running and accessible
3. Snyk account (free tier works)
4. Admin access to your GitHub repository

## 🔐 Step 1: Configure GitHub Secrets

Go to your GitHub repository: **Settings → Secrets and variables → Actions → New repository secret**

Add the following secrets:

### Required Secrets:

| Secret Name | Value | How to Get |
|-------------|-------|------------|
| `DEFECTDOJO_URL` | `http://16.78.42.164:8080` | Your DefectDojo base URL |
| `DEFECTDOJO_TOKEN` | `c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d` | DefectDojo API v2 token |
| `DEFECTDOJO_ENGAGEMENT_BANDIT` | `5` | Bandit engagement ID |
| `DEFECTDOJO_ENGAGEMENT_SNYK` | `3` | Snyk engagement ID |
| `SNYK_TOKEN` | `your-snyk-token` | From Snyk account settings |

### How to Get Snyk Token:

1. Go to https://app.snyk.io
2. Login to your account
3. Click your name → **Account Settings**
4. Scroll to **API Token** section
5. Click **Show** and copy the token
6. Click **Regenerate** if you need a new one

### How to Get DefectDojo Engagement IDs:

```bash
# Run this on your machine:
python3 query_engagements.py --active

# Output shows:
# ID: 3 - Snyk-Scan
# ID: 5 - Bandit-Scan
```

Or check in DefectDojo web UI:
1. Go to http://16.78.42.164:8080
2. Navigate to Engagements
3. Click on the engagement
4. Check the URL: `/engagement/3/` (ID is 3)

## 📁 Step 2: Add Workflow File to Repository

Copy the workflow file to your repository:

```bash
# From your repository root
mkdir -p .github/workflows
cp /home/moose/dev/pyconid-2025/.github/workflows/security-scan.yml .github/workflows/

# Commit and push
git add .github/workflows/security-scan.yml
git commit -m "Add automated security scanning workflow"
git push
```

## 🚀 Step 3: Test the Workflow

### Option A: Manual Trigger

1. Go to GitHub: **Actions** tab
2. Click **Security Scanning - Snyk & Bandit**
3. Click **Run workflow** dropdown
4. Click **Run workflow** button

### Option B: Push a Commit

```bash
git commit --allow-empty -m "Trigger security scan"
git push
```

### Option C: Wait for Schedule

The workflow runs automatically:
- Every Monday at 9 AM UTC
- On every push to main/master/develop
- On every pull request

## 📊 Step 4: View Results

### In GitHub:

1. **Actions Tab**: See workflow runs and logs
2. **Summary**: View security scan summary
3. **Artifacts**: Download scan result files (retained for 90 days)

### In DefectDojo:

1. Go to http://16.78.42.164:8080
2. Navigate to your engagements:
   - **Snyk-Scan** (ID: 3) - SCA results
   - **Bandit-Scan** (ID: 5) - SAST results
3. View findings, trends, and metrics

## ⚙️ Workflow Configuration

### Triggers:

The workflow runs on:
```yaml
- Push to: main, master, develop
- Pull requests to: main, master
- Schedule: Every Monday 9 AM UTC
- Manual: workflow_dispatch
```

### What It Does:

1. **🔍 Bandit Scan** (SAST - Static Application Security Testing)
   - Scans Python code for security issues
   - Finds: SQL injection, hardcoded secrets, insecure functions
   - Uploads results to DefectDojo

2. **📦 Snyk Scan** (SCA - Software Composition Analysis)
   - Scans dependencies for vulnerabilities
   - Checks: requirements.txt, poetry.lock
   - Uploads results to DefectDojo

3. **📤 DefectDojo Upload**
   - Automatically uploads both scan results
   - Creates findings in respective engagements
   - Tracks trends over time

4. **📊 Reporting**
   - GitHub Actions summary
   - Artifact storage (90 days)
   - Optional build failure on critical issues

## 🛠️ Customization

### Change Scan Schedule:

Edit `.github/workflows/security-scan.yml`:

```yaml
schedule:
  # Run daily at midnight
  - cron: '0 0 * * *'

  # Run every hour
  - cron: '0 * * * *'

  # Run on first day of month
  - cron: '0 0 1 * *'
```

### Fail Build on Critical Issues:

Uncomment in the workflow:

```yaml
- name: Check for critical/high vulnerabilities
  if: github.event_name == 'pull_request'
  run: |
    # Uncomment to fail the build:
    # exit 1  <-- Remove the # here
```

### Add More Scans:

Add additional steps in the workflow:

```yaml
- name: Run Semgrep
  run: |
    pip install semgrep
    semgrep --config=auto --json > semgrep-results.json

- name: Upload Semgrep to DefectDojo
  run: |
    curl -X POST "${DD_URL}/api/v2/import-scan/" \
      -F "file=@semgrep-results.json" \
      -F "scan_type=Semgrep JSON Report" \
      ...
```

### Change Python Version:

Edit the `env` section:

```yaml
env:
  PYTHON_VERSION: '3.11'  # Change to your version
```

## 🔍 Troubleshooting

### Workflow Fails: "Secret Not Found"

**Problem**: Missing GitHub secrets

**Solution**:
- Check Settings → Secrets → Actions
- Verify all required secrets are added
- Names must match exactly (case-sensitive)

### Snyk Scan Fails: "Auth Failed"

**Problem**: Invalid Snyk token

**Solution**:
- Regenerate token in Snyk account
- Update `SNYK_TOKEN` secret in GitHub

### DefectDojo Upload Fails: 403 Forbidden

**Problem**: Invalid DefectDojo token

**Solution**:
- Get new API token from DefectDojo
- Update `DEFECTDOJO_TOKEN` secret

### No Results Uploaded

**Problem**: Wrong engagement IDs

**Solution**:
```bash
# Check engagement IDs
python3 query_engagements.py --active

# Update secrets with correct IDs
```

### Workflow Doesn't Trigger

**Problem**: Wrong branch name

**Solution**:
- Check your default branch name
- Update workflow file if needed:
  ```yaml
  on:
    push:
      branches: [ main ]  # Change to your branch
  ```

## 📈 Best Practices

1. **Run on Every PR**: Catch issues before merging
2. **Schedule Regular Scans**: Weekly scans for main branches
3. **Review Findings**: Regularly check DefectDojo
4. **Fix Critical Issues**: Prioritize critical/high vulnerabilities
5. **Keep Tools Updated**: Update Snyk, Bandit versions
6. **Monitor Trends**: Track vulnerability trends in DefectDojo
7. **Rotate Tokens**: Update API tokens periodically

## 🎯 Next Steps

1. ✅ Add GitHub secrets
2. ✅ Push workflow file to repository
3. ✅ Trigger first scan manually
4. ✅ Verify results in DefectDojo
5. ✅ Configure notifications (optional)
6. ✅ Set up branch protection rules (optional)

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [DefectDojo API Docs](https://documentation.defectdojo.com/integrations/api-v2-docs/)
- [Snyk CLI Documentation](https://docs.snyk.io/snyk-cli)
- [Bandit Documentation](https://bandit.readthedocs.io/)

## 💡 Pro Tips

### Slack/Email Notifications:

Add to your workflow:

```yaml
- name: Notify on failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    webhook-url: ${{ secrets.SLACK_WEBHOOK }}
    payload: |
      {
        "text": "Security scan failed! Check: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
      }
```

### Create Issues for Findings:

```yaml
- name: Create GitHub issues for critical vulns
  uses: actions/github-script@v7
  with:
    script: |
      // Parse scan results and create issues
      // ... implementation here
```

### Matrix Strategy (Multi-version):

```yaml
strategy:
  matrix:
    python-version: ['3.9', '3.10', '3.11']
```

---

## ✅ Quick Start Checklist

- [ ] Add all 5 GitHub secrets
- [ ] Copy workflow file to `.github/workflows/`
- [ ] Push to repository
- [ ] Trigger manual workflow run
- [ ] Verify scans in GitHub Actions
- [ ] Check DefectDojo for uploaded results
- [ ] Configure branch protection (optional)
- [ ] Set up notifications (optional)

**Need help?** Check the troubleshooting section or review GitHub Actions logs!
