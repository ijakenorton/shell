defmodule Shell.Lexer do
  alias Shell.Token

  defstruct line_no: 0,
            col_no: 0,
            rest: <<>>,
            tokens: [%Token{type: :ident}]

  def tokenize(<<>>, {<<>>, :none}, acc), do: Enum.reverse(acc)

  def tokenize(<<>>, {curr, type}, acc), do: Enum.reverse(make_and_add_token({curr, type}, acc))

  def tokenize(<<?\s, rest::bitstring>>, {curr, type}, acc),
    do: tokenize(rest, {<<>>, :none}, make_and_add_token({curr, type}, acc))

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

  def tokenize(<<char::utf8, rest::bitstring>>, {curr, type}, acc) do
    _prev =
      case type do
        :none ->
          :ok

        _ ->
          make_and_add_token({curr, type}, acc)
      end

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
        ?? -> {to_char(char), :question_mark}
        ?! -> {to_char(char), :bang}
        _ -> {to_char(char), :unlexible}
      end

    {curr, type} = token

    tokenize(rest, {<<>>, :none}, [Token.new(curr, type) | acc])
  end

  def lex(input) do
    tokenize(input, {<<>>, :none}, [])
  end

  defp make_and_add_token({curr, type}, acc) do
    case type do
      :none ->
        acc

      :alpha ->
        case curr do
          "let" -> [Token.new(curr, :let) | acc]
          "fn" -> [Token.new(curr, :fn) | acc]
          _ -> [Token.new(curr, type) | acc]
        end

      _ ->
        [Token.new(curr, type) | acc]
    end
  end

  defp to_char(char), do: <<char::utf8>>
end
