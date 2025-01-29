defmodule Shell.REPL do
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

        # Here you would typically parse and evaluate the input
        # Shell.Lexer
        IO.puts("You entered: #{input}")
        loop(agent)
    end
  end
end

defmodule Shell.Lexer do
  defstruct line_no: 0, col_no: 0, curr: nil, next: nil, rest: <<>>, tokens: []

  def start do
    {:ok, agent} = Agent.start_link(fn -> [] end)
    IO.puts("Agent REPL Started (Ctrl+C to exit)")
    loop(agent)
  end

  def update_tokens(agent, token) do
    Agent.update(agent, fn token ->
      [token | tokens]
    end)
  end

  def tokens(agent) do
    Agent.get(agent, fn state ->
      Enum.reverse(state)
      |> Enum.each(&IO.puts/1)
    end)
  end

  def lex(%{rest: <<>>}), do: []

  def lex(lexer) do
    lex_line(lexer)
  end

  def lex_line(%__MODULE__{rest: <<>>} = lexer) do
    %{lexer | line_no: lexer.line_no + 1}
  end

  def lex_line(lexer) do
    lex_line(lexer)
  end

  def next(%__MODULE__{rest: <<>>} = lexer), do: lexer

  def next(%__MODULE__{rest: <<char::utf8, rest::binary>>} = lexer) do
    %__MODULE__{
      lexer
      | curr: lexer.next,
        next: char,
        rest: rest,
        col_no: lexer.col_no + 1
    }
  end
end

defmodule Shell.Token do
  defstruct curr: nil, next: nil, rest: <<>>
end

defmodule Shell.Parser do
end

ShellREPL.start()
