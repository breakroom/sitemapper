defmodule Sitemapper.TestStore do
  @behaviour Sitemapper.Store

  def write(filename, data) do
    store_path =
      File.cwd!()
      |> Path.join("test/store")

    File.mkdir_p!(store_path)

    file_path = Path.join(store_path, filename)
    File.write!(file_path, data, [:write])
  end
end
