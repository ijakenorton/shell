defmodule NoteParser do
  def parse([]), do: nil

  def parse([head | tail]) do
    IO.puts(head)

    case parse_line(head) do
      :stars -> parse_block(tail)
      :other -> parse(tail)
    end
  end

  def parse_block([head | tail]) do
    case parse_line(head) do
      :stars ->
        :other

      :other ->
        IO.puts(head)
        parse_block(tail)
    end
  end

  def parse_line([]), do: :other

  def parse_line(line) do
    do_parse_line(String.split(line))
  end

  defp do_parse_line([]), do: :other

  defp do_parse_line([head | _tail]) do
    case head do
      "***" ->
        :stars

      _ ->
        :other
    end
  end
end

# NoteParser.parse(IO.stream())

lines =
  Enum.map(IO.stream(), fn line ->
    line
  end)

NoteParser.parse(lines)

# Enum.each(IO.stream(), fn line ->
#   line =
#     line
#     |> String.downcase()
#     |> String.split()

#   NoteParser.parse(line)
# end)
