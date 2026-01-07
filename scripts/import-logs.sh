#!/bin/bash
# import-logs.sh
# Imports canonical daily summary logs and adds Jekyll front matter
#
# Usage: ./scripts/import-logs.sh [source_dir]
# Default source: ~/logs
#
# Only imports YYYY-MM-DD-daily-summary.md files (canonical daily summaries)
# Skips timestamped session logs to avoid exposing private repo details

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_DIR="${1:-$HOME/logs}"
POSTS_DIR="$REPO_DIR/_posts"

# Ensure target directory exists
mkdir -p "$POSTS_DIR"

# Counters
imported=0
skipped=0

echo "Importing daily summaries from: $SOURCE_DIR"
echo "Target directory: $POSTS_DIR"
echo ""

# Process each markdown file
for file in "$SOURCE_DIR"/*.md; do
  [ -f "$file" ] || continue

  filename=$(basename "$file")

  # Only import canonical daily summaries (YYYY-MM-DD-daily-summary.md)
  # Skip timestamped files to avoid exposing private repo commits
  if [[ "$filename" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-daily-summary\.md$ ]]; then
    date="${BASH_REMATCH[1]}"

    # Check if already imported (has front matter)
    if head -1 "$file" | grep -q "^---$"; then
      echo "Skipping (already has front matter): $filename"
      skipped=$((skipped + 1))
      continue
    fi

    # Create file with front matter prepended
    target_file="$POSTS_DIR/$filename"
    {
      printf '%s\n' "---"
      printf '%s\n' "title: \"Daily Summary - ${date}\""
      printf '%s\n' "date: $date"
      printf '%s\n' "categories: [daily-summary]"
      printf '%s\n' "tags: [commits, github]"
      printf '%s\n' "---"
      printf '\n'
      cat "$file"
    } > "$target_file"

    echo "Imported: $filename"
    imported=$((imported + 1))
  fi
done

echo ""
echo "Import complete!"
echo "  Imported: $imported"
echo "  Skipped: $skipped"
