defmodule SitemapperTest do
  use ExUnit.Case
  doctest Sitemapper

  alias Sitemapper.URL

  test "generate with 0 URLs" do
    opts = [
      sitemap_url: "http://example.org/foo"
    ]

    elements =
      Stream.concat([])
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 0
  end

  test "generate with 50,000 URLs" do
    opts = [
      sitemap_url: "http://example.org/foo"
    ]

    elements =
      Stream.concat([1..50_001])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 2
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml.gz"
    assert Enum.at(elements, 1) |> elem(0) == "sitemap.xml.gz"
  end

  test "generate with 50,001 URLs" do
    opts = [
      sitemap_url: "http://example.org/foo"
    ]

    elements =
      Stream.concat([1..50_002])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 3
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml.gz"
    assert Enum.at(elements, 1) |> elem(0) == "sitemap-00002.xml.gz"
    assert Enum.at(elements, 2) |> elem(0) == "sitemap.xml.gz"
  end
end
