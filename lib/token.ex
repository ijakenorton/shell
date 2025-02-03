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
    :dquote
  )
  defstruct [:type, :value]

  def new(value, type)
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
             :dquote
           ] do
    %__MODULE__{type: type, value: value}
  end

  #   def new({type, value})
  #       when type in [:ident, :number, :sep, :comma, :period, :alpha, :alphanumeric] do
  #     %__MODULE__{type: type, value: value}
  #   end
end
