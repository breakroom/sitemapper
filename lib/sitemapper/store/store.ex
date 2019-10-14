defmodule Sitemapper.Store do
  @callback write(String.t(), IO.chardata()) :: :ok | {:error, atom()}
end
