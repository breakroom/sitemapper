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
  `{filename, body}` tuples.

  Accepts the following `Keyword` options in `opts`:

  * `sitemap_url`: (required) The base URL where the generated sitemap files will
    live. e.g. `http://example.org`, if your sitemap lives at
    `http://example.org/sitemap.xml`
  """
  @spec generate(stream :: Enumerable.t(), opts :: keyword) :: Stream.t()
  def generate(enum, opts) do
    sitemap_url = Keyword.fetch!(opts, :sitemap_url)

    enum
    |> Stream.concat([:end])
    |> Stream.transform(nil, &reduce_url_to_sitemap/2)
    |> Stream.transform(1, &reduce_file_to_name_and_body/2)
    |> Stream.concat([:end])
    |> Stream.transform(nil, &reduce_to_index(&1, &2, sitemap_url))
    |> Stream.map(&gzip_body/1)
  end

  @doc """
  Receive a `Stream` of `{filename, body}` tuples, and persists those
  to the `Sitemapper.Store`. Will raise if persistence fails.

  Accepts the following `Keyword` options in `opts`:

  * `store`: (required) The module of the desired `Sitemapper.Store`,
    such as `Sitemapper.S3Store`.

  * `store_config`: (optional) A `Keyword` list with options for the
    `Sitemapper.Store`.
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

  def ping(opts) do
    sitemap_url = Keyword.fetch!(opts, :sitemap_url)
    index_url = URI.parse(sitemap_url) |> join_uri_and_filename("sitemap.xml.gz")
    Sitemapper.Pinger.ping(index_url)
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
        {[done], nil}

      new_progress ->
        {[], new_progress}
    end
  end

  defp reduce_file_to_name_and_body(%File{body: body}, counter) do
    {[{sitemap_filename(counter), body}], counter + 1}
  end

  defp gzip_body({filename, body}) do
    {filename, :zlib.gzip(body)}
  end

  defp sitemap_filename(counter) do
    str = Integer.to_string(counter)
    "sitemap-" <> String.pad_leading(str, 5, "0") <> ".xml.gz"
  end

  defp reduce_to_index(:end, nil, _sitemap_url) do
    {[], nil}
  end

  defp reduce_to_index(:end, index_file, _sitemap_url) do
    done_file = IndexGenerator.finalize(index_file)
    {filename, body} = index_file_to_data_and_name(done_file)
    {[{filename, body}], nil}
  end

  defp reduce_to_index({filename, body}, nil, sitemap_url) do
    reduce_to_index({filename, body}, IndexGenerator.new(), sitemap_url)
  end

  defp reduce_to_index({filename, body}, index_file, sitemap_url) do
    reference = filename_to_sitemap_reference(filename, sitemap_url)

    case IndexGenerator.add_sitemap(index_file, reference) do
      {:error, reason} when reason in [:over_length, :over_count] ->
        raise "Generated more than 50,000 sitemap indexes"

      new_file ->
        {[{filename, body}], new_file}
    end
  end

  defp index_file_to_data_and_name(%File{body: body}) do
    {"sitemap.xml.gz", body}
  end

  defp filename_to_sitemap_reference(filename, sitemap_url) do
    loc =
      URI.parse(sitemap_url)
      |> join_uri_and_filename(filename)
      |> URI.to_string()

    %SitemapReference{loc: loc}
  end

  defp join_uri_and_filename(%URI{path: nil} = uri, filename) do
    URI.merge(uri, filename)
  end

  defp join_uri_and_filename(%URI{path: path} = uri, filename) do
    path = Path.join(path, filename)
    URI.merge(uri, path)
  end
end
