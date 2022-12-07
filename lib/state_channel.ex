defmodule StateChannel do
  @callback init_state(socket :: term) :: term
  @callback on_message(key :: term, value :: term, socket :: term) :: term
  @optional_callbacks on_message: 3

  defmacro __using__([]) do
    quote do
      use Phoenix.Channel
      @behaviour StateChannel
      import StateChannel.Helpers,
        only: [set_state: 2, set_state: 3, patch_state: 3, patch_state: 4]

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    [quoted_join(env), quoted_handle_info(env), quoted_handle_in(env)]
  end

  defp quoted_join(_env) do
    quote do
      defoverridable join: 3

      @impl Phoenix.Channel
      def join(topic, message, socket) do
        topic
        |> super(message, socket)
        |> case do
          {:ok, %{assigns: %{state: _state}} = new_socket} ->
            send(self(), :after_join_broadcast_state)
            {:ok, new_socket |> Phoenix.Socket.assign(%{version: 0, applied_patches: []})}

          {:ok, new_socket} ->
            send(self(), :after_join_broadcast_state)

            {:ok,
             new_socket
             |> Phoenix.Socket.assign(:state, %{})
             |> Phoenix.Socket.assign(:version, 0)
             |> Phoenix.Socket.assign(:applied_patches, [])}

          otherwise ->
            otherwise
        end
      end
    end
  end

  defp quoted_handle_info(env) do
    if Module.defines?(env.module, {:handle_info, 2}) do
      quote do
        defoverridable handle_info: 2

        @impl Phoenix.Channel
        def handle_info(:after_join_broadcast_state, socket) do
          StateChannel.handle_info(:after_join_broadcast_state, socket)
        end

        @impl Phoenix.Channel
        def handle_info(message, socket) do
          super(message, socket)
        end
      end
    else
      quote do
        @impl Phoenix.Channel
        def handle_info(:after_join_broadcast_state, socket) do
          StateChannel.handle_info(:after_join_broadcast_state, socket)
        end
      end
    end
  end

  defp quoted_handle_in(env) do
    if Module.defines?(env.module, {:handle_in, 3}) do
      quote do
        defoverridable handle_in: 3

        @impl Phoenix.Channel
        def handle_in("_SCMSG:" <> _key = msg, payload, socket) do
          StateChannel.handle_in(__MODULE__, msg, payload, socket)
        end

        @impl Phoenix.Channel
        def handle_in(msg, payload, socket) do
          super(msg, payload, socket)
        end
      end
    else
      quote do
        @impl Phoenix.Channel
        def handle_in("_SCMSG:" <> _key = msg, payload, socket) do
          StateChannel.handle_in(__MODULE__, msg, payload, socket)
        end
      end
    end
  end

  def handle_info(:after_join_broadcast_state, socket) do
    Phoenix.Channel.push(socket, "set_state", %{
      state: socket.assigns.state,
      version: socket.assigns.version
    })

    {:noreply, socket}
  end

  def handle_in(mod, "_SCMSG:" <> key, %{"value" => value, "version" => client_version}, socket) do
    new_socket =
      socket
      |> Phoenix.Socket.assign(
        :version,
        StateChannel.Helpers.next_version(socket.assigns.version, client_version)
      )

    new_socket =
      if function_exported?(mod, :on_message, 3) do
        apply(mod, :on_message, [key, value, new_socket])
      else
        new_socket
      end

    new_socket =
      case new_socket.assigns.applied_patches do
        [] ->
          Phoenix.Channel.push(new_socket, "state_diff", %{
            version: new_socket.assigns.version,
            diff: JSONDiff.diff(socket.assigns.state, new_socket.assigns.state)
          })

          new_socket

        patches ->
          Phoenix.Channel.push(new_socket, "state_diff", %{
            version: new_socket.assigns.version,
            diff: patches
          })

          new_socket |> Phoenix.Socket.assign(:applied_patches, [])
      end

    {:noreply, new_socket}
  end

  def handle_in(mod, "_SCMSG:" <> key, %{"version" => client_version}, socket) do
    new_socket =
      socket
      |> Phoenix.Socket.assign(
        :version,
        StateChannel.Helpers.next_version(socket.assigns.version, client_version)
      )

    new_socket =
      if function_exported?(mod, :on_message, 3) do
        apply(mod, :on_message, [key, nil, new_socket])
      else
        new_socket
      end

    new_socket =
      case new_socket.assigns.applied_patches do
        [] ->
          Phoenix.Channel.push(new_socket, "state_diff", %{
            version: new_socket.assigns.version,
            diff: JSONDiff.diff(socket.assigns.state, new_socket.assigns.state)
          })

          new_socket

        patches ->
          Phoenix.Channel.push(new_socket, "state_diff", %{
            version: new_socket.assigns.version,
            diff: patches
          })

          new_socket |> Phoenix.Socket.assign(:applied_patches, [])
      end

    {:noreply, new_socket}
  end
end
