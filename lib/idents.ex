defmodule Shell.Idents do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get_ident(key) do
    Agent.get(__MODULE__, &Map.get(&1, key))
  end

  def put_ident(key, token) do
    Agent.update(__MODULE__, &Map.put(&1, key, token))
  end

  def inspect_ident() do
  end
end
