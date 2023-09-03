defmodule Huset.Sonoff.Node do
  @moduledoc """
  Stores the status of a Sonoff Mini R2 smart switch

  example of manual commands:

  body = "{ \"deviceid\" : \"ESP_E69CC4\", \"data\": {\"switch\": \"on\" }}"
  post( "http://192.168.1.116:8081/zeroconf/switch", body)

  """

  use GenServer
  use HTTPoison.Base
  require Logger

  alias Huset.Sonoff.Node

  defstruct id: "none", ip: "", status: "", description: "n/a"

  # Client API

  def start_link(init_values) do
    GenServer.start_link(__MODULE__, init_values)
  end

  @impl true
  def init(%{ip: ip_addr, id: dev_id, description: desc}) do
    {:ok,
     %Node{
       ip: ip_addr,
       status: :off,
       id: dev_id,
       description: desc
     }}
  end

  @doc """
  Returns this node process inforamtion
  """
  def get_info(pid) do
    GenServer.call(pid, :get_info)
  end

  @doc """
  Returns the internal state of the hardware device
  """
  def get_status(pid) do
    GenServer.call(pid, :get_status)
  end

  @doc """
  Handles a request to toggle the current status on/off the device
  """
  def toggle_status(pid) do
    GenServer.call(pid, :toggle_status)
  end

  # @doc """
  # Handles a request to turn on and off the device
  # """
  # def set_status(pid, new_status) when new_status in [:on, :off] do
  #   GenServer.call(pid, {:set_status, new_status})
  # end

  # @doc """
  # Handles a request to set the description description of the device
  # """
  # def set_description(pid, description) do
  #   GenServer.call(pid, {:set_description, description})
  # end

  # GenServer callbacks

  @impl true
  def handle_call(:get_info, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_status, _from, state) do
    %Node{ip: ip_addr} = state
    url = "http://#{ip_addr}:8081/zeroconf/switch"
    headers = [{"content-type", "application/json"}]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Assuming the JSON response is like: %{"status": "on", "temperature": 25}
        case Jason.decode(body) do
          {:ok, data} ->
            {:reply, data, state}

          {:error, _reason} ->
            {:reply, %{error: "Failed to decode JSON"}, state}
        end

      {:ok, %HTTPoison.Response{status_code: status}} ->
        {:reply, %{error: "Request failed with status #{status}"}, state}

      {:error, reason} ->
        {:reply, %{error: "Request failed with reason #{inspect(reason)}"}, state}
    end
  end

  def handle_call(:toggle_status, _from, state) do
    %Node{ip: ip_addr, id: device_id, status: device_status} = state

    url = "http://#{ip_addr}:8081/zeroconf/switch"
    headers = [{"content-type", "application/json"}]

    toggled_status = toggle(device_status)

    body =
      %{deviceid: device_id, data: %{switch: toggled_status}}
      |> Jason.encode!()

    HTTPoison.post(url, body, headers)
    |> handle_poison_response()
    |> case do
      {:ok, data} ->
        Logger.debug("switched successfully #{inspect(data)}")

        new_state = %{state | status: toggled_status}

        {:reply, toggled_status, new_state}

      error ->
        {:reply, error, state}
    end
  end

  @doc """

  ## Example

  Response

          %HTTPoison.Response{
            status_code: 200,
            body: "{\"seq\":26,\"error\":0}",
            headers: [
              {"Server", "openresty"},
              {"Content-Type", "application/json; charset=utf-8"},
              {"Content-Length", "20"},
              {"Connection", "close"}
            ],
            request_url: "http://192.168.1.128:8081/zeroconf/switch",
            request: %HTTPoison.Request{
              method: :post,
              url: "http://192.168.1.128:8081/zeroconf/switch",
              headers: [{"content-type", "application/json"}],
              body: "{\"data\":{\"switch\":\"on\"},\"deviceid\":\"ESP_E68C6C\"}",
              params: %{},
              options: []
            }
          }
  """
  def handle_poison_response(response) do
    case response do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:error, reason} ->
        {:error, "Request failed with reason #{inspect(reason)}"}
    end
  end

  defp toggle(:on = _device_status), do: :off
  defp toggle(:off = _device_status), do: :on
end
