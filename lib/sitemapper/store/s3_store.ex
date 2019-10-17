defmodule Sitemapper.S3Store do
  @behaviour Sitemapper.Store

  def write(filename, body, config) do
    bucket = Keyword.fetch!(config, :bucket)

    props = [
      {:content_type, "application/x-gzip"},
      {:cache_control, "must-revalidate"}
    ]

    ExAws.S3.put_object(bucket, filename, body, props)
    |> ExAws.request!()
  end
end
