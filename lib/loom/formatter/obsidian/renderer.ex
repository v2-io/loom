defmodule Loom.Formatter.Obsidian.Renderer do
  @moduledoc false

  alias Loom.Formatter.Obsidian.Config
  alias Loom.Metadata
  alias Loom.Wikilinks
  alias ExDoc.{DocGroupNode, DocNode, ModuleNode}

  @doc """
  Renders a module node into a `{relative_path, contents}` tuple suitable for writing.
  """
  @spec render(ModuleNode.t(), Config.t()) :: {String.t(), String.t()}
  def render(%ModuleNode{} = node, %Config{} = config) do
    relative_path = module_path(node)
    frontmatter = Metadata.module_frontmatter(node, config.generated_at)
    body = module_body(node)
    contents = frontmatter <> "\n" <> body

    {relative_path, contents}
  end

  defp module_path(%ModuleNode{module: module}) do
    module
    |> Module.split()
    |> case do
      [root | rest] ->
        directories = Enum.take(rest, length(rest) - 1)
        file = List.last(rest, root)

        path =
          directories
          |> Enum.concat([file <> ".md"])
          |> Path.join()

        Path.join(String.downcase(root), path)

      [] ->
        "module.md"
    end
  end

  defp module_body(%ModuleNode{} = node) do
    body_sections = [
      module_title(node),
      moduledoc(node),
      docs_groups(node)
    ]

    body_sections
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
    |> String.trim()
  end

  defp module_title(%ModuleNode{title: title, module: module}) do
    "# #{title || inspect(module)}"
  end

  defp moduledoc(%ModuleNode{source_doc: source}) do
    source
    |> normalize_markdown()
  end

  defp docs_groups(%ModuleNode{docs_groups: groups}) when groups == [], do: ""

  defp docs_groups(%ModuleNode{docs_groups: groups}) do
    groups
    |> Enum.map(&render_group/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp render_group(%DocGroupNode{title: title, docs: docs}) do
    rendered_docs =
      docs
      |> Enum.map(&render_doc/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n\n")

    case rendered_docs do
      "" ->
        ""

      _ ->
        [group_heading(title), rendered_docs]
        |> Enum.reject(&(&1 == ""))
        |> Enum.join("\n\n")
    end
  end

  defp render_doc(%DocNode{} = doc) do
    parts = [
      doc_heading(doc),
      render_signature(doc),
      normalize_markdown(doc.source_doc),
      render_specs(doc)
    ]

    parts
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp doc_heading(%DocNode{name: name, arity: arity}) do
    heading = "#{name}/#{arity}"
    "### #{heading}"
  end

  defp render_signature(%DocNode{signature: signature}) when is_binary(signature) do
    case String.trim(signature) do
      "" ->
        ""

      trimmed ->
        """
        ```elixir
        #{trimmed}
        ```
        """
        |> String.trim()
    end
  end

  defp render_signature(_), do: ""

  defp render_specs(%DocNode{specs: []}), do: ""

  defp render_specs(%DocNode{specs: specs}) do
    specs
    |> Enum.map(&spec_to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] ->
        ""

      rendered ->
        """
        ```elixir
        #{Enum.join(rendered, "\n")}
        ```
        """
        |> String.trim()
    end
  end

  defp spec_to_string(spec) when is_binary(spec), do: String.trim(spec)
  defp spec_to_string(spec), do: spec |> Macro.to_string() |> String.trim()

  defp group_heading(nil), do: "## Functions"
  defp group_heading(title) when is_binary(title), do: "## #{title}"

  defp group_heading(title) when is_atom(title) do
    formatted =
      title
      |> Atom.to_string()
      |> String.replace("_", " ")
      |> String.split()
      |> Enum.map(&String.capitalize/1)
      |> Enum.join(" ")

    "## #{formatted}"
  end

  defp normalize_markdown(nil), do: ""

  defp normalize_markdown(%{"en" => doc}) when is_binary(doc) do
    doc
    |> String.trim()
    |> Wikilinks.convert()
  end

  defp normalize_markdown(doc) when is_binary(doc) do
    doc
    |> String.trim()
    |> Wikilinks.convert()
  end
end
