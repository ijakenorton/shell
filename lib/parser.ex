defmodule Shell.Parser do
  alias Shell.AST.{Program, Expression}
  alias Shell.Token

  def parse_program(tokens) do
    case parse_expressions(tokens) do
      {:ok, expressions, []} ->
        {:ok, %Program{expressions: expressions}, []}

      {:ok, _expressions, [%Token{type: type, position: pos} | _]} ->
        {:error, "Unexpected token at end of program: #{type}", pos}

      {:error, msg, pos} ->
        {:error, msg, pos}
    end
  end

  # Top-level expression parsing
  defp parse_expressions(tokens, acc \\ [])
  defp parse_expressions([], acc), do: {:ok, Enum.reverse(acc), []}

  # Let binding
  defp parse_expressions(
         [%Token{type: :let}, %Token{type: :ident, value: name, position: pos} | rest],
         acc
       ) do
    case rest do
      [%Token{type: :equals} | value_tokens] ->
        case parse_expression(value_tokens) do
          {:ok, value_expr, remaining} ->
            let_expr = Expression.new_let(name, value_expr, pos)
            parse_expressions(remaining, [let_expr | acc])

          {:error, msg, error_pos} ->
            {:error, msg, error_pos}
        end

      _ ->
        {:error, "Expected = after identifier in let binding", pos}
    end
  end

  # Function definition
  defp parse_expressions([%Token{type: :fn, position: pos} | rest], acc) do
    case rest do
      [%Token{type: :ident, value: name} | param_tokens] ->
        case parse_function_params(param_tokens) do
          {:ok, params, [%Token{type: :lbrace} | block_tokens]} ->
            case parse_block(block_tokens) do
              {:ok, body, remaining} ->
                fn_expr = Expression.new_function(name, params, body, pos)
                parse_expressions(remaining, [fn_expr | acc])

              {:error, msg, error_pos} ->
                {:error, msg, error_pos}
            end

          {:ok, _params, [%Token{type: type, position: error_pos} | _]} ->
            {:error, "Expected { after function parameters, got #{type}", error_pos}

          {:error, msg, error_pos} ->
            {:error, msg, error_pos}
        end

      _ ->
        {:error, "Expected function name after fn", pos}
    end
  end

  # Function call
  defp parse_expressions(
         [%Token{type: :ident, value: name, position: pos}, %Token{type: :lparen} | rest],
         acc
       ) do
    case parse_function_arguments(rest) do
      {:ok, args, remaining} ->
        call_expr = Expression.new_function_call(name, args, pos)
        parse_expressions(remaining, [call_expr | acc])

      {:error, msg, error_pos} ->
        {:error, msg, error_pos}
    end
  end

  # Block expression
  defp parse_expressions([%Token{type: :lbrace, position: pos} | rest], acc) do
    case parse_block(rest) do
      {:ok, exprs, [%Token{type: :rbrace} | remaining]} ->
        block_expr = Expression.new_block(exprs, pos)
        parse_expressions(remaining, [block_expr | acc])

      {:ok, _, _} ->
        {:error, "Expected } at end of block", pos}

      {:error, msg, error_pos} ->
        {:error, msg, error_pos}
    end
  end

  # Bare identifier (error)
  defp parse_expressions([%Token{type: :ident, position: pos} | _], _acc) do
    {:error, "Unexpected identifier at top level", pos}
  end

  # Invalid top-level expression
  defp parse_expressions([%Token{type: type, position: pos} | _], _acc) do
    {:error, "Invalid top-level expression: #{type}", pos}
  end

  # Individual expression parsing
  defp parse_expression(tokens, precedence \\ :lowest)

  # Number literals
  defp parse_expression([%Token{type: :number, value: num, position: pos} | rest], _precedence) do
    {:ok, Expression.new_number(num, pos), rest}
  end

  # Identifiers
  defp parse_expression([%Token{type: :ident, value: name, position: pos} | rest], _precedence) do
    {:ok, Expression.new_identifier(name, pos), rest}
  end

  # Block expressions
  defp parse_expression([%Token{type: :lbrace, position: pos} | rest], _precedence) do
    case parse_block(rest) do
      {:ok, exprs, [%Token{type: :rbrace} | remaining]} ->
        {:ok, Expression.new_block(exprs, pos), remaining}

      {:ok, _, _} ->
        {:error, "Expected } at end of block", pos}

      {:error, msg, error_pos} ->
        {:error, msg, error_pos}
    end
  end

  # Helper functions
  defp parse_block(tokens, acc \\ []) do
    case tokens do
      [] ->
        {:error, "Unclosed block", nil}

      [%Token{type: :rbrace} | _] = rest ->
        {:ok, Enum.reverse(acc), rest}

      tokens ->
        case parse_expression(tokens) do
          {:ok, expr, remaining} ->
            parse_block(remaining, [expr | acc])

          {:error, msg, pos} ->
            {:error, msg, pos}
        end
    end
  end

  defp parse_function_arguments(tokens, acc \\ []) do
    case tokens do
      [] ->
        {:error, "Unclosed function call - expected )", nil}

      [%Token{type: :rparen} | rest] ->
        {:ok, Enum.reverse(acc), rest}

      [%Token{type: :comma} | rest] ->
        parse_function_arguments(rest, acc)

      tokens ->
        case parse_expression(tokens) do
          {:ok, expr, [%Token{type: type} | _] = rest} when type in [:comma, :rparen] ->
            parse_function_arguments(rest, [expr | acc])

          {:ok, _, [%Token{type: type, position: pos} | _]} ->
            {:error, "Expected , or ) in function arguments, got #{type}", pos}

          {:error, msg, pos} ->
            {:error, msg, pos}
        end
    end
  end

  defp parse_function_params(tokens, acc \\ []) do
    case tokens do
      [%Token{type: :lbrace} | _] = rest ->
        {:ok, Enum.reverse(acc), rest}

      [%Token{type: :ident, value: param, position: pos} | rest] ->
        param_expr = Expression.new_identifier(param, pos)
        parse_function_params(rest, [param_expr | acc])

      [%Token{type: type, position: pos} | _] ->
        {:error, "Expected parameter name or {, got #{type}", pos}

      [] ->
        {:error, "Unexpected end of input in function parameters", nil}
    end
  end
end
