defmodule Shell do
  def start do
    {:ok, agent} = Agent.start_link(fn -> %{history: []} end)
    IO.puts("Agent REPL Started (Ctrl+C to exit)")
    loop(agent)
  end

  def update_history(agent, input) do
    Agent.update(agent, fn state ->
      %{state | history: [input | state.history]}
    end)
  end

  def loop(agent) do
    input =
      IO.gets(">> ")
      |> String.trim()

    case input do
      "exit" ->
        IO.puts("\nExiting shell...")

      "" ->
        loop(agent)

      "history" ->
        # Display command history
        Agent.get(agent, fn state ->
          Enum.reverse(state.history)
          |> Enum.each(&IO.puts/1)
        end)

        loop(agent)

      input ->
        update_history(agent, input)

        lexed = Shell.Lexer.lex(input)
        IO.inspect(lexed)
        loop(agent)
    end
  end
end
