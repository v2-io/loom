defmodule Loom.MetadataTest do
  use ExUnit.Case, async: true

  alias Loom.Metadata
  alias ExDoc.ModuleNode

  test "builds module frontmatter with required fields" do
    node =
      struct(ModuleNode,
        module: Sample.Module,
        title: "Sample.Module",
        annotations: [:stable],
        group: :runtime,
        metadata: %{source_path: "lib/sample/module.ex"},
        moduledoc_file: "lib/sample/module.ex"
      )

    frontmatter = Metadata.module_frontmatter(node, ~D[2025-10-22])

    assert frontmatter =~ "title: Sample.Module"
    assert frontmatter =~ "type: module"
    assert frontmatter =~ "module: Sample.Module"
    assert frontmatter =~ "category: runtime"
    assert frontmatter =~ "status: stable"
    assert frontmatter =~ "tags:\n  - stable"
    assert frontmatter =~ "source: lib/sample/module.ex"
    assert frontmatter =~ "created: 2025-10-22"
    assert frontmatter =~ "modified: 2025-10-22"
  end
end
