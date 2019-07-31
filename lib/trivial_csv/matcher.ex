defmodule TrivialCsv.Matcher do
  @moduledoc false

  alias TrivialCsv.Schema.WrappedFun

  def call(headers, rules, context), do: compile_rules(rules, headers, context)

  defp compile_rules(_rules, _headers, _context, acc \\ [])

  defp compile_rules(
         [%{rule: matching_function, target: target} | rest],
         headers,
         context,
         acc
       ) do
    case get_header_index(headers, matching_function, context) do
      nil ->
        {:error, {:header_not_found, target}}

      index ->
        compile_rules(
          rest,
          headers,
          context,
          [{target, index} | acc]
        )
    end
  end

  defp compile_rules([], _, _, acc), do: {:ok, acc}

  defp get_header_index(headers, matching_function, context) do
    Enum.find_index(headers, &apply_function(matching_function, &1, context))
  end

  defp apply_function(%WrappedFun{arity: 1, callable: callable}, column, _context) do
    callable.(column)
  end

  defp apply_function(%WrappedFun{arity: 2, callable: callable}, column, context) do
    callable.(column, context)
  end
end
