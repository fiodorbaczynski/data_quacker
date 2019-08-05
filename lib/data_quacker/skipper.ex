defmodule DataQuacker.Skipper do
  @moduledoc false

  alias DataQuacker.Schema.WrappedFun

  def call(_, nil, _), do: false

  def call(value, skipping_rule, context) do
    apply_function(skipping_rule, value, context)
  end

  defp apply_function(%WrappedFun{arity: 1, callable: callable}, value, _context) do
    callable.(value)
  end

  defp apply_function(%WrappedFun{arity: 2, callable: callable}, value, context) do
    callable.(value, context)
  end
end
