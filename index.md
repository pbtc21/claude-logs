---
layout: default
title: Home
---

# Claude Logs

Daily summaries of Claude-assisted development.

## Recent Posts

<ul>
{% for post in site.posts limit:10 %}
  <li>
    <a href="{{ post.url | prepend: site.baseurl }}">{{ post.date | date: "%Y-%m-%d" }} - {{ post.title }}</a>
  </li>
{% endfor %}
</ul>

[View all posts](/claude-logs/archive/)
