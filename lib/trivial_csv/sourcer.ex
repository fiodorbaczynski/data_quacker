defmodule TrivialCsv.Sourcer do
  @moduledoc false

  alias TrivialCsv.Schema.WrappedFun

  def call(%WrappedFun{} = getter_function, _values, context) do
    apply_function(getter_function, context)
  end

  def call(target, values, _context) do
    get_value(target, values)
  end

  defp apply_function(%WrappedFun{arity: 0, callable: callable}, _context) do
    callable.()
  end

  defp apply_function(%WrappedFun{arity: 1, callable: callable}, context) do
    callable.(context)
  end

  defp get_value(target, values) do
    Map.get(values, target)
  end
end
