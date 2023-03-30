defmodule Sitemapper.IndexGenerator do
  @moduledoc false
  # Generates indexes

  alias Sitemapper.{Encoder, File, SitemapReference}

  @max_length 52_428_800
  @max_count 50_000

  @dec ~S(<?xml version="1.0" encoding="UTF-8"?>)
  @index_start ~S(<sitemapindex xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/siteindex.xsd" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">)
  @index_end "</sitemapindex>"

  @line_sep "\n"
  @line_sep_length String.length(@line_sep)

  @end_length String.length(@index_end) + @line_sep_length
  @max_length_offset @max_length - @end_length

  def new do
    body = [@dec, @line_sep, @index_start, @line_sep]
    length = IO.iodata_length(body)
    %File{count: 0, length: length, body: body}
  end

  def add_sitemap(
        %File{count: count, length: length, body: body},
        %SitemapReference{} = reference
      ) do
    element =
      reference
      |> sitemap_element()
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
    new_body = [body, @index_end, @line_sep]
    new_length = length + @end_length
    %File{count: count, length: new_length, body: new_body}
  end

  defp sitemap_element(%SitemapReference{} = reference) do
    elements =
      []
      |> encode_element(:loc, reference.loc)
      |> encode_element(:lastmod, reference.lastmod)

    XmlBuilder.element(:sitemap, elements)
  end

  defp encode_element(elements, _key, nil), do: elements

  defp encode_element(elements, key, value) do
    elements ++ [{key, Encoder.encode(value)}]
  end
end
