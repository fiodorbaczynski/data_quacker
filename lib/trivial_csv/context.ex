defmodule DataQuacker.Context do
  @moduledoc """
  This module provides a struct
  to hold contextual data
  for CSV parsing
  """

  @type t :: %__MODULE__{
          metadata: {atom(), atom()},
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
