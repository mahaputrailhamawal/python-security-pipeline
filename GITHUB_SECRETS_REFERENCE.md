# GitHub Secrets - Quick Reference

Copy these exact values to your GitHub repository secrets:

## 📋 GitHub Repository Settings

Path: **Settings → Secrets and variables → Actions → New repository secret**

---

## 🔐 Secrets to Add:

### 1. DEFECTDOJO_URL
```
http://16.78.42.164:8080
```

### 2. DEFECTDOJO_TOKEN
```
c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d
```

### 3. DEFECTDOJO_ENGAGEMENT_SNYK
```
3
```

### 4. DEFECTDOJO_ENGAGEMENT_BANDIT
```
5
```

### 5. SNYK_TOKEN
```
YOUR_SNYK_TOKEN_HERE
```
*(Get from: https://app.snyk.io/account → API Token)*

---

## ✅ Verification Commands

Run these to verify your setup:

```bash
# Check engagements
curl -s "http://16.78.42.164:8080/api/v2/engagements/?active=true" \
  -H "Authorization: Token c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d" \
  | python3 -c "import json,sys; [print(f'ID: {e[\"id\"]} - {e[\"name\"]}') for e in json.load(sys.stdin)['results']]"

# Test Snyk auth
snyk auth YOUR_SNYK_TOKEN_HERE
snyk test --help

# Test Bandit
bandit --version
```

---

## 📁 File Locations

- **Workflow**: `.github/workflows/security-scan.yml`
- **Setup Guide**: `GITHUB_ACTIONS_SETUP.md`
- **This Reference**: `GITHUB_SECRETS_REFERENCE.md`

---

## 🚀 Quick Start

1. Add all 5 secrets above to GitHub
2. Copy workflow file to your repo:
   ```bash
   mkdir -p .github/workflows
   cp .github/workflows/security-scan.yml YOUR_REPO/.github/workflows/
   cd YOUR_REPO
   git add .github/workflows/security-scan.yml
   git commit -m "Add security scanning"
   git push
   ```
3. Go to GitHub Actions tab
4. Click "Run workflow"
5. Check DefectDojo for results

---

## 📊 Expected Results

### After First Run:

**GitHub Actions:**
- ✅ Workflow completes successfully
- ✅ Artifacts uploaded (bandit-results.json, snyk-results.json)
- ✅ Summary shows vulnerability counts

**DefectDojo:**
- ✅ New test in Snyk-Scan engagement (ID: 3)
- ✅ New test in Bandit-Scan engagement (ID: 5)
- ✅ Findings visible in dashboard

---

## 🔧 Troubleshooting

**Issue**: "Secret not found"
→ Check secret names are exactly: `DEFECTDOJO_URL`, `DEFECTDOJO_TOKEN`, etc.

**Issue**: "Invalid token"
→ Regenerate token in DefectDojo: Profile → API Key

**Issue**: "Engagement not found"
→ Run: `python3 query_engagements.py --active` to verify IDs

---

## 📞 Support

- DefectDojo: http://16.78.42.164:8080
- Workflow Logs: GitHub → Actions → Latest run
- Scan Results: DefectDojo → Engagements → Tests
