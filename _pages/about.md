---
title: "About"
layout: default
permalink: /about/
---

# About Claude Logs

A complete history of every commit made with [Claude Code](https://github.com/anthropics/claude-code) across all projects.

## What's Tracked

Every commit that includes Claude's co-author signature:
```
Co-Authored-By: Claude <noreply@anthropic.com>
```

Or commits marked with:
```
Generated with Claude Code
```

## How It Works

The `/daily` command in Claude Code runs `update-logs.sh` which:

1. Scans all repos in `~/dev/` for Claude-assisted commits
2. Identifies commits by signature patterns
3. Generates Jekyll posts grouped by day
4. Pushes to GitHub, triggering a Pages rebuild

Each daily entry shows:
- Commit timestamp
- Short hash (linked to GitHub)
- Commit message
- Repository name

## Updating

Run `/daily` in Claude Code to scan for new commits and update the site.

## Source

- [pbtc21/claude-logs](https://github.com/pbtc21/claude-logs) - This site
- [Claude Code](https://github.com/anthropics/claude-code) - The AI coding assistant
