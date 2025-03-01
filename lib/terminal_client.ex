defmodule Shell.TerminalClient do
  alias ExTermbox.Bindings, as: Termbox
  alias ExTermbox.{Cell, Constants, Event, EventManager, Position}

  @default_host 'localhost'
  @default_port 4040
  @prompt ">> "
  @multiline_prompt "... "
  @log_file "log/shell_client.log"

  # Simple logging function
  defp log(level, message) do
    File.mkdir_p!("log")
    timestamp = NaiveDateTime.utc_now() |> NaiveDateTime.to_string()
    formatted = "#{timestamp} [#{level}] #{message}\n"
    File.write!(@log_file, formatted, [:append])
  end

  defp log_debug(message), do: log(:debug, message)
  defp log_info(message), do: log(:info, message)
  defp log_error(message), do: log(:error, message)

  # Helper to look up constant names
  defp reverse_lookup(map, val) do
    map |> Enum.find(fn {_, v} -> v == val end) |> elem(0)
  end

  def start(host \\ @default_host, port \\ @default_port) do
    log_info("------ New Shell Client Session Started ------")

    case :gen_tcp.connect(host, port, [:binary, packet: :line, active: false]) do
      {:ok, socket} ->
        log_info("Connected to shell server")
        init_terminal()

        case :gen_tcp.recv(socket, 0) do
          {:ok, welcome} ->
            welcome = String.trim(welcome)

            # Get screen dimensions
            {:ok, width} = Termbox.width()
            {:ok, height} = Termbox.height()

            state = %{
              socket: socket,
              input: "",
              cursor_pos: 0,
              history: [],
              history_index: 0,
              output: [welcome],
              screen_width: width,
              screen_height: height,
              multi_line_mode: false,
              multi_line_buffer: []
            }

            render(state)
            event_loop(state)

          {:error, reason} ->
            log_error("Error receiving welcome message: #{inspect(reason)}")
        end

      {:error, reason} ->
        log_error("Failed to connect: #{inspect(reason)}")
    end
  end

  defp init_terminal do
    :ok = Termbox.init()
    {:ok, _pid} = EventManager.start_link()
    :ok = EventManager.subscribe(self())

    # Try the ESC with mouse mode from the example
    {:ok, _} = Termbox.select_input_mode(Constants.input_mode(:esc_with_mouse))

    Termbox.clear()
    Termbox.present()
  end

  defp event_loop(state) do
    receive do
      {:event, %Event{ch: ?q, mod: mod}} when mod == 2 ->
        # Ctrl+Q to exit
        cleanup_and_exit(state)

      {:event, %Event{type: type} = event} ->
        event_type = Constants.event_type(:key)
        resize_type = Constants.event_type(:resize)

        log_debug(
          "Event received: type=#{type}, type_name=#{reverse_lookup(Constants.event_types(), type)}"
        )

        cond do
          type == event_type ->
            handle_key_event(state, event)

          type == resize_type ->
            {:ok, width} = Termbox.width()
            {:ok, height} = Termbox.height()
            new_state = %{state | screen_width: width, screen_height: height}
            render(new_state)
            event_loop(new_state)

          true ->
            event_loop(state)
        end
    end
  end

  defp handle_key_event(state, %Event{key: key, ch: ch, mod: mod}) do
    log_debug(
      "Key event: key=#{key} (#{format_key_name(key)}), ch=#{ch} (#{format_char(ch)}), mod=#{mod}"
    )

    enter_key = Constants.key(:enter)
    backspace_key = Constants.key(:backspace2)
    arrow_left = Constants.key(:arrow_left)
    arrow_right = Constants.key(:arrow_right)
    arrow_up = Constants.key(:arrow_up)
    arrow_down = Constants.key(:arrow_down)
    tab_key = Constants.key(:tab)

    # Check for common backspace codes and space
    is_backspace = key == backspace_key || ch == 8 || ch == 127
    is_space = ch == 32 || key == 32

    cond do
      # Handle Enter key
      key == enter_key ->
        current_line = state.input

        # Check if the line ends with a backslash
        if String.ends_with?(current_line, "\\") do
          # Remove the trailing backslash
          trimmed_line = String.slice(current_line, 0, String.length(current_line) - 1)

          # Add to multi-line buffer
          updated_buffer = state.multi_line_buffer ++ [trimmed_line]

          # Update state to indicate we're in multi-line mode
          new_state = %{
            state
            | # Clear the input for the next line
              input: "",
              cursor_pos: 0,
              multi_line_mode: true,
              multi_line_buffer: updated_buffer
          }

          # Add a visual indication we're in multi-line mode
          multi_line_prompt = state.output ++ ["#{@prompt}#{current_line}"]
          new_state = %{new_state | output: multi_line_prompt}

          render(new_state)
          event_loop(new_state)
        else
          # We're either not in multi-line mode, or this is the end of multi-line input
          if state.multi_line_mode do
            # Complete the multi-line command
            full_command = Enum.join(state.multi_line_buffer ++ [current_line], "\n")
            log_debug("Executing multi-line command: #{full_command}")

            # Reset multi-line state and add to history
            new_state = %{
              state
              | input: "",
                cursor_pos: 0,
                multi_line_mode: false,
                multi_line_buffer: []
            }

            # Visual indication of the complete command
            updated_output = state.output ++ ["#{@multiline_prompt}#{current_line}"]
            new_state = %{new_state | output: updated_output}

            # Send the full command to the server
            :gen_tcp.send(state.socket, full_command <> "\r\n")

            # Add the multi-line command to history as a single item
            updated_history = state.history ++ [full_command]

            # Process response as usual
            handle_server_response(new_state, updated_history)
          else
            # Regular command execution
            handle_command(state)
          end
        end

      # Debug mode
      key == tab_key ->
        debug_mode(state)

      # Backspace handling
      is_backspace ->
        log_debug(
          "Backspace pressed. Current input: '#{state.input}', cursor position: #{state.cursor_pos}"
        )

        if state.cursor_pos > 0 do
          # Get the part before the cursor position, minus the last character
          before_cursor = String.slice(state.input, 0, state.cursor_pos - 1)
          # Get the part from the cursor position onward
          after_cursor = String.slice(state.input, state.cursor_pos, String.length(state.input))

          new_input = before_cursor <> after_cursor

          log_debug(
            "After backspace: Before='#{before_cursor}', After='#{after_cursor}', New input='#{new_input}'"
          )

          new_state = %{state | input: new_input, cursor_pos: state.cursor_pos - 1}
          render(new_state)
          event_loop(new_state)
        else
          event_loop(state)
        end

      # Arrow keys
      key == arrow_left ->
        if state.cursor_pos > 0 do
          new_state = %{state | cursor_pos: state.cursor_pos - 1}
          render(new_state)
          event_loop(new_state)
        else
          event_loop(state)
        end

      key == arrow_right ->
        if state.cursor_pos < String.length(state.input) do
          new_state = %{state | cursor_pos: state.cursor_pos + 1}
          render(new_state)
          event_loop(new_state)
        else
          event_loop(state)
        end

      key == arrow_up ->
        if state.history_index < length(state.history) do
          history_index = state.history_index + 1
          history_item = Enum.at(state.history, length(state.history) - history_index)

          new_state = %{
            state
            | input: history_item,
              cursor_pos: String.length(history_item),
              history_index: history_index
          }

          render(new_state)
          event_loop(new_state)
        else
          event_loop(state)
        end

      key == arrow_down ->
        if state.history_index > 0 do
          history_index = state.history_index - 1

          history_item =
            if history_index > 0,
              do: Enum.at(state.history, length(state.history) - history_index),
              else: ""

          new_state = %{
            state
            | input: history_item,
              cursor_pos: String.length(history_item),
              history_index: history_index
          }

          render(new_state)
          event_loop(new_state)
        else
          event_loop(state)
        end

      # Space character
      is_space ->
        log_debug("Space key pressed")
        {before_cursor, after_cursor} = String.split_at(state.input, state.cursor_pos)
        new_input = before_cursor <> " " <> after_cursor
        new_state = %{state | input: new_input, cursor_pos: state.cursor_pos + 1}
        render(new_state)
        event_loop(new_state)

      # Regular character input
      key == 0 and ch > 0 ->
        char_str = <<ch::utf8>>
        log_debug("Character key pressed: #{ch} ('#{char_str}')")
        {before_cursor, after_cursor} = String.split_at(state.input, state.cursor_pos)
        new_input = before_cursor <> char_str <> after_cursor
        new_state = %{state | input: new_input, cursor_pos: state.cursor_pos + 1}
        render(new_state)
        event_loop(new_state)

      true ->
        log_debug("Unhandled key event: #{inspect(%{key: key, ch: ch, mod: mod})}")
        event_loop(state)
    end
  end

  defp format_key_name(key) do
    case reverse_lookup(Constants.keys(), key) do
      nil -> "unknown"
      name -> name
    end
  end

  defp format_char(ch) when ch > 0, do: "'" <> <<ch::utf8>> <> "'"
  defp format_char(_), do: "none"

  defp debug_mode(state) do
    Termbox.clear()
    render_text(0, 0, "DEBUG MODE: Press keys to see events (q to exit)")
    render_text(0, 1, "Key information will appear here...")
    Termbox.present()

    debug_loop(state)
  end

  defp debug_loop(state) do
    receive do
      {:event, %Event{ch: ?q}} ->
        render(state)
        event_loop(state)

      {:event, event} ->
        Termbox.clear()
        render_text(0, 0, "DEBUG MODE: Press keys to see events (q to exit)")

        # Show event details
        type_name = reverse_lookup(Constants.event_types(), event.type)
        key_name = if event.key != 0, do: reverse_lookup(Constants.keys(), event.key), else: :none

        render_text(0, 2, "Type: #{inspect(event.type)} #{inspect(type_name)}")
        render_text(0, 3, "Mod:  #{inspect(event.mod)}")
        render_text(0, 4, "Key:  #{inspect(event.key)} #{inspect(key_name)}")
        render_text(0, 5, "Char: #{inspect(event.ch)} #{inspect(<<event.ch::utf8>>)}")

        Termbox.present()
        debug_loop(state)
    end
  end

  defp handle_command(state) do
    if String.trim(state.input) == "exit" do
      cleanup_and_exit(state)
    else
      # Send command to server
      :gen_tcp.send(state.socket, state.input <> "\r\n")

      # Add command to history if not empty
      updated_history =
        if String.trim(state.input) != "",
          do: state.history ++ [state.input],
          else: state.history

      # Update output with the command that was run
      updated_output = state.output ++ ["#{@prompt}#{state.input}"]
      new_state = %{state | output: updated_output, input: "", cursor_pos: 0}

      # Process the server response
      handle_server_response(new_state, updated_history)
    end
  end

  defp handle_server_response(state, history) do
    case :gen_tcp.recv(state.socket, 0) do
      {:ok, response} ->
        trimmed_response = String.trim(response)

        # Update output with server response
        new_output = state.output ++ [trimmed_response]

        # Trim output if it gets too long
        max_lines = state.screen_height - 3

        new_output =
          if length(new_output) > max_lines,
            do: Enum.take(new_output, -max_lines),
            else: new_output

        new_state = %{state | history: history, history_index: 0, output: new_output}

        render(new_state)
        event_loop(new_state)

      {:error, reason} ->
        log_error("Error receiving server response: #{inspect(reason)}")
        cleanup_and_exit(state)
    end
  end

  defp render(state) do
    Termbox.clear()

    # Render output area
    render_output(state)

    # Determine which prompt to use
    prompt = if state.multi_line_mode, do: @multiline_prompt, else: @prompt

    # Render input line
    prompt_length = String.length(prompt)
    render_text(0, length(state.output), prompt)
    # render_text(prompt_length, state.screen_height - 1, state.input)
    render_text(prompt_length, length(state.output), state.input)

    # Set cursor position
    Termbox.set_cursor(prompt_length + state.cursor_pos, length(state.output))

    # Log the current state for debugging
    log_debug("Rendering input: '#{state.input}', cursor at: #{state.cursor_pos}")

    Termbox.present()
  end

  defp render_output(state) do
    # Get actual numeric values for screen dimensions
    width = state.screen_width
    height = state.screen_height

    state.output
    |> Enum.with_index()
    |> Enum.each(fn {line, index} ->
      # Handle line wrapping for long lines
      line_chunks = chunk_text(line, width)

      line_chunks
      |> Enum.with_index()
      |> Enum.each(fn {chunk, chunk_index} ->
        y = index + chunk_index

        if y < height - 1 do
          render_text(0, y, chunk)
        end
      end)
    end)
  end

  defp chunk_text(text, max_width) do
    if String.length(text) <= max_width do
      [text]
    else
      {chunk, rest} = String.split_at(text, max_width)
      [chunk | chunk_text(rest, max_width)]
    end
  end

  defp render_text(x, y, text) do
    text
    |> to_charlist()
    |> Enum.with_index()
    |> Enum.each(fn {ch, index} ->
      Termbox.put_cell(%Cell{position: %Position{x: x + index, y: y}, ch: ch})
    end)
  end

  defp cleanup_and_exit(state) do
    log_info("Cleaning up and exiting")
    :gen_tcp.close(state.socket)
    EventManager.stop()
    Termbox.shutdown()
    System.halt(0)
  end
end
