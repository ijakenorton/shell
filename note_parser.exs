defmodule NoteParser do
  def parse([]), do: []

  def parse(lines) do
    lines =
      do_parse(lines)

    case lines do
      _ ->
        parse(lines)
    end
  end

  defp do_parse([{head, _line_no} | tail]) do
    line = head |> String.split() |> parse_line()

    case line do
      :stars ->
        IO.puts("[REF]")
        parse_block(tail)

      :line ->
        tail
    end
  end

  def parse_block([{head, _line_no} | tail]) do
    line = head |> String.split() |> parse_line()

    case line do
      :stars ->
        IO.puts("[ENDREF]")
        IO.puts("\n")
        tail

      :line ->
        IO.puts(head)
        parse_block(tail)
    end
  end

  defp parse_line([]), do: :line

  defp parse_line([head | tail]) do
    case head do
      "***" -> :stars
      _ -> parse_line(tail)
    end
  end
end

{lines, _} =
  Enum.map_reduce(IO.stream(), 0, fn line, acc ->
    {{line, acc}, acc + 1}
  end)

_ = NoteParser.parse(lines)
