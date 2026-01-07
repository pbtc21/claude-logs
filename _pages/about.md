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

A script scans all local git repositories for commits containing Claude signatures, then generates this browsable log. Each daily entry shows:

- Commit timestamp
- Short hash (linked to GitHub)
- Commit message
- Repository name

## Source

- [whoabuddy/claude-logs](https://github.com/whoabuddy/claude-logs) - This site
- [Claude Code](https://github.com/anthropics/claude-code) - The AI coding assistant
