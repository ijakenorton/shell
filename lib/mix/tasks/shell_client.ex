defmodule Mix.Tasks.ShellClient do
  use Mix.Task
  @shortdoc "Starts the Shell terminal client"

  @impl Mix.Task
  def run(_) do
    # This ensures your application is started
    {:ok, _} = Application.ensure_all_started(:ex_termbox)

    # Start your terminal client
    Shell.TerminalClient.start()

    # If your client is designed to exit, this line won't be reached
    # But it's good to have for task supervision
    Process.sleep(:infinity)
  end
end
