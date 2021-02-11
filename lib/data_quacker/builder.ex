defmodule DataQuacker.Builder do
  @moduledoc false

  alias DataQuacker.{Context, Matcher, Sourcer, Validator, Transformer, Skipper}

  def call(
        source,
        %{__name__: schema_name, matchers: matchers, rows: schema_rows} = _schema,
        support_data,
        adapter
      ) do
    with {:ok, headers} <- adapter.get_headers(source),
         {:ok, source_rows} <- adapter.get_rows(source),
         context <-
           support_data
           |> Context.new()
           |> Context.update_metadata(:schema, schema_name),
         {:ok, column_mappings} <- Matcher.call(headers, matchers, context) do
      build_source_rows(source_rows, schema_rows, column_mappings, context, adapter)
    end
  end

  defp build_source_rows(
         _source_rows,
         _schema_rows,
         _column_mappings,
         _context,
         _adapter,
         _acc \\ [],
         _all_ok? \\ true
       )

  defp build_source_rows(
         [source_row | rest],
         schema_rows,
         column_mappings,
         context,
         adapter,
         acc,
         all_ok?
       ) do
    context = Context.increment_row(context)
    source_row = adapter.get_row(source_row)

    result = do_build_source_row(source_row, schema_rows, column_mappings, context)

    build_source_rows(
      rest,
      schema_rows,
      column_mappings,
      context,
      adapter,
      result ++ acc,
      all_ok? and
        Enum.all?(result, fn
          {:ok, _} -> true
          _ -> false
        end)
    )
  end

  defp build_source_rows([], _, _, _, _, acc, true), do: {:ok, acc}

  defp build_source_rows([], _, _, _, _, acc, false), do: {:error, acc}

  defp do_build_source_row({:ok, source_row}, schema_rows, column_mappings, context) do
    values = parse_row_values(source_row, column_mappings)

    build_schema_rows(schema_rows, values, context)
  end

  defp do_build_source_row(error, _, _, _), do: error

  defp build_schema_rows(_schema_rows, _values, _context, acc \\ [])

  defp build_schema_rows([row | rest], values, context, acc) do
    case do_build_schema_row(row, values, context) do
      :skip -> build_schema_rows(rest, values, context, acc)
      row -> build_schema_rows(rest, values, context, [row | acc])
    end
  end

  defp build_schema_rows([], _, _, acc), do: acc

  defp do_build_schema_row(
         %{
           __index__: row_index,
           fields: fields,
           validators: validators,
           transformers: transformers,
           skip_if: skip_if
         },
         values,
         context
       ) do
    with context <- Context.update_metadata(context, :row, row_index),
         {:ok, fields} <- fields |> Enum.into([]) |> build_fields(values, context),
         {:ok, fields, context} <- Transformer.call(fields, transformers, context),
         :ok <- Validator.call(fields, validators, context),
         false <- Skipper.call(fields, skip_if, context) do
      {:ok, fields}
    else
      true -> :skip
      error -> error
    end
  end

  defp build_fields(_fields, _values, _context, _acc \\ %{})

  defp build_fields([{field_name, field} | fields], values, context, acc) do
    case do_build_field(field, values, context) do
      :skip -> build_fields(fields, values, context, acc)
      {:ok, field} -> build_fields(fields, values, context, Map.put(acc, field_name, field))
      error -> error
    end
  end

  defp build_fields([], _, _, acc), do: {:ok, acc}

  defp do_build_field(
         %{
           __name__: field_name,
           validators: validators,
           transformers: transformers,
           skip_if: skip_if
         } = field,
         values,
         context
       ) do
    with context <- Context.update_metadata(context, :field, field_name),
         {:ok, value} <- do_build_field_value(field, values, context),
         {:ok, value, context} <- Transformer.call(value, transformers, context),
         :ok <- Validator.call(value, validators, context),
         false <- Skipper.call(value, skip_if, context) do
      {:ok, value}
    else
      true -> :skip
      error -> error
    end
  end

  defp do_build_field_value(%{__type__: :sourced, source: source}, values, context) do
    {:ok, Sourcer.call(source, values, context)}
  end

  defp do_build_field_value(%{__type__: :wrapper, subfields: subfields}, values, context) do
    subfields
    |> Enum.into([])
    |> build_fields(values, context)
  end

  defp parse_row_values(row, column_mappings) do
    column_mappings
    |> Enum.map(fn {target, index} -> {target, Enum.at(row, index)} end)
    |> Enum.into(%{})
  end
end
