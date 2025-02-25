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

      assert {
               :ok,
               %Shell.AST.Program{
                 expressions: [
                   %Shell.AST.Expression{
                     position: %Shell.Position{file: "Shell instance", row: 1, col: 9},
                     type: :let,
                     value: {
                       %Shell.AST.Expression{
                         type: :identifier,
                         value: "x",
                         position: %Shell.Position{file: "Shell instance", row: 1, col: 5}
                       },
                       %Shell.AST.Expression{
                         type: :number,
                         value: "5",
                         position: %Shell.Position{file: "Shell instance", row: 1, col: 9}
                       }
                     }
                   }
                 ]
               }
             } = Parser.parse_program(input)
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

      program = Parser.parse_program(input)
      IO.inspect(program)

      assert {:ok,
              %Shell.AST.Program{
                expressions: [
                  %Shell.AST.Expression{
                    type: :let,
                    value:
                      {%Shell.AST.Expression{
                         type: :identifier,
                         value: "x",
                         position: %Shell.Position{file: "Shell instance", row: 1, col: 5}
                       },
                       %Shell.AST.Expression{
                         type: :number,
                         value: "5",
                         position: %Shell.Position{file: "Shell instance", row: 1, col: 9}
                       }},
                    position: %Shell.Position{file: "Shell instance", row: 1, col: 9}
                  },
                  %Shell.AST.Expression{
                    type: :let,
                    value:
                      {%Shell.AST.Expression{
                         type: :identifier,
                         value: "y",
                         position: %Shell.Position{file: "Shell instance", row: 2, col: 5}
                       },
                       %Shell.AST.Expression{
                         type: :number,
                         value: "10",
                         position: %Shell.Position{file: "Shell instance", row: 2, col: 9}
                       }},
                    position: %Shell.Position{file: "Shell instance", row: 2, col: 9}
                  }
                ]
              }} = program
    end

    test "returns multiple errors for invalid sequence" do
      input = [
        %Token{type: :let, value: "let", position: %Position{row: 1, col: 1}},
        %Token{type: :equals, value: "=", position: %Position{row: 1, col: 5}},
        %Token{type: :let, value: "let", position: %Position{row: 2, col: 1}},
        %Token{type: :number, value: "5", position: %Position{row: 2, col: 5}},
        %Token{type: :eof, value: "", position: %Position{row: 2, col: 6}}
      ]

      assert {:error,
              [
                {:error, "Expected type: ident, got equals",
                 %Shell.Position{file: "Shell instance", row: 1, col: 5}}
              ]} =
               Parser.parse_program(input)
    end
  end
end
