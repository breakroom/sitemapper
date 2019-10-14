defmodule Sitemapper.Encoder do
  def encode(%Date{} = date) do
    date
    |> Date.to_iso8601()
  end

  def encode(%DateTime{} = dt) do
    dt
    |> DateTime.to_iso8601()
  end

  def encode(%NaiveDateTime{} = dt) do
    dt
    |> NaiveDateTime.to_iso8601()
  end

  def encode(v), do: v
end
