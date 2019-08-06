defmodule DataQuacker.Context do
  @moduledoc ~S"""
  This module provides a struct
  to hold contextual data
  for CSV parsing

  ## Metadata

  Metadata is a tuple of an atom and another atom or a non-negative integer. The first is the type of the entity currently being processed (`:field`, `:row`, etc.). The second is the name or index of the entity (name in case of a field, index in case of row).

  ## Support data

  Support data can be of any Elixir data type. It is the exact value passed as support_data to the `DataQuacker.parse/4` at runtime.

  ## Source row

  Source row is a a non-negative integer. The value is the index of the source row currently being processed.
  """

  @type t :: %__MODULE__{
          metadata: {atom(), atom() | non_neg_integer()},
          support_data: any(),
          source_row: non_neg_integer()
        }
  defstruct [:metadata, :support_data, source_row: 0]

  @doc false
  def new(support_data), do: %__MODULE__{support_data: support_data}

  @doc false
  def update_metadata(context, type, name_or_index) do
    %__MODULE__{context | metadata: {type, name_or_index}}
  end

  @doc false
  def increment_row(%__MODULE__{source_row: source_row} = context) do
    %__MODULE__{context | source_row: source_row + 1}
  end
end
