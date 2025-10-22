defmodule Loom.Formatter.Obsidian do
  @moduledoc """
  Custom ExDoc formatter that emits Obsidian-flavored markdown described in
  `refs/obsidian-flavored-markdown.md`.

  The formatter focuses on the Phase 1 deliverables captured in the design notes:

    * Generate one markdown file per module with required frontmatter metadata.
    * Convert ExDoc documentation into Obsidian-compatible markdown content.
    * Produce wikilinks for intra-project module references.
    * Mirror the module hierarchy inside the configured output directory.
  """

  alias ExDoc.ModuleNode
  alias Loom.Formatter.Obsidian.{Config, Renderer}

  @spec run([ModuleNode.t()], [ModuleNode.t()], ExDoc.Config.t()) :: String.t()
  def run(project_nodes, _filtered_modules, config) do
    config
    |> Config.build()
    |> render_modules(project_nodes)
  end

  defp render_modules(%Config{} = config, modules) do
    File.rm_rf!(config.output_path)
    File.mkdir_p!(config.output_path)

    Enum.each(modules, fn module ->
      module
      |> Renderer.render(config)
      |> write_file(config)
    end)

    config.output_path
  end

  defp write_file({relative_path, contents}, %Config{output_path: output_path}) do
    absolute_path = Path.join(output_path, relative_path)
    absolute_dir = Path.dirname(absolute_path)

    File.mkdir_p!(absolute_dir)
    File.write!(absolute_path, contents)

    absolute_path
  end
end
