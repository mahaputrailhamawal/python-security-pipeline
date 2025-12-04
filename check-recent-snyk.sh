#!/bin/bash
DD_URL="http://16.78.42.164:8080"
DD_TOKEN="c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d"

echo "Recent Snyk Tests (Engagement 3):"
echo "================================"

for TEST_ID in 64 66 68 70 72; do
  COUNT=$(curl -s "${DD_URL}/api/v2/findings/?test=${TEST_ID}" \
    -H "Authorization: Token ${DD_TOKEN}" | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('count', 0))")
  echo "Test $TEST_ID: $COUNT findings"
done
