defmodule Shell.Server do
  alias Shell.Evaluator
  use GenServer
  require Logger
  @port 4040

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    case :gen_tcp.listen(@port, [:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, listen_socket} ->
        Logger.info("Shell server listening on port #{@port}")
        acceptor = spawn_link(fn -> accept_connections(listen_socket) end)
        {:ok, %{socket: listen_socket, acceptor: acceptor}}

      {:error, reason} ->
        Logger.error("Failed to start shell server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  defp accept_connections(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client_socket} ->
        Logger.info("New shell connection accepted")
        spawn(fn -> handle_client(client_socket) end)
        accept_connections(socket)

      {:error, reason} ->
        Logger.error("Failed to accept connection: #{inspect(reason)}")
        accept_connections(socket)
    end
  end

  defp handle_client(socket) do
    Logger.debug("Starting new shell session")
    # Add newline to the welcome message
    :gen_tcp.send(socket, "Its Shelling Time\r\n>> ")
    shell_loop(socket, "")
  end

  # Define helper functions at the module level, not nested inside shell_loop
  defp count_chars(string, char) do
    string
    |> String.graphemes()
    |> Enum.count(fn c -> c == char end)
  end

  defp complete_command?(input) do
    # Count of opening and closing braces and parentheses
    open_braces = count_chars(input, "{")
    close_braces = count_chars(input, "}")
    open_parens = count_chars(input, "(")
    close_parens = count_chars(input, ")")

    # Make sure braces and parentheses are balanced
    brace_balanced = open_braces == close_braces
    paren_balanced = open_parens == close_parens

    brace_balanced and paren_balanced
  end

  defp shell_loop(socket, buffer) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        input = String.trim(data)
        Logger.debug("Received input: #{input}")

        case input do
          "exit" ->
            :gen_tcp.send(socket, "Goodbye!\r\n")
            :gen_tcp.close(socket)

          "" when buffer == "" ->
            :gen_tcp.send(socket, ">> ")
            shell_loop(socket, "")

          "history" when buffer == "" ->
            case Shell.History.get_history() do
              [] ->
                :gen_tcp.send(socket, "No history or history service not available\r\n>> ")

              history ->
                formatted =
                  history
                  |> Enum.with_index(1)
                  |> Enum.map(fn {cmd, i} -> "#{i}: #{cmd}\r\n" end)
                  |> Enum.join("")

                :gen_tcp.send(socket, formatted <> ">> ")
            end

            shell_loop(socket, "")

          input ->
            # Accumulate the input
            new_buffer = if buffer == "", do: input, else: buffer <> "\n" <> input

            # Try to process the accumulated input
            if complete_command?(new_buffer) do
              # Process the complete command
              case Shell.History.put_history(new_buffer) do
                {:error, :not_started} ->
                  Logger.warning("History service not available")

                _ ->
                  :ok
              end

              {tokens, _pos} = Shell.Lexer.lex(new_buffer)

              shell_message =
                case Shell.Parser.parse_program(tokens) do
                  {:ok, ast} ->
                    eval = Evaluator.eval(ast)

                    case eval do
                      {:error, message, pos} ->
                        Enum.reverse([message])
                        |> Enum.with_index(1)
                        |> Enum.map(fn {cmd, i} -> "#{i}: #{inspect(cmd)}\r\n" end)
                        |> Enum.join("")

                      _ ->
                        eval
                    end

                  {:error, errors} ->
                    Enum.reverse(errors)
                    |> Enum.with_index(1)
                    |> Enum.map(fn {cmd, i} -> "#{i}: #{inspect(cmd)}\r\n" end)
                    |> Enum.join("")
                end

              :gen_tcp.send(socket, "#{shell_message}\r\n>> ")
              shell_loop(socket, "")
            else
              # Command is incomplete, keep accumulating
              :gen_tcp.send(socket, "... ")
              shell_loop(socket, new_buffer)
            end
        end

      {:error, :closed} ->
        Logger.info("Client disconnected")
        :ok

      {:error, reason} ->
        Logger.error("Shell error: #{inspect(reason)}")
        :gen_tcp.close(socket)
    end
  end
end
