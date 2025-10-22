defmodule Loom.Formatter.Obsidian.Renderer do
  @moduledoc false

  alias Loom.Formatter.Obsidian.Config
  alias Loom.{Markdown, Metadata}
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
      docs_groups(node),
      diagram_sections(node)
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
    Markdown.normalize(doc)
  end

  defp normalize_markdown(doc) when is_binary(doc) do
    Markdown.normalize(doc)
  end

  defp normalize_markdown(_), do: ""

  defp diagram_sections(%ModuleNode{} = node) do
    node
    |> module_diagrams()
    |> Enum.map(&render_diagram/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp module_diagrams(%ModuleNode{metadata: metadata}) when is_map(metadata) do
    keys = [:loom_diagrams, :mermaid, :diagrams, "loom_diagrams", "mermaid", "diagrams"]

    keys
    |> Enum.flat_map(fn key ->
      metadata
      |> Map.get(key)
      |> diagrams_from_value()
    end)
    |> Enum.reject(&(&1 == %{}))
    |> Enum.uniq_by(&{Map.get(&1, :title), Map.get(&1, :code)})
  end

  defp module_diagrams(_), do: []

  defp diagrams_from_value(nil), do: []
  defp diagrams_from_value(list) when is_list(list), do: Enum.map(list, &normalize_diagram/1)
  defp diagrams_from_value(value), do: [normalize_diagram(value)]

  defp normalize_diagram(%{code: code} = diagram) when is_binary(code) do
    %{
      title: Map.get(diagram, :title) || Map.get(diagram, "title") || "Diagram",
      code: String.trim(code),
      type: Map.get(diagram, :type) || Map.get(diagram, "type") || :mermaid,
      description: Map.get(diagram, :description) || Map.get(diagram, "description")
    }
  end

  defp normalize_diagram(%{diagram: code} = diagram) when is_binary(code) do
    normalize_diagram(Map.put(diagram, :code, code))
  end

  defp normalize_diagram(code) when is_binary(code) do
    %{
      title: "Diagram",
      code: String.trim(code),
      type: :mermaid
    }
  end

  defp normalize_diagram(_), do: %{}

  defp render_diagram(%{code: code} = diagram) when is_binary(code) and code != "" do
    case normalize_diagram_type(Map.get(diagram, :type)) do
      :mermaid -> render_mermaid_diagram(diagram)
      _ -> ""
    end
  end

  defp render_diagram(_), do: ""

  defp render_mermaid_diagram(%{title: title, code: code, description: description}) do
    sections = [
      diagram_heading(title),
      maybe_description(description),
      "```mermaid\n#{code}\n```"
    ]

    sections
    |> Enum.reject(&(&1 == ""))
    |> Enum.join("\n\n")
  end

  defp normalize_diagram_type(type) when type in [:mermaid, "mermaid"], do: :mermaid
  defp normalize_diagram_type(_), do: :unknown

  defp diagram_heading(nil), do: "## Diagram"
  defp diagram_heading(title) when is_binary(title), do: "## #{title}"

  defp maybe_description(nil), do: ""

  defp maybe_description(text) when is_binary(text) do
    text
    |> Markdown.normalize()
  end
end
