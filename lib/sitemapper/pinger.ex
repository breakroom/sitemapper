defmodule Sitemapper.Pinger do
  @moduledoc """
  Module which pings search engines, notifying about the sitemap update

  ## Configuration

  * `:urls` -- a list of url templates. Default list is
  ```elixir
  [
     "http://google.com/ping?sitemap=%s",
     "http://www.bing.com/webmaster/ping.aspx?sitemap=%s"
  ]
  ```
  """

  @default_urls [
    "http://google.com/ping?sitemap=%s",
    "http://www.bing.com/webmaster/ping.aspx?sitemap=%s"
  ]

  def ping(sitemap_url, config) do
    config
    |> Keyword.get(:urls, @default_urls)
    |> Enum.each(fn url ->
      url
      |> String.replace("%s", sitemap_url)
      |> String.to_charlist()
      |> :httpc.request()
    end)
  end
end
