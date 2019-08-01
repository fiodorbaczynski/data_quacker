defmodule DataQuacker do
  alias DataQuacker.Builder

  @spec parse(String.t(), map(), any(), Keyword.t()) :: any()
  def parse(file_path, schema, support_data, opts \\ []) do
    with opts <- apply_defaults_opts(opts),
         {:ok, file_stream} <- stream_file(file_path),
         source <- decode_source(file_stream, Keyword.get(opts, :separator)) do
      Builder.call(source, schema, support_data)
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
      [headers | rows] -> {headers, rows}
      error -> error
    end
  end

  defp apply_defaults_opts(opts) do
    Keyword.merge(Application.get_all_env(:data_quacker), opts)
  end
end
