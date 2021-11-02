defmodule PhilomenaWeb.Autocomplete.AssociationController do
  use PhilomenaWeb, :controller

  alias Philomena.Elasticsearch
  alias Philomena.Images.Image
  alias Philomena.Tags.Tag
  alias Philomena.Repo
  import Ecto.Query

  @spec create(Plug.Conn.t(), any) :: Plug.Conn.t()
  def create(conn, params) do
    tags =
      case extract_tags(params) do
        [] ->
          []

        tags ->
          queries = Enum.map(tags, &%{term: %{"namespaced_tags.name" => &1}})

          tag_ids =
            Image
            |> Elasticsearch.search(%{
              query: %{
                bool: %{
                  must: queries
                }
              },
              size: 0,
              aggregations: %{
                sample: %{
                  sampler: %{shard_size: 100},
                  aggregations: %{
                    related: %{
                      terms: %{
                        field: "tag_ids",
                        size: 50
                      }
                    }
                  }
                }
              }
            })
            |> Kernel.get_in(["aggregations", "sample", "related", "buckets"])
            |> Enum.map(&String.to_integer(&1["key"]))

          Tag
          |> where([t], t.id in ^tag_ids and t.name not in ^tags)
          |> Repo.all()
          |> Enum.map(&%{label: "#{&1.name} (#{&1.images_count})", value: &1.name})
      end

    json(conn, tags)
  end

  @spec extract_tags(any) :: [String.t()]
  defp extract_tags(%{"tags" => tags}) when is_list(tags) do
    tags
    |> Enum.filter(&is_binary/1)
    |> Enum.filter(&String.valid?/1)
    |> Enum.map(&String.downcase/1)
    |> Enum.map(&String.trim/1)
  end

  defp extract_tags(_params), do: []
end
