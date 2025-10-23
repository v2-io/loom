defmodule Loom.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/josephwecker/loom"

  def project do
    [
      app: :loom,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      docs: docs(),
      name: "Loom",
      source_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # ex_doc must be available at compile time (not runtime) for formatter integration
      # Remove `only: [:dev, :test]` so it's available when Loom is used as dependency
      {:ex_doc, "~> 0.34", runtime: false}
    ]
  end

  defp description do
    """
    Weave living documentation for AI agents. Transforms Elixir code, PRAXES patterns,
    and architecture docs into Obsidian-flavored markdown with rich cross-references,
    queryable metadata, and knowledge graph topology.
    """
  end

  defp package do
    [
      name: "loom",
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => @source_url,
        "Docs" => "https://hexdocs.pm/loom"
      }
    ]
  end

  defp docs do
    [
      main: "Loom",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "thoughts.md",
        "obsidian-flavored-markdown.md"
      ],
      groups_for_extras: [
        "Design Documents": ~r/thoughts|obsidian/
      ]
    ]
  end
end
