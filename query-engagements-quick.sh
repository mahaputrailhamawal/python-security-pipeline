#!/bin/bash
# Quick DefectDojo Engagement Queries

DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

echo "================================"
echo "DefectDojo Engagement Query"
echo "================================"
echo ""

case "${1:-list}" in
  list|all)
    echo "📋 All Engagements:"
    curl -s "${DD_URL}/api/v2/engagements/" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; [print(f'ID: {e[\"id\"]:3} | {e[\"name\"]:25} | {e[\"status\"]:15} | Active: {\"✅\" if e.get(\"active\") else \"❌\"}') for e in json.load(sys.stdin)['results']]"
    ;;

  active)
    echo "✅ Active Engagements:"
    curl -s "${DD_URL}/api/v2/engagements/?active=true" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; [print(f'ID: {e[\"id\"]:3} | {e[\"name\"]:25} | {e[\"status\"]}') for e in json.load(sys.stdin)['results']]"
    ;;

  inactive)
    echo "❌ Inactive Engagements:"
    curl -s "${DD_URL}/api/v2/engagements/?active=false" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; [print(f'ID: {e[\"id\"]:3} | {e[\"name\"]:25} | {e[\"status\"]}') for e in json.load(sys.stdin)['results']]"
    ;;

  tests)
    if [ -z "$2" ]; then
      echo "Usage: $0 tests <engagement_id>"
      exit 1
    fi
    echo "📝 Tests for Engagement ID: $2"
    curl -s "${DD_URL}/api/v2/tests/?engagement=$2" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "import json,sys; [print(f'Test ID: {t[\"id\"]:3} | Type: {t[\"test_type_name\"]:25} | Date: {t[\"target_start\"]}') for t in json.load(sys.stdin)['results']]"
    ;;

  count)
    echo "📊 Engagement Statistics:"
    curl -s "${DD_URL}/api/v2/engagements/" \
      -H "Authorization: Token ${DD_TOKEN}" | \
      python3 -c "
import json, sys
data = json.load(sys.stdin)
total = data.get('count', 0)
results = data.get('results', [])
active = sum(1 for e in results if e.get('active'))
statuses = {}
for e in results:
    s = e.get('status', 'Unknown')
    statuses[s] = statuses.get(s, 0) + 1

print(f'Total: {total}')
print(f'Active: {active}')
print(f'Inactive: {total - active}')
print('\nBy Status:')
for status, count in sorted(statuses.items()):
    print(f'  {status}: {count}')
"
    ;;

  help|*)
    echo "Usage: $0 [command] [args]"
    echo ""
    echo "Commands:"
    echo "  list, all     - List all engagements (default)"
    echo "  active        - List only active engagements"
    echo "  inactive      - List only inactive engagements"
    echo "  tests <id>    - List tests for engagement ID"
    echo "  count         - Show engagement statistics"
    echo "  help          - Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                  # List all"
    echo "  $0 active           # Active only"
    echo "  $0 tests 3          # Tests for engagement 3"
    echo "  $0 count            # Statistics"
    ;;
esac
