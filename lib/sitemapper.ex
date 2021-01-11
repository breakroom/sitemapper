defmodule Sitemapper do
  @moduledoc """
  Sitemapper is an Elixir library for generating [XML Sitemaps](https://www.sitemaps.org).

  It's designed to generate large sitemaps while maintaining a low
  memory profile. It can persist sitemaps to Amazon S3, disk or any
  other adapter you wish to write.
  """
  alias Sitemapper.{File, IndexGenerator, SitemapGenerator, SitemapReference}

  @doc """
  Receives a `Stream` of `Sitemapper.URL` and returns a `Stream` of
  `{filename, body}` tuples, representing the individual sitemap XML
  files, followed by an index XML file.

  Accepts the following `Keyword` options in `opts`:

  * `sitemap_url` - The base URL where the generated sitemap
    files will live. e.g. `http://example.org`, if your sitemap lives at
    `http://example.org/sitemap.xml` (required)
  * `gzip` - Sets whether the files are gzipped (default: `true`)
  * `name` - An optional suffix for the sitemap filename. e.g. If you
    set to `news`, will produce `sitemap-news.xml.gz` and
    `sitemap-news-00001.xml.gz` filenames. (default: `nil`)
  * `index_lastmod` - An optional Date/DateTime/NaiveDateTime for the lastmod
    element in the index. (default: `Date.utc_today()`)
  """
  @spec generate(stream :: Enumerable.t(), opts :: keyword) :: Stream.t()
  def generate(enum, opts) do
    sitemap_url = Keyword.fetch!(opts, :sitemap_url)
    gzip_enabled = Keyword.get(opts, :gzip, true)
    name = Keyword.get(opts, :name)
    index_lastmod = Keyword.get(opts, :index_lastmod, Date.utc_today())

    enum
    |> Stream.concat([:end])
    |> Stream.transform(nil, &reduce_url_to_sitemap/2)
    |> Stream.transform(1, &reduce_file_to_name_and_body(&1, &2, name, gzip_enabled))
    |> Stream.concat([:end])
    |> Stream.transform(
      nil,
      &reduce_to_index(&1, &2, sitemap_url, name, gzip_enabled, index_lastmod)
    )
    |> Stream.map(&maybe_gzip_body(&1, gzip_enabled))
  end

  @doc """
  Receives a `Stream` of `{filename, body}` tuples, and persists
  those to the `Sitemapper.Store`.

  Will raise if persistence fails.

  Accepts the following `Keyword` options in `opts`:

  * `store` - The module of the desired `Sitemapper.Store`,
    such as `Sitemapper.S3Store`. (required)

  * `store_config` -  A `Keyword` list with options for the
    `Sitemapper.Store`. (optional, but usually required)
  """
  @spec persist(Enumerable.t(), keyword) :: Stream.t()
  def persist(enum, opts) do
    store = Keyword.fetch!(opts, :store)
    store_config = Keyword.get(opts, :store_config, [])

    enum
    |> Stream.each(fn {filename, body} ->
      :ok = store.write(filename, body, store_config)
    end)
  end

  @doc """
  Receives a `Stream` of `{filename, body}` tuples, takes the last
  one (the index file), and pings Google and Bing with its URL.
  """
  @spec ping(Enumerable.t(), keyword) :: Stream.t()
  def ping(enum, opts) do
    sitemap_url = Keyword.fetch!(opts, :sitemap_url)

    enum
    |> Stream.take(-1)
    |> Stream.map(fn {filename, _body} ->
      index_url =
        URI.parse(sitemap_url)
        |> join_uri_and_filename(filename)
        |> URI.to_string()

      Sitemapper.Pinger.ping(index_url)
    end)
  end

  defp reduce_url_to_sitemap(:end, nil) do
    {[], nil}
  end

  defp reduce_url_to_sitemap(:end, progress) do
    done = SitemapGenerator.finalize(progress)
    {[done], nil}
  end

  defp reduce_url_to_sitemap(url, nil) do
    reduce_url_to_sitemap(url, SitemapGenerator.new())
  end

  defp reduce_url_to_sitemap(url, progress) do
    case SitemapGenerator.add_url(progress, url) do
      {:error, reason} when reason in [:over_length, :over_count] ->
        done = SitemapGenerator.finalize(progress)
        next = SitemapGenerator.new() |> SitemapGenerator.add_url(url)
        {[done], next}

      new_progress ->
        {[], new_progress}
    end
  end

  defp reduce_file_to_name_and_body(%File{body: body}, counter, name, gzip_enabled) do
    {[{filename(name, gzip_enabled, counter), body}], counter + 1}
  end

  defp maybe_gzip_body({filename, body}, true) do
    {filename, :zlib.gzip(body)}
  end

  defp maybe_gzip_body({filename, body}, false) do
    {filename, body}
  end

  defp reduce_to_index(:end, nil, _sitemap_url, _name, _gzip_enabled, _lastmod) do
    {[], nil}
  end

  defp reduce_to_index(:end, index_file, _sitemap_url, name, gzip_enabled, _lastmod) do
    done_file = IndexGenerator.finalize(index_file)
    {filename, body} = index_file_to_data_and_name(done_file, name, gzip_enabled)
    {[{filename, body}], nil}
  end

  defp reduce_to_index({filename, body}, nil, sitemap_url, name, gzip_enabled, lastmod) do
    reduce_to_index(
      {filename, body},
      IndexGenerator.new(),
      sitemap_url,
      name,
      gzip_enabled,
      lastmod
    )
  end

  defp reduce_to_index({filename, body}, index_file, sitemap_url, _name, _gzip_enabled, lastmod) do
    reference = filename_to_sitemap_reference(filename, sitemap_url, lastmod)

    case IndexGenerator.add_sitemap(index_file, reference) do
      {:error, reason} when reason in [:over_length, :over_count] ->
        raise "Generated more than 50,000 sitemap indexes"

      new_file ->
        {[{filename, body}], new_file}
    end
  end

  defp index_file_to_data_and_name(%File{body: body}, name, gzip_enabled) do
    {filename(name, gzip_enabled), body}
  end

  defp filename_to_sitemap_reference(filename, sitemap_url, lastmod) do
    loc =
      URI.parse(sitemap_url)
      |> join_uri_and_filename(filename)
      |> URI.to_string()

    %SitemapReference{loc: loc, lastmod: lastmod}
  end

  defp join_uri_and_filename(%URI{path: nil} = uri, filename) do
    URI.merge(uri, filename)
  end

  defp join_uri_and_filename(%URI{path: path} = uri, filename) do
    path = Path.join(path, filename)
    URI.merge(uri, path)
  end

  defp filename(name, gzip, count \\ nil) do
    prefix = ["sitemap", name] |> Enum.reject(&is_nil/1) |> Enum.join("-")

    suffix =
      case count do
        nil ->
          ""

        c ->
          str = Integer.to_string(c)
          "-" <> String.pad_leading(str, 5, "0")
      end

    extension =
      case gzip do
        true -> ".xml.gz"
        false -> ".xml"
      end

    prefix <> suffix <> extension
  end
end
