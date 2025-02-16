defmodule Shell.Token do
  # Define all token types in one place
  @token_types [
    # Identifiers and literals
    :ident,
    :number,
    :alpha,
    :alphanumeric,

    # Keywords
    :fn,
    :let,
    :return,

    # Separators and delimiters
    :sep,
    :comma,
    :period,
    :dot,
    :lparen,
    :rparen,
    :lbrace,
    :rbrace,
    :squote,
    :dquote,

    # Operators
    :equals,
    :plus,
    :minus,
    :asterix,
    :fslash,
    :bslash,
    :bang,
    :question_mark,

    # Whitespace
    :newline,
    :tab,

    # Special
    :unlexible
  ]

  # Create type spec from the token types
  @type token_type :: unquote(Enum.reduce(@token_types, &{:|, [], [&1, &2]}))

  defstruct [:type, :value, :position]

  # Use the module attribute for validation
  def new(value, type, position) when type in @token_types do
    %__MODULE__{type: type, value: value, position: position}
  end

  # Helper function to check if a type is valid
  def valid_type?(type), do: type in @token_types

  # Helper to get all valid types
  def types, do: @token_types
end
