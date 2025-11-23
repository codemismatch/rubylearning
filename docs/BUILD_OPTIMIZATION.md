# Build Performance Optimization Guide

## Current Performance

- **Build time:** ~1.95-2.0 seconds
- **Files processed:** 51+ tutorial pages + blog posts + static pages
- **Parallel processing:** 12 threads
- **No incremental builds:** All files processed every time

## Optimization Opportunities

### 1. Incremental Builds (Biggest Win - ~50-70% faster)

**Current:** All files are processed on every build, even if unchanged.

**Optimization:** Check file modification times and skip unchanged files.

**Expected improvement:** 0.6-1.0 seconds (50-70% faster for unchanged files)

### 2. Asset Copying Optimization

**Current:** All assets copied on every build.

**Optimization:** Check file mtimes and only copy changed assets.

**Expected improvement:** 0.1-0.2 seconds

### 3. Skip normalize_content_quotes When Not Needed

**Current:** Scans all markdown files every build.

**Optimization:** Only run if files contain smart quotes, or skip entirely if files haven't changed.

**Expected improvement:** 0.05-0.1 seconds

### 4. Optimize Regex Operations

**Current:** Regex patterns compiled on every use.

**Optimization:** Pre-compile regex patterns as constants.

**Expected improvement:** 0.05-0.1 seconds

### 5. Parallel Asset Copying

**Current:** Already parallel, but could be optimized further.

**Optimization:** Batch operations, reduce file system calls.

**Expected improvement:** 0.05 seconds

## Implementation Priority

1. **Incremental builds** - ✅ IMPLEMENTED
2. **Asset copying optimization** - ✅ IMPLEMENTED
3. **Regex optimization** - Low impact but easy
4. **normalize_content_quotes optimization** - Low impact

## Implementation Status

### ✅ Incremental Builds (Implemented)

**How it works:**
- Build cache stored in `public/.typophic_cache.json`
- Tracks file modification times
- Skips processing unchanged files
- Only processes changed files

**Limitation:**
- Currently skips parsing unchanged files entirely
- This means collections/indexes may be incomplete if files are skipped
- **Workaround:** For now, incremental builds work best when only content changes, not structure
- **Future:** Separate parsing (all files) from rendering (changed files only)

### ✅ Asset Copying Optimization (Implemented)

**How it works:**
- Compares source and destination file modification times
- Only copies changed assets
- Skips unchanged files

## Target Performance

- **Full build (all files changed):** ~1.8-2.0 seconds (current)
- **Incremental build (no changes):** ~0.3-0.5 seconds (expected)
- **Incremental build (few changes):** ~0.5-1.0 seconds (expected)

## Usage

The incremental build system is **automatic**. No configuration needed.

**First build:** Full build (creates cache)
**Subsequent builds:** Incremental (uses cache)

**To force full rebuild:** Delete `public/.typophic_cache.json`
