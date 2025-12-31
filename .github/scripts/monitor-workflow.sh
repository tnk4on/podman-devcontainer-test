#!/bin/bash
# Monitor GitHub Actions workflow run progress

set -e

RUN_ID="$1"
if [ -z "$RUN_ID" ]; then
  # Get latest run if no ID provided
  RUN_ID=$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId' 2>/dev/null || echo "")
  if [ -z "$RUN_ID" ]; then
    echo "Error: No workflow run found"
    exit 1
  fi
  echo "Using latest run: $RUN_ID"
fi

echo "=== Monitoring workflow run: $RUN_ID ==="
echo "Press Ctrl+C to stop monitoring"
echo ""

START_TIME=$(date +%s)
LAST_STATUS=""

while true; do
  RUN_DATA=$(gh run view "$RUN_ID" --json status,conclusion,createdAt,updatedAt,jobs 2>/dev/null || echo "")
  
  if [ -z "$RUN_DATA" ]; then
    echo "$(date '+%H:%M:%S') - Run not found or inaccessible"
    sleep 5
    continue
  fi
  
  STATUS=$(echo "$RUN_DATA" | jq -r '.status // "unknown"')
  CONCLUSION=$(echo "$RUN_DATA" | jq -r '.conclusion // ""')
  UPDATED=$(echo "$RUN_DATA" | jq -r '.updatedAt // ""')
  
  if [ "$STATUS" != "$LAST_STATUS" ]; then
    ELAPSED=$(( $(date +%s) - START_TIME ))
    echo "$(date '+%H:%M:%S') - Status: $STATUS${CONCLUSION:+ ($CONCLUSION)} (${ELAPSED}s elapsed)"
    
    # Show job status
    echo "$RUN_DATA" | jq -r '.jobs[]? | "  \(.name): \(.status) \(.conclusion // "")"' | head -5
    
    LAST_STATUS="$STATUS"
  fi
  
  if [ "$STATUS" = "completed" ]; then
    echo ""
    echo "=== Final Results ==="
    echo "$RUN_DATA" | jq -r '.jobs[] | "\(.name): \(.status) \(.conclusion // "")"'
    break
  fi
  
  sleep 5
done

