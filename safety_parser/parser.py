"""
DefectDojo Parser for Safety CLI JSON Output
Supports Safety v3.x JSON format
"""

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
        """
        Parse Safety JSON and create findings
        """
        data = json.load(file)
        findings = []

        # Parse Safety 3.x JSON format
        scan_results = data.get('scan_results', {})
        projects = scan_results.get('projects', [])

        for project in projects:
            project_location = project.get('location', '')
            files = project.get('files', [])

            for file_info in files:
                file_location = file_info.get('location', 'Unknown')
                file_type = file_info.get('type', '')

                dependencies = file_info.get('results', {}).get('dependencies', [])

                for dependency in dependencies:
                    package_name = dependency.get('name', 'Unknown')
                    specifications = dependency.get('specifications', [])

                    for spec in specifications:
                        raw_spec = spec.get('raw', '')

                        # Extract version from specification
                        version = self._extract_version(raw_spec)

                        # Get vulnerabilities
                        vuln_info = spec.get('vulnerabilities', {})
                        known_vulns = vuln_info.get('known_vulnerabilities', [])

                        for vuln in known_vulns:
                            # Skip ignored vulnerabilities
                            if vuln.get('ignored'):
                                continue

                            # Create finding from vulnerability
                            finding = self._create_finding(
                                vuln=vuln,
                                package_name=package_name,
                                version=version,
                                file_location=file_location,
                                file_type=file_type,
                                remediation_info=vuln_info.get('remediation'),
                                test=test
                            )

                            if finding:
                                findings.append(finding)

        return findings

    def _extract_version(self, raw_spec):
        """Extract version from package specification"""
        if "==" in raw_spec:
            # Format: "package (==1.2.3) ; python_version..."
            version = raw_spec.split("==")[1].split(")")[0].split(";")[0].strip()
            return version
        return "unknown"

    def _create_finding(self, vuln, package_name, version, file_location,
                       file_type, remediation_info, test):
        """Create a Finding object from vulnerability data"""

        vuln_id = str(vuln.get('id', 'UNKNOWN'))
        vuln_spec = vuln.get('vulnerable_spec', '')

        # Build title
        title = f"{package_name} ({version}) - Safety ID {vuln_id}"

        # Build description
        description = f"""**Package:** {package_name}
**Current Version:** {version}
**Vulnerable Specification:** {vuln_spec}
**File:** {file_location}
**File Type:** {file_type}
**Safety ID:** {vuln_id}
"""

        # Determine severity (Safety doesn't provide this, default to Medium)
        severity = "Medium"

        # Build mitigation message
        mitigation = "Update the package to a secure version."
        if remediation_info:
            recommended = remediation_info.get('recommended')
            closest_secure = remediation_info.get('closest_secure')

            if recommended:
                mitigation = f"Update {package_name} from {version} to {recommended}"
            elif closest_secure:
                mitigation = f"Update {package_name} from {version} to {closest_secure}"

        # Build references
        references = f"Safety ID: {vuln_id}\n"
        references += f"More info: https://data.safetycli.com/vulnerabilities/{vuln_id}/"

        # Create Finding
        finding = Finding(
            title=title,
            test=test,
            severity=severity,
            description=description,
            mitigation=mitigation,
            references=references,
            file_path=file_location,
            component_name=package_name,
            component_version=version,
            vuln_id_from_tool=vuln_id,
            unique_id_from_tool=f"safety_{package_name}_{version}_{vuln_id}",
            static_finding=True,
            dynamic_finding=False,
            verified=True,  # Safety findings are verified
            active=True,
        )

        return finding
