defmodule HusetUi.Sonoff do
  @moduledoc """
  Stores the status of a Sonoff Mini R2 smart switch

  example of manual commands:

  body = "{ \"deviceid\" : \"ESP_E69CC4\", \"data\": {\"switch\": \"on\" }}"
  post( "http://192.168.1.116:8081/zeroconf/switch", body)

  """

  use GenServer
  use HTTPoison.Base

  alias HusetUi.Sonoff

  defstruct ip: "", url: "", mode: "", name: "none", location: "n/a"

  # @expected_fields ~w( body headers request request_url status_code )
  @expected_fields ~w( error seq )

  # Client Functions aka the public interface.
  # see https://elixir-lang.org/cheatsheets/gen-server.pdf

  # entry point to starte this server, the callback from the GenServer goes to init()
  def start_link(init_values) do
    GenServer.start_link(__MODULE__, init_values)
  end

  @impl true
  def init(%{ip: ip_addr, name: dev_name}) do
    post_url = "http://#{ip_addr}:8081/zeroconf/switch"

    status = %Sonoff{
      ip: ip_addr,
      url: post_url,
      mode: :off,
      name: dev_name
    }

    # start HTTPoison instance
    case start() do
      {:ok, []} -> {:ok, status}
      _ -> {:error, "Cannot start #{__MODULE__}"}
    end
  end

  # returns the internal state of this device
  def get_status(pid) do
    GenServer.call(pid, :get_status)
  end

  # returns the on/off status of this device
  def get_mode(pid) do
    GenServer.call(pid, :get_mode)
  end

  def set_mode(pid, new_mode) when new_mode in [:on, :off] do
    GenServer.call(pid, {:set_mode, new_mode})
  end

  def set_location(pid, location) do
    GenServer.call(pid, {:set_location, location})
  end

  def switch_mode(pid) do
    GenServer.call(pid, :switch_mode)
  end

  @impl true
  def handle_call(:get_status, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_mode, _from, state) do
    {:reply, state.mode, state}
  end

  @impl true
  def handle_call(:switch_mode, _from, state) do
    state =
      case state.mode do
        :on -> %{state | mode: :off}
        :off -> %{state | mode: :on}
      end

    send_mode(state)

    {:reply, state.mode, state}
  end

  @impl true
  def handle_call({:set_mode, new_mode}, _from, state) do
    state = %{state | mode: new_mode}
    send_mode(state)
  end

  @impl true
  def handle_call({:set_location, new_location}, _from, state) do
    state = %{state | location: new_location}
    {:reply, new_location, state}
  end

  # Posion is a Json parser https://github.com/devinus/poison
  # SonoffNet.switch_device(ser, "ESP_E68C6C")
  # Sending switch 'off' command...
  # url: http://192.168.1.128:8081/zeroconf/switch
  # body: { "deviceid" : "ESP_E68C6C", "data": {"switch": "off" }}
  # process_response_body() this is when the callack from HTTPoison is received
  # Body: "{\"seq\":23,\"error\":0}"
  # Decoded: %{"error" => 0, "seq" => 23}
  # result:: []
  # :ok
  @impl true
  def process_response_body(body) do
    IO.puts("Received callack from HTTPoison")

    res =
      body
      |> Poison.decode!()
      |> Map.take(@expected_fields)
      |> Enum.map(fn {key, value} -> {String.to_atom(key), value} end)

    case res[:error] do
      0 -> :ok
      _ -> IO.puts("Faile to send command")
    end
  end

  # sends the command to switch mode (on/off) which is already updated in the state
  def send_mode(state) do
    mode_str = Atom.to_string(state.mode)
    IO.puts("Sending switch '#{mode_str}' command...")

    body = "{ \"deviceid\" : \"#{state.name}\", \"data\": {\"switch\": \"#{mode_str}\" }}"
    IO.puts("url: #{state.url}")
    IO.puts("body: #{body}")

    post(state.url, body)
  end
end
