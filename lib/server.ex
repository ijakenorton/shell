defmodule Shell.Server do
  use GenServer
  require Logger

  @port 4040  # Choose your port

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    case :gen_tcp.listen(@port, [:binary, packet: :line, active: false, reuseaddr: true]) do
      {:ok, listen_socket} ->
        Logger.info("Shell server listening on port #{@port}")
        # Start accepting connections
        spawn_link(fn -> accept_connections(listen_socket) end)
        {:ok, %{socket: listen_socket}}
      {:error, reason} ->
        Logger.error("Failed to start shell server: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  defp accept_connections(socket) do
    case :gen_tcp.accept(socket) do
      {:ok, client_socket} ->
        Logger.info("New shell connection accepted")
        # Start a new shell process for this connection
        spawn_link(fn -> handle_client(client_socket) end)
        # Continue accepting new connections
        accept_connections(socket)
      {:error, reason} ->
        Logger.error("Failed to accept connection: #{inspect(reason)}")
        accept_connections(socket)
    end
  end

  defp handle_client(socket) do
    :gen_tcp.send(socket, "Welcome to Shell\r\n")
    shell_loop(socket)
  end

  defp shell_loop(socket) do
    :gen_tcp.send(socket, ">> ")
    case :gen_tcp.recv(socket, 0) do
      {:ok, data} ->
        input = String.trim(data)
        case input do
          "exit" ->
            :gen_tcp.send(socket, "Goodbye!\r\n")
            :gen_tcp.close(socket)
          "" ->
            shell_loop(socket)
          input ->
            # Your existing shell logic here
            lexed = Shell.Lexer.lex(input)
            :gen_tcp.send(socket, "#{inspect(lexed)}\r\n")
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
