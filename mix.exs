defmodule Sitemapper.MixProject do
  use Mix.Project

  @version "0.4.0"

  def project do
    [
      app: :sitemapper,
      version: @version,
      elixir: "~> 1.9",
      deps: deps(),
      name: "Sitemapper",
      source_url: "https://github.com/tomtaylor/sitemapper",
      description: "Stream based XML Sitemap generator",
      package: package(),
      docs: docs()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Tom Taylor"],
      links: %{"GitHub" => "https://github.com/tomtaylor/sitemapper"}
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}"
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:xml_builder, "~> 2.1.1"},
      {:ex_aws_s3, "~> 2.0", optional: true},
      {:fast_sitemap, "~> 0.1.0", only: :bench},
      {:benchee, "~> 1.0", only: :bench},
      {:benchee_html, "~> 1.0", only: :bench},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
