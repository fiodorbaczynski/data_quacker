defmodule DataQuacker.FileManager do
  @moduledoc false

  @callback stream!(Path.t()) :: Stream.t() | File.Stream.t() | {:error, String.t()}
  @callback read_link!(Path.t()) :: {:ok, binary()} | {:error, String.t()}

  defdelegate stream!(path), to: File
  defdelegate read_link!(url), to: File
end
