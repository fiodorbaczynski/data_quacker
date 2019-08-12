defmodule DataQuacker.Case do
  @moduledoc false

  use ExUnit.CaseTemplate

  using do
    quote do
      import DataQuacker.Case
    end
  end
end
