defmodule Sitemapper.URL do
  @moduledoc """
  Represents a URL for inclusion in a Sitemap.
  """

  @enforce_keys [:loc]
  defstruct [:loc, :lastmod, :changefreq, :priority, :images]

  @type changefreq :: :always | :hourly | :daily | :weekly | :monthly | :yearly | :never

  @typedoc "Image structure for image sitemaps"
  @type image :: %{loc: String.t()}

  @typedoc "URL structure for sitemap generation"
  @type t :: %__MODULE__{
          loc: String.t(),
          lastmod: Date.t() | DateTime.t() | NaiveDateTime.t() | nil,
          changefreq: changefreq | nil,
          priority: float | nil,
          images: [image] | nil
        }
end
