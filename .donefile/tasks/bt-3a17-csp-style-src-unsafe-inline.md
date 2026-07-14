---
id: bt-3a17
title: CSP style-src 'unsafe-inline' appears unnecessary — tighten it
status: open
priority: p3
tags:
  - security
created: 2026-07-14
---

vercel.json CSP has style-src 'self' 'unsafe-inline'. Verified there are NO inline <style> blocks or style= attributes in index.html/about.html/privacy.html (grep clean). The needle animation uses CSSOM ($needle.style.left, tuner.js:418) which CSP does NOT gate. So 'unsafe-inline' for styles is very likely removable, tightening the policy at zero functional cost. Fix: drop 'unsafe-inline' from style-src and smoke-test the needle/layout; re-add only if something breaks.
