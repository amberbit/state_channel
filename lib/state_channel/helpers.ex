defmodule StateChannel.Helpers do
  import Phoenix.Socket, only: [assign: 3]

  def next_version(server_version, client_version) do
    if client_version > server_version do
      client_version + 1
    else
      server_version + 2
    end
  end

  def set_state(socket, new_state) do
    socket
    |> assign(:state, new_state)
    |> assign(:applied_patches, [])
  end

  def set_state(socket, key, value) do
    current_state = socket.assigns.state

    socket
    |> assign(:state, Map.put(current_state, key, value))
    |> assign(:applied_patches, [])
  end

  def patch_state(socket, :add, path, value) when is_binary(path) do
    patch = %{"op" => "add", "path" => path, "value" => value}
    do_patch_state(socket, patch)
  end

  def patch_state(socket, :replace, path, value) when is_binary(path) do
    patch = %{"op" => "replace", "path" => path, "value" => value}
    do_patch_state(socket, patch)
  end

  def patch_state(socket, :remove, path) when is_binary(path) do
    patch = %{"op" => "remove", "path" => path}
    do_patch_state(socket, patch)
  end

  defp do_patch_state(socket, patch) do
    {:ok, patched_state} = JSONPatch.patch(socket.assigns.state, [patch])

    socket
    |> assign(:state, patched_state)
    |> assign(:applied_patches, socket.assigns.applied_patches ++ [patch])
  end
end
