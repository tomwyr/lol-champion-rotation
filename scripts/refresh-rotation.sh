#!/bin/bash
set -euo pipefail

# Redirect stdout and stderr to the log file
exec >> "/app/scripts/cron.log" 2>&1

# Log the current timestamp and job name
echo "$(date '+%Y-%m-%d %H:%M:%S'): Refresh rotation"

# Call endpoint to refresh champion rotation
curl -w "\n" -s -XPOST -H "Authorization: Bearer $APP_MANAGEMENT_KEY" "$APP_BASE_URL/rotation/refresh"
