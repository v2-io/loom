# Loom

**Weave living documentation for AI agents.**

Loom transforms Elixir code, PRAXES patterns, and architecture documents into Obsidian-flavored markdown with:

- 🔗 **Rich cross-references** - Automatic wikilinks and backlinks
- 📊 **Queryable metadata** - Frontmatter + Dataview queries
- 🌐 **Knowledge graphs** - Topology emerges from relationships
- 🎨 **Semantic markup** - Callouts, diagrams, math notation
- 🤖 **AI-agent optimized** - Structured for machine consumption

## Vision

Documentation as a **living knowledge base** that:

1. **Consumes** multiple sources (ExDoc, PRAXES, ADRs, transcripts)
2. **Weaves** them together (cross-links, unified metadata, queries)
3. **Serves** AI agents (structured, queryable, graph-traversable)

## Status


🚧 **Pre-alpha** - Initial research and design phase

See:

- [[refs/thoughts.md]] - Research findings and architectural thinking
- [[refs/obsidian-flavored-markdown.md]] - Technical specification
- (See refs/*.md for more initial planning and documentation)

## Roadmap

### Phase 1: ExDoc Formatter (Week 1)
- [x] Project initialization
- [ ] Basic markdown generation from ExDoc nodes
- [ ] Frontmatter extraction from module attributes
- [ ] Wikilink conversion for module references
- [ ] File structure (mirrors module hierarchy)

### Phase 2: Obsidian Enhancements (Week 2)
- [x] Callout conversion (warnings, examples, deprecations)
- [x] Mermaid diagram generation (supervision trees)
- [x] Dataview index generation
- [x] Tag hierarchy normalization

### Phase 3: Multi-Source Integration (Week 3)
- [ ] PRAXES importer
- [ ] Architecture doc linker
- [ ] Cross-source wikilink resolution

### Phase 4: AI Agent Tooling (Week 4+)
- [ ] Graph traversal API
- [ ] Semantic search integration
- [ ] Query builder for common patterns

## Usage (Future)

```bash
# Generate Obsidian vault from Elixir project
mix loom.generate --vault ~/vaults/my-project

# Import PRAXES
mix loom.import.praxes ~/eli/_shared/PRAXES --vault ~/vaults/my-project

# Generate indices
mix loom.index --vault ~/vaults/my-project
```

### Development Formatter

While Phase 1 is in progress you can already experiment with the Obsidian formatter by updating your `mix.exs`:

```elixir
def project do
  [
    docs: [
      output: "vault",
      formatters: ["html", Loom.Formatter.Obsidian],
      obsidian: [
        vault_name: "My Project API"
      ]
    ]
  ]
end
```

Running `mix docs` will now generate HTML as usual and additionally materialise Obsidian-flavoured markdown under `vault/` following the module hierarchy rules captured in `refs/obsidian-flavored-markdown.md`.

Phase 2 enhancements are active by default:

- Callouts expressed as `## WARNING`, `## NOTE`, etc. become Obsidian `[!warning]`/`[!note]` blocks.
- Inline module/function references wrapped in backticks are rewritten as wikilinks.
- Modules that provide `:mermaid`/`:loom_diagrams` metadata (title + code) get rendered Mermaid fences.
- A generated `indexes/module-index.md` file contains Dataview tables/lists to navigate modules.
- Tags from annotations/module metadata are normalised into hierarchical identifiers such as `elixir/otp/genserver`.

## Installation

**Not yet published to Hex.**

For development:

```elixir
def deps do
  [
    {:loom, path: "~/src/loom"}
  ]
end
```

## Contributing

This project is in early research/design. Feedback welcome via issues or discussions.

## License

Apache 2.0

## Acknowledgments

Inspired by:
- [Obsidian](https://obsidian.md) - Knowledge graph thinking
- [ExDoc](https://github.com/elixir-lang/ex_doc) - Elixir documentation
- [Zoetica](https://github.com/josephwecker/zoetica) - ELI consciousness infrastructure
- [Temporal Software Theory](https://josephwecker.github.io/tst) - Change-aware development

# Repository Guidelines

## Project Structure & Module Organization
Loom is an Elixir Mix project. Core source lives under `lib/`, currently anchored by `Loom` and the namespaces it will grow (`Loom.*`). Tests mirror modules in `test/` using `*_test.exs`. Generated build artifacts stay in `_build/`, while vendored dependencies are in `deps/`; avoid committing either. Project-wide reference docs and research notes (`README.md`, `thoughts.md`, `obsidian-flavored-markdown.md`) sit at the repository root—use them before proposing architecture changes.

## Build, Test, and Development Commands
- `mix deps.get` – install or update dependencies; run after pulling new commits.
- `mix compile` – compile Elixir sources; surfaces warnings you should resolve before review.
- `mix test` – execute ExUnit suites, including doctests; required pre-push.
- `mix docs` – render Obsidian-flavored markdown via ExDoc once formatter modules land.
- `iex -S mix` – open an interactive shell for exploring loom helpers during development.

## Coding Style & Naming Conventions
Format all changes with `mix format`; it enforces two-space indentation, consistent pipe alignment, and spacing rules. Modules use `CamelCase` (e.g., `Loom.Formatter.Markdown`), functions and variables use `snake_case`, and predicate helpers should end in `?`. Name files after the primary module (`lib/loom/formatter/markdown.ex`) and keep public APIs documented with `@doc` plus doctests where practical. Include focused module-level docstrings to feed downstream knowledge graph tooling.

## Testing Guidelines
Use ExUnit for unit and integration coverage, keeping doctests synchronized with example outputs (`@moduledoc` and `@doc` blocks). Mirror module structure in `test/` and suffix individual tests with the feature under exercise (e.g., `"generates frontmatter"`). Aim for meaningful assertions rather than structural pattern matches, and target ≥80% coverage using `mix test --cover` when touching core transformers. When adding Mix tasks, prefer CLI smoke tests that verify key options.

## Commit & Pull Request Guidelines
Write commit subjects in the imperative, mirroring the existing history (`Initial loom project: …`). Group related changes, and keep descriptions under 72 characters with optional detail in the body. Pull requests should include: (1) a concise summary of the problem and approach, (2) references to relevant design docs or issues, and (3) verification notes (`mix test`, `mix format`). Add screenshots or vault diffs when the change affects generated markdown so reviewers—and downstream agents—grasp the impact quickly.
