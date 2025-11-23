# Typophic Crystal Port Development Summary

This document summarizes the development activity and key decisions made during the process of porting the Ruby-based Typophic static site generator to Crystal.

## 1. Original Goal and Initial Analysis

The primary goal was to port the Ruby Typophic application to Crystal, leveraging Crystal's Ruby-like syntax for development speed and its compiled nature for performance benefits (native binaries, faster execution).

Initial analysis of the Ruby codebase highlighted significant challenges:
*   **Dynamic Ruby Features:** Extensive use of `OpenStruct` for flexible data access, `instance_eval` for dynamic pipeline configuration, and `send`/`method_missing` for dynamic method dispatch. These features are fundamentally incompatible with Crystal's static type system.
*   **Runtime Template Loading:** The Ruby version dynamically loads and renders ERB templates based on theme configurations.

## 2. Architectural Decisions for Porting

Given the incompatibility of core Ruby dynamic features with Crystal's static type system, a direct port was deemed infeasible. The approach shifted to a **re-implementation** in Crystal, adhering to Crystal's paradigms while mirroring the original application's functionality. Key architectural decisions included:
*   **Replacing Dynamic Configuration:** Moving from Ruby's `instance_eval` (used in `Pipelinefile`) to a statically defined, Crystal-native configuration or a macro-based DSL (though a direct macro DSL wasn't fully implemented, the static pipeline structure in `Builder` supports this).
*   **Replacing Dynamic Data Structures:** Moving from `OpenStruct` to statically defined Crystal `struct` or `class` types (e.g., `Page` and `Site` structs) or explicit `Hash(String, YAML::Any)` for data interchange.
*   **Static Method Dispatch:** Replacing dynamic `send` calls with explicit method calls or `case` statements.

## 3. Core Builder Class Porting (`builder.cr`)

The `Typophic::Builder` class forms the core of the static site generator. Its port involved translating a large amount of Ruby logic into idiomatic Crystal, including:
*   **Initialization:** Setting up source/output directories, theme paths, and loading configurations.
*   **`load_config`:** Parsing `config.yml` and handling environment variable overrides. This involved extensive debugging of `YAML::Any` type handling in Crystal.
*   **`load_data_files`:** Loading YAML and JSON data files from the `/data` directory. This required careful conversion between `JSON::Any` and `YAML::Any`.
*   **`configure_themes`:** Handling theme detection, fallback logic, and ensuring theme directories exist.
*   **`copy_static_assets`:** Copying assets using `FileUtils` and Crystal's concurrency primitives (`spawn`, `WaitGroup`, `Channel`) for parallelization.
*   **`process_content_files`:** Orchestrating content parsing, indexing, and rendering, also with parallelization support.
    *   **`parse_page`:** Reading files, extracting front matter, and determining content renderer.
    *   **`build_page_context`:** Generating page metadata (permalinks, slugs, dates, etc.). This required careful handling of YAML types and `Time` parsing.
    *   **`index_page`:** Populating collections, archives, and taxonomies.
    *   **`inject_collection_data_into_site`:** Injecting processed collection data into the main site context.
    *   **`write_collection_indexes`:** Outputting JSON indexes for collections.

## 4. Template Engine Integration

This was a particularly challenging phase, highlighting the differences between dynamic (Ruby ERB) and static (Crystal ECR/Liquid) templating.

*   **Initial Attempt (Crinja):**
    *   Crinja was chosen due to its Jinja2-like syntax and runtime rendering capabilities.
    *   Encountered a persistent and unresolvable compilation error: `Error: expected argument #1 of yield expected to be Crinja::Value, not (Array(Crinja::Value) | Bool | ...)`. This was diagnosed as a likely incompatibility between Crinja v0.7.0 and Crystal v1.18.2, making it a blocking issue.
    *   Debugging involved simplifying contexts, but the error persisted, pointing to a fundamental library/compiler type interaction problem.
    *   `shards install` also presented issues with dependency resolution for `file_watcher` and `crinja` itself.

