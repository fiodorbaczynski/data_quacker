defmodule DataQuacker.Adapters.CSV do
  @moduledoc ~S"""
  This is a CSV adapter which can parse CSV files
  from the local filesystem or fetched over http.

  It is the default used if no adapter is specified.

  ## Example source

  - Local file path: `"path/to/csv/file.csv"`
  - Remote file url: `"https://remote_file.com/file/abc"`
  """

  @behaviour DataQuacker.Adapter

  @file_manager Application.get_env(:data_quacker, :file_manager) || FileManager

  @impl true
  @doc ~S"""
  Takes in a string with the path or url to the file, and a keyword list of options.

  ## Options
  - `:separator` - the ASCII value of the column separator in the CSV file; usually retrieved with the `?*` notation where "*" is the character, for example: `?,` for a comma, `?;` for a semicolon, etc.
  - `:local?` - a boolean flag representing whether the file is present on the local file system or on a remote server
  """
  def parse_source(file_path_or_url, opts) do
    case get_file(file_path_or_url, opts) do
      {:ok, raw_data} -> decode_source(raw_data, get_separator(opts))
      error -> error
    end
  end

  defp get_file(file_path_or_url, opts) do
    case Keyword.get(opts, :local?, true) do
      true -> {:ok, @file_manager.stream!(file_path_or_url)}
      false -> {:ok, @file_manager.read_link!(file_path_or_url)}
    end
  rescue
    _ -> {:error, "File does not exist or is corrupted"}
  end

  defp decode_source(source_stream, separator) do
    source_stream
    |> CSV.decode(separator: separator)
    |> Enum.into([])
    |> case do
      [headers | rows] -> {:ok, %{headers: headers, rows: rows}}
      error -> error
    end
  end

  defp get_separator(opts) do
    Keyword.get(opts, :separator, ?,)
  end

  @impl true
  def get_headers(%{headers: headers}), do: headers

  @impl true
  def get_rows(%{rows: rows}), do: {:ok, rows}

  @impl true
  def get_row(row), do: row
end
