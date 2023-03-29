defmodule Sitemapper.SitemapReference do
  @moduledoc false

  @enforce_keys [:loc]
  defstruct [:loc, :lastmod]

  @type t :: %__MODULE__{
          loc: String.t(),
          lastmod: Date.t() | DateTime.t() | NaiveDateTime.t() | nil
        }
end
