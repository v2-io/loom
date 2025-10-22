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
- [`thoughts.md`](thoughts.md) - Research findings and architectural thinking
- [`obsidian-flavored-markdown.md`](obsidian-flavored-markdown.md) - Technical specification

## Roadmap

### Phase 1: ExDoc Formatter (Week 1)
- [x] Project initialization
- [ ] Basic markdown generation from ExDoc nodes
- [ ] Frontmatter extraction from module attributes
- [ ] Wikilink conversion for module references
- [ ] File structure (mirrors module hierarchy)

### Phase 2: Obsidian Enhancements (Week 2)
- [ ] Callout conversion (warnings, examples, deprecations)
- [ ] Mermaid diagram generation (supervision trees)
- [ ] Dataview index generation
- [ ] Tag hierarchy normalization

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

