defmodule Sitemapper.URL do
  @moduledoc """
  Represents a URL for inclusion in a Sitemap.
  """

  @enforce_keys [:loc]
  defstruct [:loc, :lastmod, :changefreq, :priority]

  @type changefreq :: :always | :hourly | :daily | :weekly | :monthly | :yearly | :never

  @typedoc "URL structure for sitemap generation"
  @type t :: %__MODULE__{
          loc: String.t(),
          lastmod: Date.t() | DateTime.t() | NaiveDateTime.t() | nil,
          changefreq: changefreq | nil,
          priority: float | nil
        }
end
