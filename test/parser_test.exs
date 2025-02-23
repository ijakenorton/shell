defmodule Shell.ParserTest do
  use ExUnit.Case
  alias Shell.{Parser, Token, Position}
  alias Shell.AST.{Program, Expression}

  describe "parse_program/1" do
    test "returns error when no tokens" do
      assert {:error, ["no tokens to parse, possibly a lexer error"]} = Parser.parse_program([])
    end

    test "parses a single number" do
      input = [
        %Token{type: :number, value: "5", position: %Position{row: 1, col: 1}},
        %Token{type: :eof, value: "", position: %Position{row: 1, col: 2}}
      ]

      assert {:ok, %Program{expressions: [expr]}} = Parser.parse_program(input)
      assert expr.type == :number
      assert expr.value == "5"
    end

    test "parses a single identifier" do
      input = [
        %Token{type: :ident, value: "x", position: %Position{row: 1, col: 1}},
        %Token{type: :eof, value: "", position: %Position{row: 1, col: 2}}
      ]

      assert {:ok, %Program{expressions: [expr]}} = Parser.parse_program(input)
      assert expr.type == :identifier
      assert expr.value == "x"
    end

    test "parses multiple expressions" do
      input = [
        %Token{type: :number, value: "5", position: %Position{row: 1, col: 1}},
        %Token{type: :number, value: "10", position: %Position{row: 1, col: 3}},
        %Token{type: :eof, value: "", position: %Position{row: 1, col: 5}}
      ]

      assert {:ok, %Program{expressions: exprs}} = Parser.parse_program(input)
      assert length(exprs) == 2
      [first, second] = exprs
      assert first.type == :number
      assert first.value == "5"
      assert second.type == :number
      assert second.value == "10"
    end

    test "parses let expression" do
      input = [
        %Token{type: :let, value: "let", position: %Position{row: 1, col: 1}},
        %Token{type: :ident, value: "x", position: %Position{row: 1, col: 5}},
        %Token{type: :equals, value: "=", position: %Position{row: 1, col: 7}},
        %Token{type: :number, value: "5", position: %Position{row: 1, col: 9}},
        %Token{type: :eof, value: "", position: %Position{row: 1, col: 10}}
      ]

      assert {:ok, %Program{expressions: [expr]}} = Parser.parse_program(input)
      assert expr.type == :let
      assert expr.value.identifier.value == "x"
      assert expr.value.expression.value == "5"
    end

    test "returns errors for incomplete let expression" do
      input = [
        %Token{type: :let, value: "let", position: %Position{row: 1, col: 1}},
        %Token{type: :number, value: "5", position: %Position{row: 1, col: 5}},
        %Token{type: :eof, value: "", position: %Position{row: 1, col: 6}}
      ]

      assert {:error, errors} = Parser.parse_program(input)
      assert length(errors) > 0

      assert Enum.any?(errors, fn {:error, msg, _pos} ->
               msg =~ "Expected type: ident"
             end)
    end

    test "parses multiple let expressions" do
      input = [
        %Token{type: :let, value: "let", position: %Position{row: 1, col: 1}},
        %Token{type: :ident, value: "x", position: %Position{row: 1, col: 5}},
        %Token{type: :equals, value: "=", position: %Position{row: 1, col: 7}},
        %Token{type: :number, value: "5", position: %Position{row: 1, col: 9}},
        %Token{type: :let, value: "let", position: %Position{row: 2, col: 1}},
        %Token{type: :ident, value: "y", position: %Position{row: 2, col: 5}},
        %Token{type: :equals, value: "=", position: %Position{row: 2, col: 7}},
        %Token{type: :number, value: "10", position: %Position{row: 2, col: 9}},
        %Token{type: :eof, value: "", position: %Position{row: 2, col: 11}}
      ]

      assert {:ok, %Program{expressions: exprs}} = Parser.parse_program(input)
      assert length(exprs) == 2
      [first, second] = exprs
      assert first.type == :let
      assert first.value.identifier.value == "x"
      assert first.value.expression.value == "5"
      assert second.type == :let
      assert second.value.identifier.value == "y"
      assert second.value.expression.value == "10"
    end

    test "returns multiple errors for invalid sequence" do
      input = [
        %Token{type: :let, value: "let", position: %Position{row: 1, col: 1}},
        %Token{type: :equals, value: "=", position: %Position{row: 1, col: 5}},
        %Token{type: :let, value: "let", position: %Position{row: 2, col: 1}},
        %Token{type: :number, value: "5", position: %Position{row: 2, col: 5}},
        %Token{type: :eof, value: "", position: %Position{row: 2, col: 6}}
      ]

      assert {:error, errors} = Parser.parse_program(input)
      assert length(errors) > 1
    end
  end
