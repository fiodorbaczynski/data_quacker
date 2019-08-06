defmodule DataQuacker.Validator do
  @moduledoc false

  alias DataQuacker.Context

  alias DataQuacker.Schema.WrappedFun

  @type validation_result :: :ok | :error | {:error, any()}

  @spec call(any(), nonempty_list(WrappedFun.t()), Context.t()) :: validation_result()
  def call(value, [validator | rest], context) do
    case apply_validation(value, validator, context) do
      :ok ->
        call(value, rest, context)

      true ->
        call(value, rest, context)

      false ->
        :error

      {:error, _} = error ->
        error

      :error ->
        :error

      el ->
        raise """

        Validator in #{elem(context.metadata, 0)} #{elem(context.metadata, 1)}
        returned an incorrect value #{inspect(el)}.

        Validators can only have returns of type:
        `:ok | :error | {:error, any()} | true | false`
        """
    end
  end

  @spec call(any(), [], Context.t()) :: :ok
  def call(_, [], _), do: :ok

  @spec apply_validation(any(), WrappedFun.t(1), Context.t()) :: any()
  defp apply_validation(value, %WrappedFun{callable: callable, arity: 1}, _context) do
    callable.(value)
  end

  @spec apply_validation(any(), WrappedFun.t(2), Context.t()) :: any()
  defp apply_validation(value, %WrappedFun{callable: callable, arity: 2}, context) do
    callable.(value, context)
  end
end
