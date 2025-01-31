defmodule Shell.Lexer do
  alias Shell.Token

  defstruct line_no: 0,
            col_no: 0,
            curr: nil,
            next: nil,
            rest: <<>>,
            tokens: [%Token{type: :ident}]

  def statements(input, acc \\ [])
  def statements(<<>>, acc), do: Enum.reverse(acc)

  def statements(input, acc) do
    {rest, line} = statement(input)
    statements(rest, [line | acc])
  end

  def statement(input, acc \\ <<>>)
  def statement(<<>>, acc), do: {<<>>, acc}
  def statement(<<?., rest::bitstring>>, acc), do: {rest, acc}

  def statement(<<char::utf8, rest::bitstring>>, acc) do
    statement(rest, <<acc::binary, char::utf8>>)
  end

  def tokenize(<<>>, curr, acc), do: Enum.reverse([Token.new(:ident, curr) | acc])

  def tokenize(<<?,, rest::bitstring>>, curr, acc) do
    new = Token.new(:ident, curr)
    acc = [new | acc]
    tokenize(rest, <<>>, [Token.new(:comma, <<?,>>) | acc])
  end

  def tokenize(<<char::utf8, rest::bitstring>>, curr, acc)
      when char in ?a..?z or
             char in ?A..?Z or
             char == ?\s do
    tokenize(rest, <<curr::binary, char::utf8>>, acc)
  end

  def tokenize(<<char::utf8, rest::bitstring>>, curr, acc)
      when char in ?0..?9 do
    tokenize(rest, <<curr::binary, char::utf8>>, acc)
  end

  def lex(input) do
    statements = statements(input)
    statements |> Enum.map(&tokenize(&1, <<>>, []))
  end

  def lex_line(%__MODULE__{rest: <<>>} = lexer) do
    %{lexer | line_no: lexer.line_no + 1}
  end

  def lex_line(lexer) do
    lex_line(lexer)
  end

  def next(%__MODULE__{rest: <<>>} = lexer), do: lexer

  def next(%__MODULE__{rest: <<char::utf8, rest::binary>>} = lexer) do
    %__MODULE__{
      lexer
      | curr: lexer.next,
        next: char,
        rest: rest,
        col_no: lexer.col_no + 1
    }
  end
end
