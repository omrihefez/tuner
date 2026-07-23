#!/usr/bin/env node
// Fails the build if a cached static asset (per sw.js's own ASSETS list)
// changed in this diff but sw.js's CACHE version string didn't move —
// the classic "shipped a change, forgot to bump the cache" bug.
"use strict";

const { execSync } = require("child_process");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");

function sh(cmd) {
  return execSync(cmd, { cwd: ROOT, encoding: "utf8" }).trim();
}

function refExists(ref) {
  try {
    sh(`git rev-parse --verify ${ref}`);
    return true;
  } catch {
    return false;
  }
}

function resolveBaseRef() {
  if (process.env.GITHUB_BASE_REF) {
    // pull_request event: diff against the PR's base branch.
    const candidate = `origin/${process.env.GITHUB_BASE_REF}`;
    if (refExists(candidate)) return candidate;
  }
  if (process.env.GITHUB_EVENT_BEFORE && !/^0+$/.test(process.env.GITHUB_EVENT_BEFORE)) {
    if (refExists(process.env.GITHUB_EVENT_BEFORE)) return process.env.GITHUB_EVENT_BEFORE;
  }
  if (refExists("HEAD~1")) return "HEAD~1";
  return null;
}

const baseRef = resolveBaseRef();
if (!baseRef) {
  console.log("check-sw-cache-bump: no base commit to diff against (first commit / shallow history) — skipping");
  process.exit(0);
}

function showFile(ref, file) {
  try {
    return sh(`git show ${ref}:${file}`);
  } catch {
    return null; // file didn't exist at that ref
  }
}

function extractCache(source) {
  if (source == null) return null;
  const match = source.match(/const\s+CACHE\s*=\s*["']([^"']+)["']/);
  return match ? match[1] : null;
}

const swBefore = showFile(baseRef, "sw.js");
const swAfter = showFile("HEAD", "sw.js");

if (swAfter == null) {
  console.log("check-sw-cache-bump: sw.js not present at HEAD — skipping");
  process.exit(0);
}

function extractAssets(source) {
  if (source == null) return [];
  const match = source.match(/const\s+ASSETS\s*=\s*(\[[^\]]*\])/);
  if (!match) return [];
  try {
    return JSON.parse(match[1].replace(/'/g, '"'));
  } catch {
    return [];
  }
}

const trackedAssets = new Set(
  extractAssets(swAfter)
    .map((a) => (a === "/" ? "index.html" : a.replace(/^\//, "")))
    .filter(Boolean)
);

const changedFiles = sh(`git diff --name-only ${baseRef} HEAD`)
  .split("\n")
  .filter(Boolean);

const changedAssets = changedFiles.filter((f) => trackedAssets.has(f));
const cacheBefore = extractCache(swBefore);
const cacheAfter = extractCache(swAfter);
const swChanged = changedFiles.includes("sw.js");

if (changedAssets.length === 0) {
  console.log("check-sw-cache-bump: no cached assets changed — OK");
  process.exit(0);
}

if (cacheAfter == null) {
  console.error("check-sw-cache-bump: could not find `const CACHE = \"...\"` in sw.js");
  process.exit(1);
}

if (!swChanged || cacheBefore === cacheAfter) {
  console.error(
    `check-sw-cache-bump: cached asset(s) changed [${changedAssets.join(", ")}] but sw.js CACHE ` +
      `version was not bumped (still "${cacheAfter}"). Bump CACHE in sw.js so clients pick up the update.`
  );
  process.exit(1);
}

console.log(`check-sw-cache-bump: CACHE bumped ${cacheBefore} -> ${cacheAfter} for changed assets [${changedAssets.join(", ")}] — OK`);
