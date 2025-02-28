defmodule Shell.Object do
  defmodule Number do
    defstruct [:value]
  end

  defmodule Function do
    defstruct [:parameters, :body]
  end

  defmodule Environment do
    defstruct store: %{}

    def new, do: %__MODULE__{}

    def get(env, name) do
      Map.fetch(env.store, name)
    end

    def set(env, name, value) do
      %{env | store: Map.put(env.store, name, value)}
    end
  end

  defimpl String.Chars, for: Shell.Object.Number do
    def to_string(%Shell.Object.Number{value: value}), do: Integer.to_string(value)
  end

  defimpl String.Chars, for: Shell.Object.Function do
    def to_string(function),
      do:
        "fn#{Enum.reduce(function.parameters, "", fn param, acc -> "#{acc} #{param}" end)} { ... }"
  end
end
