defmodule Loom.Tags do
  @moduledoc """
  Normalizes tag lists into Obsidian-friendly hierarchical identifiers.

  Rules:

    * Accept atoms or strings, converting everything to lowercase strings.
    * Replace whitespace with hyphens within tag segments.
    * Preserve forward-slash hierarchy, normalizing each segment.
    * Remove duplicates and empty entries.
  """

  @doc """
  Normalizes and de-duplicates a list of tags.
  """
  @spec normalize([String.t() | atom()]) :: [String.t()]
  def normalize(tags) when is_list(tags) do
    tags
    |> Enum.map(&normalize_tag/1)
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.uniq()
    |> Enum.sort()
  end

  def normalize(_), do: []

  defp normalize_tag(tag) when is_atom(tag),
    do: tag |> Atom.to_string() |> normalize_tag()

  defp normalize_tag(tag) when is_binary(tag) do
    tag
    |> String.trim()
    |> case do
      "" ->
        nil

      value ->
        value
        |> String.split("/", trim: true)
        |> Enum.map(&normalize_segment/1)
        |> Enum.join("/")
    end
  end

  defp normalize_tag(_), do: nil

  defp normalize_segment(segment) do
    segment
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\- ]/, "")
    |> String.replace(~r/\s+/, "-")
    |> String.trim("-")
  end
end
