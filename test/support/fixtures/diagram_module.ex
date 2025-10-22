defmodule Loom.Support.DiagramModule do
  @moduledoc """
  Fixture module that advertises a supervision tree via metadata.
  """

  @moduledoc loom_diagrams: [
               %{
                 title: "Lifecycle Diagram",
                 code: """
                 graph TD
                   Start --> Init
                   Init --> Running
                   Running --> Shutdown
                 """
               }
             ],
             tags: ["elixir/otp/genserver"],
             category: :runtime

  @doc """
  No-op function used only to keep the module externals simple.
  """
  def run, do: :ok
end
