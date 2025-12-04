# Manual Safety Parser Installation (Step by Step)

If you're getting permission denied, follow these manual steps:

## Option A: SSH to DefectDojo Server (Recommended)

### Step 1: Copy Parser to Server

From your current machine:
```bash
scp -r safety_parser root@108.136.165.202:/tmp/
```

### Step 2: SSH to Server

```bash
ssh root@108.136.165.202
```

### Step 3: Find DefectDojo Container

```bash
docker ps | grep defectdojo
# Or
docker ps | grep uwsgi
```

Look for container with name like: `defectdojo-uwsgi-1` or `defectdojo_uwsgi_1`

### Step 4: Copy Parser to Container

```bash
# Replace CONTAINER_NAME with actual container name
docker cp /tmp/safety_parser CONTAINER_NAME:/app/dojo/tools/safety_scan
```

Example:
```bash
docker cp /tmp/safety_parser defectdojo-uwsgi-1:/app/dojo/tools/safety_scan
```

### Step 5: Update factory.py

```bash
# Access container as root
docker exec -it --user root CONTAINER_NAME bash

# Backup factory.py
cp /app/dojo/tools/factory.py /app/dojo/tools/factory.py.backup

# Edit factory.py
vi /app/dojo/tools/factory.py
# Or use nano
nano /app/dojo/tools/factory.py
```

**Add these lines:**

1. **Add import** (around line 50-100 with other parser imports):
```python
from dojo.tools.safety_scan.parser import SafetyScanParser
```

2. **Add to factory dict** (around line 200-300 in the big dictionary):
```python
'Safety Scan': SafetyScanParser(),
```

Save and exit (`:wq` in vi, or `Ctrl+X` then `Y` in nano)

### Step 6: Restart Services

```bash
exit  # Exit container

# Restart DefectDojo
docker restart defectdojo-uwsgi-1
docker restart defectdojo-celerybeat-1 defectdojo-celeryworker-1

# Or restart all DefectDojo containers
docker ps --filter "name=defectdojo" --format "{{.Names}}" | xargs docker restart
```

### Step 7: Verify

```bash
# Check files exist
docker exec defectdojo-uwsgi-1 ls -la /app/dojo/tools/safety_scan/

# Should show:
# __init__.py
# parser.py
```

---

## Option B: Direct Container Access (If You Have Root Access)

If you can access the DefectDojo server:

```bash
# 1. SSH to server
ssh root@108.136.165.202

# 2. Access container as root
docker exec -it --user root CONTAINER_NAME bash

# 3. Create directory
mkdir -p /app/dojo/tools/safety_scan

# 4. Create files manually
cd /app/dojo/tools/safety_scan

# 5. Create __init__.py
cat > __init__.py << 'EOF'
# DefectDojo Safety Scan Parser
EOF

# 6. Create parser.py (use the content from safety_parser/parser.py)
vi parser.py
# Paste the full parser.py content here
```

Then follow steps 5-7 from Option A.

---

## Option C: Use Automated Script

If you have SSH access to the DefectDojo server:

```bash
chmod +x install_safety_parser_remote.sh
./install_safety_parser_remote.sh
```

This script will automatically:
- Copy files to server
- Find container
- Install parser
- Update factory.py
- Restart services

---

## Troubleshooting

### "Permission denied" when creating directory
- Use `docker exec -it --user root CONTAINER_NAME bash` to access as root
- Or use `docker cp` which doesn't require permissions inside container

### "Container not found"
```bash
# List all containers
docker ps -a

# Check DefectDojo is running
docker-compose ps  # if using docker-compose
```

### "Cannot modify factory.py"
```bash
# Access container as root
docker exec -it --user root CONTAINER_NAME bash

# Check file permissions
ls -la /app/dojo/tools/factory.py

# Fix permissions if needed
chmod 644 /app/dojo/tools/factory.py
```

### "Import error after restart"
```bash
# Check for syntax errors
docker exec CONTAINER_NAME python -c "from dojo.tools.safety_scan.parser import SafetyScanParser; print('OK')"

# Check logs
docker logs CONTAINER_NAME
```

---

## After Installation

Test the parser:
```bash
python3 upload-results.py \
  --host "108.136.165.202:8080" \
  --api_key "c5b84e31fcbeb1aaf7cda88d5dbe05ef8c9a8e1d" \
  --engagement_id 1 \
  --result_file "safety-scan-clean.json" \
  --scanner "Safety Scan" \
  --product_id 1 \
  --lead_id 1 \
  --environment "Development"
```

Expected output:
```
Status Code: 201
Successfully uploaded the results to Defect Dojo
```
