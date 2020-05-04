# Sitemapper

[![Hex pm](http://img.shields.io/hexpm/v/sitemapper.svg?style=flat)](https://hex.pm/packages/sitemapper)

Sitemapper is an Elixir library for generating [XML Sitemaps](https://www.sitemaps.org).

It's designed to generate large sitemaps while maintaining a low memory profile. It can persist sitemaps to Amazon S3, disk or any other adapter you wish to write.

## Installation

```elixir
def deps do
  [
    {:sitemapper, "~> 0.4.0"}
  ]
end
```

## Usage

```elixir
  def generate_sitemap() do
    config = [
      store: Sitemapper.S3Store,
      store_config: [bucket: "example-bucket"],
      sitemap_url: "http://example-bucket.s3-aws-region.amazonaws.com"
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
    |> Sitemapper.persist(config)
    |> Sitemapper.ping(config)
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
      |> Sitemapper.persist(config)
      |> Sitemapper.ping(config)
    end)
  end
```

## Todo

- Support extended Sitemap properties, like images, video, etc.

## Benchmarks

`sitemapper` is about 50% faster than `fast_sitemap`. In the large scenario below (1,000,000 URLs) `sitemapper` uses ~50MB peak memory consumption, while `fast_sitemap` uses ~1000MB.

```shell
$ MIX_ENV=bench mix run bench/bench.exs
Operating System: macOS
CPU Information: Intel(R) Core(TM) i7-4870HQ CPU @ 2.50GHz
Number of Available Cores: 8
Available memory: 16 GB
Elixir 1.9.1
Erlang 22.0.4

Benchmark suite executing with the following configuration:
warmup: 2 s
time: 10 s
memory time: 0 ns
parallel: 1
inputs: large, medium, small
Estimated total run time: 1.20 min

Benchmarking fast_sitemap - simple with input large...
Benchmarking fast_sitemap - simple with input medium...
Benchmarking fast_sitemap - simple with input small...
Benchmarking sitemapper - simple with input large...
Benchmarking sitemapper - simple with input medium...
Benchmarking sitemapper - simple with input small...

##### With input large #####
Name                            ips        average  deviation         median         99th %
sitemapper - simple          0.0353        28.32 s     ±0.00%        28.32 s        28.32 s
fast_sitemap - simple        0.0223        44.76 s     ±0.00%        44.76 s        44.76 s

Comparison:
sitemapper - simple          0.0353
fast_sitemap - simple        0.0223 - 1.58x slower +16.45 s

##### With input medium #####
Name                            ips        average  deviation         median         99th %
sitemapper - simple            0.35         2.85 s     ±0.57%         2.85 s         2.87 s
fast_sitemap - simple          0.23         4.28 s     ±0.46%         4.28 s         4.30 s

Comparison:
sitemapper - simple            0.35
fast_sitemap - simple          0.23 - 1.50x slower +1.43 s

##### With input small #####
Name                            ips        average  deviation         median         99th %
sitemapper - simple           32.00       31.25 ms     ±8.01%       31.20 ms       37.22 ms
fast_sitemap - simple         21.55       46.41 ms     ±6.96%       46.26 ms       56.36 ms

Comparison:
sitemapper - simple           32.00
fast_sitemap - simple         21.55 - 1.49x slower +15.16 ms
```
