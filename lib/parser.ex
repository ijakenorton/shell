defmodule Shell.Parser do
  require Logger
  require Shell.Debug
  alias Shell.Precedence
  alias Shell.Position
  alias Shell.Debug
  alias Shell.Token
  alias Shell.AST.{Program, Expression}

  @type parser_error :: {:error, String.t(), Position.t()}
  @type prefix_parse_fn :: (t() -> {:ok, t(), Expression.t()} | {:error, t()})
  @type infix_parse_fn :: (t(), Expression.t() -> {:ok, t(), Expression.t()} | {:error, t()})

  @type t :: %__MODULE__{
          tokens: [Token.t()],
          curr: Token.t(),
          next: Token.t(),
          expressions: [Expression.t()],
          errors: [parser_error()],
          prefix_parse_fns: %{Token.token_type() => prefix_parse_fn()},
          infix_parse_fns: %{Token.token_type() => infix_parse_fn()}
        }

  defstruct tokens: [],
            curr: %Token{},
            next: %Token{},
            expressions: [],
            errors: [],
            prefix_parse_fns: %{},
            infix_parse_fns: %{}

  def parse_program([]), do: {:error, ["no tokens to parse, possibly a lexer error"]}
  def parse_program([token | []]), do: parse_expression(token)

  def parse_program(tokens) do
    program = do_parse_program(new(tokens))

    case program do
      {:ok, parser} -> {:ok, %Program{expressions: Enum.reverse(parser.expressions)}}
      {:error, parser} -> {:error, parser.errors}
    end
  end

  @spec do_parse_program(t()) :: {:ok, t()} | {:error, t()}
  def do_parse_program(parser) do
    if parser.curr.type == :eof do
      case parser.errors do
        [] ->
          {:ok, parser}

        _errors ->
          Debug.debug_inspect({:error, parser})
          {:error, parser}
      end
    else
      case parse_expression(parser) do
        {:ok, parser, expression} ->
          parser
          |> append_expression(expression)
          |> next_token()
          |> do_parse_program()

        {:error, parser} ->
          Debug.debug_inspect({:error, parser})
          {:error, parser}
      end
    end
  end

  @spec parse_expression(t()) :: {:ok, t(), Expression.t()} | {:error, t()}
  def parse_expression(parser, precedence \\ Shell.Precedence.lowest()) do
    case Map.get(parser.prefix_parse_fns, parser.curr.type) do
      nil ->
        err =
          {:error,
           append_error(
             parser,
             {:error, "no prefix parse function for #{parser.curr.type} found",
              parser.curr.position}
           )}

        Debug.debug_inspect(err)
        err

      prefix_fn ->
        case prefix_fn.(parser) do
          {:ok, parser, left_exp} ->
            parse_infix_expression(parser, left_exp, precedence)

          {:error, error} ->
            Debug.debug_inspect({:error, parser})

            {:error, error}
        end
    end
  end

  @spec parse_infix_expression(t(), Expression.t(), Precedence.precedence_value()) ::
          {:ok, t(), Expression.t()} | parser_error()

  def parse_infix_expression(parser, left_exp, precedence) do
    case Map.get(parser.infix_parse_fns, parser.next.type) do
      nil ->
        {:ok, parser, left_exp}

      infix_fn ->
        next_precedence = Shell.Precedence.get_precedence(parser.next.type)

        if precedence < next_precedence do
          parser = next_token(parser)

          case infix_fn.(parser, left_exp) do
            {:ok, parser, new_exp} ->
              parse_infix_expression(parser, new_exp, precedence)

            err ->
              Debug.debug_inspect(err)
              err
          end
        else
          {:ok, parser, left_exp}
        end
    end
  end

  def parse_let(parser) do
    with {:ok, parser} <- expect_peek?(parser, :ident),
         {:ok, parser, identifier} <- parse_identifier(parser),
         {:ok, parser} <- expect_peek?(parser, :equals),
         parser <- next_token(parser),
         {:ok, parser, value} <- parse_expression(parser, Shell.Precedence.lowest()) do
      {:ok, parser, Expression.new_let(identifier, value, parser.curr.position)}
    else
      {:error, parser} ->
        Debug.debug_inspect({:error, parser})
        {:error, parser}
    end
  end

  @spec parse_infix_operator(t(), Expression.t()) :: {:ok, t(), Expression.t()} | parser_error()
  def parse_infix_operator(parser, left) do
    operator = parser.curr.type
    precedence = Shell.Precedence.get_precedence(operator)
    parser = next_token(parser)

    case parse_expression(parser, precedence) do
      {:ok, parser, right} ->
        {:ok, parser, Expression.new_infix(left, operator, right, parser.curr.position)}

      err ->
        Debug.debug_inspect(err)
        err
    end
  end

  @spec parse_number(t()) :: {:ok, t(), Expression.t()}
  def parse_number(%__MODULE__{curr: curr} = parser) do
    {:ok, parser, Expression.new_number(curr.value, curr.position)}
  end

  @spec parse_identifier(t()) :: {:ok, t(), Expression.t()}
  def parse_identifier(%__MODULE__{curr: curr} = parser) do
    {:ok, parser, Expression.new_identifier(curr.value, curr.position)}
  end

  @spec curTokenIs?(t(), Token.token_type()) :: boolean()
  def curTokenIs?(parser, type) do
    parser.curr.type == type
  end

  @spec peekTokenIs?(t(), Token.token_type()) :: boolean()
  def peekTokenIs?(parser, type) do
    parser.next.type == type
  end

  @spec expect_peek?(t(), Token.token_type()) :: {:ok, t()} | {:error, t()}
  def expect_peek?(parser, type) do
    case peekTokenIs?(parser, type) do
      true ->
        {:ok, next_token(parser)}

      false ->
        {:error,
         append_error(
           parser,
           {:error, "Expected type: #{type}, got #{parser.next.type}", parser.next.position}
         )}
    end
  end

  @spec append_error(t(), parser_error()) :: t()
  def append_error(parser, {:error, _, _} = error) do
    %__MODULE__{
      parser
      | errors: [error | parser.errors]
    }
  end

  @spec append_expression(t(), Expression.t() | nil) :: t()
  def append_expression(parser, nil), do: parser

  def append_expression(parser, expression) do
    %__MODULE__{
      parser
      | expressions: [expression | parser.expressions]
    }
  end

  @spec register_prefix_fns(t()) :: t()
  defp register_prefix_fns(parser) do
    prefix_fns = %{
      let: &parse_let/1,
      ident: &parse_identifier/1,
      number: &parse_number/1
    }

    %{parser | prefix_parse_fns: prefix_fns}
  end

  @spec register_infix_fns(t()) :: t()
  defp register_infix_fns(parser) do
    infix_fns = %{
      plus: &parse_infix_operator/2,
      minus: &parse_infix_operator/2,
      asterisk: &parse_infix_operator/2,
      slash: &parse_infix_operator/2,
      eq: &parse_infix_operator/2,
      not_eq: &parse_infix_operator/2,
      lt: &parse_infix_operator/2,
      gt: &parse_infix_operator/2
    }

    %{parser | infix_parse_fns: infix_fns}
  end

  @spec new([Token.t()]) :: t()
  def new([]) do
    eof = Token.new("eof", :eof, %Position{})

    %__MODULE__{tokens: [], curr: eof, next: eof, expressions: [], errors: []}
    |> register_prefix_fns()
    |> register_infix_fns()
  end

  def new([curr | []]) do
    eof =
      Token.new("eof", :eof, %Position{
        file: curr.position.file,
        row: curr.position.row,
        col: curr.position.col + 1
      })

    %__MODULE__{tokens: [], curr: curr, next: eof, expressions: [], errors: []}
    |> register_prefix_fns()
    |> register_infix_fns()
  end

  @spec new([Token.t()]) :: t()
  def new([curr | rest]) do
    [next | rest] = rest

    %__MODULE__{tokens: rest, curr: curr, next: next, expressions: [], errors: []}
    |> register_prefix_fns()
    |> register_infix_fns()
  end

  @spec next_token(t()) :: t()
  def next_token(%__MODULE__{tokens: [], curr: curr, next: next} = parser) do
    %__MODULE__{parser | curr: next, next: curr, tokens: []}
  end

  def next_token(%__MODULE__{tokens: [token | rest], curr: _curr, next: next} = parser) do
    %__MODULE__{parser | tokens: rest, curr: next, next: token}
  end
end
