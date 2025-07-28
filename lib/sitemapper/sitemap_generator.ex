defmodule Sitemapper.SitemapGenerator do
  @moduledoc false

  alias Sitemapper.{Encoder, File, URL}

  @max_length 52_428_800
  @max_count 50_000

  @dec ~S(<?xml version="1.0" encoding="UTF-8"?>)
  @urlset_base ~S(<urlset xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd" xmlns="http://www.sitemaps.org/schemas/sitemap/0.9")
  @image_namespace ~S( xmlns:image="http://www.google.com/schemas/sitemap-image/1.1")
  @urlset_end "</urlset>"

  defp urlset_start(_has_images = true), do: @urlset_base <> @image_namespace <> ">"
  defp urlset_start(_has_images = false), do: @urlset_base <> ">"

  @line_sep "\n"
  @line_sep_length String.length(@line_sep)

  @end_length String.length(@urlset_end) + @line_sep_length
  @max_length_offset @max_length - @end_length

  def new do
    urlset = urlset_start(false)
    body = [@dec, @line_sep, urlset, @line_sep]
    length = IO.iodata_length(body)
    %File{count: 0, length: length, body: body, has_images: false}
  end

  def add_url(%File{has_images: true} = file, %URL{} = url) do
    do_add_url(file, url)
  end

  def add_url(%File{has_images: false} = file, %URL{images: [_ | _]} = url) do
    updated_file = add_image_namespace_to_file(file)
    do_add_url(updated_file, url)
  end

  def add_url(%File{has_images: false} = file, %URL{} = url) do
    do_add_url(file, url)
  end

  def finalize(%File{body: body, length: length} = file) do
    new_body = [body, @urlset_end, @line_sep]
    new_length = length + @end_length
    %File{file | body: new_body, length: new_length}
  end

  defp do_add_url(
         %File{count: count, length: length, body: body, has_images: has_images},
         %URL{} = url
       ) do
    element =
      url
      |> url_element()
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
        %File{count: new_count, length: new_length, body: new_body, has_images: has_images}
    end
  end

  defp url_element(%URL{} = url) do
    basic_elements =
      [:loc, :lastmod, :changefreq, :priority]
      |> Enum.reduce([], fn k, acc ->
        case Map.get(url, k) do
          nil ->
            acc

          v ->
            acc ++ [{k, Encoder.encode(v)}]
        end
      end)

    image_elements =
      case Map.get(url, :images) do
        nil ->
          []

        images when is_list(images) ->
          images
          |> Enum.take(1000)
          |> Enum.map(&image_element/1)

        _ ->
          []
      end

    all_elements = basic_elements ++ image_elements

    XmlBuilder.element(:url, all_elements)
  end

  defp image_element(%{loc: loc}) do
    {"image:image", [{"image:loc", loc}]}
  end

  defp add_image_namespace_to_file(%File{body: body, length: length} = file) do
    updated_body = add_image_namespace_to_body(body)
    namespace_diff = IO.iodata_length(updated_body) - IO.iodata_length(body)
    %File{file | body: updated_body, has_images: true, length: length + namespace_diff}
  end

  defp add_image_namespace_to_body(body) do
    body_string = IO.iodata_to_binary(body)
    String.replace(body_string, urlset_start(false), urlset_start(true))
  end
end
