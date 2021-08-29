defmodule DataQuacker.Skipper do
  @moduledoc false

  alias DataQuacker.Context

  alias DataQuacker.Schema.WrappedFun

  @type skipper_result :: true | false

  @spec call(any(), nil, any()) :: false
  def call(_value, nil, _context), do: false

  @spec call(any(), WrappedFun.t(), Context.t()) :: skipper_result()
  def call(value, skipping_rule, context) do
    case apply_function(skipping_rule, value, context) do
      result when is_boolean(result) ->
        result

      el ->
        raise """

        Skipper in #{elem(context.metadata, 0)} #{elem(context.metadata, 1)}
        returned an incorrect value #{inspect(el)}.

        Skippers can only have returns of type:
        `true | false`
        """
    end
  end

  @spec apply_function(any(), WrappedFun.t(1), Context.t()) :: any()
  defp apply_function(%WrappedFun{arity: 1, callable: callable}, value, _context) do
    callable.(value)
  end

  @spec apply_function(any(), WrappedFun.t(2), Context.t()) :: any()
  defp apply_function(%WrappedFun{arity: 2, callable: callable}, value, context) do
    callable.(value, context)
  end
end
