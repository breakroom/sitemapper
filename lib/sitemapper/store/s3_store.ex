defmodule Sitemapper.S3Store do
  @moduledoc """
  S3 sitemap store implementation using ExAWS

  ## Configuration

  - `:bucket` (required) -- a bucket handle to save to
  - `:path` -- a prefix path which is appended to the filename
  - `:extra_props` -- a list of extra object properties
  """
  @behaviour Sitemapper.Store

  def write(filename, body, config) do
    bucket = Keyword.fetch!(config, :bucket)

    props = [
      {:content_type, content_type(filename)},
      {:cache_control, "must-revalidate"},
      {:acl, :public_read}
      | Keyword.get(config, :extra_props, [])
    ]

    bucket
    |> ExAws.S3.put_object(key(filename, config), body, props)
    |> ExAws.request!()

    :ok
  end

  defp content_type(filename) do
    if String.ends_with?(filename, ".gz") do
      "application/x-gzip"
    else
      "application/xml"
    end
  end

  defp key(filename, config) do
    case Keyword.fetch(config, :path) do
      :error -> filename
      {:ok, path} -> Path.join([path, filename])
    end
  end
end
