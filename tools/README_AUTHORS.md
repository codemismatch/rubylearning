# Author Data Refresh Tool

## Purpose
Automatically rebuild `data/authors.yml` from Git commit history and GitHub API data.

## Usage

### Dry Run (Preview Changes)
```bash
ruby tools/refresh_authors.rb --dry-run
```

### Apply Changes
```bash
ruby tools/refresh_authors.rb
```

## What It Does

1. **Scans Git History**: Finds all unique commit emails across all branches
2. **Matches Existing Authors**: Preserves manually-configured data
3. **Fetches GitHub Data**: Gets name, avatar, and bio from GitHub API
4. **Updates authors.yml**: Writes clean, formatted YAML with all authors

## Features

- ✅ Preserves existing author data
- ✅ Adds new authors automatically
- ✅ Refreshes GitHub profile data
- ✅ Handles email variants (typos, multiple addresses)
- ✅ Supports GitHub API token for higher rate limits

## GitHub API Token (Optional)

For higher rate limits (5000/hour instead of 60/hour), set:

```bash
export GITHUB_TOKEN="your_github_personal_access_token"
ruby tools/refresh_authors.rb
```

## Example Output

```
============================================================
  Typophic Authors Refresh Tool
============================================================

🔍 Scanning Git history for authors...
   Found 3 unique commit emails

📧 Processing: Pankaj Doharey <pankajdoharey@gmail.com>
   ✓ Already exists as 'pankajdoharey'
   ↻ Refreshed from GitHub: @metacritical

📧 Processing: Neeraj Doharey <neeraj.doharey@live.com>
   ✓ Already exists as 'neerajdoharey'
   ↻ Refreshed from GitHub: @neerajdoharey

✅ Successfully updated data/authors.yml
   Total authors: 2
```
