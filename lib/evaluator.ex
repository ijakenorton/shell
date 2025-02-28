defmodule Shell.Evaluator do
  require Logger
  require Shell.Debug
  alias Shell.Position
  alias Shell.Debug
  alias Shell.AST.{Program, Expression}
  alias Shell.Object.Number
  alias Shell.Object.Function
  alias Shell.Idents

  def eval(%Program{expressions: expressions}) do
    eval_expressions(expressions)
  end

  defp eval_expressions(expressions) do
    result =
      Enum.reduce(expressions, nil, fn expr, _last_result ->
        eval_expression(expr)
      end)

    case result do
      {:error, message, pos} -> {:error, message, pos}
      _ -> result
    end
  end

  defp eval_expression(%Expression{type: :number, value: value, position: pos} = expression) do
    case Integer.parse(value) do
      {number, ""} ->
        %Number{value: number}

      _ ->
        Debug.debug_inspect(expression)
        {:error, "Not a valid integer: #{value}", pos}
    end
  end

  defp eval_expression(%Expression{type: :identifier, value: name, position: pos} = expression) do
    Debug.debug_inspect(expression)

    case Idents.get_ident(name) do
      nil ->
        Debug.debug_inspect(Idents.inspect_idents())
        {:error, "identifier not found: #{name}", pos}

      value ->
        value
    end
  end

  defp eval_expression(%Expression{type: :infix, value: {:plus, left, right}}) do
    with %Number{value: left_val} <- eval_expression(left),
         %Number{value: right_val} <- eval_expression(right) do
      %Number{value: left_val + right_val}
    end
  end

  defp eval_expression(%Expression{type: :infix, value: {:asterisk, left, right}}) do
    with %Number{value: left_val} <- eval_expression(left),
         %Number{value: right_val} <- eval_expression(right) do
      %Number{value: left_val * right_val}
    end
  end

  defp eval_expression(%Expression{
         type: :function,
         value: {parameters, body}
       }) do
    parameters = Enum.map(parameters, fn %Expression{type: _, value: value} -> value end)
    %Function{parameters: parameters, body: body}
  end

  defp eval_expression(%Expression{type: :let, value: {name, value_expr}} = expression) do
    Debug.debug_inspect(expression)
    Debug.debug_inspect(name)
    value = eval_expression(value_expr)
    Idents.put_ident(name.value, value)
    value
  end

  defp eval_expression(%Expression{type: type, position: pos}) do
    {:error, "#{type} is not implemented", pos}
  end

  defp eval_expression(input) do
    Debug.debug_warning(input)
    {:error, "Unknown input, probably an interpreter error", %Position{}}
  end
end
