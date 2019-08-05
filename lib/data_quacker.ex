defmodule DataQuacker do
  alias DataQuacker.Builder

  @spec parse(String.t(), map(), any(), Keyword.t()) :: any()
  def parse(source, schema, support_data, opts \\ []) do
    with opts <- apply_default_opts(opts),
         adapter <- Keyword.get(opts, :adapter),
         source <- adapter.parse_source(source) do
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
      adapter_opts: [separator: ?,, local: true]
    ]
  end
end
