#!/bin/bash
# Install Safety Parser to Remote DefectDojo Server

echo "===================================="
echo "Safety Parser Remote Installation"
echo "===================================="
echo ""

# Configuration
DEFECTDOJO_HOST="108.136.165.202"
DEFECTDOJO_USER="root"  # Change this if needed
PARSER_DIR="/tmp/safety_parser"

echo "This script will:"
echo "1. Copy safety_parser/ to remote server"
echo "2. Find DefectDojo container"
echo "3. Copy parser into container"
echo "4. Update factory.py"
echo "5. Restart DefectDojo"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Step 1: Copy parser to remote server
echo ""
echo "Step 1: Copying parser files to server..."
scp -r safety_parser ${DEFECTDOJO_USER}@${DEFECTDOJO_HOST}:${PARSER_DIR}

if [ $? -ne 0 ]; then
    echo "❌ Failed to copy files. Check SSH access."
    exit 1
fi

echo "✅ Files copied to server"

# Step 2-5: SSH into server and install
echo ""
echo "Step 2-5: Installing parser on server..."

ssh ${DEFECTDOJO_USER}@${DEFECTDOJO_HOST} << 'ENDSSH'
#!/bin/bash

echo ""
echo "Finding DefectDojo container..."
UWSGI_CONTAINER=$(docker ps --filter "name=uwsgi" --filter "name=defectdojo" --format "{{.Names}}" | head -1)

if [ -z "$UWSGI_CONTAINER" ]; then
    UWSGI_CONTAINER=$(docker ps --filter "ancestor=defectdojo/defectdojo-django" --format "{{.Names}}" | head -1)
fi

if [ -z "$UWSGI_CONTAINER" ]; then
    echo "❌ DefectDojo container not found!"
    echo ""
    echo "Available containers:"
    docker ps --format "{{.Names}}"
    exit 1
fi

echo "✅ Found container: $UWSGI_CONTAINER"
echo ""

# Copy parser to container
echo "Copying parser to container..."
docker cp /tmp/safety_parser $UWSGI_CONTAINER:/app/dojo/tools/safety_scan

if [ $? -ne 0 ]; then
    echo "❌ Failed to copy to container"
    exit 1
fi

echo "✅ Parser copied to container"
echo ""

# Update factory.py
echo "Updating factory.py..."
docker exec $UWSGI_CONTAINER bash -c "
# Backup factory.py
cp /app/dojo/tools/factory.py /app/dojo/tools/factory.py.backup

# Check if import already exists
if grep -q 'from dojo.tools.safety_scan.parser import SafetyScanParser' /app/dojo/tools/factory.py; then
    echo '⚠️  Import already exists in factory.py'
else
    # Add import after other parser imports
    sed -i '/from dojo.tools.*import/a from dojo.tools.safety_scan.parser import SafetyScanParser' /app/dojo/tools/factory.py
    echo '✅ Added import to factory.py'
fi

# Check if parser already registered
if grep -q \"'Safety Scan': SafetyScanParser()\" /app/dojo/tools/factory.py; then
    echo '⚠️  Parser already registered in factory.py'
else
    # Add parser to factory dict - find the last parser entry and add after it
    sed -i \"/^[[:space:]]*'.*':[[:space:]]*.*Parser()/a\\    'Safety Scan': SafetyScanParser(),\" /app/dojo/tools/factory.py
    echo '✅ Registered parser in factory.py'
fi
"

echo ""
echo "Restarting DefectDojo services..."
docker restart $UWSGI_CONTAINER

# Also restart celery if it exists
CELERY_CONTAINERS=$(docker ps --filter "name=celery" --filter "name=defectdojo" --format "{{.Names}}")
if [ ! -z "$CELERY_CONTAINERS" ]; then
    for container in $CELERY_CONTAINERS; do
        echo "Restarting $container..."
        docker restart $container
    done
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Waiting for services to start (10 seconds)..."
sleep 10

# Verify
echo ""
echo "Verifying installation..."
docker exec $UWSGI_CONTAINER ls -la /app/dojo/tools/safety_scan/

ENDSSH

echo ""
echo "===================================="
echo "Installation Complete!"
echo "===================================="
echo ""
echo "Test the parser with:"
echo "python3 upload-results.py \\"
echo "  --host \"108.136.165.202:8080\" \\"
echo "  --api_key \"c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d\" \\"
echo "  --engagement_id 1 \\"
echo "  --result_file \"safety-scan-clean.json\" \\"
echo "  --scanner \"Safety Scan\" \\"
echo "  --product_id 1 \\"
echo "  --lead_id 1 \\"
echo "  --environment \"Development\""
