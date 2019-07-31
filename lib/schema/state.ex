defmodule TrivialCsv.Schema.State do
  @moduledoc false

  alias TrivialCsv.Schema.State

  defstruct cursor: [], flags: %{}, schema: %{}, matchers: [], rows: [], fields: %{}

  def new(), do: %State{}

  def clear_fields(state) do
    %State{state | fields: %{}}
  end

  def flag(%State{flags: flags} = state, flag, value) do
    flags = Map.put(flags, flag, value)

    %State{state | flags: flags}
  end

  def flagged?(%State{flags: flags}, flag) do
    Map.get(flags, flag, false)
  end

  def cursor_at?(%State{cursor: []}, type), do: is_nil(type)

  def cursor_at?(%State{cursor: cursor}, type) do
    elem(hd(cursor), 0) == type
  end

  def target(%State{cursor: cursor}) do
    target_from_cursor(cursor)
  end

  def cursor_exit(%State{cursor: cursor} = state, levels \\ 1) do
    %State{state | cursor: Enum.drop(cursor, levels)}
  end

  def register(%State{cursor: cursor} = state, :schema, {schema_name, schema}) do
    cursor = [{:schema, schema_name} | cursor]

    schema = Map.merge(new_schema(schema_name), schema)

    %State{state | schema: schema, cursor: cursor}
  end

  def register(%State{cursor: cursor, rows: rows} = state, :row, {row_index, row}) do
    cursor = [{:row, row_index} | cursor]

    row = Map.merge(new_row(row_index), row)
    rows = rows ++ [row]

    %State{state | rows: rows, cursor: cursor}
  end

  def register(%State{cursor: cursor, fields: fields} = state, :field, {field_name, field}) do
    cursor = [{:field, field_name} | cursor]
    needle = field_needle(cursor)

    field = Map.merge(new_field(field_name), field)
    fields = put_in(fields, Enum.reverse(needle), field)

    %State{state | fields: fields, cursor: cursor}
  end

  def register(%State{matchers: matchers, cursor: cursor} = state, :matcher, rule) do
    matcher = %{rule: rule, target: target_from_cursor(cursor)}
    matchers = [matcher | matchers]

    %State{state | matchers: matchers}
  end

  def update(%State{schema: existing_schema} = state, :schema, schema) do
    schema = Map.merge(existing_schema, schema)

    %State{state | schema: schema}
  end

  def update(%State{cursor: cursor, rows: rows} = state, :row, row) do
    index = elem(hd(cursor), 1)

    rows = List.update_at(rows, index, &Map.merge(&1, row))

    %State{state | rows: rows}
  end

  def update(%State{cursor: cursor, fields: fields} = state, :field, field) do
    needle = field_needle(cursor)

    fields = update_in(fields, Enum.reverse(needle), &Map.merge(&1, field))

    %State{state | fields: fields}
  end

  def get(%State{cursor: cursor, rows: rows}, :row) do
    Enum.at(rows, elem(hd(cursor), 1))
  end

  def get(%State{cursor: cursor, fields: fields}, :field) do
    needle = field_needle(cursor)

    get_in(fields, Enum.reverse(needle))
  end

  defp new_schema(name) do
    %{__name__: name, matchers: [], rows: []}
  end

  defp new_row(index) do
    %{__index__: index, fields: %{}, validators: [], parsers: [], skip_if: nil}
  end

  defp new_field(name) do
    %{
      __name__: name,
      __type__: nil,
      source: nil,
      subfields: %{},
      validators: [],
      parsers: [],
      skip_if: nil
    }
  end

  defp fields_cursor(cursor) do
    cursor |> Enum.split_while(&(elem(&1, 0) == :field)) |> elem(0)
  end

  defp target_from_cursor(cursor) do
    Enum.map(cursor, &elem(&1, 1))
  end

  defp field_needle(cursor) do
    cursor |> fields_cursor() |> target_from_cursor() |> Enum.intersperse(:subfields)
  end
end
