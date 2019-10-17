defmodule Sitemapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :sitemapper,
      version: "0.1.0",
      elixir: "~> 1.8",
      deps: deps(),
      name: "Sitemapper",
      source_url: "https://github.com/tomtaylor/sitemapper",
      description: "Stream based XML Sitemap generator",
      package: package()
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      maintainers: ["Tom Taylor"],
      links: %{"GitHub" => "https://github.com/tomtaylor/sitemapper"}
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:xml_builder, "~> 2.1.1"},
      {:ex_aws_s3, "~> 2.0", optional: true},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
