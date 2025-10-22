defmodule Loom.Metadata do
  @moduledoc """
  Utility helpers for building the YAML frontmatter that Obsidian consumes.

  The metadata schema follows the design outlined in
  `refs/obsidian-flavored-markdown.md`, starting with the minimum set of
  required properties and progressively adding optional fields when the source
  data is available.
  """

  alias ExDoc.ModuleNode

  @type frontmatter :: [{String.t(), String.t() | [String.t()]}]

  @doc """
  Produces an Obsidian frontmatter block for the given module node.
  """
  @spec module_frontmatter(ModuleNode.t(), Date.t()) :: String.t()
  def module_frontmatter(%ModuleNode{} = node, %Date{} = generated_at) do
    metadata =
      []
      |> append({"title", node_title(node)})
      |> append({"type", "module"})
      |> append({"module", inspect(node.module)})
      |> maybe_append({"category", module_category(node)})
      |> maybe_append({"status", module_status(node)})
      |> maybe_append({"source", module_source(node)})
      |> maybe_append({"tags", module_tags(node)})
      |> append({"created", Date.to_iso8601(generated_at)})
      |> append({"modified", Date.to_iso8601(generated_at)})

    frontmatter_block(metadata)
  end

  defp node_title(%ModuleNode{title: nil, module: module}) do
    inspect(module)
  end

  defp node_title(%ModuleNode{title: title}) do
    title
  end

  defp module_source(%ModuleNode{metadata: metadata, moduledoc_file: file})
       when is_binary(file) and file != "" do
    Map.get(metadata || %{}, :source_path, file)
  end

  defp module_source(%ModuleNode{metadata: metadata}) when is_map(metadata) do
    Map.get(metadata, :source_path) || Map.get(metadata, :source)
  end

  defp module_source(_), do: nil

  defp module_status(%ModuleNode{deprecated: message}) when is_binary(message),
    do: "deprecated"

  defp module_status(%ModuleNode{annotations: annotations}) do
    annotations
    |> List.wrap()
    |> Enum.find(fn ann ->
      ann in ["stable", "experimental", "deprecated", :stable, :experimental, :deprecated]
    end)
    |> case do
      nil -> nil
      value -> value |> to_string()
    end
  end

  defp module_category(%ModuleNode{group: group}) when is_binary(group), do: group
  defp module_category(%ModuleNode{group: group}) when is_atom(group), do: Atom.to_string(group)
  defp module_category(_), do: nil

  defp module_tags(%ModuleNode{annotations: annotations}) do
    annotations
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.reject(&(&1 == ""))
    |> case do
      [] -> nil
      tags -> tags
    end
  end

  defp frontmatter_block(metadata) do
    data =
      metadata
      |> Enum.map(&serialize/1)
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")

    """
    ---
    #{data}
    ---
    """
    |> String.trim()
  end

  defp maybe_append(list, {_key, nil}), do: list
  defp maybe_append(list, {_key, []}), do: list
  defp maybe_append(list, entry), do: append(list, entry)

  defp append(list, entry), do: list ++ [entry]

  defp serialize({key, value}) when is_binary(value) do
    "#{key}: #{value}"
  end

  defp serialize({key, list}) when is_list(list) do
    serialized_items =
      list
      |> Enum.map(&"  - #{&1}")
      |> Enum.join("\n")

    "#{key}:\n#{serialized_items}"
  end
end
