#!/usr/bin/env bash
#
# Update Claude Logs - Generates Jekyll posts from git activity
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOGS_DIR="$(dirname "$SCRIPT_DIR")"
POSTS_DIR="$LOGS_DIR/_posts"
DEV_DIR="$HOME/dev"

DATE="${1:-$(date +%Y-%m-%d)}"
POST_FILE="$POSTS_DIR/$DATE-daily-summary.md"

echo "Generating log for $DATE..."

# Collect git data from all repos
TOTAL_COMMITS=0
REPOS_ACTIVE=0

declare -A REPO_COMMITS
declare -A REPO_MESSAGES

for org_dir in "$DEV_DIR"/*/; do
  [ -d "$org_dir" ] || continue
  for repo_dir in "$org_dir"*/; do
    [ -d "$repo_dir/.git" ] || continue

    repo_name=$(basename "$repo_dir")

    # Get commits for this date
    commits=$(cd "$repo_dir" && git log --oneline --since="$DATE 00:00" --until="$DATE 23:59" 2>/dev/null || true)

    if [ -n "$commits" ]; then
      commit_count=$(echo "$commits" | wc -l)
      TOTAL_COMMITS=$((TOTAL_COMMITS + commit_count))
      REPOS_ACTIVE=$((REPOS_ACTIVE + 1))
      REPO_COMMITS["$repo_name"]=$commit_count
      REPO_MESSAGES["$repo_name"]=$(echo "$commits" | sed 's/^[a-f0-9]* /- /' | head -10)
    fi
  done
done

if [ "$TOTAL_COMMITS" -eq 0 ]; then
  echo "No Claude-assisted commits found for $DATE"
  exit 0
fi

# Generate Jekyll post
cat > "$POST_FILE" << EOF
---
layout: post
title: "Daily Summary"
date: $DATE
categories: daily
tags: [claude, development]
---

## At a Glance

| Commits | Repos | Issues | PRs |
|---------|-------|--------|-----|
| $TOTAL_COMMITS | $REPOS_ACTIVE | 0 | 0 |

## Commits by Repository

| Repository | Commits |
|------------|---------|
EOF

for repo in "${!REPO_COMMITS[@]}"; do
  echo "| $repo | ${REPO_COMMITS[$repo]} |" >> "$POST_FILE"
done

cat >> "$POST_FILE" << 'EOF'

## Activity Details

EOF

for repo in "${!REPO_COMMITS[@]}"; do
  echo "### $repo" >> "$POST_FILE"
  echo "" >> "$POST_FILE"
  echo "${REPO_MESSAGES[$repo]}" >> "$POST_FILE"
  echo "" >> "$POST_FILE"
done

echo "Generated: $POST_FILE"
echo "Commits: $TOTAL_COMMITS across $REPOS_ACTIVE repos"
