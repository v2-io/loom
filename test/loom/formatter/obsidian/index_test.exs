defmodule Loom.Formatter.Obsidian.IndexTest do
  use ExUnit.Case, async: true

  alias Loom.Formatter.Obsidian.{Config, Index}

  test "generates module index dataview note" do
    config = struct(Config, generated_at: ~D[2025-10-22])

    [{path, contents}] = Index.generate([], config)

    assert path == "indexes/module-index.md"
    assert contents =~ "title: Module Index"
    assert contents =~ "type: index"
    assert contents =~ "created: 2025-10-22"
    assert contents =~ "```dataview"
  end
end
