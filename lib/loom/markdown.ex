defmodule Loom.Markdown do
  @moduledoc """
  Normalizes markdown content produced by ExDoc to align with Loom's
  Obsidian-flavored dialect.

  Responsibilities:

    * Convert conventional ExDoc headings (`## WARNING`, etc.) into Obsidian
      callouts (`> [!warning] ...`).
    * Apply wikilink conversion for module/function references.
    * Trim surrounding whitespace while preserving intentional spacing inside
      the content.
  """

  alias Loom.Wikilinks

  @callout_map [
    {"WARNING", "warning"},
    {"NOTE", "note"},
    {"EXAMPLE", "example"},
    {"DEPRECATED", "danger"},
    {"TIP", "tip"},
    {"PRAXIS", "praxis"},
    {"ARCHITECTURE", "architecture"},
    {"MISSION CRITICAL", "mission-critical"},
    {"MISSION-CRITICAL", "mission-critical"}
  ]

  @doc """
  Applies callout conversion, wikilink normalization, and whitespace trimming.
  """
  @spec normalize(String.t()) :: String.t()
  def normalize(text) when is_binary(text) do
    text
    |> String.trim()
    |> convert_callouts()
    |> Wikilinks.convert()
  end

  defp convert_callouts(text) do
    Enum.reduce(callout_regexes(), text, fn {_heading, callout, regex}, acc ->
      Regex.replace(regex, acc, fn _match, body ->
        body =
          body
          |> String.trim()
          |> prefix_lines("> ")

        """
        > [!#{callout}]
        #{body}
        """
        |> String.trim()
      end)
    end)
  end

  defp prefix_lines("", _prefix), do: ""

  defp prefix_lines(content, prefix) do
    content
    |> String.split("\n")
    |> Enum.map(fn line ->
      cond do
        String.trim(line) == "" -> prefix
        true -> prefix <> line
      end
    end)
    |> Enum.join("\n")
  end

  defp callout_regexes do
    for {heading, callout} <- @callout_map do
      {
        heading,
        callout,
        ~r/^##\s+#{heading}\s*\n(?<body>.*?)(?=^##\s+\S|\z)/ims
      }
    end
  end
end
