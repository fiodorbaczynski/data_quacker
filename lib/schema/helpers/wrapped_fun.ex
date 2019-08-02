defmodule DataQuacker.Schema.WrappedFun do
  @moduledoc false

  @type t :: %__MODULE__{
          callable: (... -> any()),
          arity: non_neg_integer()
        }

  @type t(arity) :: %__MODULE__{
          callable: (... -> any()),
          arity: arity
        }
  defstruct [:callable, :arity]
end
