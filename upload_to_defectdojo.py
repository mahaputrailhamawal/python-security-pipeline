#!/usr/bin/env python3
"""
DefectDojo Upload Script for Safety Scan Results
Uploads Safety scan JSON reports to DefectDojo via API
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime
import requests
from typing import Optional


class DefectDojoUploader:
    def __init__(self, base_url: str, api_token: str, verify_ssl: bool = True):
        """
        Initialize DefectDojo uploader

        Args:
            base_url: DefectDojo base URL (e.g., https://defectdojo.example.com)
            api_token: API token for authentication
            verify_ssl: Whether to verify SSL certificates
        """
        self.base_url = base_url.rstrip('/')
        self.api_token = api_token
        self.verify_ssl = verify_ssl
        self.headers = {
            'Authorization': f'Token {api_token}'
        }

    def upload_scan(
        self,
        file_path: str,
        engagement_id: int,
        scan_type: str = "Safety Scan",
        verified: bool = True,
        active: bool = True,
        scan_date: Optional[str] = None,
        close_old_findings: bool = False,
        push_to_jira: bool = False
    ) -> dict:
        """
        Upload scan results to DefectDojo

        Args:
            file_path: Path to the Safety scan JSON file
            engagement_id: DefectDojo engagement ID
            scan_type: Type of scan (default: "Safety Scan")
            verified: Mark findings as verified
            active: Mark findings as active
            scan_date: Scan date (default: today)
            close_old_findings: Close old findings
            push_to_jira: Push findings to JIRA

        Returns:
            Response from DefectDojo API
        """
        if not scan_date:
            scan_date = datetime.now().strftime('%Y-%m-%d')

        url = f"{self.base_url}/api/v2/import-scan/"

        with open(file_path, 'rb') as f:
            files = {'file': (Path(file_path).name, f, 'application/json')}
            data = {
                'engagement': engagement_id,
                'scan_type': scan_type,
                'verified': str(verified).lower(),
                'active': str(active).lower(),
                'scan_date': scan_date,
                'close_old_findings': str(close_old_findings).lower(),
                'push_to_jira': str(push_to_jira).lower(),
            }

            print(f"Uploading {file_path} to DefectDojo...")
            print(f"Engagement ID: {engagement_id}")
            print(f"Scan Type: {scan_type}")

            response = requests.post(
                url,
                headers=self.headers,
                files=files,
                data=data,
                verify=self.verify_ssl
            )

        if response.status_code in [200, 201]:
            print("✅ Upload successful!")
            result = response.json()
            print(f"Test ID: {result.get('test')}")
            print(f"Findings: {result.get('statistics', {})}")
            return result
        else:
            print(f"❌ Upload failed: {response.status_code}")
            print(f"Response: {response.text}")
            response.raise_for_status()

    def list_engagements(self, product_id: Optional[int] = None, limit: int = 10) -> list:
        """
        List available engagements

        Args:
            product_id: Filter by product ID
            limit: Maximum number of results

        Returns:
            List of engagements
        """
        url = f"{self.base_url}/api/v2/engagements/"
        params = {'limit': limit}
        if product_id:
            params['product'] = product_id

        response = requests.get(
            url,
            headers=self.headers,
            params=params,
            verify=self.verify_ssl
        )

        if response.status_code == 200:
            return response.json().get('results', [])
        else:
            print(f"Failed to fetch engagements: {response.status_code}")
            return []

    def create_engagement(
        self,
        product_id: int,
        name: str,
        description: str = "",
        target_start: Optional[str] = None,
        target_end: Optional[str] = None
    ) -> dict:
        """
        Create a new engagement

        Args:
            product_id: Product ID
            name: Engagement name
            description: Engagement description
            target_start: Start date (YYYY-MM-DD)
            target_end: End date (YYYY-MM-DD)

        Returns:
            Created engagement details
        """
        url = f"{self.base_url}/api/v2/engagements/"

        if not target_start:
            target_start = datetime.now().strftime('%Y-%m-%d')
        if not target_end:
            target_end = datetime.now().strftime('%Y-%m-%d')

        data = {
            'product': product_id,
            'name': name,
            'description': description,
            'target_start': target_start,
            'target_end': target_end,
            'status': 'In Progress'
        }

        response = requests.post(
            url,
            headers=self.headers,
            json=data,
            verify=self.verify_ssl
        )

        if response.status_code in [200, 201]:
            print(f"✅ Engagement created: {name}")
            return response.json()
        else:
            print(f"❌ Failed to create engagement: {response.status_code}")
            print(f"Response: {response.text}")
            response.raise_for_status()


def main():
    parser = argparse.ArgumentParser(
        description='Upload Safety scan results to DefectDojo',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Upload scan results
  python upload_to_defectdojo.py -f safety-results.json -e 123 -u https://dd.example.com -t YOUR_TOKEN

  # List engagements
  python upload_to_defectdojo.py --list-engagements -u https://dd.example.com -t YOUR_TOKEN

  # Create new engagement
  python upload_to_defectdojo.py --create-engagement -p 5 -n "Q4 Security Scan" -u https://dd.example.com -t YOUR_TOKEN
        """
    )

    # Common arguments
    parser.add_argument('-u', '--url', required=True, help='DefectDojo URL')
    parser.add_argument('-t', '--token', required=True, help='API token')
    parser.add_argument('--no-verify-ssl', action='store_true', help='Disable SSL verification')

    # Upload arguments
    parser.add_argument('-f', '--file', help='Safety scan JSON file')
    parser.add_argument('-e', '--engagement-id', type=int, help='Engagement ID')
    parser.add_argument('-s', '--scan-type', default='Safety Scan', help='Scan type (default: Safety Scan)')
    parser.add_argument('--scan-date', help='Scan date (YYYY-MM-DD)')
    parser.add_argument('--close-old-findings', action='store_true', help='Close old findings')
    parser.add_argument('--push-to-jira', action='store_true', help='Push to JIRA')

    # Listing arguments
    parser.add_argument('--list-engagements', action='store_true', help='List engagements')
    parser.add_argument('-p', '--product-id', type=int, help='Product ID for filtering')

    # Creation arguments
    parser.add_argument('--create-engagement', action='store_true', help='Create new engagement')
    parser.add_argument('-n', '--name', help='Engagement name')
    parser.add_argument('-d', '--description', default='', help='Engagement description')

    args = parser.parse_args()

    uploader = DefectDojoUploader(
        base_url=args.url,
        api_token=args.token,
        verify_ssl=not args.no_verify_ssl
    )

    try:
        if args.list_engagements:
            engagements = uploader.list_engagements(product_id=args.product_id)
            print(f"\nFound {len(engagements)} engagement(s):")
            for eng in engagements:
                print(f"  ID: {eng['id']} - {eng['name']} (Product: {eng['product']})")

        elif args.create_engagement:
            if not args.product_id or not args.name:
                print("Error: --product-id and --name are required for creating engagement")
                sys.exit(1)

            engagement = uploader.create_engagement(
                product_id=args.product_id,
                name=args.name,
                description=args.description
            )
            print(f"Created engagement ID: {engagement['id']}")

        elif args.file and args.engagement_id:
            result = uploader.upload_scan(
                file_path=args.file,
                engagement_id=args.engagement_id,
                scan_type=args.scan_type,
                scan_date=args.scan_date,
                close_old_findings=args.close_old_findings,
                push_to_jira=args.push_to_jira
            )
        else:
            parser.print_help()
            print("\nError: Either provide --file and --engagement-id, or use --list-engagements/--create-engagement")
            sys.exit(1)

    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {e}")
        sys.exit(1)
    except FileNotFoundError as e:
        print(f"❌ File not found: {e}")
        sys.exit(1)


if __name__ == '__main__':
    main()
