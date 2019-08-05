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

  @impl true
  def parse_source(source, _opts) do
    {:ok, source}
  end

  @impl true
  def get_headers(%{headers: headers}), do: {:ok, headers}

  @impl true
  def get_rows(%{rows: rows}), do: {:ok, rows}

  @impl true
  def get_row(row), do: {:ok, row}
end
