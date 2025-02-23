# defmodule Shell.EvaluatorTest do
#   use ExUnit.Case
#   alias Shell.{Parser, Lexer, Evaluator, Idents, Object.Number}

#   setup do
#     Idents.clear()
#     :ok
#   end

#   describe "basic evaluation" do
#     test "evaluates numbers" do
#       input = "let x = 42"
#       {tokens, _pos} = Lexer.lex(input)
#       {:ok, ast, []} = Parser.parse_program(tokens)
#       assert %Number{value: 42} = Evaluator.eval(ast)
#       assert %Number{value: 42} = Idents.get_ident("x")
#     end

#     test "evaluates addition" do
#       input = "let x = 40 + 2"
#       {tokens, _pos} = Lexer.lex(input)
#       assert {:ok, ast, []} = Parser.parse_program(tokens)
#       assert %Number{value: 42} = Evaluator.eval(ast)
#       assert %Number{value: 42} = Idents.get_ident("x")
#     end

#     test "evaluates chained addition" do
#       input = "let x = 20 + 10 + 12"
#       {tokens, _pos} = Lexer.lex(input)
#       assert {:ok, ast, []} = Parser.parse_program(tokens)
#       assert %Number{value: 42} = Evaluator.eval(ast)
#       assert %Number{value: 42} = Idents.get_ident("x")
#     end

#     test "evaluates identifiers" do
#       Idents.put_ident("x", %Number{value: 40})
#       input = "let y = x + 2"
#       {tokens, _pos} = Lexer.lex(input)
#       assert {:ok, ast, []} = Parser.parse_program(tokens)
#       assert %Number{value: 42} = Evaluator.eval(ast)
#       assert %Number{value: 42} = Idents.get_ident("y")
#     end
#   end

#   describe "error handling" do
#     test "handles undefined identifiers" do
#       input = "let x = y + 2"
#       {tokens, _pos} = Lexer.lex(input)
#       assert {:ok, ast, []} = Parser.parse_program(tokens)
#       assert {:error, "identifier not found: y"} = Evaluator.eval(ast)
#     end
#   end
# end
