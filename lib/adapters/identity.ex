defmodule DataQuacker.Adapters.Identity do
  @moduledoc ~S"""
  This is an "identity adapter".
  It takes in a map with `:headers` and `:rows` as the keys.

  This adapter is very useful for testing a particular schema,
  but can also be used as the actual adapter if needed.

  ## Example source

  ```elixir
  %{
    headers: ["First name", "Last name", "Age"],
    rows: [
      ["John", "Smith", "21"],
      # ...
    ]
  }
  ```
  """

  @behaviour DataQuacker.Adapter

  @impl DataQuacker.Adapter
  @doc ~S"""
  Takes in a map with `:headers` and `:rows` keys, where the value under `:headers` is a list of strings, and the value under `:rows` is a list of lists of anything.

  > Note: Each list in in the rows list must be of the same length as the headers list.
  """
  def parse_source(source, _opts) do
    {:ok, source}
  end

  @impl DataQuacker.Adapter
  def get_headers(%{headers: headers}), do: {:ok, headers}

  @impl DataQuacker.Adapter
  def get_rows(%{rows: rows}), do: {:ok, rows}

  @impl DataQuacker.Adapter
  def get_row(row), do: {:ok, row}
end
