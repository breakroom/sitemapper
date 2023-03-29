defmodule Sitemapper.Store do
  @moduledoc """
  Store behaviour
  """

  @doc """
  Stores file with a part of sitemap into storage
  """
  @callback write(filename :: String.t(), body :: IO.chardata(), config :: Keyword.t()) ::
              :ok | {:error, atom()}
end
