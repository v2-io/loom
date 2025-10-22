defmodule Loom.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/josephwecker/loom"

  def project do
    [
      app: :loom,
      version: @version,
      elixir: "~> 1.18",
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

  defp deps do
    [
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
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
