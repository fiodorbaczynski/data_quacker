defmodule DataQuacker.FunWrapperHelperTest do
  use DataQuacker.Case, async: true

  alias DataQuacker.Schema.WrappedFun
  alias DataQuacker.SchemaError

  alias DataQuacker.TestModules

  describe "wrap_fun/2" do
    test "should wrap a function and return a wrapped function struct" do
      assert [{TestModules.SampleWrappedFunctions, _}] =
               compile_file("sample_wrapped_functions.exs")

      assert %WrappedFun{callable: fun0, arity: 0} =
               TestModules.SampleWrappedFunctions.wrapped_fun0()

      assert fun0.() == "no args"

      assert %WrappedFun{callable: fun1, arity: 1} =
               TestModules.SampleWrappedFunctions.wrapped_fun1()

      assert fun1.("a") == "a"

      assert %WrappedFun{callable: fun2, arity: 2} =
               TestModules.SampleWrappedFunctions.wrapped_fun2()

      assert fun2.("a", "b") == {"a", "b"}
    end

    test "given a function and expected numeric arity should not compile if the function's arity does not match the assertion" do
      assert_raise(SchemaError, ~r/unexpected.+arity/si, fn ->
        Code.eval_string(
          """
          defmodule TestFunWrapper do
            import DataQuacker.Schema.FunWrapper

            @fun wrap_fun(fn _ -> nil end, 2)
          end
          """,
          [],
          __ENV__
        )
      end)

      assert_raise(SchemaError, ~r/unexpected.+arity/si, fn ->
        Code.eval_string(
          """
          defmodule TestFunWrapper do
            import DataQuacker.Schema.FunWrapper

            @fun wrap_fun(fn _, _ -> nil end, 1)
          end
          """,
          [],
          __ENV__
        )
      end)
    end

    test "given a function and expected range of arity should not compile if the function's arity does not match the assertion" do
      assert_raise(SchemaError, ~r/unexpected.+arity/si, fn ->
        Code.eval_string(
          """
          defmodule TestFunWrapper do
            import DataQuacker.Schema.FunWrapper

            @fun wrap_fun(fn -> nil end, 1..2)
          end
          """,
          [],
          __ENV__
        )
      end)

      assert_raise(SchemaError, ~r/unexpected.+arity/si, fn ->
        Code.eval_string(
          """
          defmodule TestFunWrapper do
            import DataQuacker.Schema.FunWrapper

            @fun wrap_fun(fn _, _, _ -> nil end, 1..2)
          end
          """,
          [],
          __ENV__
        )
      end)
    end
  end
end
