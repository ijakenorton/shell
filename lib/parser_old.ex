defmodule Shell.Parser_old do
  alias Shell.Position
  alias Shell.AST.{Program, Expression}
  alias Shell.Token
  alias Shell.Precedence

  @type parser_error :: {:error, String.t(), Position.t()}

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

  @spec parse_expressions(Token.tokens(), [Expression.t()]) ::
          {:ok, [Expression.t()], []} | parser_error()
  # Top-level expression parsing
  defp parse_expressions(tokens, acc \\ [])
  defp parse_expressions([], acc), do: {:ok, Enum.reverse(acc), []}

  # Let binding
  defp parse_expressions(
         [%Token{type: :let}, %Token{type: :ident, value: name, position: pos} | rest],
         acc
       ) do
    case rest do
      [%Token{type: :equals, value: _value, position: eq_pos} | []] ->
        {:error, "Expected number, ident or lbrace, got nothing", eq_pos}

      [%Token{type: :equals} | value_tokens] ->
        case parse_expression(value_tokens, 1) do
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

  # Invalid top-level expression
  defp parse_expressions([%Token{type: type, position: pos} | _rest], _acc) do
    {:error, "Invalid top-level expression: #{type}", pos}
  end

  @spec parse_expression(Token.tokens(), Precedence.precedence_value()) ::
          {:ok, Expression.t(), Token.tokens()}
          | {:error, String.t(), Position.t()}
  # Expression parsing with precedence
  defp parse_expression(tokens, precedence \\ Precedence.lowest()) do
    with {:ok, left, rest} <- parse_prefix(tokens),
         {:ok, result, remaining} <- parse_expression_continue(left, rest, precedence) do
      {:ok, result, remaining}
    end
  end

  @spec parse_expression_continue(Expression.t(), Token.tokens(), Precedence.precedence_value()) ::
          {:ok, Expression.t(), Token.tokens()} | parser_error()

  defp parse_expression_continue(left, [], _precedence) do
    {:ok, left, []}
  end

  defp parse_expression_continue(left, [next_token | _] = tokens, precedence) do
    next_precedence = Precedence.get_precedence(next_token.type)

    if precedence < next_precedence do
      with {:ok, new_left, remaining} <- parse_infix(left, tokens, next_precedence) do
        parse_expression_continue(new_left, remaining, next_precedence)
      end
    else
      {:ok, left, tokens}
    end
  end

  @spec parse_prefix(Token.tokens()) ::
          {:ok, Expression.t(), Token.tokens()} | parser_error()
  # Prefix parsing functions
  defp parse_prefix([%Token{type: type, position: pos} = token | rest] = tokens) do
    case type do
      :number ->
        {:ok, Expression.new_number(token.value, token.position), rest}

      :ident ->
        {:ok, Expression.new_identifier(token.value, token.position), rest}

      :plus ->
        {:ok, Expression.new_plus(token.value, token.position), rest}

      :fn ->
        case parse_function(tokens) do
          {:error, message, nil} -> {:error, message, pos}
          _ -> parse_function(tokens)
        end

      :lbrace ->
        case parse_block(tokens) do
          {:error, message, nil} -> {:error, message, pos}
          _ -> parse_block(tokens)
        end

      _ ->
        {:error, "No prefix parse function for #{type}", token.position}
    end
  end

  # Infix parsing functions
  @spec parse_infix(Expression.t(), Token.tokens(), Precedence.precedence_value()) ::
          {:ok, Expression.t(), Token.tokens()} | parser_error()
  defp parse_infix(left, [%Token{type: :plus, position: pos} | rest], _precedence) do
    with {:ok, right, remaining} <- parse_expression(rest, Precedence.sum()) do
      {:ok, %Expression{type: :infix, value: {:plus, left, right}, position: pos}, remaining}
    end
  end

  defp parse_infix(left, [%Token{type: :lparen, position: pos} | rest], _precedence) do
    case parse_function_arguments(rest) do
      {:ok, args, remaining} ->
        {:ok, Expression.new_function_call(left.value, args, left.position), remaining}

      {:error, message, nil} ->
        {:error, message, pos}

      error ->
        error
    end
  end

  defp parse_infix(left, rest, _precedence) do
    {:ok, left, rest}
  end

  # Helper functions
  defp parse_function([%Token{type: :fn, position: pos} | rest]) do
    case parse_function_params(rest) do
      {:ok, params, [%Token{type: :lbrace} | block_tokens]} ->
        case parse_block(block_tokens) do
          {:ok, body, remaining} ->
            {:ok, Expression.new_function(params, body, pos), remaining}

          error ->
            error
        end

      {:ok, _params, [%Token{type: type, position: error_pos} | _]} ->
        {:error, "Expected { after function parameters, got #{type}", error_pos}

      error ->
        error
    end
  end

  @spec parse_block(Token.tokens(), [Expression.t()]) ::
          {:ok, [Expression.t()], Token.tokens()}
          | {:error, String.t(), Position.t() | nil}
  defp parse_block(tokens, acc \\ []) do
    case tokens do
      [] ->
        {:error, "Unclosed block", nil}

      [%Token{type: :rbrace} | rest] ->
        {:ok, Enum.reverse(acc), rest}

      tokens ->
        case parse_expression(tokens, Precedence.lowest()) do
          {:ok, expr, remaining} ->
            parse_block(remaining, [expr | acc])

          {:error, msg, pos} ->
            {:error, msg, pos}
        end
    end
  end

  @spec parse_function_arguments(Token.tokens(), [Expression.t()]) ::
          {:ok, [Expression.t()], Token.tokens()}
          | parser_error()
  defp parse_function_arguments(tokens, acc \\ []) do
    case tokens do
      [] ->
        {:error, "Unclosed function call - expected )", nil}

      [%Token{type: :rparen} | rest] ->
        {:ok, Enum.reverse(acc), rest}

      [%Token{type: :comma} | rest] ->
        parse_function_arguments(rest, acc)

      tokens ->
        case parse_expression(tokens, Precedence.lowest()) do
          {:ok, expr, [%Token{type: type} | _] = rest} when type in [:comma, :rparen] ->
            parse_function_arguments(rest, [expr | acc])

          {:ok, _, [%Token{type: type, position: pos} | _]} ->
            {:error, "Expected , or ) in function arguments, got #{type}", pos}

          {:error, msg, pos} ->
            {:error, msg, pos}
        end
    end
  end

  @spec parse_function_params(Token.tokens(), [Expression.t()]) ::
          {:ok, [Expression.t()], Token.tokens()}
          | {:error, String.t(), Position.t() | nil}
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
