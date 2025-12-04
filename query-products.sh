#!/bin/bash
# Query DefectDojo Products via CLI

DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

case "${1:-list}" in
  list|all)
    echo "📦 All Products:"
    echo ""
    curl -s "${DD_URL}/api/v2/products/" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "
import json, sys
data = json.load(sys.stdin)
products = data.get('results', [])

for p in products:
    print(f'ID: {p[\"id\"]:3} | Name: {p[\"name\"]:30} | Type: {p.get(\"prod_type\", \"N/A\")}')
    print(f'       Description: {p.get(\"description\", \"No description\")[:70]}')
    print()

print(f'Total: {data.get(\"count\", 0)} product(s)')
"
    ;;

  detail)
    if [ -z "$2" ]; then
      echo "Usage: $0 detail <product_id>"
      exit 1
    fi
    echo "📦 Product Details (ID: $2):"
    echo ""
    curl -s "${DD_URL}/api/v2/products/$2/" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "
import json, sys
p = json.load(sys.stdin)

print(f'ID: {p.get(\"id\")}')
print(f'Name: {p.get(\"name\")}')
print(f'Description: {p.get(\"description\", \"N/A\")}')
print(f'Product Type: {p.get(\"prod_type\", \"N/A\")}')
print(f'Created: {p.get(\"created\", \"N/A\")}')
print(f'Engagements: {p.get(\"engagement_count\", 0)}')
print(f'Findings: {p.get(\"findings_count\", 0)}')
"
    ;;

  search)
    if [ -z "$2" ]; then
      echo "Usage: $0 search <product_name>"
      exit 1
    fi
    echo "🔍 Searching for: $2"
    echo ""
    curl -s "${DD_URL}/api/v2/products/?name__icontains=$2" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "
import json, sys
data = json.load(sys.stdin)
products = data.get('results', [])

if not products:
    print('No products found')
else:
    for p in products:
        print(f'ID: {p[\"id\"]:3} | Name: {p[\"name\"]}')
"
    ;;

  names)
    echo "📋 Product Names (for GitHub workflow):"
    echo ""
    curl -s "${DD_URL}/api/v2/products/" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "
import json, sys
data = json.load(sys.stdin)
products = data.get('results', [])

print('Use these exact names in workflow:')
print()
for p in products:
    print(f'  product=\"{p[\"name\"]}\"  # ID: {p[\"id\"]}')
"
    ;;

  json)
    echo "Getting all products as JSON..."
    curl -s "${DD_URL}/api/v2/products/" \
      -H "Authorization: Token ${DD_TOKEN}"
    ;;

  help|*)
    echo "Usage: $0 [command] [args]"
    echo ""
    echo "Commands:"
    echo "  list, all         - List all products (default)"
    echo "  detail <id>       - Get product details by ID"
    echo "  search <name>     - Search products by name"
    echo "  names             - List product names for workflows"
    echo "  json              - Get raw JSON output"
    echo "  help              - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                      # List all"
    echo "  $0 detail 1             # Get product ID 1"
    echo "  $0 search Trial         # Search for 'Trial'"
    echo "  $0 names                # Show names for workflow"
    ;;
esac
