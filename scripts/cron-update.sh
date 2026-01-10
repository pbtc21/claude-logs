#!/usr/bin/env bash
#
# Cron wrapper for daily log generation
# Run via: 0 23 * * * /home/publius/dev/personal/claude-logs/scripts/cron-update.sh
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGS_DIR="$(dirname "$SCRIPT_DIR")"

cd "$LOGS_DIR"

# Generate today's log
"$SCRIPT_DIR/update-logs.sh"

# Check if there are changes to commit
if git diff --quiet && git diff --cached --quiet; then
  echo "No changes to commit"
  exit 0
fi

# Commit and push
git add -A
git commit -m "log: daily summary $(date +%Y-%m-%d)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"

git push origin master

echo "Pushed daily log to GitHub"
