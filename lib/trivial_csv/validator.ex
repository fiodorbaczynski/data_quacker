defmodule DataQuacker.Validator do
  @moduledoc false

  alias DataQuacker.Context

  alias DataQuacker.Schema.WrappedFun

  @type validation_result :: :ok | :error | {:error, any()}

  @spec call(any(), nonempty_list(WrappedFun.t()), Context.t()) :: validation_result()
  def call(value, [validator | rest], context) do
    case apply_validation(value, validator, context) do
      :ok -> call(value, rest, context)
      true -> call(value, rest, context)
      false -> :error
      error -> error
    end
  end

  @spec call(any(), [], Context.t()) :: :ok
  def call(_, [], _), do: :ok

  @spec apply_validation(any(), WrappedFun.t(1), Context.t()) ::
          validation_result() | true | false
  defp apply_validation(value, %WrappedFun{callable: callable, arity: 1}, _context) do
    callable.(value)
  end

  @spec apply_validation(any(), WrappedFun.t(2), Context.t()) :: validation_result()
  defp apply_validation(value, %WrappedFun{callable: callable, arity: 2}, context) do
    callable.(value, context)
  end
end
