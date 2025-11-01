# Hugo to Typophic Theme Converter

This Ruby script converts Hugo themes to Typophic-compatible themes. Typophic is a static site generator that uses ERB templates instead of Hugo's Go templates.

## Features

- Converts Hugo template syntax (`{{ .Variable }}`) to Typophic ERB syntax (`<%= variable %>`)
- Maps Hugo variables to Typophic equivalents:
  - `.Site.Params.variable` → `site["variable"]`
  - `.Params.variable` → `page["variable"]`
  - `.Content` → `content`
  - `.Title` → `page["title"]`
- Converts Hugo partials to Typophic includes
- Handles conditional statements, loops, and template functions
- Creates appropriate Typophic directory structure

## Usage

```bash
ruby hugo_to_typophic_converter.rb <hugo_theme_path> <new_typophic_theme_name>
```

Example:
```bash
ruby hugo_to_typophic_converter.rb themes/hugo-serif-theme hugo-serif-typophic
```

## What Gets Converted

- **Template structure**: Hugo layouts are mapped to Typophic layouts
- **Partials**: Hugo partials become Typophic includes (with `_` prefix)
- **Variables**: Hugo template variables are converted to ERB syntax
- **Conditionals**: `{{ if }}` statements become `<% if %>` statements
- **Loops**: `{{ range }}` loops become `<% .each do |item| %>` loops
- **Partials**: `{{ partial }}` calls become `<%= render_partial() %>` calls
- **Assets**: CSS, JS, and images are copied to appropriate directories

## Manual Review Required

Some complex Hugo features require manual review and adjustment:

1. **Complex template operations** - Variables like `{{ $services := where ... }}` need manual implementation
2. **Advanced functions** - Complex where clauses and sorting operations
3. **Nested partial contexts** - Partials with complex context dictionaries
4. **Template definitions** - Hugo template blocks and named templates
5. **Custom functions** - Hugo-specific template functions

Look for `<%# Manual review required %>` and `<%# REVIEW: Context ... %>` comments in converted files.

## Typophic Theme Structure

After conversion, the theme will have this structure:
```
themes/your-theme/
├── layouts/
│   ├── default.html
│   ├── home.html
│   └── page.html
├── includes/
│   ├── _header.html
│   └── _footer.html
├── css/
├── js/
└── images/
```

## Manual Fixes After Conversion

Some manual fixes are often needed to make the converted theme work properly:

1. **Create proper layout structure**: Create base `default.html` layout that other pages can inherit from
2. **Fix complex Hugo constructs**: Convert complex Hugo template logic to Ruby code
3. **Add missing partials**: Create partials that are referenced in the main layouts
4. **Adjust asset references**: Ensure CSS, JS, and image paths are correct

## Example: Hugo Serif Theme Implementation

The `hugo-serif-typophic` theme demonstrates a successful conversion with:
- Proper layout structure using Typophic's ERB templating
- Fixed complex Hugo template logic to Ruby enumerable operations
- All required partials created for proper functionality
- Working CSS and JS assets

## Limitations

- Some complex Hugo template logic cannot be automatically converted
- Data filtering and sorting operations require manual implementation
- Advanced Hugo functions like scratch variables are not supported
- Manual review is needed for complex templates

## Best Practices After Conversion

1. Review all templates with "Manual review" comments
2. Test the converted theme with actual content
3. Adjust CSS/JS if class names or HTML structure changed
4. Update the site configuration to use the new theme
5. Add any missing Typophic-specific helper functions
6. Create a proper base layout structure that follows Typophic conventions