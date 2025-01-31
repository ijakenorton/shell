defmodule Shell.Parser do
  alias Shell.Token
  use Agent

  defstruct curr_line: [%Token{}], all: [%Token{}]

  def start_link(_opts) do
    Agent.start_link(fn -> [] end)
  end

  def get(parser) do
    Agent.get(parser, & &1)
  end

  def get_reversed(parser) do
    Agent.get(parser, &Enum.reverse(&1))
  end

  def put(parser, token) do
    Agent.update(parser, fn tokens -> [token | tokens] end)
  end

  def do_stuff() do
    IO.puts("do other stuff")
  end
end
