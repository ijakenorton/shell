defmodule Shell.Token do
  @type token_type :: :ident | :number | :sep | :comma | :period
  defstruct [:type, :value]

  def new(type, value) when type in [:ident, :number, :sep, :comma, :period] do
    %__MODULE__{type: type, value: value}
  end
end
