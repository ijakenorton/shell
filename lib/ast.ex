defmodule Shell.AST do
  defmodule Expression do
    @type t :: %__MODULE__{
            type: expression_type(),
            value: term(),
            position: Shell.Position.t()
          }
    defstruct [:type, :value, :position]

    # Literals and identifiers
    @type expression_type ::
            :number
            | :identifier
            # Bindings
            | :let
            # Function-related
            | :function
            | :function_call
            # Blocks/sequences of expressions
            | :block

    @spec new_number(String.t(), Shell.Position.t()) :: %__MODULE__{type: :number}
    def new_number(value, position) do
      %__MODULE__{
        type: :number,
        value: value,
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

    @spec new_identifier(String.t(), Shell.Position.t()) :: %__MODULE__{type: :identifier}
    def new_identifier(name, position) do
      %__MODULE__{
        type: :identifier,
        value: name,
        position: position
      }
    end

    @spec new_let(String.t(), expression_type(), Shell.Position.t()) :: %__MODULE__{type: :let}
    def new_let(name, value_expr, position) do
      %__MODULE__{
        type: :let,
        # Tuple containing the name and value expression
        value: {name, value_expr},
        position: position
      }
    end

    @spec new_function([%__MODULE__{type: :identifier}], expression_type(), Shell.Position.t()) ::
            %__MODULE__{type: :function}
    def new_function(params, body, position) do
      %__MODULE__{
        type: :function,
        # Tuple of {function_name, parameter_list, body_expression}
        value: {params, body},
        position: position
      }
    end

    @spec new_function_call(String.t(), [expression_type()], Shell.Position.t()) ::
            %__MODULE__{type: :function_call}
    def new_function_call(name, args, position) do
      %__MODULE__{
        type: :function_call,
        value: {name, args},
        position: position
      }
    end

    @spec new_block([expression_type()], Shell.Position.t()) ::
            %__MODULE__{type: :block}
    def new_block(expressions, position) do
      %__MODULE__{
        type: :block,
        # List of expressions
        value: expressions,
        position: position
      }
    end
  end

  defmodule Program do
    defstruct expressions: []

    def new, do: %__MODULE__{}

    def add_expression(program, expression) do
      %{program | expressions: [expression | program.expressions]}
    end
  end
end
