defmodule Shell.Token do
  @type(
    token_type :: :ident,
    :number,
    :sep,
    :comma,
    :period,
    :alpha,
    :alphanumeric,
    :dot,
    :equals,
    :asterix,
    :fslash,
    :bslash,
    :lparen,
    :rparen,
    :lbrace,
    :rbrace,
    :squote,
    :dquote,
    :fn,
    :let,
    :newline,
    :unlexible
  )
  defstruct [:type, :value, :position]

  def new(value, type, position)
      when type in [
             :ident,
             :number,
             :sep,
             :comma,
             :period,
             :alpha,
             :alphanumeric,
             :dot,
             :equals,
             :asterix,
             :fslash,
             :bslash,
             :lparen,
             :rparen,
             :lbrace,
             :rbrace,
             :squote,
             :dquote,
             :fn,
             :let,
             :newline,
             :unlexible
           ] do
    %__MODULE__{type: type, value: value, position: position}
  end

  #   def new({type, value})
  #       when type in [:ident, :number, :sep, :comma, :period, :alpha, :alphanumeric] do
  #     %__MODULE__{type: type, value: value}
  #   end
end
