defmodule HusetWeb.SonoffLive do
  use Phoenix.LiveView

  require Logger
  alias Huset.Sonoff.Net

  def render(assigns) do
    ~H"""
    <div class="flex flex-col p-1 rounded-xl shadow-md bg-gradient-to-r from-green-400 to-blue-500">
      <ul class="flex flex-col">
        <div :if={length(@devices) == 0} class="px-2">
          <p class="font-bold">No devices configued</p>
          <div class="font-normal">
            See <span class="font-light italic">config.exs</span>
          </div>
        </div>
        <%= for %{id: id, ip: ip, description: desc} <- @devices do %>
          <li>
            <ul class="flex flex-col justify-end md:flex-row md:justify-around items-end">
              <div class="mt-2 text-gray-500 text-xs invisible md:visible">
                <%= ip %>
              </div>
              <button
                phx-click="toggle_status"
                phx-value-device_id={id}
                class="bg-purple-600 hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-600 focus:ring-opacity-50 rounded-xl shadow-md w-48 py-6 m-1 justify-end text-xl text-yellow-100 font-semibold"
              >
                <%= desc %>
              </button>
            </ul>
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def mount(_params, _assigns, socket) do
    devices = Net.get_devices()
    {:ok, assign(socket, :devices, devices)}
  end

  def handle_event("toggle_status", %{"device_id" => id}, socket) do
    try do
      Net.toggle_status(id)
    catch
      error -> Logger.warn("Node #{id} did not respond. Error: #{error}")
    end

    {:noreply, socket}
  end
end
