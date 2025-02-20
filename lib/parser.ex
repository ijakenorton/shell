defmodule Shell.Parser do
  alias Shell.Position
  alias Shell.Token
  alias Shell.AST.{Program, Expression}

  @type parser_error :: {:error, String.t(), Position.t()}
  @type t :: %__MODULE__{
          tokens: Token.t(),
          curr: Token.t(),
          next: Token.t()
        }
  defstruct [:tokens, :curr, :next]

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

  @spec parse_expressions([]) :: parser_error()

  defp(parse_expressions([])) do
    {:error, "No tokens", %Position{}}
  end

  @spec parse_expressions(Token.tokens()) :: {:ok, [Expression.t()], []}
  defp(parse_expressions(tokens)) do
    expressions = [%Expression{}]
    {:ok, expressions, []}
  end

  @spec next_token(t()) :: t()
  defp next_token(%__MODULE__{tokens: [token | rest], curr: curr, next: next}) do
    %__MODULE__{
      tokens: rest,
      curr: next,
      next: token
    }
  end
end
