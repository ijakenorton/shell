defmodule Shell.Debug do
  defmacro debug_log(message) do
    quote do
      Logger.warning("#{__MODULE__} at #{__ENV__.file}:#{__ENV__.line}: #{unquote(message)}")
    end
  end
end
