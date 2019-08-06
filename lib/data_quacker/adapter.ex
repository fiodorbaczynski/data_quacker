defmodule DataQuacker.Adapter do
  @moduledoc ~S"""
  Specifies the behaviour to which adapters must conform.

  An adapter must implement these functions: `parse_source/2`, `get_headers/1`, `get_rows/1`, `get_row/1`.

  The first one takes a source (e.g. a file path) and a keyword list of options,
  and returns a tuple of `{:ok, any()}` or `{:error, any()}`.
  In case of success the second element of the tuple
  will be the value given to the other two function.

  The second one takes the result of `parse_source/2`
  and returns `{:ok, list(any())} | {:error, any()}`.
  In case of success the second element of the tuple
  will be the value used to determine the indexes
  of sources described in the schema.

  The third one takes the result of `parse_source/2`
  and returns `{:ok, list(any())} | {:error, any()}`.
  In case of success each subsequent element of the resulting list
  will be passed to the get row function.

  The last one takes an element of the list
  which is the result of `get_rows/1`
  and returns `{:ok, list(any())} | {:error, any()}`.
  In case of success the resulting list will be treated
  as the list of columns in a row of the source.

  > Note: The resulting list in the `get_row/1` function must be of the same length as the resulting list in the `get_headers/1` function.

  For an example implementation take a look at the built-in adapters.

  > The rationale behind this API for adapters is that, depending on the source, potential errors may occur at different stages of parsing the source. For example the CSV library included in the default CSV adapter returns a tuple with `:ok` or `:error`as the first element for each row. However, some external APIs, like Google Sheets, return a list of rows without specifying for each whether it's valid or not. Therefore we need for it to be possible to specify that for each row, but not required for an adapter to eagerly iterate over all of the rows and wrap them in a tuple with `:ok`.
  """

  @callback parse_source(any(), Keyword.t()) :: {:ok, any()} | {:error, any()}
  @callback get_headers(any()) :: {:ok, list(any())} | {:error, any()}
  @callback get_rows(any()) :: {:ok, list(any())} | {:error, any()}
  @callback get_row(any()) :: {:ok, list(any())} | {:error, any()}
end
