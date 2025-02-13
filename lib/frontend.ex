defmodule Shell.Frontend do
  import Shell.History, only: [get_history: 0, put_history: 1]

  def shell_loop do
    IO.puts("Welcome to the shell!")
    do_shell_loop()
  end

  defp do_shell_loop do
    case IO.gets(">> ") do
      :eof ->
        Process.exit(self(), :normal)

      {:error, reason} ->
        Process.exit(self(), {:error, reason})

      input ->
        input = String.trim(input)

        case input do
          "exit" ->
            IO.puts("\nExiting shell...")
            Process.exit(self(), :normal)

          "kill" ->
            IO.puts("\nSimulating crash...")
            Process.exit(self(), :crash)

          "" ->
            do_shell_loop()

          "history" ->
            get_history()
            do_shell_loop()

          input ->
            put_history(input)
            lexed = Shell.Lexer.lex(input)
            IO.inspect(lexed)
            do_shell_loop()
        end
    end
  end
end
