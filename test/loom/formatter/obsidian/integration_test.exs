defmodule Loom.Formatter.Obsidian.IntegrationTest do
  use ExUnit.Case, async: false

  alias Loom.Formatter.Obsidian.{Config, Renderer}

  @tmp_dir Path.join(System.tmp_dir!(), "loom_obsidian_formatter_test")

  setup_all do
    start_supervised!(ExDoc.Refs)
    :ok
  end

  setup do
    File.rm_rf!(@tmp_dir)
    File.mkdir_p!(@tmp_dir)
    on_exit(fn -> ExDoc.Refs.clear() end)
    :ok
  end

  test "renders mermaid diagrams advertised via moduledoc metadata" do
    exdoc_config = ExDoc.Config.build("Loom", "0.1.0", output: @tmp_dir)

    {modules, _filtered} =
      ExDoc.Retriever.docs_from_modules(
        [Loom.Support.DiagramModule],
        exdoc_config
      )

    module_node = hd(modules)

    loom_config = Config.build(%{exdoc_config | output: @tmp_dir})

    {_relative_path, contents} = Renderer.render(module_node, loom_config)

    assert contents =~ "# Loom.Support.DiagramModule"
    assert contents =~ "```mermaid"
    assert contents =~ "graph TD"
    assert contents =~ "## Lifecycle Diagram"
    assert contents =~ "tags:\n  - elixir/otp/genserver"
    assert contents =~ "category: runtime"
  end
end
