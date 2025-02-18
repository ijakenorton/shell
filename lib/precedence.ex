defmodule Shell.Precedence do
  @type precedence_level ::
          :lowest | :equals | :lessgreater | :sum | :product | :prefix | :call | :index

  @type precedence_value :: 1..8

  # Define constants for precedence levels
  @lowest 1
  @equals 2
  @lessgreater 3
  @sum 4
  @product 5
  @prefix 6
  @call 7
  @index 8

  @precedences %{
    eq: @equals,
    not_eq: @equals,
    lt: @lessgreater,
    gt: @lessgreater,
    plus: @sum,
    minus: @sum,
    slash: @product,
    asterisk: @product,
    lparen: @call,
    lbracket: @index
  }

  @spec lowest() :: precedence_value
  def lowest, do: @lowest

  @spec equals() :: precedence_value
  def equals, do: @equals

  @spec lessgreater() :: precedence_value
  def lessgreater, do: @lessgreater

  @spec sum() :: precedence_value
  def sum, do: @sum

  @spec product() :: precedence_value
  def product, do: @product

  @spec prefix() :: precedence_value
  def prefix, do: @prefix

  @spec call() :: precedence_value
  def call, do: @call

  @spec index() :: precedence_value
  def index, do: @index

  @spec precedences() :: %{atom() => precedence_value}
  def precedences, do: @precedences

  @spec get_precedence(atom()) :: precedence_value
  def get_precedence(token_type) do
    Map.get(@precedences, token_type, @lowest)
  end
end
