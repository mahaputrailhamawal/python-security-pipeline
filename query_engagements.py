#!/usr/bin/env python3
"""
Query DefectDojo Engagements
"""

import requests
import json
from datetime import datetime

# Configuration
DD_URL = "http://16.78.42.164:8080"
DD_TOKEN = "c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

headers = {"Authorization": f"Token {DD_TOKEN}"}

def get_engagements(active=None, product=None, status=None):
    """Get engagements with optional filters"""
    url = f"{DD_URL}/api/v2/engagements/"
    params = {}

    if active is not None:
        params['active'] = str(active).lower()
    if product:
        params['product'] = product
    if status:
        params['status'] = status

    response = requests.get(url, headers=headers, params=params)

    if response.status_code == 200:
        return response.json()
    else:
        print(f"Error: {response.status_code} - {response.text}")
        return None

def display_engagements(data):
    """Display engagements in a formatted way"""
    if not data:
        return

    engagements = data.get('results', [])
    total = data.get('count', 0)

    print(f"\n{'='*80}")
    print(f"📊 Total Engagements: {total}")
    print(f"{'='*80}\n")

    for eng in engagements:
        print(f"ID: {eng['id']}")
        print(f"Name: {eng['name']}")
        print(f"Product: {eng['product']}")
        print(f"Status: {eng['status']}")
        print(f"Active: {'✅' if eng.get('active', False) else '❌'}")
        print(f"Target: {eng['target_start']} → {eng['target_end']}")
        print(f"Lead: {eng.get('lead', 'N/A')}")
        print(f"Tests: {eng.get('test_count', 0)}")
        print(f"Created: {eng.get('created', 'N/A')}")
        print(f"-" * 80)

def get_engagement_tests(engagement_id):
    """Get all tests for a specific engagement"""
    url = f"{DD_URL}/api/v2/tests/?engagement={engagement_id}"
    response = requests.get(url, headers=headers)

    if response.status_code == 200:
        return response.json()
    return None

if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description='Query DefectDojo Engagements')
    parser.add_argument('--active', action='store_true', help='Show only active engagements')
    parser.add_argument('--product', type=int, help='Filter by product ID')
    parser.add_argument('--status', help='Filter by status (e.g., "In Progress")')
    parser.add_argument('--engagement-id', type=int, help='Get specific engagement details')
    parser.add_argument('--show-tests', action='store_true', help='Show tests for each engagement')

    args = parser.parse_args()

    if args.engagement_id:
        # Get specific engagement
        url = f"{DD_URL}/api/v2/engagements/{args.engagement_id}/"
        response = requests.get(url, headers=headers)
        if response.status_code == 200:
            data = {'results': [response.json()], 'count': 1}
            display_engagements(data)

            if args.show_tests:
                tests = get_engagement_tests(args.engagement_id)
                if tests:
                    print(f"\n📝 Tests for Engagement {args.engagement_id}:")
                    for test in tests.get('results', []):
                        print(f"  - Test ID: {test['id']} | Type: {test['test_type_name']} | Date: {test['target_start']}")
    else:
        # Query with filters
        data = get_engagements(
            active=True if args.active else None,
            product=args.product,
            status=args.status
        )
        display_engagements(data)

        if args.show_tests and data:
            for eng in data.get('results', []):
                tests = get_engagement_tests(eng['id'])
                if tests and tests.get('count', 0) > 0:
                    print(f"\n📝 Tests for '{eng['name']}' (ID: {eng['id']}):")
                    for test in tests.get('results', []):
                        print(f"  - Test ID: {test['id']} | Type: {test['test_type_name']} | Findings: {test.get('finding_count', 0)}")
                    print()
