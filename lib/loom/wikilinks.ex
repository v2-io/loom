defmodule Loom.Wikilinks do
  @moduledoc """
  Converts inline code references from ExDoc output into Obsidian wikilinks.

  Supported conversions (see `refs/obsidian-flavored-markdown.md`):

    * `` `MyApp.Module` `` → `[[MyApp.Module]]`
    * `` `MyApp.Module.function/2` `` → `[[MyApp.Module#function/2]]`
    * `` `function/1` `` → `[[#function/1]]`
  """

  @module_call ~r/`([A-Z][A-Za-z0-9_.]*)\.([a-z_][a-z0-9_]*\/\d+)`/
  @module ~r/`([A-Z][A-Za-z0-9_.]*)`/
  @local_call ~r/`([a-z_][a-z0-9_]*\/\d+)`/

  @doc """
  Converts eligible inline code references into wikilinks.
  """
  @spec convert(String.t()) :: String.t()
  def convert(text) when is_binary(text) do
    text
    |> convert_module_calls()
    |> convert_modules()
    |> convert_local_calls()
  end

  defp convert_module_calls(text) do
    Regex.replace(@module_call, text, fn _, module, fun ->
      "[[#{module}##{fun}]]"
    end)
  end

  defp convert_modules(text) do
    Regex.replace(@module, text, fn _, module ->
      "[[#{module}]]"
    end)
  end

  defp convert_local_calls(text) do
    Regex.replace(@local_call, text, fn _, fun ->
      "[[#" <>
        fun <>
        "]]"
    end)
  end
end
