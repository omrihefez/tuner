#!/usr/bin/env node
// Catches dead internal links/asset refs (href/src starting with "/") in the
// HTML and the manifest before they reach users. External and mailto: links
// are left alone — this only checks paths this repo actually serves.
"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const HTML_FILES = fs.readdirSync(ROOT).filter((f) => f.endsWith(".html"));

let failures = 0;

function resolveInternalPath(ref) {
  const clean = ref.split("#")[0].split("?")[0];
  if (clean === "" || clean === "/") return "index.html";
  return clean.replace(/^\//, "");
}

function checkFileRefs(file, contents, attrPattern) {
  let match;
  while ((match = attrPattern.exec(contents)) !== null) {
    const ref = match[1];
    if (!ref.startsWith("/")) continue; // only internal absolute paths
    const relPath = resolveInternalPath(ref);
    const fullPath = path.join(ROOT, relPath);
    if (!fs.existsSync(fullPath)) {
      console.error(`${file}: broken internal link "${ref}" -> missing ${relPath}`);
      failures++;
    }
  }
}

for (const file of HTML_FILES) {
  const contents = fs.readFileSync(path.join(ROOT, file), "utf8");
  checkFileRefs(file, contents, /\bhref="([^"]+)"/g);
  checkFileRefs(file, contents, /\bsrc="([^"]+)"/g);
}

// manifest.json: must parse, and every icon it points at must exist
const manifestPath = path.join(ROOT, "manifest.json");
if (fs.existsSync(manifestPath)) {
  let manifest;
  try {
    manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
  } catch (err) {
    console.error(`manifest.json: malformed JSON — ${err.message}`);
    failures++;
    manifest = null;
  }
  for (const icon of (manifest && manifest.icons) || []) {
    const relPath = resolveInternalPath(icon.src);
    if (!fs.existsSync(path.join(ROOT, relPath))) {
      console.error(`manifest.json: missing icon file "${icon.src}" -> ${relPath}`);
      failures++;
    }
  }
}

if (failures > 0) {
  console.error(`\n✖ ${failures} broken internal reference(s)`);
  process.exit(1);
}

console.log("✓ all internal links and manifest icon refs resolve");
