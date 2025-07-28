defmodule Sitemapper.File do
  @moduledoc false
  @enforce_keys [:count, :length, :body]
  defstruct [:count, :length, :body, :has_images]
end
