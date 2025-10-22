defmodule Loom.Vault.GraphTest do
  use ExUnit.Case, async: true

  alias Loom.Vault.Graph

  test "upserting documents indexes forward links, backlinks, and tags" do
    {graph, diff} =
      Graph.new()
      |> Graph.upsert("docs/source",
        content: "See [[docs/target]] and [[Another|alias]].",
        tags: ["runtime", "Elixir/OTP"]
      )

    assert diff.added_links == MapSet.new(["docs/target", "Another"])
    assert diff.added_tags == MapSet.new(["runtime", "elixir/otp"])
    assert Graph.forward_links(graph, "docs/source") == MapSet.new(["docs/target", "Another"])
    assert Graph.backlinks(graph, "docs/target") == MapSet.new(["docs/source"])
    assert Graph.backlinks(graph, "Another") == MapSet.new(["docs/source"])
    assert Graph.tags(graph, "docs/source") == MapSet.new(["runtime", "elixir/otp"])
    assert Graph.documents_with_tag(graph, "runtime") == MapSet.new(["docs/source"])
  end

  test "upserting reflects diffs when links or tags change" do
    {graph, _} =
      Graph.upsert(Graph.new(), "docs/source", content: "See [[old]].", tags: ["alpha"])

    {graph, diff} =
      Graph.upsert(graph, "docs/source",
        content: "See [[new]].",
        tags: ["beta"],
        metadata: %{status: "experimental"}
      )

    assert diff.added_links == MapSet.new(["new"])
    assert diff.removed_links == MapSet.new(["old"])
    assert diff.added_tags == MapSet.new(["beta"])
    assert diff.removed_tags == MapSet.new(["alpha"])

    assert Graph.backlinks(graph, "old") == MapSet.new()
    assert Graph.backlinks(graph, "new") == MapSet.new(["docs/source"])
    assert Graph.documents_with_tag(graph, "beta") == MapSet.new(["docs/source"])
    assert Graph.metadata(graph, "docs/source") == %{status: "experimental"}
  end

  test "delete removes backlinks, tags, and metadata" do
    {graph, _} = Graph.upsert(Graph.new(), "docs/a", content: "See [[docs/b]]", tags: ["keep"])
    {graph, _} = Graph.upsert(graph, "docs/b", content: "See [[docs/a]]", tags: ["remove"])
    {graph, _} = Graph.upsert(graph, "docs/c", content: "See [[docs/b]]")

    {graph, diff} = Graph.delete(graph, "docs/b")

    assert diff.removed_links == MapSet.new(["docs/a"])
    assert Graph.forward_links(graph, "docs/b") == MapSet.new()
    assert Graph.backlinks(graph, "docs/b") == MapSet.new(["docs/a", "docs/c"])
    assert Graph.documents_with_tag(graph, "keep") == MapSet.new(["docs/a"])
    assert Graph.forward_links(graph, "docs/c") == MapSet.new(["docs/b"])
    assert Graph.documents_with_tag(graph, "remove") == MapSet.new()
    assert Graph.metadata(graph, "docs/b") == %{}
    assert Graph.backlinks(graph, "docs/a") == MapSet.new()
  end
end
