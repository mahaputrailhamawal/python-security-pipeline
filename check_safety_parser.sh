#!/bin/bash
# Check if Safety parser exists in DefectDojo installation

echo "Checking for Safety parser in DefectDojo..."
echo ""

# Try to find the DefectDojo container
CONTAINERS=$(docker ps --filter "name=defectdojo" --format "{{.Names}}" 2>/dev/null)

if [ -z "$CONTAINERS" ]; then
    echo "❌ No DefectDojo containers found"
    echo ""
    echo "Please run this command manually on your DefectDojo server:"
    echo "  docker exec -it <defectdojo-uwsgi-container> ls -la /app/dojo/tools/safety_scan/"
    exit 1
fi

echo "Found DefectDojo containers:"
echo "$CONTAINERS"
echo ""

# Check each container for the parser
for container in $CONTAINERS; do
    echo "Checking container: $container"

    # Check if safety_scan parser directory exists
    if docker exec $container test -d /app/dojo/tools/safety_scan 2>/dev/null; then
        echo "✅ Safety parser found in $container!"
        docker exec $container ls -la /app/dojo/tools/safety_scan/
        exit 0
    fi
done

echo "❌ Safety parser not found in any container"
echo ""
echo "You need to add the Safety parser code to DefectDojo"
