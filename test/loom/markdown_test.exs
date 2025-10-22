defmodule Loom.MarkdownTest do
  use ExUnit.Case, async: true

  alias Loom.Markdown

  test "converts warning headings into callouts with wikilinks" do
    markdown = """
    ## WARNING
    Use `MyApp.Module` for all operations.
    """

    result = Markdown.normalize(markdown)

    assert result =~ "> [!warning]"
    assert result =~ "Use [[MyApp.Module]] for all operations."
    refute result =~ "## WARNING"
  end
end
