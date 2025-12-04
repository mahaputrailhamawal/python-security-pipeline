#!/usr/bin/env python3
"""
Convert Safety scan JSON to OSV Scanner format for DefectDojo import
"""

import json
import sys
from pathlib import Path


def convert_safety_to_osv(safety_file: str, output_file: str = "osv-results.json"):
    """Convert Safety JSON to OSV Scanner format"""

    with open(safety_file, 'r') as f:
        safety_data = json.load(f)

    osv_results = {
        "results": []
    }

    # Extract vulnerabilities from Safety scan
    for project in safety_data.get('scan_results', {}).get('projects', []):
        for file_info in project.get('files', []):
            file_location = file_info.get('location', '')

            for dep in file_info.get('results', {}).get('dependencies', []):
                package_name = dep.get('name', '')

                for spec in dep.get('specifications', []):
                    raw_spec = spec.get('raw', '')

                    # Extract version from spec (e.g., "jinja2 (==3.1.4)")
                    version = "unknown"
                    if "==" in raw_spec:
                        version = raw_spec.split("==")[1].split(")")[0].strip()

                    vulnerabilities = spec.get('vulnerabilities', {}).get('known_vulnerabilities', [])

                    for vuln in vulnerabilities:
                        # Skip ignored vulnerabilities
                        if vuln.get('ignored'):
                            continue

                        vuln_id = vuln.get('id', 'UNKNOWN')

                        # Create OSV-style package entry
                        package_entry = {
                            "source": {
                                "path": file_location,
                                "type": "lockfile"
                            },
                            "package": {
                                "name": package_name,
                                "version": version,
                                "ecosystem": "PyPI"
                            },
                            "vulnerabilities": [
                                {
                                    "id": f"SAFETY-{vuln_id}",
                                    "aliases": [f"SAFETY-{vuln_id}"],
                                }
                            ]
                        }

                        osv_results["results"].append(package_entry)

    # Write OSV format
    with open(output_file, 'w') as f:
        json.dump(osv_results, f, indent=2)

    vuln_count = len(osv_results["results"])
    print(f"✅ Converted {vuln_count} vulnerabilities to OSV format")
    print(f"📄 Output: {output_file}")

    return output_file


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 convert_safety_to_osv.py <safety-json-file> [output-file]")
        print("\nExample:")
        print("  python3 convert_safety_to_osv.py safety-scan-clean.json osv-results.json")
        sys.exit(1)

    safety_file = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else "osv-results.json"

    if not Path(safety_file).exists():
        print(f"❌ File not found: {safety_file}")
        sys.exit(1)

    convert_safety_to_osv(safety_file, output_file)
