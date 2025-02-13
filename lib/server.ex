defmodule Shell.Server do
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
    shell_loop(socket)
  end

  defp shell_loop(socket) do
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        input = String.trim(data)
        Logger.debug("Received input: #{input}")

        case input do
          "exit" ->
            :gen_tcp.send(socket, "Goodbye!\r\n")
            :gen_tcp.close(socket)

          "" ->
            :gen_tcp.send(socket, ">> ")
            shell_loop(socket)

          "history" ->
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

            shell_loop(socket)

          input ->
            case Shell.History.put_history(input) do
              {:error, :not_started} ->
                Logger.warning("History service not available")

              _ ->
                :ok
            end

            lexed = Shell.Lexer.lex(input)
            :gen_tcp.send(socket, "#{inspect(lexed)}\r\n>> ")
            shell_loop(socket)
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
