# Typophic Internals

> This document is inspired by Nanoc’s “Internals” guide. It captures how we want Typophic to behave under the hood so that contributors have a shared mental model. Everything here is a work in progress—we’ll grow and refine it as the engine evolves.

## Data Model

- **Entities** (planned): raw Ruby objects that hold canonical state (`Typophic::Entity::Page`, `Typophic::Entity::Layout`, …). Entities should be persistence-friendly and free of presentation logic.
- **Views** (current): what the CLI and templates interact with. Views wrap entities, enforce read/write safety, and expose helper APIs (e.g., `page.title`, `page.path`).
- **Helpers**: Ruby modules found in `helpers/` or `themes/<name>/helpers/` under the `Typophic::Helpers` namespace. They are automatically mixed into the view context.

### Why mirror Nanoc?

Nanoc cleanly separates low-level state (entities) from high-level APIs (views). Typophic will follow that pattern so we can:

1. lock down direct mutations (only preprocessing should be able to mutate entities),
2. expose specialised views (mutable, compilation, post-compilation), and
3. keep serialization/caching logic outside of the template layer.

For now, Typophic mostly operates on view-like structs. As we dogfood the engine we’ll formalise the entity/view split and migrate the builder accordingly.

## Dependency Tracking

Typophic already records **soft dependencies** while building collections:

- Raw content access (`page.raw_markdown`) → watch the source file checksum.
- Attribute access (`page['title']`, `config['base_url']`) → track individual keys.
- Compiled content (`other_page.compiled_html`) → note the rendered output snapshot.
- Path (`page.path`) → track routing info.

Next steps, inspired by Nanoc:

1. Persist dependency edges between runs.
2. Store property flags per edge so we only rebuild when relevant data changes.
3. Introduce **hard dependencies** when a rep reads another rep’s compiled content; use them to order compilation and suspend/resume safely.

## Outdatedness Checker

Typophic will mark a rep as outdated when any of the following occurs (mirrors Nanoc, with a Typophic twist):

1. First-time compilation (no cached output).
2. Raw content hash changed.
3. Frontmatter/attributes read by dependents changed.
4. Theme or helper code touched (`helpers/`, `themes/<name>/helpers/`).
5. Config keys used by the rep changed.
6. Compiled-content dependency changed.
7. Route/path changed.

Implementation plan:

- Keep per-rep checksum store (current builder already writes JSON summaries—extend that to include full signatures).
- Leverage the dependency store to propagate outdatedness, just like Nanoc’s `OutdatednessChecker`.
- Surface “why” messages (e.g., “outdated because posts/welcome.md:title changed”) to aid debugging.

## Action Pipeline

Nanoc uses an **action provider** that yields `filter`, `layout`, `snapshot`, … instructions. Typophic will adopt a simplified version:

- `Typophic::Theme::Pipeline` will emit a small instruction set (`render_markdown`, `apply_layout`, `write_snapshot`).
- The CLI will ask for an action sequence per rep, allowing future providers (e.g., JSON feeds, custom pipelines) without touching the compiler core.
- Filters/layouts stay theme-driven, keeping the dogfood experience simple.

## Compilation Stages

We can closely mirror Nanoc’s staged flow:

1. **Preprocess** – run `helpers/preprocess.rb` if present (future).
2. **BuildReps** – determine reps and action sequences (already happening in builder, but will be explicit soon).
3. **LoadState** – load previous checksums/dependencies (future cache store).
4. **CalculateChecksums** – compute hashes for content, attributes, helpers, config.
5. **DetermineOutdatedness** – mark stale reps via the rules above.
6. **ForgetOutdatedDependencies** – drop stale edges for outdated reps.
7. **Prune** – delete files in `public/` with no matching rep (already handled via `.htaccess`/build step; will be formalised).
8. **CompileReps** – execute action sequences, honour hard dependencies, reuse cached steps where possible.
9. **StoreState** – save new checksums, dependencies, and snapshots.
10. **Postprocess** – future hook for deployment scripts.
11. **Cleanup** – remove temporary snapshots/cache entries.

### Per-Rep Phases

Within `CompileReps`, each rep will go through:

1. **Cache** – attempt to read cached compiled output (already planned).
2. **Recalculate** – run pending actions when cache miss occurs.
3. **Resume** – suspend if a hard dependency isn’t ready; resume once satisfied.
4. **Write** – emit files/snapshots.
5. **MarkDone** – record completion time and signature.

## Improvements Over Nanoc

- **Unified CLI**: no separate Rules DSL—everything flows through the gem-friendly CLI/API.
- **Convention-first themes**: ERB + frontmatter by default; rules and pipelines are inferred so simple sites need zero extra config.
- **Helpers auto-loading**: drop-in Ruby modules without manual registration.
- **Transparent caches**: default JSON state in `.typophic/cache.json`, easy to inspect/remove.
- **Dogfooding**: rubylearning stays the canonical test bed, ensuring features are grounded in real-world needs.

## Roadmap

1. Persist dependency graph + outdatedness signatures.
2. Introduce hard-dependency-aware compiler with suspension/resume.
3. Add `typophic inspect` debug command to show why a rep is outdated.
4. Ship multiple theme pipelines (blog, docs) as separate gems.
5. Explore parallel compilation once dependency ordering is rock solid.

Contributions are welcome! If you’re interested in helping with any of the above, open an issue so we can coordinate design details up front.

