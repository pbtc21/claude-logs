#!/bin/bash
# update-logs.sh
# Scans all local repos for Claude-assisted commits and updates the Jekyll site
#
# Usage: ./scripts/update-logs.sh
#
# Identifies Claude commits by:
# - Co-Authored-By: Claude in commit body
# - "Generated with Claude Code" in commit body
# - "anthropic" mention in commit body

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
POSTS_DIR="$REPO_DIR/_posts"
DATA_DIR="$REPO_DIR/_data"
TMP_FILE="/tmp/claude-commits-$$.json"

echo "Scanning for Claude commits..."

# Create JSON array of commits
echo "[" > "$TMP_FILE"
first=true

for gitdir in $(find ~/dev -name ".git" -type d 2>/dev/null); do
  repo_path=$(dirname "$gitdir")
  repo_name=$(basename "$repo_path")
  parent_name=$(basename $(dirname "$repo_path"))

  cd "$repo_path" 2>/dev/null || continue

  # Get remote URL for GitHub link
  remote_url=$(git remote get-url origin 2>/dev/null | sed 's/\.git$//' | sed 's|git@github.com:|https://github.com/|')
  [ -z "$remote_url" ] && continue

  # Search for Claude commits
  while IFS='|' read -r hash date author subject; do
    [ -z "$hash" ] && continue

    # Check if commit has Claude signature
    body=$(git log -1 --format="%b" "$hash" 2>/dev/null)
    if echo "$body" | grep -qi "claude\|anthropic"; then
      if [ "$first" = true ]; then
        first=false
      else
        echo "," >> "$TMP_FILE"
      fi

      # Escape JSON strings
      subject_escaped=$(echo "$subject" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | tr -d '\n')
      author_escaped=$(echo "$author" | sed 's/"/\\"/g')

      cat >> "$TMP_FILE" << ENTRY
  {
    "hash": "$hash",
    "date": "$date",
    "author": "$author_escaped",
    "subject": "$subject_escaped",
    "repo": "$parent_name/$repo_name",
    "url": "$remote_url/commit/$hash"
  }
ENTRY
    fi
  done < <(git log --all --format="%H|%aI|%an|%s" 2>/dev/null)
done

echo "]" >> "$TMP_FILE"

# Process with Python to dedupe, sort, and generate posts
python3 << PYTHON
import json
from collections import defaultdict
from datetime import datetime
from zoneinfo import ZoneInfo
import os

PST = ZoneInfo('America/Los_Angeles')

# Load data
with open('$TMP_FILE') as f:
    commits = json.load(f)

# Dedupe by hash
seen = set()
unique = []
for c in commits:
    if c['hash'] not in seen:
        seen.add(c['hash'])
        unique.append(c)

# Convert all dates to PST
for c in unique:
    dt = datetime.fromisoformat(c['date'])
    dt_pst = dt.astimezone(PST)
    c['date_pst'] = dt_pst.isoformat()
    c['date_only'] = dt_pst.strftime('%Y-%m-%d')
    c['time_only'] = dt_pst.strftime('%H:%M')

# Sort by date descending
unique.sort(key=lambda x: x['date_pst'], reverse=True)

# Group by date (PST)
by_date = defaultdict(list)
for c in unique:
    by_date[c['date_only']].append(c)

# Group by repo
by_repo = defaultdict(list)
for c in unique:
    by_repo[c['repo']].append(c)

# Create directories
posts_dir = '$POSTS_DIR'
data_dir = '$DATA_DIR'
os.makedirs(posts_dir, exist_ok=True)
os.makedirs(data_dir, exist_ok=True)

# Clear existing posts
for f in os.listdir(posts_dir):
    if f.endswith('.md'):
        os.remove(os.path.join(posts_dir, f))

# Generate daily posts
for date, day_commits in sorted(by_date.items(), reverse=True):
    day_by_repo = defaultdict(list)
    for c in day_commits:
        day_by_repo[c['repo']].append(c)

    filename = f"{date}-daily-log.md"
    filepath = os.path.join(posts_dir, filename)

    dt = datetime.fromisoformat(date)
    formatted_date = dt.strftime("%B %d, %Y")

    content = f"""---
title: "{formatted_date}"
date: {date}
categories: [daily-log]
tags: [{', '.join(sorted(set(c['repo'].split('/')[0] for c in day_commits)))}]
commits: {len(day_commits)}
repos: {len(day_by_repo)}
---

**{len(day_commits)} commits** across **{len(day_by_repo)} repos**

<!--more-->

"""

    for repo, repo_commits in sorted(day_by_repo.items()):
        content += f"## {repo}\n\n"
        for c in sorted(repo_commits, key=lambda x: x['date_pst'], reverse=True):
            time = c['time_only']
            subject = c['subject']
            url = c['url']
            short_hash = c['hash'][:7]
            content += f"- \`{time}\` [{short_hash}]({url}) {subject}\n"
        content += "\n"

    with open(filepath, 'w') as f:
        f.write(content)

# Save stats
stats = {
    'total_commits': len(unique),
    'total_repos': len(by_repo),
    'total_days': len(by_date),
    'last_updated': datetime.now().isoformat(),
    'repos': [{'name': repo, 'commits': len(cs)} for repo, cs in sorted(by_repo.items(), key=lambda x: -len(x[1]))]
}

with open(os.path.join(data_dir, 'stats.json'), 'w') as f:
    json.dump(stats, f, indent=2)

print(f"Generated {len(by_date)} daily logs")
print(f"Total: {len(unique)} commits across {len(by_repo)} repos")
PYTHON

# Cleanup
rm -f "$TMP_FILE"

echo ""
echo "Done! Posts updated in $POSTS_DIR"
