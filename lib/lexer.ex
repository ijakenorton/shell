defmodule Shell.Lexer do
  alias Shell.Token
  alias Shell.Position

  defstruct rest: <<>>,
            position: %Position{},
            curr_token: {<<>>, :none, %Position{}},
            tokens: [%Token{type: :ident}]

  def tokenize(%__MODULE__{
        rest: <<>>,
        position: end_pos,
        curr_token: {<<>>, :none, _position},
        tokens: acc
      }),
      do: {Enum.reverse(acc), end_pos}

  def tokenize(%__MODULE__{
        rest: <<>>,
        position: end_pos,
        curr_token: {curr, type, position},
        tokens: acc
      }),
      do: {Enum.reverse(make_and_add_token({curr, type, position}, acc)), end_pos}

  def tokenize(%__MODULE__{
        rest: <<?\s, rest::bitstring>>,
        position: lexer_pos,
        curr_token: {curr, type, position},
        tokens: acc
      }) do
    new_pos = increment_col(lexer_pos)

    tokenize(%__MODULE__{
      rest: rest,
      position: new_pos,
      curr_token: {<<>>, :none, new_pos},
      tokens: make_and_add_token({curr, type, position}, acc)
    })
  end

  def tokenize(%__MODULE__{
        rest: <<char::utf8, rest::bitstring>>,
        position: lexer_pos,
        curr_token: {curr, type, position},
        tokens: acc
      })
      when char in ?a..?z or
             char in ?A..?Z do
    new_pos = increment_col(lexer_pos)

    case type do
      :none ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :alpha, lexer_pos},
          tokens: acc
        })

      :alpha ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :alpha, position},
          tokens: acc
        })

      :number ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :alphanumeric, position},
          tokens: acc
        })

      :alphanumeric ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :alphanumeric, position},
          tokens: acc
        })
    end
  end

  def tokenize(%__MODULE__{
        rest: <<char::utf8, rest::bitstring>>,
        position: lexer_pos,
        curr_token: {curr, type, position},
        tokens: acc
      })
      when char in ?0..?9 do
    new_pos = increment_col(lexer_pos)

    case type do
      :none ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :number, lexer_pos},
          tokens: acc
        })

      :alpha ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :number, position},
          tokens: acc
        })

      :number ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :alphanumeric, position},
          tokens: acc
        })

      :alphanumeric ->
        tokenize(%__MODULE__{
          rest: rest,
          position: new_pos,
          curr_token: {<<curr::binary, char::utf8>>, :alphanumeric, position},
          tokens: acc
        })
    end
  end

  def tokenize(%__MODULE__{
        rest: <<char::utf8, rest::bitstring>>,
        position: lexer_pos,
        curr_token: {curr, type, position},
        tokens: acc
      }) do
    _prev =
      case type do
        :none ->
          :ok

        _ ->
          make_and_add_token({curr, type, position}, acc)
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
        ?\n -> {to_char(char), :newline}
        _ -> {to_char(char), :unlexible}
      end

    {curr, type} = token
    new_pos = increment_col(lexer_pos)

    tokenize(%__MODULE__{
      rest: rest,
      position: new_pos,
      curr_token: {<<>>, :none, %Position{}},
      tokens: make_and_add_token({curr, type, position}, acc)
    })
  end

  def lex(input) do
    tokenize(%__MODULE__{
      rest: input,
      position: %Position{},
      curr_token: {<<>>, :none, %Position{}},
      tokens: []
    })
  end

  defp make_and_add_token({curr, type, position}, acc) do
    case type do
      :none ->
        acc

      :alpha ->
        case curr do
          "let" -> [Token.new(curr, :let, position) | acc]
          "fn" -> [Token.new(curr, :fn, position) | acc]
          _ -> [Token.new(curr, type, position) | acc]
        end

      _ ->
        [Token.new(curr, type, position) | acc]
    end
  end

  defp to_char(char), do: <<char::utf8>>

  defp increment_col(%Position{file: file, row: row, col: col}) do
    %Position{file: file, row: row, col: col + 1}
  end
end
