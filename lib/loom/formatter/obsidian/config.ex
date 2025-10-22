defmodule Loom.Formatter.Obsidian.Config do
  @moduledoc false

  defstruct output_path: nil,
            vault_name: nil,
            generated_at: Date.utc_today(),
            formatter_opts: %{}

  @type t :: %__MODULE__{
          output_path: String.t(),
          vault_name: String.t() | nil,
          generated_at: Date.t(),
          formatter_opts: map()
        }

  @doc """
  Builds a formatter config from the ExDoc config map.
  """
  @spec build(map()) :: t()
  def build(%{output: output} = config) do
    generated_at =
      case Map.get(config, :obsidian, %{}) do
        %{generated_at: %Date{} = date} -> date
        _ -> Date.utc_today()
      end

    opts = Map.get(config, :obsidian, %{})

    %__MODULE__{
      output_path: Path.expand(output),
      vault_name: Map.get(opts, :vault_name),
      generated_at: generated_at,
      formatter_opts: opts
    }
  end
end
