# defmodule Shell.LexerTest do
#   use ExUnit.Case
#   alias Shell.{Lexer, Token, Position}

#   test "lexes identifiers" do
#     inputs_and_expected = [
#       {"x", :ident},
#       {"variable", :ident},
#       # alphanumeric becomes ident
#       {"x1", :ident},
#       # alphanumeric becomes ident
#       {"num123", :ident},
#       # keyword recognition
#       {"let", :let},
#       # keyword recognition
#       {"fn", :fn}
#     ]

#     for {input, expected_type} <- inputs_and_expected do
#       {[token | _], _pos} = Lexer.lex(input)
#       assert token.type == expected_type
#       assert token.value == input
#     end
#   end

#   test "lexes symbols" do
#     inputs_and_expected = [
#       {"=", :equals},
#       {".", :dot},
#       {"(", :lparen},
#       {")", :rparen},
#       {"{", :lbrace},
#       {"}", :rbrace}
#     ]

#     for {input, expected_type} <- inputs_and_expected do
#       {[token | _], _pos} = Lexer.lex(input)
#       assert token.type == expected_type
#       assert token.value == input
#     end
#   end

#   test "tracks position correctly" do
#     input = "let x = 5"
#     {tokens, end_pos} = Lexer.lex(input)

#     expected_positions = [
#       # let
#       {1, 1},
#       # x
#       {1, 5},
#       # =
#       {1, 7},
#       # 5
#       {1, 9}
#     ]

#     tokens_with_positions = Enum.zip(tokens, expected_positions)

#     for {token, {expected_row, expected_col}} <- tokens_with_positions do
#       assert token.position.row == expected_row
#       assert token.position.col == expected_col
#     end

#     # Check final position
#     assert end_pos.col == 10
#   end

#   test "handles complex input" do
#     input = "fn add x1 y2 { x1 + y2 }"
#     {tokens, _pos} = Lexer.lex(input)

#     expected_tokens = [
#       %Token{type: :fn, value: "fn"},
#       %Token{type: :ident, value: "add"},
#       %Token{type: :ident, value: "x1"},
#       %Token{type: :ident, value: "y2"},
#       %Token{type: :lbrace, value: "{"},
#       %Token{type: :ident, value: "x1"},
#       %Token{type: :plus, value: "+"},
#       %Token{type: :ident, value: "y2"},
#       %Token{type: :rbrace, value: "}"}
#     ]

#     assert length(tokens) == length(expected_tokens)

#     for {actual, expected} <- Enum.zip(tokens, expected_tokens) do
#       assert actual.type == expected.type
#       assert actual.value == expected.value
#     end
#   end

#   test "handles empty input" do
#     {tokens, pos} = Lexer.lex("")
#     assert tokens == []
#     assert pos == %Position{row: 1, col: 1}
#   end

#   test "handles unlexible characters" do
#     input = "@"
#     {[token | _], _pos} = Lexer.lex(input)
#     assert token.type == :unlexible
#     assert token.value == "@"
#   end

#   test "handles whitespace" do
#     # Multiple spaces
#     input = "let   x    =    5"
#     {tokens, _pos} = Lexer.lex(input)

#     expected_types = [:let, :ident, :equals, :number]
#     expected_values = ["let", "x", "=", "5"]

#     actual_types = Enum.map(tokens, & &1.type)
#     actual_values = Enum.map(tokens, & &1.value)

#     assert actual_types == expected_types
#     assert actual_values == expected_values
#   end
# end
