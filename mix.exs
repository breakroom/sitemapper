defmodule Sitemapper.MixProject do
  use Mix.Project

  @version "0.9.0"

  def project do
    [
      app: :sitemapper,
      version: @version,
      elixir: "~> 1.12",
      deps: deps(),
      name: "Sitemapper",
      source_url: "https://github.com/breakroom/sitemapper",
      description: "Stream based XML Sitemap generator",
      package: package(),
      docs: docs()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Tom Taylor"],
      files: [
        "lib",
        "mix.exs",
        "README.md",
        ".formatter.exs"
      ],
      links: %{
        "GitHub" => "https://github.com/breakroom/sitemapper",
        "Changelog" => "https://github.com/breakroom/sitemapper/blob/main/CHANGELOG.md"
      }
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "readme",
      extras: ["README.md", "CHANGELOG.md"]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl]
    ]
  end

  defp deps do
    [
      {:xml_builder, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0", optional: true},
      {:google_api_storage, "~> 0.34", optional: true},

      # Bench
      {:fast_sitemap, "~> 0.1.0", only: :bench},
      {:benchee, "~> 1.0", only: :bench},
      {:benchee_html, "~> 1.0", only: :bench},

      # Dev
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:credo, "~> 1.5", only: :dev, runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end
end
