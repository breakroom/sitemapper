defmodule Sitemapper.SitemapGeneratorTest do
  use ExUnit.Case
  doctest Sitemapper.SitemapGenerator

  alias Sitemapper.{File, SitemapGenerator, URL}

  test "add_url and finalize with a simple URL" do
    url = %URL{loc: "http://example.com"}

    %File{count: count, length: length, body: body} =
      SitemapGenerator.new()
      |> SitemapGenerator.add_url(url)
      |> SitemapGenerator.finalize()

    assert count == 1
    assert length == 330

    assert IO.chardata_to_string(body) ==
             "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<urlset xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd\" xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n<url>\n  <loc>http://example.com</loc>\n</url>\n</urlset>\n"

    assert length == IO.iodata_length(body)
  end

  test "add_url with more than 50,000 URLs" do
    result =
      0..50_000
      |> Enum.map(fn i ->
        %URL{loc: "http://example.com/#{i}"}
      end)
      |> Enum.reduce(SitemapGenerator.new(), fn url, acc ->
        SitemapGenerator.add_url(acc, url)
      end)

    assert result == {:error, :over_count}
  end

  test "add_url with more than 50MB" do
    {error, %File{count: count, length: length, body: body}} =
      0..50_000
      |> Enum.map(fn i ->
        block = String.duplicate("a", 1024)
        %URL{loc: "http://example.com/#{block}/#{i}"}
      end)
      |> Enum.reduce_while(SitemapGenerator.new(), fn url, acc ->
        case SitemapGenerator.add_url(acc, url) do
          {:error, _} = err ->
            acc = SitemapGenerator.finalize(acc)
            {:halt, {err, acc}}

          other ->
            {:cont, other}
        end
      end)

    assert error == {:error, :over_length}
    assert count == 48735
    assert length == 52_428_035
    assert length == IO.iodata_length(body)
  end
end