end

# defmodule Shell.ParserTest do
#   use ExUnit.Case
#   alias Shell.Lexer
#   alias Shell.{Parser, AST.Expression, AST.Program, Token, Position}

#   describe "basic parsing" do
#     test "parses empty program" do
#       assert {:ok, %Program{expressions: []}, []} = Parser.parse_program([])
#     end

#     test "handles unexpected end of input" do
#       tokens = [
#         token(:let, "let", 1, 1),
#         token(:ident, "x", 1, 5)
#       ]

#       assert {:error, "Expected = after identifier in let binding", %Position{row: 1, col: 5}} =
#                Parser.parse_program(tokens)
#     end

#     test "handles unexpected end of input after = " do
#       tokens = [
#         token(:let, "let", 1, 1),
#         token(:ident, "x", 1, 5),
#         token(:equals, "=", 1, 7)
#       ]

#       assert {:error, "Expected number, ident or lbrace, got nothing",
#               %Shell.Position{file: "", row: 1, col: 7}} =
#                Parser.parse_program(tokens)
#     end
#   end

#   describe "let expressions" do
#     test "parses simple let binding" do
#       tokens = [
#         token(:let, "let", 1, 1),
#         token(:ident, "x", 1, 5),
#         token(:equals, "=", 1, 7),
#         token(:number, "42", 1, 9)
#       ]

#       assert {:ok,
#               %Program{
#                 expressions: [
#                   %Expression{
#                     type: :let,
#                     value:
#                       {"x",
#                        %Expression{
#                          type: :number,
#                          value: "42",
#                          position: %Position{row: 1, col: 9}
#                        }},
#                     position: %Position{row: 1, col: 5}
#                   }
#                 ]
#               }, []} = Parser.parse_program(tokens)
#     end
#   end

#   describe "infix expressions" do
#     test "parses plus operator" do
#       tokens = [
#         token(:let, "let", 1, 1),
#         token(:ident, "x", 1, 5),
#         token(:equals, "=", 1, 7),
#         token(:number, "1", 1, 9),
#         token(:plus, "+", 1, 11),
#         token(:number, "2", 1, 13)
#       ]

#       assert {:ok,
#               %Program{
#                 expressions: [
#                   %Expression{
#                     type: :let,
#                     value:
#                       {"x",
#                        %Expression{
#                          type: :infix,
#                          value:
#                            {:plus,
#                             %Expression{
#                               type: :number,
#                               value: "1",
#                               position: %Position{row: 1, col: 9}
#                             },
#                             %Expression{
#                               type: :number,
#                               value: "2",
#                               position: %Position{row: 1, col: 13}
#                             }},
#                          position: %Position{row: 1, col: 11}
#                        }},
#                     position: %Position{row: 1, col: 5}
#                   }
#                 ]
#               }, []} = Parser.parse_program(tokens)
#     end

#     test "parses chained plus operators" do
#       tokens = [
#         token(:let, "let", 1, 1),
#         token(:ident, "x", 1, 5),
#         token(:equals, "=", 1, 7),
#         token(:number, "1", 1, 9),
#         token(:plus, "+", 1, 11),
#         token(:number, "2", 1, 13),
#         token(:plus, "+", 1, 15),
#         token(:number, "3", 1, 17)
#       ]

