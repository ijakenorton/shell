defmodule Shell.Idents do
  use Agent

  def start_link(_opts) do
    # Start with a stack containing just the global environment
    Agent.start_link(fn -> [%{}] end, name: __MODULE__)
  end

  def get_ident(key) do
    Agent.get(__MODULE__, fn environments ->
      # Look for the key in each environment, starting from the most local
      Enum.find_value(environments, fn env ->
        Map.get(env, key)
      end)
    end)
  end

  def put_ident(key, value) do
    Agent.update(__MODULE__, fn [current | rest] ->
      # Update only the most local environment
      [Map.put(current, key, value) | rest]
    end)

    value
  end

  def push_environment do
    Agent.update(__MODULE__, fn environments ->
      # Add a new empty environment at the top of the stack
      [%{} | environments]
    end)
  end

  def pop_environment do
    Agent.update(__MODULE__, fn
      # Don't pop the last environment, replace it
      [_current] -> [%{}]
      [_current | rest] -> rest
    end)
  end

  def inspect_idents do
    Agent.get(__MODULE__, & &1)
  end

  def clear do
    Agent.update(__MODULE__, fn _state -> [%{}] end)
  end
end
