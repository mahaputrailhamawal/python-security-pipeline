#!/bin/bash
# Script to add Safety Scan parser to DefectDojo

echo "Adding Safety Scan parser to DefectDojo..."

# Add Tool Type via API
curl -X POST "http://108.136.165.202:8080/api/v2/tool_types/" \
  -H "Authorization: Token c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Safety Scan",
    "description": "Safety CLI vulnerability scanner for Python dependencies"
  }' | python3 -c "
import json
import sys
try:
    data = json.load(sys.stdin)
    if 'id' in data:
        print('✅ Safety Scan parser added successfully!')
        print(f'   ID: {data[\"id\"]}')
        print(f'   Name: {data[\"name\"]}')
    else:
        print('Response:', data)
except Exception as e:
    print(f'❌ Error: {e}')
    print(sys.stdin.read())
"

echo ""
echo "Verifying..."
curl -s -X GET "http://108.136.165.202:8080/api/v2/tool_types/?name=Safety" \
  -H "Authorization: Token c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d" | python3 -c "
import json
import sys
data = json.load(sys.stdin)
if data.get('count', 0) > 0:
    print('✅ Safety Scan parser is now available!')
else:
    print('❌ Parser not found. Check DefectDojo logs.')
"
