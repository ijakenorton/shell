defmodule Shell.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Shell.Registry},
      {Task.Supervisor, name: Shell.TaskSupervisor},
      Shell.Server
    ]

    opts = [strategy: :one_for_one, name: Shell.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
