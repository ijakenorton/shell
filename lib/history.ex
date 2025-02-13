defmodule Shell.History do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def get_history do
    Agent.get(__MODULE__, &Enum.reverse(&1))
  end

  def put_history(line) do
    Agent.update(__MODULE__, &[line | &1])
  end

  def inspect_ident() do
  end
end