*   **Decision to Switch to Liquid:**
    *   After the Crinja impasse, `amberframework/liquid.cr` (Liquid) was selected as an alternative, offering similar runtime rendering, logic, and filtering capabilities.
    *   Successfully integrated Liquid into `builder.cr`.
    *   **`Page` and `Site` Data Structures:** Defined `Page` and `Site` structs to represent template contexts, each with a `to_liquid` method to convert their data into Liquid-compatible Crystal types.
    *   **`yaml_any_to_crystal` Helper:** A crucial recursive helper function was developed to convert complex `YAML::Any` structures into native Crystal types that Liquid's `from_crystal` could robustly handle.
    *   **`render_layout` and `render_inline_template`:** Implemented using `Liquid::Template.parse` and `template.render` methods, constructing the context hash from `site.to_liquid` and `page.to_liquid`.
    *   **Helper Methods:** Ruby's `TemplateContext` helpers (e.g., `asset_path`, `url_for`, `render_partial`) were ported as private methods in `Builder`, with their outputs being added to the Liquid context. `truncate` and `strip_html` functions are often handled directly by Liquid filters.

## 5. Content Processing Pipeline (`pipeline_markdown` and others)

The content processing, primarily focused on Markdown rendering, was ported:
*   **`pipeline_markdown`:** A complex custom regex-based Markdown-to-HTML converter was translated from Ruby.
*   **`build_code_window`:** A helper for formatting code blocks into HTML wrappers was ported.
*   **Other pipeline methods (`pipeline_hash_blocks`, `pipeline_ruby_pre_blocks`, `pipeline_ruby_exec`):** These custom block transformers were ported using Crystal's regex capabilities.
*   **RuboCop Integration:** `pipeline_rubocop_ruby_blocks` was left as a placeholder, as a Crystal equivalent of RuboCop integration was outside the scope of this port.

## 6. CLI Commands Porting

The core CLI commands were ported to integrate with the `Builder` class:
*   **`build.cr`:** Implemented command-line argument parsing using Crystal's `OptionParser`, instantiated `Typophic::Builder`, and invoked its `build` method.
*   **`serve.cr`:** A more complex command involving:
    *   `OptionParser` for server-specific arguments.
    *   `HTTP::Server` for serving static files from the `public` directory.
    *   `FileWatcher` for monitoring file changes and triggering site rebuilds.
    *   **Live Reload:** Implementation of `NoCacheHandler`, `StaticFileHandler`, `LiveReloadHandler`, `BuildTimeHandler`, and `LiveReloadScript` module to inject a JavaScript client that polls for build changes and reloads the browser.
    *   **Concurrency:** Utilized Crystal's `spawn` for running the HTTP server in a background fiber and `WaitGroup` for parallel processing within the Builder.

## 7. General Challenges and Lessons Learned

*   **Crystal's Strict Type System:** The most significant challenge was consistently satisfying Crystal's type checker, especially when dealing with data originating from dynamic sources like YAML and JSON (`YAML::Any`, `JSON::Any`). This required explicit type conversions and careful structural definitions.
*   **Debugging Dependency Issues:** Resolving conflicting or unavailable shard versions (`file_watcher`, `liquid`).
*   **ECR vs. Runtime Templates:** Initial misunderstanding of ECR's compile-time nature led to the exploration of other runtime template engines.
*   **Structural Syntax Errors:** Debugging `EOF` errors and other structural issues in Crystal can be challenging with large code blocks, requiring careful line-by-line review.
*   **Incremental Development:** Breaking down complex features into smaller, testable increments proved essential for managing complexity and debugging.

## 8. Next Steps

According to the established TODO list, the remaining tasks are:
*   Implement `typophic deploy` command (and any other remaining CLI commands).
*   Add comprehensive testing for all ported components.
*   Refine error handling and logging further where needed.
*   Address `TODO` comments throughout the codebase.

This concludes the summary of the Crystal prototype's development activity.
