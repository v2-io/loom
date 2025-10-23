defmodule Loom.Metadata do
  @moduledoc """
  Utility helpers for building the YAML frontmatter that Obsidian consumes.

  The metadata schema follows the design outlined in
  `refs/obsidian-flavored-markdown.md`, starting with the minimum set of
  required properties and progressively adding optional fields when the source
  data is available.
  """

  alias ExDoc.ModuleNode
  alias Loom.Tags

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

  defp module_status(%ModuleNode{annotations: annotations, metadata: metadata}) do
    status_candidates =
      annotations
      |> List.wrap()
      |> Enum.map(&normalize_status/1)

    metadata_status =
      case metadata do
        %{status: status} -> normalize_status(status)
        %{"status" => status} -> normalize_status(status)
        _ -> nil
      end

    [metadata_status | status_candidates]
    |> Enum.filter(&(&1 in ["stable", "experimental", "deprecated"]))
    |> List.first()
  end

  defp module_category(%ModuleNode{metadata: %{category: category}}),
    do: normalize_category(category)

  defp module_category(%ModuleNode{metadata: %{"category" => category}}),
    do: normalize_category(category)

  defp module_category(%ModuleNode{group: group}) when is_binary(group),
    do: normalize_category(group)

  defp module_category(%ModuleNode{group: group}) when is_atom(group),
    do: normalize_category(Atom.to_string(group))

  defp module_category(_), do: nil

  defp module_tags(%ModuleNode{annotations: annotations, metadata: metadata}) do
    metadata_tags =
      case metadata do
        %{tags: tags} -> List.wrap(tags)
        %{"tags" => tags} -> List.wrap(tags)
        _ -> []
      end

    annotations
    |> List.wrap()
    |> Enum.map(&to_string/1)
    |> Enum.concat(metadata_tags)
    |> Tags.normalize()
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

  defp normalize_status(value) when is_atom(value),
    do: value |> Atom.to_string() |> normalize_status()

  defp normalize_status(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> nil
      other -> other
    end
  end

  defp normalize_status(_), do: nil

  defp normalize_category(value) when is_atom(value),
    do: normalize_category(Atom.to_string(value))

  defp normalize_category(value) when is_binary(value) do
    value
    |> String.trim()
    |> String.downcase()
    |> case do
      "" -> nil
      other -> other
    end
  end

  defp normalize_category(_), do: nil

  defp serialize({key, value}) when is_binary(value) do
    "#{key}: #{value}"
  end

  # Handle charlist (list of integers) - convert to string
  defp serialize({key, value}) when is_list(value) do
    if :io_lib.printable_list(value) do
      # It's a charlist, convert to string
      "#{key}: #{to_string(value)}"
    else
      # It's a real list, serialize as YAML list
      serialized_items =
        value
        |> Enum.map(&"  - #{&1}")
        |> Enum.join("\n")

      "#{key}:\n#{serialized_items}"
    end
  end
end
