defmodule DataQuacker.Adapters.CSV do
  @moduledoc ~S"""
  This is a CSV adapter which can parse CSV files
  from the local filesystem or fetched over http.

  It is the default used if no adapter is specified.

  ## Example source

  `"path/to/csv/file.csv"`
  `"https://remote_file.com/file/abc`
  """

  @behaviour DataQuacker.Adapter

  @impl true
  def parse_source(file_path_or_url, opts) do
    case get_file(file_path_or_url, opts) do
      {:ok, raw_data} -> decode_source(raw_data, get_separator(opts))
      error -> error
    end
  end

  defp get_file(file_path_or_url, opts) do
    case Keyword.get(opts, :local, true) do
      true -> stream_file(file_path_or_url)
      _ -> File.read_link(file_path_or_url)
    end
  end

  defp stream_file(file_path) do
    {:ok, File.stream!(file_path)}
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
