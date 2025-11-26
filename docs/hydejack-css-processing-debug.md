# Hydejack CSS Processing Debug Session

**Date:** 2025-11-26  
**Status:** In Progress - Debugging include path resolution

## Problem Summary

The Hydejack theme's main stylesheet (`themes/hydejack/assets/css/hydejack-9.2.1.css`) is not being correctly processed, resulting in an unstyled site. The CSS file contains Liquid front matter and uses the `scssify` filter to compile SCSS, but the generated output is only 58 bytes and contains a Liquid error.

### Current Error

```
Liquid error: Liquid error: No such template 'header.txt'
```

Despite `themes/hydejack/includes/header.txt` existing on disk, the Liquid renderer cannot find it during asset processing.

## Root Cause Analysis

The CSS file structure is:
```liquid
---
---
{% capture include_to_scssify %}{% include styles/style.scss %}{% endcapture %}{% include header.txt %}{{ include_to_scssify | scssify }}
```

This requires:
1. Liquid processing to handle `{% include %}` tags
2. The `scssify` filter to compile the SCSS content
3. Correct include path resolution for theme files

## Changes Made

### 1. Modified `lib/typophic/builder.rb`

#### Added `render_liquid_asset` helper method (lines 384-413)
```ruby
def render_liquid_asset(body, relative_path, label)
  # Determine theme name from label
  theme_name = if label.start_with?("theme: ")
                 label.sub("theme: ", "")
               elsif label == "default theme (root)"
                 @default_theme_name
               else
                 nil
               end
  
  theme_includes = @theme_paths[theme_name] ? File.join(@theme_paths[theme_name], "includes") : nil
  
  # Debug logging for hydejack CSS
  if relative_path.end_with?("hydejack-9.2.1.css")
    puts "DEBUG: render_liquid_asset for #{relative_path}"
    puts "  label: #{label}"
    puts "  theme_name: #{theme_name}"
    puts "  theme_includes_dir: #{theme_includes}"
    puts "  site_includes_dir: #{@site_includes_dir}"
  end

  page_context = { "path" => relative_path, "url" => "/#{relative_path}" }
  
  renderer = Typophic::Renderer::Liquid.new(
    content: "",
    site: @site,
    page: page_context,
    current_theme: theme_name,
    site_includes_dir: @site_includes_dir,
    theme_includes_dir: theme_includes,
    builder: self
  )
  renderer.render(body)
end
```

#### Updated `copy_asset_tree` method (lines 331-368)
Added logic to handle `.css` files with Liquid front matter:

```ruby
elsif file.end_with?(".css")
  content = File.read(file)
  if content =~ /\A---\s*\n/
    # Process CSS with Liquid if front matter is present
    front_matter, body = extract_front_matter(content)
    content = render_liquid_asset(body, relative, label)
    File.write(target, content)
  else
    FileUtils.cp(file, target)
  end
```

## Current Investigation

### Debug Logging Added
Added debug output to `render_liquid_asset` to inspect:
- `label` - The asset source label (e.g., "theme: hydejack")
- `theme_name` - Resolved theme name
- `theme_includes_dir` - Path to theme's includes directory
- `site_includes_dir` - Path to site's includes directory

### Next Steps

1. **Capture Debug Output**
   - Run `bin/typophic build > build.log 2>&1`
   - Check `build.log` for DEBUG output
   - Verify that `theme_name` is correctly resolved to "hydejack"
   - Verify that `theme_includes_dir` points to `themes/hydejack/includes`

2. **Verify Include Path Resolution**
   - Check `lib/typophic/renderer/liquid.rb` to ensure the `Include` tag searches both:
     - `@theme_includes_dir` (should be `themes/hydejack/includes`)
     - `@site_includes_dir` (should be `includes`)
   - Verify that the file lookup logic handles both absolute and relative paths

3. **Possible Issues to Investigate**
   - The `label` parameter might not be formatted as expected (e.g., not "theme: hydejack")
   - The `@theme_paths` hash might not contain the "hydejack" key
   - The `Include` tag might not be using the correct search paths
   - There might be a mismatch between how theme assets are copied vs. how content pages are rendered

4. **Alternative Approaches**
   - If theme resolution fails, consider hardcoding the theme name for CSS assets in the Hydejack theme directory
   - Add fallback logic to search all known theme include directories
   - Consider processing theme CSS files differently from site CSS files

## Files to Review

- `/Users/pankajdoharey/Development/rubylearning/lib/typophic/builder.rb` (lines 331-413)
- `/Users/pankajdoharey/Development/rubylearning/lib/typophic/renderer/liquid.rb` (Include tag implementation)
- `/Users/pankajdoharey/Development/rubylearning/lib/typophic/renderer/jekyll_tags.rb` (Include tag overrides)
- `/Users/pankajdoharey/Development/rubylearning/themes/hydejack/assets/css/hydejack-9.2.1.css`
- `/Users/pankajdoharey/Development/rubylearning/themes/hydejack/includes/header.txt`
- `/Users/pankajdoharey/Development/rubylearning/themes/hydejack/includes/styles/style.scss`

## Expected Outcome

Once fixed, `public/assets/css/hydejack-9.2.1.css` should:
- Be significantly larger than 58 bytes (likely 50KB+)
- Contain compiled CSS, not Liquid error messages
- Include all Hydejack theme styles
- Result in a properly styled site when viewed in the browser

## Testing Commands

```bash
# Build the site
bin/typophic build

# Check CSS file size
ls -lh public/assets/css/hydejack-9.2.1.css

# View CSS content (first 50 lines)
head -50 public/assets/css/hydejack-9.2.1.css

# Search for debug output
grep -A 5 "DEBUG: render_liquid_asset" build.log

# Serve and test in browser
bin/typophic serve
# Then visit http://localhost:3000
```

## Related Context

- The `scssify` filter was implemented in `lib/typophic/renderer/liquid.rb` (lines 137-147)
- Theme configuration merging was added to `load_config` in `builder.rb` (lines 194-214)
- The `Include` tag was refactored to support Jekyll-style argument passing (lines 4-58 in `jekyll_tags.rb`)
- Front matter extraction was fixed to handle empty front matter blocks (lines 519-532 in `builder.rb`)
