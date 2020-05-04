defmodule Sitemapper.SitemapGenerator do
  alias Sitemapper.{Encoder, File, URL}

  @max_length 52_428_800
  @max_count 50_000

  @dec "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  @urlset_start "<urlset xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd\" xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">"
  @urlset_end "</urlset>"

  @line_sep "\n"
  @line_sep_length String.length(@line_sep)

  @end_length String.length(@urlset_end) + @line_sep_length
  @max_length_offset @max_length - @end_length

  def new() do
    body = [@dec, @line_sep, @urlset_start, @line_sep]
    length = IO.iodata_length(body)
    %File{count: 0, length: length, body: body}
  end

  def add_url(%File{count: count, length: length, body: body}, %URL{} = url) do
    element =
      url_element(url)
      |> XmlBuilder.generate()

    element_length = IO.iodata_length(element)
    new_length = length + element_length + @line_sep_length
    new_count = count + 1

    cond do
      new_length >= @max_length_offset ->
        {:error, :over_length}

      new_count > @max_count ->
        {:error, :over_count}

      true ->
        new_body = [body, element, @line_sep]
        %File{count: new_count, length: new_length, body: new_body}
    end
  end

  def finalize(%File{count: count, length: length, body: body}) do
    new_body = [body, @urlset_end, @line_sep]
    new_length = length + @end_length
    %File{count: count, length: new_length, body: new_body}
  end

  defp url_element(%URL{} = url) do
    elements =
      [:loc, :lastmod, :changefreq, :priority]
      |> Enum.reduce([], fn k, acc ->
        case Map.get(url, k) do
          nil ->
            acc

          v ->
            acc ++ [{k, Encoder.encode(v)}]
        end
      end)

    XmlBuilder.element(:url, elements)
  end
end
