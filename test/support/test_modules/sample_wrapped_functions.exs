defmodule DataQuacker.TestModules.SampleWrappedFunctions do
  import DataQuacker.Schema.FunWrapper

  @fun0 wrap_fun(fn ->
          "no args"
        end)

  @fun1 wrap_fun(fn arg1 ->
          arg1
        end)

  @fun2 wrap_fun(fn arg1, arg2 ->
          {arg1, arg2}
        end)

  def wrapped_fun0 do
    @fun0
  end

  def wrapped_fun1 do
    @fun1
  end

  def wrapped_fun2 do
    @fun2
  end
end
