defmodule Shell.Lexer do
  alias Shell.Token
  alias Shell.Position

  @symbols %{
    ?. => :dot,
    ?= => :equals,
    ?+ => :plus,
    ?- => :plus,
    ?* => :asterix,
    ?/ => :fslash,
    ?\\ => :bslash,
    ?( => :lparen,
    ?) => :rparen,
    ?{ => :lbrace,
    ?} => :rbrace,
    ?' => :squote,
    ?" => :dquote,
    ?? => :question_mark,
    ?! => :bang,
    ?\n => :newline
  }

  # Validate that all symbol types are valid token types
  for {_char, type} <- @symbols do
    unless Token.valid_type?(type) do
      raise "Invalid token type #{type} in symbols map"
    end
  end

  @keywords %{
    "let" => :let,
    "fn" => :fn,
    "return" => :return
  }

  # Validate that all keyword types are valid token types
  for {_word, type} <- @keywords do
    unless Token.valid_type?(type) do
      raise "Invalid token type #{type} in keywords map"
    end
  end

  defstruct rest: <<>>,
            position: %Position{},
            curr_token: {<<>>, :none, %Position{}},
            tokens: [%Token{type: :ident}]

  def lex(input) do
    tokenize(%__MODULE__{
      rest: input,
      position: %Position{},
      curr_token: {<<>>, :none, %Position{}},
      tokens: []
    })
  end

  # End of the tokens 
  def tokenize(%__MODULE__{
        rest: <<>>,
        position: end_pos,
        curr_token: {<<>>, :none, _position},
        tokens: acc
      }),
      do: {Enum.reverse(acc), end_pos}

  # Last token
  def tokenize(%__MODULE__{
        rest: <<>>,
        position: end_pos,
        curr_token: {curr, type, position},
        tokens: acc
      }),
      do: {Enum.reverse(make_and_add_token({curr, type, position}, acc)), end_pos}

  # End current token with whitespace
  def tokenize(%__MODULE__{
        rest: <<char, rest::bitstring>>,
        position: lexer_pos,
        curr_token: {curr, type, position},
        tokens: acc
      })
      when char in [?\s, ?\t] do
    new_pos = increment_col(lexer_pos)

    tokenize(%__MODULE__{
      rest: rest,
      position: new_pos,
      curr_token: {<<>>, :none, new_pos},
      tokens: make_and_add_token({curr, type, position}, acc)
    })
  end

  # Combined handling for alphanumeric characters
  def tokenize(%__MODULE__{
        rest: <<char::utf8, rest::bitstring>>,
        position: lexer_pos,
        curr_token: {curr, type, position},
        tokens: acc
      })
      when char in ?a..?z or char in ?A..?Z or char in ?0..?9 do
    new_pos = increment_col(lexer_pos)
    new_type = determine_type(char, type)
    token_position = get_position(type, lexer_pos, position)

    tokenize(%__MODULE__{
      rest: rest,
      position: new_pos,
      curr_token: {<<curr::binary, char::utf8>>, new_type, token_position},
      tokens: acc
    })
  end

  # Symbol handling
  def tokenize(%__MODULE__{
        rest: <<char::utf8, rest::bitstring>>,
        position: lexer_pos,
        curr_token: {curr, type, position},
        tokens: acc
      }) do
    tokens =
      case type do
        :none -> acc
        _ -> make_and_add_token({curr, type, position}, acc)
      end

    {token_value, token_type} =
      case Map.get(@symbols, char) do
        nil -> {to_char(char), :unlexible}
        symbol_type -> {to_char(char), symbol_type}
      end

    new_pos = increment_col(lexer_pos)

    tokenize(%__MODULE__{
      rest: rest,
      position: new_pos,
      curr_token: {<<>>, :none, new_pos},
      tokens: make_and_add_token({token_value, token_type, lexer_pos}, tokens)
    })
  end

  # Helper functions
  defp determine_type(char, current_type) when char in ?0..?9 do
    case current_type do
      :none -> :number
      :alpha -> :alphanumeric
      type -> type
    end
  end

  defp determine_type(_char, current_type) do
    case current_type do
      :none -> :alpha
      type -> type
    end
  end

  defp get_position(:none, lexer_pos, _position), do: lexer_pos
  defp get_position(_type, _lexer_pos, position), do: position

  defp make_and_add_token({curr, :alpha, position}, acc) do
    type = Map.get(@keywords, curr, :ident)
    [Token.new(curr, type, position) | acc]
  end

  defp make_and_add_token({curr, :alphanumeric, position}, acc) do
    type = Map.get(@keywords, curr, :ident)
    [Token.new(curr, type, position) | acc]
  end

  defp make_and_add_token({curr, type, position}, acc) when type != :none do
    [Token.new(curr, type, position) | acc]
  end

  defp make_and_add_token({_curr, :none, _position}, acc), do: acc

  defp to_char(char), do: <<char::utf8>>

  defp increment_col(%Position{file: file, row: row, col: col}) do
    %Position{file: file, row: row, col: col + 1}
  end

  defp increment_row(%Position{file: file, row: row}) do
    %Position{file: file, row: row + 1, col: 1}
  end
end
