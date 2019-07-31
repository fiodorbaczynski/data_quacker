defmodule TrivialCsv.Schema.FunWrapper do
  @moduledoc false

  alias TrivialCsv.SchemaError
  alias TrivialCsv.Schema.WrappedFun

  defmacro wrap_fun(fun, expected_arity \\ nil) do
    arity = fun_arity(fun)
    args = fun_args(arity)
    name = random_name()

    maybe_assert_arity!(arity, expected_arity)

    quote do
      def unquote(name)(unquote_splicing(args)) do
        unquote(fun).(unquote_splicing(args))
      end

      %WrappedFun{callable: &(__MODULE__.unquote(name) / unquote(arity)), arity: unquote(arity)}
    end
  end

  defp fun_arity(quoted_fun) do
    with {fun, _} <- Code.eval_quoted(quoted_fun),
         fun_info <- :erlang.fun_info(fun),
         arity when not is_nil(arity) <- Keyword.get(fun_info, :arity) do
      arity
    else
      _ -> raise SchemaError, "Invalid function given"
    end
  end

  defp fun_args(0), do: []

  defp fun_args(arity) do
    Enum.map(1..arity, fn i ->
      arg_name = String.to_atom("arg#{i}")

      # AST for a variable
      {arg_name, [], __MODULE__}
    end)
  end

  defp maybe_assert_arity!(arity, expected_arity) do
    {unquoted_expected_arity, _} = Code.eval_quoted(expected_arity)

    case unquoted_expected_arity do
      nil ->
        :ok

      %Range{first: first, last: last} when arity >= first and arity <= last ->
        :ok

      i when is_integer(i) and arity == i ->
        :ok

      el ->
        raise SchemaError, """

        A function of unexpected arity #{arity} given.
        Should be #{inspect(el)}
        """
    end
  end

  defp random_name() do
    :crypto.strong_rand_bytes(64)
    |> Base.url_encode64()
    |> binary_part(0, 64)
    |> String.to_atom()
  end
end
