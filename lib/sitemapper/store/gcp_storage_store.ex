if Code.ensure_loaded?(GoogleApi.Storage.V1) do
  defmodule Sitemapper.GCPStorageStore do
    @moduledoc """
    GCP Storage `Sitemapper.Store` implementation

    You'll need to include the [`google_api_storage`](https://hex.pm/packages/google_api_storage) dependency to use this.

    ## Configuration

    - `:bucket` (required) -- a bucket to persist to
    - `:conn` -- pass in your own `GoogleApi.Storage.V1.Connection`, depending on how you authenticate with GCP
    - `:path` -- a path which is prefixed to the filenames
    - `:cache_control` -- an explicit `Cache-Control` header for the persisted files
    """
    @behaviour Sitemapper.Store

    alias GoogleApi.Storage.V1, as: Storage

    def write(filename, body, config) do
      bucket = Keyword.fetch!(config, :bucket)

      conn =
        Keyword.get_lazy(config, :conn, fn ->
          GoogleApi.Storage.V1.Connection.new()
        end)

      path = Keyword.get(config, :path, "")
      cache_control = Keyword.get(config, :cache_control, "must-revalidate")
      upload_filename = Path.join(path, filename)

      metadata = %Storage.Model.Object{
        name: upload_filename,
        cacheControl: cache_control,
        contentType: content_type(upload_filename)
      }

      resp =
        Storage.Api.Objects.storage_objects_insert_iodata(
          conn,
          bucket,
          "multipart",
          metadata,
          body
        )

      case resp do
        {:ok, _} -> :ok
        {:error, reason} -> {:error, reason}
      end
    end

    defp content_type(filename) do
      if String.ends_with?(filename, ".gz") do
        "application/x-gzip"
      else
        "application/xml"
      end
    end
  end
end
