# How to Add Safety Parser to DefectDojo

Your DefectDojo instance is missing the Safety parser code. Here's how to add it:

## Option 1: Upgrade DefectDojo (Recommended)

Safety parser is available in **DefectDojo v2.15.0+**. If you're running an older version:

```bash
# Check your version
docker exec -it <defectdojo-uwsgi-container> python manage.py version

# Upgrade to latest version
# Follow: https://documentation.defectdojo.com/getting_started/upgrading/
```

## Option 2: Manually Add Safety Parser

If you can't upgrade, add the parser manually:

### Step 1: Access DefectDojo Server

SSH into your DefectDojo server or access the container:

```bash
# Find the uwsgi/django container
docker ps | grep defectdojo

# Access the container
docker exec -it <uwsgi-container-name> bash
```

### Step 2: Create Parser Directory

```bash
cd /app/dojo/tools
mkdir -p safety_scan
cd safety_scan
```

### Step 3: Create Parser Files

**File 1: `__init__.py`**
```python
# Empty file to make it a Python package
```

**File 2: `parser.py`**
```python
import json
from dojo.models import Finding

class SafetyScanParser:
    """
    Parser for Safety CLI JSON output
    """

    def get_scan_types(self):
        return ["Safety Scan"]

    def get_label_for_scan_types(self, scan_type):
        return "Safety Scan"

    def get_description_for_scan_types(self, scan_type):
        return "Import Safety CLI JSON vulnerability scan results"

    def get_findings(self, file, test):
        data = json.load(file)
        findings = []

        # Parse Safety 3.x JSON format
        for project in data.get('scan_results', {}).get('projects', []):
            for file_info in project.get('files', []):
                file_location = file_info.get('location', 'Unknown')

                for dependency in file_info.get('results', {}).get('dependencies', []):
                    package_name = dependency.get('name', 'Unknown')

                    for spec in dependency.get('specifications', []):
                        raw_spec = spec.get('raw', '')

                        # Extract version
                        version = "unknown"
                        if "==" in raw_spec:
                            version = raw_spec.split("==")[1].split(")")[0].split(";")[0].strip()

                        vulnerabilities = spec.get('vulnerabilities', {}).get('known_vulnerabilities', [])

                        for vuln in vulnerabilities:
                            # Skip ignored vulnerabilities
                            if vuln.get('ignored'):
                                continue

                            vuln_id = vuln.get('id', 'UNKNOWN')
                            vuln_spec = vuln.get('vulnerable_spec', '')

                            # Create finding
                            finding = Finding(
                                title=f"{package_name} ({version}) - Vulnerability {vuln_id}",
                                test=test,
                                severity="Medium",  # Default, can be enhanced
                                description=f"Package: {package_name}\\nVersion: {version}\\nVulnerable Spec: {vuln_spec}\\nFile: {file_location}",
                                mitigation="Update to a secure version",
                                references=f"Safety ID: {vuln_id}",
                                file_path=file_location,
                                component_name=package_name,
                                component_version=version,
                                vuln_id_from_tool=str(vuln_id),
                                unique_id_from_tool=f"safety_{package_name}_{version}_{vuln_id}",
                                static_finding=True,
                                dynamic_finding=False,
                            )

                            # Add remediation if available
                            remediation = spec.get('vulnerabilities', {}).get('remediation', {})
                            if remediation:
                                recommended = remediation.get('recommended')
                                if recommended:
                                    finding.mitigation = f"Update {package_name} to version {recommended}"

                            findings.append(finding)

        return findings
```

### Step 4: Register Parser

Edit `/app/dojo/tools/factory.py`:

```python
# Add this import near the top with other imports
from dojo.tools.safety_scan.parser import SafetyScanParser

# Find the factory dictionary and add:
'Safety Scan': SafetyScanParser(),
```

### Step 5: Restart DefectDojo

```bash
# Exit container
exit

# Restart services
docker-compose restart uwsgi celerybeat celeryworker
# or
docker restart <container-names>
```

### Step 6: Run Migrations (if needed)

```bash
docker exec -it <uwsgi-container> python manage.py migrate
```

## Option 3: Use Alternative Format (Quick Workaround)

Use **Trivy** instead, which has native DefectDojo support:

```bash
# Install Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin

# Scan
trivy fs --format json --output trivy-results.json ./simple-web-flask

# Upload
python3 upload_to_defectdojo.py \
  -f trivy-results.json \
  -e 1 \
  -u http://108.136.165.202:8080 \
  -t c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d \
  -s "Trivy Scan"
```

## Verification

After adding the parser, verify it works:

```bash
# Check available parsers
curl -s "http://108.136.165.202:8080/api/v2/test_types/?name=Safety" \
  -H "Authorization: Token YOUR_TOKEN"

# Try upload
python3 upload_to_defectdojo.py \
  -f safety-scan-clean.json \
  -e 1 \
  -u http://108.136.165.202:8080 \
  -t YOUR_TOKEN \
  -s "Safety Scan"
```

## Need Help?

- DefectDojo Docs: https://documentation.defectdojo.com/
- Safety Parser Example: https://github.com/DefectDojo/django-DefectDojo/tree/master/dojo/tools
- DefectDojo GitHub: https://github.com/DefectDojo/django-DefectDojo
