defmodule DataQuacker.Skipper do
  @moduledoc false

  alias DataQuacker.Context

  alias DataQuacker.Schema.WrappedFun

  @type skipper_result :: true | false

  @spec call(any(), nil, any()) :: false
  def call(_, nil, _), do: false

  @spec call(any(), WrappedFun.t(), Context.t()) :: skipper_result()
  def call(value, skipping_rule, context) do
    apply_function(skipping_rule, value, context)
  end

  @spec apply_function(any(), WrappedFun.t(1), Context.t()) :: skipper_result()
  defp apply_function(%WrappedFun{arity: 1, callable: callable}, value, _context) do
    callable.(value)
  end

  @spec apply_function(any(), WrappedFun.t(2), Context.t()) :: skipper_result()
  defp apply_function(%WrappedFun{arity: 2, callable: callable}, value, context) do
    callable.(value, context)
  end
end
