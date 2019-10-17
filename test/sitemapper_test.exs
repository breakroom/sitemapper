defmodule SitemapperTest do
  use ExUnit.Case
  doctest Sitemapper

  alias Sitemapper.URL

  test "generate with 50,001 URLs" do
    path = File.cwd!() |> Path.join("test/store")

    config = [
      store: Sitemapper.TestStore,
      store_config: [path: path],
      sitemap_url: "http://example.org/foo"
    ]

    response =
      Stream.concat([1..50_002])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(config)

    assert response == :ok
  end
end
