defmodule DataQuacker.SkipperTest do
  use ExUnit.Case, async: true

  alias DataQuacker.Skipper

  alias DataQuacker.Context

  alias DataQuacker.Schema.WrappedFun

  describe "call/3" do
    setup do
      skipper_fun_1 = %WrappedFun{arity: 1, callable: fn value -> value == "abc" end}

      skipper_fun_2 = %WrappedFun{
        arity: 2,
        callable: fn value, context -> value == context.support_data.expected_value end
      }

      incorrect_type_skipper_fun_1 = %WrappedFun{arity: 1, callable: fn _value -> :ok end}

      incorrect_type_skipper_fun_2 = %WrappedFun{
        arity: 2,
        callable: fn _value, _context -> :ok end
      }

      {:ok,
       skipper_fun_1: skipper_fun_1,
       skipper_fun_2: skipper_fun_2,
       incorrect_type_skipper_fun_1: incorrect_type_skipper_fun_1,
       incorrect_type_skipper_fun_2: incorrect_type_skipper_fun_2}
    end

    test "given a skipper function with arity 1 and a value should apply the function to the value",
         %{skipper_fun_1: skipper_fun_1} do
      assert Skipper.call("abc", skipper_fun_1, %Context{}) == true
      assert Skipper.call("def", skipper_fun_1, %Context{}) == false
    end

    test "given a skipper function with arity 2 and a value should apply the function to the value with the context",
         %{skipper_fun_2: skipper_fun_2} do
      assert Skipper.call("abc", skipper_fun_2, %Context{support_data: %{expected_value: "abc"}}) ==
               true

      assert Skipper.call("def", skipper_fun_2, %Context{support_data: %{expected_value: "abc"}}) ==
               false
    end

    test "given a skipper function with arity 1 and an incorrect return type should raise",
         %{incorrect_type_skipper_fun_1: incorrect_type_skipper_fun_1} do
      assert_raise(RuntimeError, ~r/skipper.+field.+abc.+incorrect.+value/si, fn ->
        Skipper.call("abc", incorrect_type_skipper_fun_1, %Context{metadata: {:field, :abc}})
      end)
    end

    test "given a skipper function with arity 2 and an incorrect return type should raise",
         %{incorrect_type_skipper_fun_2: incorrect_type_skipper_fun_2} do
      assert_raise(RuntimeError, ~r/skipper.+field.+abc.+incorrect.+value/si, fn ->
        Skipper.call("abc", incorrect_type_skipper_fun_2, %Context{metadata: {:field, :abc}})
      end)
    end
  end
end
