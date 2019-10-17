defmodule Sitemapper.MixProject do
  use Mix.Project

  def project do
    [
      app: :sitemapper,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:ex_aws_s3, "~> 2.0", optional: true}
    ]
  end
end
