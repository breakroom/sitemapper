defmodule Sitemapper.Pinger do
  @urls [
    "http://google.com/ping?sitemap=%s",
    "http://www.bing.com/webmaster/ping.aspx?sitemap=%s"
  ]

  def ping(sitemap_url) do
    @urls
    |> Enum.map(fn url ->
      ping_url = String.replace(url, "%s", sitemap_url)
      :httpc.request('#{ping_url}')
    end)
  end
end
