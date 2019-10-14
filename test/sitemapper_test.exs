defmodule SitemapperTest do
  use ExUnit.Case
  doctest Sitemapper

  alias Sitemapper.URL

  setup_all do
    Application.put_env(:sitemapper, :store, Sitemapper.TestStore)
    Application.put_env(:sitemapper, :url, "http://example.org/")
  end

  test "generate with 50,001 URLs" do
    response =
      Stream.concat([1..50_002])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate()

    assert response == :ok
  end
end