#       assert {:ok,
#               %Program{
#                 expressions: [
#                   %Expression{
#                     type: :let,
#                     value:
#                       {"x",
#                        %Expression{
#                          type: :infix,
#                          value:
#                            {:plus,
#                             %Expression{
#                               type: :infix,
#                               value:
#                                 {:plus,
#                                  %Expression{
#                                    type: :number,
#                                    value: "1",
#                                    position: %Position{row: 1, col: 9}
#                                  },
#                                  %Expression{
#                                    type: :number,
#                                    value: "2",
#                                    position: %Position{row: 1, col: 13}
#                                  }},
#                               position: %Position{row: 1, col: 11}
#                             },
#                             %Expression{
#                               type: :number,
#                               value: "3",
#                               position: %Position{row: 1, col: 17}
#                             }},
#                          position: %Position{row: 1, col: 15}
#                        }},
#                     position: %Position{row: 1, col: 5}
#                   }
#                 ]
#               }, []} = Parser.parse_program(tokens)
#     end
#   end

#   # describe "block expressions" do
#   #   test "parses empty block" do
#   #     tokens = [
#   #       token(:lbrace, "{", 1, 1),
#   #       token(:rbrace, "}", 1, 2)
#   #     ]

#   #     assert {:ok,
#   #             %Program{
#   #               expressions: [
#   #                 %Expression{
#   #                   type: :block,
#   #                   value: [],
#   #                   position: %Position{row: 1, col: 1}
#   #                 }
#   #               ]
#   #             }, []} = Parser.parse_program(tokens)
#   #   end

#   #   test "parses block with expressions" do
#   #     tokens = [
#   #       token(:lbrace, "{", 1, 1),
#   #       token(:number, "42", 1, 2),
#   #       token(:rbrace, "}", 1, 4)
#   #     ]

#   #     assert {:ok,
#   #             %Program{
#   #               expressions: [
#   #                 %Expression{
#   #                   type: :block,
#   #                   value: [
#   #                     %Expression{
#   #                       type: :number,
#   #                       value: "42",
#   #                       position: %Position{row: 1, col: 2}
#   #                     }
#   #                   ],
#   #                   position: %Position{row: 1, col: 1}
#   #                 }
#   #               ]
#   #             }, []} = Parser.parse_program(tokens)
#   #   end
#   # end

#   # describe "function expressions" do
#   #   test "parses function call" do
#   #     tokens = [
#   #       token(:ident, "add", 1, 1),
#   #       token(:lparen, "(", 1, 4),
#   #       token(:number, "1", 1, 5),
#   #       token(:comma, ",", 1, 6),
#   #       token(:number, "2", 1, 8),
#   #       token(:rparen, ")", 1, 9)
#   #     ]

#   #     assert {:ok,
#   #             %Program{
#   #               expressions: [
#   #                 %Expression{
#   #                   type: :function_call,
#   #                   value: {
#   #                     "add",
#   #                     [
#   #                       %Expression{
#   #                         type: :number,
#   #                         value: "1",
#   #                         position: %Position{row: 1, col: 5}
#   #                       },
#   #                       %Expression{
#   #                         type: :number,
#   #                         value: "2",
#   #                         position: %Position{row: 1, col: 8}
#   #                       }
#   #                     ]
#   #                   },
#   #                   position: %Position{row: 1, col: 1}
#   #                 }
#   #               ]
#   #             }, []} = Parser.parse_program(tokens)
#   #   end
#   # end

#   # Helper for creating tokens (can use helper function here as it's not in a match)
#   defp token(type, value, row, col) do
#     %Token{
#       type: type,
#       value: value,
#       position: %Position{row: row, col: col}
#     }
#   end
# end
