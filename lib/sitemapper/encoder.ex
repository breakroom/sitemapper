defmodule Sitemapper.Encoder do
  @moduledoc false
  def encode(%dt{} = date) when dt in [Date, DateTime, NaiveDateTime] do
    date
    |> dt.to_iso8601()
  end

  def encode(v), do: v
end
