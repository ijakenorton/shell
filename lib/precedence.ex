defmodule Shell.Precedence do
  # Define constants for precedence levels
  @lowest 1
  # == 
  @equals 2
  # > or 
  @lessgreater 3
  # +
  @sum 4
  # *
  @product 5
  # -X or !X
  @prefix 6
  # myFunction(X)
  @call 7
  # array[index]
  @index 8

  # Create a map of token types to precedence levels
  @precedences %{
    :eq => @equals,
    :not_eq => @equals,
    :lt => @lessgreater,
    :gt => @lessgreater,
    :plus => @sum,
    :minus => @sum,
    :slash => @product,
    :asterisk => @product,
    :lparen => @call,
    :lbracket => @index
  }

  # Make constants accessible outside the module
  def lowest, do: @lowest
  def equals, do: @equals
  def lessgreater, do: @lessgreater
  def sum, do: @sum
  def product, do: @product
  def prefix, do: @prefix
  def call, do: @call
  def index, do: @index

  # Getter for precedences map
  def precedences, do: @precedences

  # Helper to get precedence for a specific token
  def get_precedence(token_type) do
    Map.get(@precedences, token_type, @lowest)
  end
end
