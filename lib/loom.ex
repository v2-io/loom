defmodule Loom do
  @moduledoc """
  Loom weaves living documentation for AI agents.

  Transforms multiple documentation sources into Obsidian-flavored markdown with:

  - **Rich cross-references** - Automatic wikilinks and backlinks
  - **Queryable metadata** - YAML frontmatter + Dataview queries
  - **Knowledge graphs** - Topology emerges from relationships
  - **Semantic markup** - Callouts, diagrams, math notation
  - **AI-agent optimized** - Structured for machine consumption

  ## Architecture

  Loom operates as a **documentation transformer** with multiple input sources:

  1. **ExDoc** - Elixir code documentation via custom formatter
  2. **PRAXES** - Reusable patterns with metadata
  3. **Architecture docs** - ADRs and specifications
  4. **Session transcripts** - Curated conversations

  These sources are woven together into a unified Obsidian vault with:

  - Automatic cross-linking
  - Unified metadata schema
  - Query capabilities via Dataview
  - Graph visualization

  ## Usage

  ### Generate from ExDoc

      # In your project's mix.exs
      def project do
        [
          docs: [
            formatters: ["markdown"],
            markdown: [
              output: "vault/project-docs",
              vault_name: "My Project API"
            ]
          ]
        ]
      end

      # Then run:
      mix docs

  ### Import PRAXES

      Loom.import_praxes("~/eli/_shared/PRAXES", vault: "vault/project-docs")

  ### Generate indices

      Loom.generate_index("vault/project-docs")

  ## Design Principles

  1. **Source of Truth: Code** - Documentation generated from code, not manually maintained
  2. **Links Over Categories** - Prefer relationships over rigid hierarchies
  3. **Metadata as First-Class** - Every document has queryable frontmatter
  4. **Visual = Parseable** - Diagrams have text source (Mermaid, not images)
  5. **Progressive Enhancement** - Start with basic markdown, add features incrementally

  ## See Also

  - `Loom.Formatter.Markdown` - ExDoc custom formatter
  - `Loom.Metadata` - Frontmatter schema
  - `Loom.Wikilinks` - Cross-reference conversion
  """

  @doc """
  Get the current version of Loom.

  ## Examples

      iex> Loom.version()
      "0.1.0"

  """
  def version do
    Application.spec(:loom, :vsn) |> to_string()
  end
end
