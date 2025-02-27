defmodule Shell.AST do
  defmodule Expression do
    # for numbers and identifiers
    @type value_type ::
            String.t()
            # for plus operations
            | {:plus, t(), t()}
            # for let bindings (name, value)
            | {String.t(), t()}
            # for functions (params, body)
            | {[t()], t()}
            # for function calls (name, args)
            | {String.t(), [t()]}
            # for blocks
            | [t()]

    @type t :: %__MODULE__{
            type: expression_type(),
            value: value_type(),
            position: Shell.Position.t()
          }

    defstruct [:type, :value, :position]

    @type expression_type ::
            :number
            | :identifier
            | :let
            | :function
            | :function_call
            | :block
            | :infix

    @spec new_number(String.t(), Shell.Position.t()) :: t()
    def new_number(value, position) do
      %__MODULE__{
        type: :number,
        value: value,
        position: position
      }
    end

    @spec new_prefix(expression_type(), t(), Shell.Position.t()) :: t()
    def new_prefix(type, value, position) do
      %__MODULE__{
        type: type,
        value: value,
        position: position
      }
    end

    @spec new_identifier(String.t(), Shell.Position.t()) :: t()
    def new_identifier(name, position) do
      %__MODULE__{
        type: :identifier,
        value: name,
        position: position
      }
    end

    @spec new_let(t(), t(), Shell.Position.t()) :: t()
    def new_let(identifier, value_expr, position) do
      %__MODULE__{
        type: :let,
        value: {identifier, value_expr},
        position: position
      }
    end

    @spec new_function([t()], [t()], Shell.Position.t()) :: t()
    def new_function(params, body, position) do
      %__MODULE__{
        type: :function,
        value: {params, body},
        position: position
      }
    end

    @spec new_function_call(String.t(), [t()], Shell.Position.t()) :: t()
    def new_function_call(name, args, position) do
      %__MODULE__{
        type: :function_call,
        value: {name, args},
        position: position
      }
    end

    @spec new_block([t()], Shell.Position.t()) :: t()
    def new_block(expressions, position) do
      %__MODULE__{
        type: :block,
        value: expressions,
        position: position
      }
    end

    @spec new_plus(expression_type(), Shell.Position.t()) :: %__MODULE__{type: :plus}
    def new_plus(value, position) do
      %__MODULE__{
        type: :plus,
        value: value,
        position: position
      }
    end

    def new_infix(left, operator, right, position) do
      %__MODULE__{
        type: :infix,
        value: {operator, left, right},
        position: position
      }
    end
  end

  defmodule Program do
    @type t :: %__MODULE__{expressions: [Expression.t()]}
    defstruct expressions: []

    @spec new() :: t()
    def new, do: %__MODULE__{}

    @spec add_expression(t(), Expression.t()) :: t()
    def add_expression(program, expression) do
      %{program | expressions: [expression | program.expressions]}
    end
  end
end
