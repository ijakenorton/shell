defmodule Shell.Debug do
  require Logger

  defmacro debug_inspect(message) do
    quote do
      Logger.debug(
        "#{__MODULE__} at #{__ENV__.file}:#{__ENV__.line}: #{inspect(unquote(message), pretty: true)}"
      )
    end
  end
end
