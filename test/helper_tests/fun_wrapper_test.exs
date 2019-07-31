defmodule TrivialCsv.FunWrapperHelperTest do
  use TrivialCsv.Case, async: true

  alias TrivialCsv.Schema.WrappedFun
  alias TrivialCsv.SchemaError

  alias TrivialCsv.TestModules

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
            import TrivialCsv.Schema.FunWrapper

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
            import TrivialCsv.Schema.FunWrapper

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
            import TrivialCsv.Schema.FunWrapper

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
            import TrivialCsv.Schema.FunWrapper

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
