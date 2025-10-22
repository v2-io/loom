defmodule Loom.Vault.Graph do
  @moduledoc """
  Maintains forward/backward wikilink edges and hierarchical tag indices for a
  generated vault.

  The structure is intentionally lightweight so it can be embedded inside a
  supervising process or persisted to disk by a future Loom vault service. All
  operations are designed to be incremental: upserting a document updates only
  the edges and tags that changed.
  """

  alias Loom.Tags

  defstruct forwards: %{},
            backlinks: %{},
            doc_tags: %{},
            tag_index: %{},
            metadata: %{}

  @wikilink_regex ~r/!?\[\[([^\]]+)\]\]/

  @type doc_id :: String.t()
  @type link :: String.t()
  @type tag :: String.t()
  @type metadata :: map()

  @type t :: %__MODULE__{
          forwards: %{optional(doc_id) => MapSet.t(link)},
          backlinks: %{optional(link) => MapSet.t(doc_id)},
          doc_tags: %{optional(doc_id) => MapSet.t(tag)},
          tag_index: %{optional(tag) => MapSet.t(doc_id)},
          metadata: %{optional(doc_id) => metadata}
        }

  @type upsert_opts ::
          [
            {:content, String.t()},
            {:links, Enumerable.t(link)},
            {:tags, Enumerable.t(tag)},
            {:metadata, metadata}
          ]

  @type diff :: %{
          added_links: MapSet.t(link),
          removed_links: MapSet.t(link),
          added_tags: MapSet.t(tag),
          removed_tags: MapSet.t(tag)
        }

  @doc """
  Returns an empty graph.
  """
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc """
  Upserts a document with the given options and returns both the updated graph
  and the diff that callers can use for incremental downstream updates.
  """
  @spec upsert(t(), doc_id, upsert_opts) :: {t(), diff}
  def upsert(%__MODULE__{} = graph, doc_id, opts \\ []) when is_binary(doc_id) do
    content = Keyword.get(opts, :content, "")

    links =
      opts
      |> Keyword.get_lazy(:links, fn -> extract_links(content) end)
      |> MapSet.new()

    normalized_tags =
      opts
      |> Keyword.get(:tags, [])
      |> Tags.normalize()
      |> MapSet.new()

    metadata = Keyword.get(opts, :metadata, %{})

    prev_links = Map.get(graph.forwards, doc_id, MapSet.new())
    prev_tags = Map.get(graph.doc_tags, doc_id, MapSet.new())

    diff = %{
      added_links: MapSet.difference(links, prev_links),
      removed_links: MapSet.difference(prev_links, links),
      added_tags: MapSet.difference(normalized_tags, prev_tags),
      removed_tags: MapSet.difference(prev_tags, normalized_tags)
    }

    graph =
      graph
      |> store_forward_links(doc_id, links)
      |> update_backlinks(doc_id, prev_links, links)
      |> update_tags(doc_id, prev_tags, normalized_tags)
      |> put_metadata(doc_id, metadata)

    {graph, diff}
  end

  @doc """
  Removes the given document from the graph.
  """
  @spec delete(t(), doc_id) :: {t(), diff}
  def delete(%__MODULE__{} = graph, doc_id) when is_binary(doc_id) do
    prev_links = Map.get(graph.forwards, doc_id, MapSet.new())
    prev_tags = Map.get(graph.doc_tags, doc_id, MapSet.new())

    diff = %{
      added_links: MapSet.new(),
      removed_links: prev_links,
      added_tags: MapSet.new(),
      removed_tags: prev_tags
    }

    graph =
      graph
      |> remove_forward_links(doc_id)
      |> remove_backlinks(doc_id, prev_links)
      |> remove_tags(doc_id, prev_tags)
      |> remove_metadata(doc_id)

    {graph, diff}
  end

  @doc """
  Returns the outgoing links for a document.
  """
  @spec forward_links(t(), doc_id) :: MapSet.t(link)
  def forward_links(%__MODULE__{} = graph, doc_id) do
    Map.get(graph.forwards, doc_id, MapSet.new())
  end

  @doc """
  Returns the backlinks pointing to the given link/document.
  """
  @spec backlinks(t(), link) :: MapSet.t(doc_id)
  def backlinks(%__MODULE__{} = graph, link) do
    Map.get(graph.backlinks, link, MapSet.new())
  end

  @doc """
  Returns the tags attached to a document.
  """
  @spec tags(t(), doc_id) :: MapSet.t(tag)
  def tags(%__MODULE__{} = graph, doc_id) do
    Map.get(graph.doc_tags, doc_id, MapSet.new())
  end

  @doc """
  Returns the document ids associated with a tag.
  """
  @spec documents_with_tag(t(), tag) :: MapSet.t(doc_id)
  def documents_with_tag(%__MODULE__{} = graph, tag) do
    Map.get(graph.tag_index, tag, MapSet.new())
  end

  @doc """
  Returns stored metadata for a document (or an empty map if none has been recorded).
  """
  @spec metadata(t(), doc_id) :: metadata
  def metadata(%__MODULE__{} = graph, doc_id) do
    Map.get(graph.metadata, doc_id, %{})
  end

  @doc """
  Extracts wikilinks from markdown. Supports aliases (splits at `|`) and ignores embeds.
  """
  @spec extract_links(String.t()) :: [link]
  def extract_links(markdown) when is_binary(markdown) do
    @wikilink_regex
    |> Regex.scan(markdown)
    |> Enum.reduce([], fn [match, target], acc ->
      if String.starts_with?(match, "!") do
        acc
      else
        [normalize_link(target) | acc]
      end
    end)
    |> Enum.reverse()
    |> Enum.uniq()
  end

  def extract_links(_), do: []

  defp normalize_link(target) do
    target
    |> String.split("|", parts: 2)
    |> hd()
    |> String.trim()
  end

  defp store_forward_links(%__MODULE__{} = graph, doc_id, links) do
    %__MODULE__{graph | forwards: Map.put(graph.forwards, doc_id, links)}
  end

  defp remove_forward_links(%__MODULE__{} = graph, doc_id) do
    %__MODULE__{graph | forwards: Map.delete(graph.forwards, doc_id)}
  end

  defp update_backlinks(%__MODULE__{} = graph, doc_id, prev_links, new_links) do
    backlinks =
      graph.backlinks
      |> remove_backlink_entries(doc_id, prev_links)
      |> add_backlink_entries(doc_id, new_links)

    %__MODULE__{graph | backlinks: backlinks}
  end

  defp remove_backlinks(%__MODULE__{} = graph, doc_id, links) do
    backlinks = remove_backlink_entries(graph.backlinks, doc_id, links)
    %__MODULE__{graph | backlinks: backlinks}
  end

  defp remove_backlink_entries(backlinks, doc_id, links) do
    Enum.reduce(links, backlinks, fn link, acc ->
      Map.update(acc, link, MapSet.new(), fn set ->
        set
        |> MapSet.delete(doc_id)
        |> empty_to_nil()
      end)
      |> prune_nil(link)
    end)
  end

  defp add_backlink_entries(backlinks, doc_id, links) do
    Enum.reduce(links, backlinks, fn link, acc ->
      Map.update(acc, link, MapSet.new([doc_id]), &MapSet.put(&1, doc_id))
    end)
  end

  defp update_tags(%__MODULE__{} = graph, doc_id, prev_tags, new_tags) do
    tag_index =
      graph.tag_index
      |> remove_tag_entries(doc_id, prev_tags)
      |> add_tag_entries(doc_id, new_tags)

    %__MODULE__{graph | tag_index: tag_index, doc_tags: Map.put(graph.doc_tags, doc_id, new_tags)}
  end

  defp remove_tags(%__MODULE__{} = graph, doc_id, tags) do
    tag_index = remove_tag_entries(graph.tag_index, doc_id, tags)

    %__MODULE__{
      graph
      | tag_index: tag_index,
        doc_tags: Map.delete(graph.doc_tags, doc_id)
    }
  end

  defp remove_tag_entries(tag_index, doc_id, tags) do
    Enum.reduce(tags, tag_index, fn tag, acc ->
      Map.update(acc, tag, MapSet.new(), fn set ->
        set
        |> MapSet.delete(doc_id)
        |> empty_to_nil()
      end)
      |> prune_nil(tag)
    end)
  end

  defp add_tag_entries(tag_index, doc_id, tags) do
    Enum.reduce(tags, tag_index, fn tag, acc ->
      Map.update(acc, tag, MapSet.new([doc_id]), &MapSet.put(&1, doc_id))
    end)
  end

  defp put_metadata(%__MODULE__{} = graph, doc_id, metadata) when is_map(metadata) do
    %__MODULE__{graph | metadata: Map.put(graph.metadata, doc_id, metadata)}
  end

  defp put_metadata(%__MODULE__{} = graph, doc_id, _metadata) do
    remove_metadata(graph, doc_id)
  end

  defp remove_metadata(%__MODULE__{} = graph, doc_id) do
    %__MODULE__{graph | metadata: Map.delete(graph.metadata, doc_id)}
  end

  defp empty_to_nil(set) do
    if MapSet.size(set) == 0, do: nil, else: set
  end

  defp prune_nil(map, key) do
    case Map.get(map, key) do
      nil -> Map.delete(map, key)
      _ -> map
    end
  end
end
