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

  def tokenize(<<>>, {<<>>, :none}, acc), do: Enum.reverse(acc)
  def tokenize(<<>>, {curr, type}, acc), do: Enum.reverse([Token.new(curr, type) | acc])

  def tokenize(<<?\s, rest::bitstring>>, {curr, type}, acc) do
    case type do
      :none ->
        tokenize(rest, {<<>>, :none}, acc)

      _ ->
        new = Token.new(curr, type)
        tokenize(rest, {<<>>, :none}, [new | acc])
    end
  end

  def tokenize(<<char::utf8, rest::bitstring>>, {curr, type}, acc)
      when char in ?a..?z or
             char in ?A..?Z do
    case type do
      :none -> tokenize(rest, {<<curr::binary, char::utf8>>, :alpha}, acc)
      :alpha -> tokenize(rest, {<<curr::binary, char::utf8>>, :alpha}, acc)
      :number -> tokenize(rest, {<<curr::binary, char::utf8>>, :alphanumeric}, acc)
      :alphanumeric -> tokenize(rest, {<<curr::binary, char::utf8>>, :alphanumeric}, acc)
    end
  end

  def tokenize(<<char::utf8, rest::bitstring>>, {curr, type}, acc)
      when char in ?0..?9 do
    case type do
      :none -> tokenize(rest, {<<curr::binary, char::utf8>>, :number}, acc)
      :number -> tokenize(rest, {<<curr::binary, char::utf8>>, :number}, acc)
      :alpha -> tokenize(rest, {<<curr::binary, char::utf8>>, :alphanumeric}, acc)
      :alphanumeric -> tokenize(rest, {<<curr::binary, char::utf8>>, :alphanumeric}, acc)
    end
  end

  def tokenize(<<char::utf8, rest::bitstring>>, {_curr, _type}, acc) do
    token =
      case char do
        ?. -> {to_char(char), :dot}
        ?= -> {to_char(char), :equals}
        ?* -> {to_char(char), :asterix}
        ?/ -> {to_char(char), :fslash}
        ?\\ -> {to_char(char), :bslash}
        ?( -> {to_char(char), :lparen}
        ?) -> {to_char(char), :rparen}
        ?{ -> {to_char(char), :lbrace}
        ?} -> {to_char(char), :rbrace}
        ?' -> {to_char(char), :squote}
        ?" -> {to_char(char), :dquote}
        _ -> raise RuntimeError, message: "#{to_char(char)} is not lexible"
      end

    {curr, type} = token

    tokenize(rest, {<<>>, :none}, [Token.new(curr, type) | acc])
  end

  def lex(input) do
    statements = statements(input)
    statements |> Enum.map(&tokenize(&1, {<<>>, :none}, []))
  end

  defp to_char(char), do: <<char::utf8>>
  # def lex_line(%__MODULE__{rest: <<>>} = lexer) do
  #   %{lexer | line_no: lexer.line_no + 1}
  # end

  # def lex_line(lexer) do
  #   lex_line(lexer)
  # end

  # def next(%__MODULE__{rest: <<>>} = lexer), do: lexer

  # def next(%__MODULE__{rest: <<char::utf8, rest::binary>>} = lexer) do
  #   %__MODULE__{
  #     lexer
  #     | curr: lexer.next,
  #       next: char,
  #       rest: rest,
  #       col_no: lexer.col_no + 1
  #   }
  # end
end
