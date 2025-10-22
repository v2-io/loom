defmodule Loom.Formatter.Obsidian.RendererTest do
  use ExUnit.Case, async: true

  alias Loom.Formatter.Obsidian.{Config, Renderer}
  alias ExDoc.{DocGroupNode, DocNode, ModuleNode}

  @date ~D[2025-10-22]

  test "renders module content with wikilinks and structure" do
    docs =
      [
        %DocNode{
          name: :start_link,
          arity: 1,
          signature: "def start_link(opts)",
          specs: ["@spec start_link(keyword()) :: GenServer.on_start()"],
          source_doc: %{
            "en" =>
              "Initialises the process by calling `Sample.Other` and `start_link/1`.\n\n## TIP\nPrefer supervised invocations."
          }
        }
      ]

    groups = [
      %DocGroupNode{
        title: nil,
        docs: docs
      }
    ]

    node =
      struct(ModuleNode,
        module: Sample.Example,
        title: "Sample.Example",
        source_doc: %{
          "en" =>
            "Module overview referencing `Sample.Other`.\n\n## WARNING\nNever bypass the supervision tree."
        },
        docs_groups: groups,
        annotations: [:stable],
        group: :runtime,
        metadata: %{
          source_path: "lib/sample/example.ex",
          mermaid: [
            %{title: "Lifecycle States", code: "graph TD; A-->B"}
          ]
        },
        moduledoc_file: "lib/sample/example.ex"
      )

    config = struct(Config, output_path: "tmp/loom", generated_at: @date)

    {relative_path, contents} = Renderer.render(node, config)

    assert relative_path == Path.join(["sample", "Example.md"])

    assert contents =~ "---"
    assert contents =~ "title: Sample.Example"
    assert contents =~ "module: Sample.Example"
    assert contents =~ "created: 2025-10-22"
    assert contents =~ "# Sample.Example"
    assert contents =~ "[[Sample.Other]]"
    assert contents =~ "[[#start_link/1]]"
    assert contents =~ "### start_link/1"
    assert contents =~ "```elixir"
    assert contents =~ "> [!warning]"
    assert contents =~ "> [!tip]"
    assert contents =~ "## Lifecycle States"
    assert contents =~ "```mermaid\ngraph TD; A-->B\n```"
  end
end
