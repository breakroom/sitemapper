defmodule Sitemapper.FileStore do
  @moduledoc """
  Store which persists sitemap on local filesystem

  ## Configuration

  * `:path` (required) - directory to save to
  """

  @behaviour Sitemapper.Store

  def write(filename, data, config) do
    store_path = Keyword.fetch!(config, :path)
    file_path = Path.join(store_path, filename)
    File.write!(file_path, data, [:write])
  end
end
