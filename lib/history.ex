defmodule Shell.History do
  use Agent

  def start_link(_opts) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def get_history do
    if Process.whereis(__MODULE__) do
      Agent.get(__MODULE__, &Enum.reverse(&1))
    else
      # Return empty list if Agent isn't started
      []
    end
  end

  def put_history(line) do
    if Process.whereis(__MODULE__) do
      Agent.update(__MODULE__, &[line | &1])
    else
      # Could log error or start the Agent here
      {:error, :not_started}
    end
  end
end
