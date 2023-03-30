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

    assert Enum.empty?(elements)
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
          lastmod: ~D[2020-01-01],
          changefreq: :hourly
        }
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 2
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml.gz"
    assert Enum.at(elements, 0) |> elem(1) |> unzip() == fixture_content("sitemap-100-urls.xml")
    assert Enum.at(elements, 1) |> elem(0) == "sitemap.xml.gz"

    assert Enum.at(elements, 1) |> elem(1) |> unzip() ==
             fixture_content("sitemap-index-with-one-file.xml")
             |> with_todays_date()
             |> with_a_gzip_file_extension()
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
    assert Enum.at(elements, 0) |> elem(1) |> unzip() == fixture_content("sitemap-50000-urls.xml")
    assert Enum.at(elements, 1) |> elem(0) == "sitemap.xml.gz"

    assert Enum.at(elements, 1) |> elem(1) |> unzip() ==
             fixture_content("sitemap-index-with-one-file.xml")
             |> with_todays_date()
             |> with_a_gzip_file_extension()
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
        %URL{
          loc: "http://example.com/#{i}",
          lastmod: ~D[2020-01-01],
          priority: 0.5,
          changefreq: :hourly
        }
      end)
      |> Sitemapper.generate(opts)

    assert Enum.count(elements) == 2
    assert Enum.at(elements, 0) |> elem(0) == "sitemap-00001.xml"

    assert Enum.at(elements, 0) |> elem(1) |> IO.chardata_to_string() ==
             fixture_content("sitemap-100-urls.xml")

    assert Enum.at(elements, 1) |> elem(0) == "sitemap.xml"

    assert Enum.at(elements, 1) |> elem(1) |> IO.chardata_to_string() ==
             fixture_content("sitemap-index-with-one-file.xml")
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

  defp unzip(data) do
    :zlib.gunzip(data)
  end

  defp fixture_content(name) do
    File.read!(Path.join([__DIR__, "fixtures", name]))
  end

  defp with_todays_date(str) do
    today = Date.utc_today() |> Date.to_iso8601()

    String.replace(str, "2020-01-01", today)
  end

  defp with_a_gzip_file_extension(str) do
    String.replace(str, ".xml", ".xml.gz")
  end
end
