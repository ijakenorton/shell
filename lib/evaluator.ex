defmodule Shell.Evaluator do
  alias Shell.AST.{Program, Expression}
  alias Shell.Object.Number
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

  defp eval_expression(%Expression{type: :number, value: value}) do
    %Number{value: String.to_integer(value)}
  end

  defp eval_expression(%Expression{type: :identifier, value: name}) do
    case Idents.get_ident(name) do
      nil -> {:error, "identifier not found: #{name}"}
      value -> value
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

  defp eval_expression(%Expression{type: :let, value: {name, value_expr}}) do
    value = eval_expression(value_expr)
    Idents.put_ident(name, value)
    value
  end

  defp eval_expression(%Expression{type: type, position: pos}) do
    {:error, "#{type} is not implemented", pos}
  end
end
