defmodule DataQuacker.Case do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import DataQuacker.Case
    end
  end

  def compile_file(name) do
    Code.compile_file(name, "test/support/test_modules")
  end
end
