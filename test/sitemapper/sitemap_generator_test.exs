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
    assert count == 48_735
    assert length == 52_428_035
    assert length == IO.iodata_length(body)
  end

  test "add_url with images" do
    url = %URL{
      loc: "http://example.com",
      images: [
        %{loc: "http://example.com/image1.jpg"},
        %{loc: "http://example.com/image2.png"}
      ]
    }

    %File{count: count, length: length, body: body} =
      SitemapGenerator.new()
      |> SitemapGenerator.add_url(url)
      |> SitemapGenerator.finalize()

    assert count == 1

    xml_string = IO.chardata_to_string(body)
    assert String.contains?(xml_string, "<image:image>")
    assert String.contains?(xml_string, "<image:loc>http://example.com/image1.jpg</image:loc>")
    assert String.contains?(xml_string, "<image:loc>http://example.com/image2.png</image:loc>")
    assert length == IO.iodata_length(body)
  end

  test "add_url with more than 1000 images limits to 1000" do
    images = Enum.map(1..1001, fn i -> %{loc: "http://example.com/image#{i}.jpg"} end)

    url = %URL{
      loc: "http://example.com",
      images: images
    }

    %File{count: count, length: length, body: body} =
      SitemapGenerator.new()
      |> SitemapGenerator.add_url(url)
      |> SitemapGenerator.finalize()

    assert count == 1

    xml_string = IO.chardata_to_string(body)
    image_count = xml_string |> String.split("<image:image>") |> length() |> Kernel.-(1)
    assert image_count == 1000
    assert length == IO.iodata_length(body)
  end

  test "add_url with nil images" do
    url = %URL{loc: "http://example.com", images: nil}

    %File{count: count, length: length, body: body} =
      SitemapGenerator.new()
      |> SitemapGenerator.add_url(url)
      |> SitemapGenerator.finalize()

    assert count == 1

    xml_string = IO.chardata_to_string(body)
    refute String.contains?(xml_string, "<image:image>")
    assert length == IO.iodata_length(body)
  end

  test "conditional image namespace - no images means no namespace" do
    url = %URL{loc: "http://example.com"}

    %File{body: body} =
      SitemapGenerator.new()
      |> SitemapGenerator.add_url(url)
      |> SitemapGenerator.finalize()

    xml_string = IO.chardata_to_string(body)
    refute String.contains?(xml_string, "xmlns:image")
    assert String.contains?(xml_string, "xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"")
  end

  test "conditional image namespace - images present means namespace added" do
    url = %URL{
      loc: "http://example.com",
      images: [%{loc: "http://example.com/image.jpg"}]
    }

    %File{body: body} =
      SitemapGenerator.new()
      |> SitemapGenerator.add_url(url)
      |> SitemapGenerator.finalize()

    xml_string = IO.chardata_to_string(body)

    assert String.contains?(
             xml_string,
             "xmlns:image=\"http://www.google.com/schemas/sitemap-image/1.1\""
           )

    assert String.contains?(xml_string, "<image:image>")
  end

  test "conditional image namespace - mixed URLs add namespace when first image appears" do
    url_no_images = %URL{loc: "http://example.com/page1"}

    url_with_images = %URL{
      loc: "http://example.com/page2",
      images: [%{loc: "http://example.com/image.jpg"}]
    }

    %File{body: body} =
      SitemapGenerator.new()
      |> SitemapGenerator.add_url(url_no_images)
      |> SitemapGenerator.add_url(url_with_images)
      |> SitemapGenerator.finalize()

    xml_string = IO.chardata_to_string(body)

    assert String.contains?(
             xml_string,
             "xmlns:image=\"http://www.google.com/schemas/sitemap-image/1.1\""
           )

    assert String.contains?(xml_string, "<image:image>")
  end
end
