defmodule Shell.Position do
  @type t :: %__MODULE__{
          file: String.t(),
          row: integer(),
          col: integer()
        }
  defstruct file: "Shell instance", row: 1, col: 1
end
