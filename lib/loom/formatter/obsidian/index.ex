defmodule Loom.Formatter.Obsidian.Index do
  @moduledoc false

  alias Loom.Formatter.Obsidian.Config

  @doc """
  Generates Dataview-powered index pages.
  """
  @spec generate([ExDoc.ModuleNode.t()], Config.t()) :: [{String.t(), String.t()}]
  def generate(_modules, %Config{} = config) do
    [
      {"indexes/module-index.md", module_index(config)}
    ]
  end

  defp module_index(%Config{generated_at: generated_at}) do
    date = Date.to_iso8601(generated_at)

    """
    ---
    title: Module Index
    type: index
    generated: true
    created: #{date}
    modified: #{date}
    ---

    # Loom Module Index

    ## Modules by Category

    ```dataview
    TABLE module, status, category
    FROM ""
    WHERE type = "module"
    SORT category, module
    ```

    ## GenServers

    ```dataview
    LIST
    FROM ""
    WHERE type = "module" AND contains(tags, "elixir/otp/genserver")
    ```

    ## Recently Updated

    ```dataview
    TABLE file.mtime as "Updated", module
    FROM ""
    WHERE type = "module"
    SORT file.mtime DESC
    LIMIT 10
    ```
    """
    |> String.trim()
  end
end
