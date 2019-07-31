defmodule TrivialCsv.Schema.WrappedFun do
  @moduledoc """
  This module provides
  a struct for representing
  a wrapped function
  returned by the
  FunWrapper.wrap_fun/3 macro
  """

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
