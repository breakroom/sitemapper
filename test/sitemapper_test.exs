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

  test "generate with complex URLs" do
    opts = [
      sitemap_url: "http://example.org/foo"
    ]

    elements =
      Stream.concat([1..100])
      |> Stream.map(fn i ->
        %URL{
          loc: "http://example.com/#{i}",
          priority: 0.5,
          lastmod: ~U[2020-01-01 00:00:00Z],
          changefreq: :hourly
        }
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 2
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml.gz"
    assert Enum.at(elements, 0) |> elem(1) |> IO.iodata_length() == 505
    assert Enum.at(elements, 1) |> elem(0) == "sitemap.xml.gz"
    assert Enum.at(elements, 1) |> elem(1) |> IO.iodata_length() == 177
  end

  test "generate with 50,000 URLs" do
    opts = [
      sitemap_url: "http://example.org/foo"
    ]

    elements =
      Stream.concat([1..50_000])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 2
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml.gz"
    assert Enum.at(elements, 0) |> elem(1) |> IO.iodata_length() == 127_957
    assert Enum.at(elements, 1) |> elem(0) == "sitemap.xml.gz"
    assert Enum.at(elements, 1) |> elem(1) |> IO.iodata_length() == 177
  end

  test "generate with 50,001 URLs" do
    opts = [
      sitemap_url: "http://example.org/foo"
    ]

    elements =
      Stream.concat([1..50_001])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 3
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml.gz"
    assert Enum.at(elements, 1) |> elem(0) == "sitemap-00002.xml.gz"
    assert Enum.at(elements, 2) |> elem(0) == "sitemap.xml.gz"
  end

  test "generate with gzip disabled" do
    opts = [
      sitemap_url: "http://example.org/foo",
      gzip: false,
      index_lastmod: ~D[2020-01-01]
    ]

    elements =
      Stream.concat([1..100])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(opts)

    sitemap_00001_contents = File.read!(Path.join(__DIR__, "fixtures/sitemap-00001.xml"))
    sitemap_index_contents = File.read!(Path.join(__DIR__, "fixtures/sitemap.xml"))

    assert Enum.count(elements) == 2
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml"
    assert Enum.at(elements, 0) |> elem(1) |> IO.chardata_to_string() == sitemap_00001_contents
    assert Enum.at(elements, 1) |> elem(0) == "sitemap.xml"
    assert Enum.at(elements, 1) |> elem(1) |> IO.chardata_to_string() == sitemap_index_contents
  end

  test "generate with an alternative name" do
    opts = [
      sitemap_url: "http://example.org/foo",
      name: "alt"
    ]

    elements =
      Stream.concat([1..50_000])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 2
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-alt-00001.xml.gz"
    assert Enum.at(elements, 1) |> elem(0) == "sitemap-alt.xml.gz"
  end

  test "generate and persist" do
    store_path = File.cwd!() |> Path.join("test/store")
    File.mkdir_p!(store_path)

    opts = [
      sitemap_url: "http://example.org/foo",
      store: Sitemapper.FileStore,
      store_config: [
        path: store_path
      ]
    ]


    elements =
      Stream.concat([1..50_002])
      |> Stream.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Sitemapper.generate(opts)
      |> Sitemapper.persist(opts)

    assert Enum.count(elements) == 3
  end
end
