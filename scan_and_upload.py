#!/usr/bin/env python3
"""
Automated Safety Scan and DefectDojo Upload Script
Runs Safety scan, generates JSON output, and uploads to DefectDojo
"""

import argparse
import json
import subprocess
import sys
from pathlib import Path
from datetime import datetime
from typing import Optional
import os


def load_config(config_file: str = 'defectdojo_config.json') -> dict:
    """Load configuration from JSON file"""
    if Path(config_file).exists():
        with open(config_file, 'r') as f:
            return json.load(f)
    return {}


def run_safety_scan(
    target_dir: str = '.',
    output_file: str = 'safety-scan-results.json'
) -> tuple[bool, str]:
    """
    Run Safety scan and generate JSON output

    Args:
        target_dir: Directory to scan
        output_file: Output JSON file path

    Returns:
        Tuple of (success, output_file_path)
    """
    print(f"🔍 Running Safety scan on: {target_dir}")

    cmd = [
        'safety',
        'scan',
        '--output', 'json',
        '--save-json', output_file
    ]

    try:
        # Run Safety scan
        result = subprocess.run(
            cmd,
            cwd=target_dir,
            capture_output=True,
            text=True
        )

        # Safety may return non-zero if vulnerabilities found
        # Check if JSON file was created
        output_path = Path(target_dir) / output_file
        if output_path.exists():
            print(f"✅ Safety scan completed: {output_path}")

            # Parse JSON to show summary
            try:
                with open(output_path, 'r') as f:
                    # Read the file and find JSON content
                    content = f.read()
                    # Find the JSON part (after the text output)
                    json_start = content.find('{')
                    if json_start >= 0:
                        json_content = content[json_start:]
                        data = json.loads(json_content)

                        # Extract vulnerability count
                        vuln_count = 0
                        for project in data.get('scan_results', {}).get('projects', []):
                            for file_info in project.get('files', []):
                                for dep in file_info.get('results', {}).get('dependencies', []):
                                    for spec in dep.get('specifications', []):
                                        vulns = spec.get('vulnerabilities', {}).get('known_vulnerabilities', [])
                                        # Count non-ignored vulnerabilities
                                        vuln_count += sum(1 for v in vulns if not v.get('ignored'))

                        print(f"📊 Found {vuln_count} active vulnerabilities")
            except Exception as e:
                print(f"⚠️  Could not parse scan results: {e}")

            return True, str(output_path)
        else:
            print(f"❌ Safety scan failed to generate output file")
            print(f"STDOUT: {result.stdout}")
            print(f"STDERR: {result.stderr}")
            return False, ""

    except FileNotFoundError:
        print("❌ Safety command not found. Please install: pip install safety")
        return False, ""
    except Exception as e:
        print(f"❌ Error running Safety scan: {e}")
        return False, ""


def extract_json_from_safety_output(file_path: str) -> bool:
    """
    Extract pure JSON from Safety output file (removes text output at beginning)

    Args:
        file_path: Path to Safety output file

    Returns:
        True if successful
    """
    try:
        with open(file_path, 'r') as f:
            content = f.read()

        # Find where JSON starts
        json_start = content.find('{')
        if json_start >= 0:
            json_content = content[json_start:]

            # Verify it's valid JSON
            json.loads(json_content)

            # Write back pure JSON
            with open(file_path, 'w') as f:
                f.write(json_content)

            print(f"✅ Extracted pure JSON to {file_path}")
            return True
    except Exception as e:
        print(f"⚠️  Could not extract JSON: {e}")
        return False


def upload_to_defectdojo(
    file_path: str,
    defectdojo_url: str,
    api_token: str,
    engagement_id: int,
    verify_ssl: bool = True
) -> bool:
    """
    Upload scan results to DefectDojo

    Args:
        file_path: Path to scan results JSON
        defectdojo_url: DefectDojo base URL
        api_token: API token
        engagement_id: Engagement ID
        verify_ssl: Verify SSL certificates

    Returns:
        True if successful
    """
    print(f"\n📤 Uploading to DefectDojo...")

    cmd = [
        'python3',
        'upload_to_defectdojo.py',
        '-f', file_path,
        '-e', str(engagement_id),
        '-u', defectdojo_url,
        '-t', api_token,
        '-s', 'Safety Scan'
    ]

    if not verify_ssl:
        cmd.append('--no-verify-ssl')

    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(result.stdout)
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Upload failed:")
        print(e.stdout)
        print(e.stderr)
        return False


def main():
    parser = argparse.ArgumentParser(
        description='Run Safety scan and upload results to DefectDojo',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Scan current directory and upload
  python scan_and_upload.py -d ./simple-web-flask -u https://dd.example.com -t TOKEN -e 123

  # Use config file
  python scan_and_upload.py -c defectdojo_config.json -d ./simple-web-flask

  # Scan only (no upload)
  python scan_and_upload.py -d ./simple-web-flask --scan-only
        """
    )

    parser.add_argument('-d', '--directory', default='.', help='Directory to scan')
    parser.add_argument('-o', '--output', default='safety-scan-results.json', help='Output JSON file')
    parser.add_argument('-c', '--config', help='Config file with DefectDojo settings')

    # DefectDojo arguments
    parser.add_argument('-u', '--url', help='DefectDojo URL')
    parser.add_argument('-t', '--token', help='API token')
    parser.add_argument('-e', '--engagement-id', type=int, help='Engagement ID')
    parser.add_argument('--no-verify-ssl', action='store_true', help='Disable SSL verification')

    # Options
    parser.add_argument('--scan-only', action='store_true', help='Only run scan, do not upload')
    parser.add_argument('--upload-only', help='Skip scan, upload existing file')

    args = parser.parse_args()

    # Load config if provided
    config = {}
    if args.config:
        config = load_config(args.config)
        print(f"📋 Loaded config from: {args.config}")

    # Merge config with command line args (CLI args take precedence)
    defectdojo_url = args.url or config.get('defectdojo_url')
    api_token = args.token or config.get('api_token')
    engagement_id = args.engagement_id or config.get('engagement_id')
    verify_ssl = not (args.no_verify_ssl or config.get('no_verify_ssl', False))

    success = True
    scan_file = args.output

    # Run scan unless upload-only mode
    if not args.upload_only:
        success, scan_file = run_safety_scan(args.directory, args.output)
        if success:
            # Extract pure JSON
            extract_json_from_safety_output(scan_file)

    else:
        scan_file = args.upload_only
        if not Path(scan_file).exists():
            print(f"❌ File not found: {scan_file}")
            sys.exit(1)

    # Upload to DefectDojo unless scan-only mode
    if success and not args.scan_only:
        if not all([defectdojo_url, api_token, engagement_id]):
            print("\n❌ Missing DefectDojo configuration!")
            print("Provide either:")
            print("  1. -u URL -t TOKEN -e ENGAGEMENT_ID")
            print("  2. -c config_file.json")
            print("\nScan results saved to:", scan_file)
            sys.exit(1)

        success = upload_to_defectdojo(
            scan_file,
            defectdojo_url,
            api_token,
            engagement_id,
            verify_ssl
        )

    if success:
        print("\n✅ Process completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ Process failed")
        sys.exit(1)


if __name__ == '__main__':
    main()
