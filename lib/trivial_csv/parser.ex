defmodule TrivialCsv.Parser do
  @moduledoc false

  alias TrivialCsv.Context

  alias TrivialCsv.Schema.WrappedFun

  @type parsing_result :: {:ok, any()} | {:error, any()}

  @spec call(any(), nonempty_list(WrappedFun.t()), Context.t()) :: parsing_result()
  def call(value, [parser | rest], context) do
    case apply_parser(value, parser, context) do
      {:ok, value} -> call(value, rest, context)
      {:error, _} = error -> error
    end
  end

  @spec call(any(), [], Context.t()) :: {:ok, any()}
  def call(value, [], _), do: {:ok, value}

  @spec apply_parser(any(), WrappedFun.t(1), Context.t()) :: parsing_result()
  defp apply_parser(value, %WrappedFun{callable: callable, arity: 1}, _context) do
    callable.(value)
  end

  @spec apply_parser(any(), WrappedFun.t(2), Context.t()) :: parsing_result()
  defp apply_parser(value, %WrappedFun{callable: callable, arity: 2}, context) do
    callable.(value, context)
  end
end
