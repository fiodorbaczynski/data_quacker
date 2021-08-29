defmodule DataQuacker.Transformer do
  @moduledoc false

  alias DataQuacker.Context

  alias DataQuacker.Schema.WrappedFun

  @type transformation_result :: {:ok, any()} | {:ok, any(), any()} | {:error, any()} | :error

  @spec call(any(), nonempty_list(WrappedFun.t()), Context.t()) :: transformation_result()
  def call(value, [transformer | rest], context) do
    case apply_transformer(value, transformer, context) do
      {:ok, value} ->
        call(value, rest, context)

      {:ok, value, support_data} ->
        call(value, rest, %{context | support_data: support_data})

      {:error, _details} = error ->
        error

      :error ->
        :error

      el ->
        raise """

        Transformer in #{elem(context.metadata, 0)} #{elem(context.metadata, 1)}
        returned an incorrect value #{inspect(el)}.

        Transformers can only have returns of type:
        `{:ok, any()} | {:ok, any(), any()} | {:error, any()} | :error`
        """
    end
  end

  @spec call(any(), [], Context.t()) :: {:ok, any(), Context.t()}
  def call(value, [], context), do: {:ok, value, context}

  @spec apply_transformer(any(), WrappedFun.t(1), Context.t()) :: any()
  defp apply_transformer(value, %WrappedFun{callable: callable, arity: 1}, _context) do
    callable.(value)
  end

  @spec apply_transformer(any(), WrappedFun.t(2), Context.t()) :: any()
  defp apply_transformer(value, %WrappedFun{callable: callable, arity: 2}, context) do
    callable.(value, context)
  end
end
