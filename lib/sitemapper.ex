defmodule Sitemapper do
  alias Sitemapper.{File, IndexGenerator, SitemapGenerator, SitemapReference}

  def generate(enum) do
    enum
    |> Stream.concat([:end])
    |> Stream.transform(nil, &reduce_url_to_sitemap/2)
    |> Stream.transform(1, &reduce_file_to_data_and_name/2)
    |> Stream.map(&gzip_body/1)
    |> Stream.map(&persist_returning_filename/1)
    |> Stream.map(&map_filename_to_sitemap_reference/1)
    |> Stream.concat([:end])
    |> Stream.transform(nil, &reduce_filename_to_index/2)
    |> Stream.map(&map_index_file_to_data_and_name/1)
    |> Stream.map(&gzip_body/1)
    |> Stream.map(&persist_returning_filename/1)
    |> Stream.run()
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

  defp reduce_file_to_data_and_name(%File{body: body}, counter) do
    {[{body, sitemap_filename(counter)}], counter + 1}
  end

  defp gzip_body({body, filename}) do
    {:zlib.gzip(body), filename}
  end

  defp persist_returning_filename({body, filename}) do
    store_module = Application.fetch_env!(:sitemapper, :store)
    :ok = store_module.write(filename, body)
    filename
  end

  defp sitemap_filename(counter) do
    str = Integer.to_string(counter)
    "sitemap-" <> String.pad_leading(str, 6, "0") <> ".xml.gz"
  end

  defp reduce_filename_to_index(:end, nil) do
    {[], nil}
  end

  defp reduce_filename_to_index(:end, file) do
    done = IndexGenerator.finalize(file)
    {[done], nil}
  end

  defp reduce_filename_to_index(url, nil) do
    reduce_filename_to_index(url, IndexGenerator.new())
  end

  defp reduce_filename_to_index(url, file) do
    case IndexGenerator.add_sitemap(file, url) do
      {:error, reason} when reason in [:over_length, :over_count] ->
        raise "Generated more than 50,000 sitemap indexes"

      new_file ->
        {[], new_file}
    end
  end

  defp map_index_file_to_data_and_name(%File{body: body}) do
    {body, "sitemap-index.xml.gz"}
  end

  defp map_filename_to_sitemap_reference(filename) do
    url = Application.fetch_env!(:sitemapper, :url)
    %SitemapReference{loc: "#{url}#{filename}"}
  end
end
