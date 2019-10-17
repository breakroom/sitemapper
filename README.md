# Sitemapper

Sitemapper is an Elixir library for generating Sitemaps ((more about Sitemaps)[https://www.sitemaps.org]).

It's designed for generating large sitemaps while maintaining a low memory profile. It can persist sitemaps in Amazon S3, on disk, or any adapter you wish to write.

## Installation

```elixir
def deps do
  [
    {:sitemapex, "~> 0.1.0"}
  ]
end
```

## Usage

```elixir
  def generate_sitemap() do
    config = [
      store: Sitemapper.S3Store,
      store_config: [bucket: "example-bucket"],
      sitemap_url: "https://example-bucket.awes.com/"
    ]

    Stream.concat([1..100_001])
    |> Stream.map(fn i ->
      %Sitemapper.URL{
        loc: "http://example.com/page-#{i}",
        changefreq: :daily,
        lastmod: Date.utc_today()
      }
    end)
    |> Sitemapper.generate(config)
  end
```

`Sitemapper.generate` receives a `Stream` of URLs. This makes it easy to stream the contents of an Ecto Repo into a sitemap.

```elixir
  def generate_sitemap() do
    config = [
      store: Sitemapper.S3Store,
      store_config: [bucket: "example-bucket"],
      sitemap_url: "http://example-bucket.s3-aws-region.amazonaws.com"
    ]

    Repo.transaction(fn ->
      User
      |> Repo.stream()
      |> Stream.map(fn %User{username: username, updated_at: updated_at} ->
        %Sitemapper.URL{
          loc: "http://example.com/users/#{username}",
          changefreq: :hourly,
          lastmod: updated_at
        }
      end)
      |> Sitemapper.generate(config)
    end)
  end
```
