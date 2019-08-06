defmodule DataQuacker do
  @moduledoc ~S"""
  DataQuacker is a library which aims at helping validating, transforming and parsing non-sandboxed data.

  The most common example for such data, and the original idea behind this project, is CSV files.
  The scope of this library is not, however, in  any way limited to CSV files.
  This library ships by default with two adapters: `DataQuacker.Adapters.CSV` for CSV files,
  and `DataQuacker.Adapters.Identity` for "in-memory data".
  Any other data source may be used with the help of a third party adapters; see: `DataQuacker.Adapter`.

  This library is comprised of three main components:

  - `DataQuacker`, which provides the `parse/4` function to parse data using a schema
  - `DataQuacker.Schema`, which a DSL for declaratively defining schemas which describe the mapping between the source data and the desired output
  - `DataQuacker.Adapters.CSV` and `DataQuacker.Adapters.Identity`, which extract data from sources into a format required by the  `parse/4` function

  > Note: Writing this documentation is a challenge since the complexity of this library stems from the possibility of parsing arbitrary data into arbitrarily nested maps with arbitrary rules for any fields and rows (you can see some examples in `DataQuacker.Schema`). For this reason not everything may be clear to a user from just reading the documentation. In most cases if you do something that is not allowed, you will get a compile-time error with a helpful message. However, if you find anything unclear after reading this documentation, or that you have to "fight" with the tool, please do not hesitate to open a pull request or an issue on the github repo. The idea behind this project is to help people (including myself) rid themselves of the pains associated with parsing unstructured data, not add to it.

  ## Example

  > Most of the "juice", like transforming, validating, nesting, skipping, etc., is in the `DataQuacker.Schema` module, so the more complex and interesting examples also live there. Please take a look at its documentation for more in-depth examples.

  Given the following table of ducks in a pond, in the form of a CSV file:

  |   Type   |     Colour     | Age |
  |:--------:|:--------------:|-----|
  | Mallard  | green          | 3   |
  | Domestic | white          | 2   |
  | Mandarin | multi-coloured | 4   |

  we want to have a list of maps with `:type`, `:colour` and `:age` as the keys.

  This can be achieved by creating the following schema and parser modules:

  Schema

  ```elixir
  defmodule PondSchema do
    use DataQuacker.Schema

    schema :pond do
      field :type do
        source("type")
      end

      field :colour do
        # make the "u" optional
        # in case we get an American data source :)

        source(~r/colou?r/i)
      end

      field :age do
        source("age")
      end
    end
  end
  ```

  Parser

  ```
  defmodule PondParser do
    def parse(file_path) do
      DataQuacker.parse(
        file_path,
        PondSchema.schema_structure(:pond),
        nil
      )
    end
  end
  ```

    iex> PondParser.parse("path/to/file.csv")
    iex> {:ok, [
    iex>   {:ok, %{type: "Mandarin", colour: "multi-coloured", age: "4"}},
    iex>   {:ok, %{type: "Domestic", colour: "white", age: "2"}},
    iex>   {:ok, %{type: "Mallard", colour: "green", age: "3"}},
    iex> ]}

  Using this schema and parser we get a tuple of `:ok` or `:error`, and a list of rows,
  each of which is also a tuple of `:ok` or `:error`, but with a map as the second element.
  The topmost `:ok` or `:error` indicates whether *all* rows are valid,
  and those for individual rows indicate whether that particular row is valid

  > Note: The rows in the result are in the reverse order compared to the source rows. This is because for large lists reversing may be an expensive operation, which is often redundant, for example if the result is supposed to be inserted in a database.

  Now suppose we also want to validate that the type is one in a list of types we know,
  and get the age in the form of an integer.
  We need to make some changes to our schema

  ```elixir
  defmodule PondSchema do
    use DataQuacker.Schema

    schema :pond do
      field :type do
        validate(fn type -> type in ["Mallard", "Domestic", "Mandarin"] end)

        source("type")
      end

      field :colour do
        # make the "u" optional
        # in case we get an American data source :)

        source(~r/colou?r/i)
      end

      field :age do
        transform(fn age_str ->
          case Integer.parse(str) do
            {age_int, _} -> {:ok, age_int}
            :error -> :error
          end
        end)

        source("age")
      end
    end
  end
  ```

  Using the same input file the output is now:

  iex> PondParser.parse("path/to/file.csv")
  iex> {:ok, [
  iex>   {:ok, %{type: "Mandarin", colour: "multi-coloured", age: 4}},
  iex>   {:ok, %{type: "Domestic", colour: "white", age: 2}},
  iex>   {:ok, %{type: "Mallard", colour: "green", age: 3}},
  iex> ]}

  (the difference is in the type of "age")

  If we add some invalid fields to the file, however, the result will be quite different:

  |   Type   |     Colour     | Age      |
  |:--------:|:--------------:|----------|
  | Mallard  | green          | 3        |
  | Domestic | white          | 2        |
  | Mandarin | multi-coloured | 4        |
  | Mystery  | golden         | 100      |
  | Black    | black          | Infinity |

  iex> PondParser.parse("path/to/file.csv")
  iex> {:ok, [
  iex>   :error,
  iex>   :error,
  iex>   {:ok, %{type: "Mandarin", colour: "multi-coloured", age: 4}}
  iex>   {:ok, %{type: "Domestic", colour: "white", age: 2}},
  iex>   {:ok, %{type: "Mallard", colour: "green", age: 3}},
  iex> ]}

  Since the last two rows of the input are invalid, the first two rows in the output are errors.

  > Note: The errors can be made more descriptive by returning tuples `{:error, any()}` from the validators and parsers. You can see this in action in the examples for the `DataQuacker.Schema` module.
  """

  alias DataQuacker.Builder

  @doc """
  Takes in a source, a schema, support data, and a keyword list of options.
  Returns a tuple with `:ok` or `:error` (indicating whether all rows are valid) as the first element,
  and a list of tuples `{:ok, map()} | {:error, any()} | :error)`.
  In case of `{:ok, map()}` for a given row, the map is the output defined in the schema.

  ## Source

  Any data which will be given to the adapter so that it can retrieve the source data.
  In case of the `DataQuacker.Adapter.CSV` this can be a file path or a file url.

  ## Schema

  A schema formed with the DSL from `DataQuacker.Schema`.

  ## Support data

  Any data which is supposed to be accessible inside various schema elements when parsing a source.

  ## Options

  The options can also be specified in the config, for example:

  ```elixir
  use Mix.Config

  # ...

  config :data_quacker,
    adapter: DataQuacker.Adapters.Identity,
    adapter_opts: []

  # ...
  ```

  - `:adapter` - the adapter module to be used to retrieve the source data; defaults to `DataQuacker.Adapters.CSV`
  - `:adapter_opts` - a keyword list of opts to be passed to the adapter; defaults to `[separator: ?,, local?: true]`; for a list of available adapter options see the documentation for the particular adapter
  """
  @spec parse(any(), map(), any(), Keyword.t()) ::
          {:ok, list({:ok, map()} | {:error, any()} | :error)}
          | {:error, list({:ok, map()} | {:error, any()} | :error)}
  def parse(source, schema, support_data, opts \\ []) do
    with opts <- apply_default_opts(opts),
         adapter <- get_adapter(opts),
         {:ok, source} <- adapter.parse_source(source, get_adapter_opts(opts)) do
      Builder.call(source, schema, support_data, adapter)
    end
  end

  defp apply_default_opts(opts) do
    default_opts()
    |> Keyword.merge(Application.get_all_env(:data_quacker))
    |> Keyword.merge(opts)
  end

  defp default_opts do
    [
      adapter: DataQuacker.Adapters.CSV,
      adapter_opts: [separator: ?,, local?: true]
    ]
  end

  defp get_adapter(opts) do
    Keyword.get(opts, :adapter)
  end

  defp get_adapter_opts(opts) do
    Keyword.get(opts, :adapter_opts, [])
  end
end
