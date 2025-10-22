# Loom Vault Service Plan

**Purpose:** blueprint for a background service that mirrors critical Obsidian behaviours for AI agents and headless workflows.

## Objectives

1. **File System Awareness** – watch configured vault roots for creates/updates/deletes and stream mutations into Loom's processing pipeline.
2. **Graph Maintenance** – maintain a live backlink + tag graph so agents can query relationships without opening Obsidian.
3. **Dataview Execution** – evaluate Dataview-like queries server-side, materialising indices, tables, and task lists on change.
4. **Rendering Utilities** – expose markdown-to-rich artefact renderers (callouts, Mermaid, math) for clients that lack Obsidian's UI.
5. **API Surface** – provide local HTTP/gRPC endpoints for querying docs, metadata, backlinks, indices, and triggering regenerations.

## Core Components

- **Watcher**: cross-platform file watcher built atop `:fs`/`FileSystem` (Mac/Linux) with debounce + batching; emits `:vault_event` stream.
- **Ingestor**: parses changed markdown into AST + metadata, reusing Loom.Markdown/Tagnormaliser; updates persistent graph store.
- **Graph Store**: ETS or SQLite-backed adjacency lists for wikilinks, tag hierarchies, embeds, and block refs.
- **Dataview Engine**:
  - Parse Dataview code fences with a small DSL (subset supporting `TABLE`, `LIST`, `TASK`, `WHERE`, `SORT`, `LIMIT`).
  - Execute queries against graph store + file metadata; cache results; emit regenerated markdown (or JSON) for subscribers.
- **Renderer**: shareable module that mirrors Obsidian preview semantics (callouts, diagrams, tasks, embeds) for API responses.
- **API Gateway**: Phoenix (or Bandit + Plug) service exposing REST + SSE/websocket updates; endpoints for backlinks, tag clouds, dataview results, note content, search.
- **Job Scheduler**: handles expensive recomputations (full Dataview refresh, Mermaid pre-render, search index rebuild) off main watcher loop.

## Phased Delivery

1. **Minimal Watcher (Week 1)**
   - Standalone Mix app `loom_vault`.
   - File watcher + metadata extraction.
   - Persist forward/back links in ETS; expose basic HTTP endpoints (`/notes/:id`, `/notes/:id/backlinks`).

2. **Dataview Lite (Week 2)**
   - Implement Dataview subset parser.
   - On change, recompute affected queries; write generated indices under `indexes/`.
   - Provide `/dataview` endpoint returning JSON; CLI command `mix loom.vault.refresh` for manual runs.

3. **Graph API (Week 3)**
   - Add tag hierarchy and block reference tracking.
   - Provide graph traversal endpoints (`neighbors`, `shortest_path`, `impact_analysis`).
   - Introduce pluggable storage (ETS in-memory; SQLite disk-backed).

4. **Rendering Extensions (Week 4)**
   - Integrate Mermaid CLI (optional) for SVG exports; fallback to text for agents.
   - Offer HTML/JSON representations with callouts, tasks, embeds resolved.
   - Stream updates over WebSocket/SSE to subscribing agents/tools.

5. **Advanced Features (Week 5+)**
   - Full-text search index (Bleve/Meilisearch integration).
   - Authentication + multi-tenant vault support.
   - Pipeline hooks for PRAXES/ADR ingestion and cross-project link resolution.

## Open Questions

- Which Dataview features are MVP vs deferred (JS inline, complex expressions)?
- How to manage vault-scale performance (incremental graph updates vs periodic rebuilds)?
- Should Mermaid rendering be performed server-side (via headless CLI) or deferred to clients?
- Best format for agent consumption: JSON-LD graph, SQLite snapshots, or GraphQL API?

## Next Steps

1. Prototype watcher + backlink graph using existing Loom formatter output as seed data.
2. Define Dataview subset grammar and parser tests.
3. Select storage abstraction (ETS for dev, SQLite for persistence) and sketch schemas.
4. Draft REST API contract and threat model (local vs remote exposure).
5. Schedule spikes for Mermaid rendering feasibility and full-text search integration.
