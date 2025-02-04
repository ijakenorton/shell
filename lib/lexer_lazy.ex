defmodule Shell.LexerLazy do
  alias Shell.Token

  def lex(input) when is_binary(input) do
    input
    |> Stream.unfold(&next_char/1)
    |> Stream.chunk_while(
      # Accumulator is now {chars, current_type}
      {[], :none},
      &chunk_token/2,
      &finish_token/1
    )
    |> Stream.map(&create_token/1)
    |> Enum.to_list()
  end

  defp next_char(<<>>), do: nil
  defp next_char(<<char::utf8, rest::binary>>), do: {char, rest}

  defp chunk_token(char, {acc, type}) do
    case {char, type} do
      # Starting a new number
      {x, :none} when x in ?0..?9 ->
        {:cont, {[char], :number}}

      # Continuing a number
      {x, :number} when x in ?0..?9 ->
        {:cont, {[char | acc], :number}}

      # Starting a new word
      {x, :none} when x in ?a..?z or x in ?A..?Z ->
        {:cont, {[char], :alpha}}

      # Continuing a word
      {x, :alpha} when x in ?a..?z or x in ?A..?Z ->
        {:cont, {[char | acc], :alpha}}

      # Separators - emit current token and the separator
      {?,, _} ->
        {:cont, {Enum.reverse(acc), type}, {[], :none}}

      # Space or other character - emit current token if exists
      {?\s, _} when acc != [] ->
        {:cont, {Enum.reverse(acc), type}, {[], :none}}

      # Type changing (number -> alpha or alpha -> number) - emit current and start new
      {x, :number} when x in ?a..?z or x in ?A..?Z ->
        {:cont, {Enum.reverse(acc), :number}, {[char], :alpha}}

      {x, :alpha} when x in ?0..?9 ->
        {:cont, {Enum.reverse(acc), :alpha}, {[char], :number}}

      # Default - start fresh
      {_, _} ->
        if acc == [] do
          {:cont, {[], :none}}
        else
          {:cont, {Enum.reverse(acc), type}, {[], :none}}
        end
    end
  end

  defp finish_token({[], _}), do: {:cont, []}
  defp finish_token({acc, type}), do: {:cont, {Enum.reverse(acc), type}, []}

  defp create_token({chars, :number}) when length(chars) > 0 do
    Token.new(:number, to_string(chars))
  end

  defp create_token({chars, :alpha}) when length(chars) > 0 do
    Token.new(:ident, to_string(chars))
  end

  defp create_token([?,]) do
    Token.new(:comma, ",")
  end
end
