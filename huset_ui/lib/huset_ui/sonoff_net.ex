defmodule Dashb.SonoffNet do

  @moduledoc """
  This is a client API implemented with HTTPoison wrapper for interfacing
  Sonoff Mini R2 smart switch
  """

  use GenServer
  alias Dashb.Sonoff

  @doc """
  Interface for starting this as supervised child process
  """
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, %{}, name: SonoffServer)
  end

  @impl true
  def init(status) do
    # TODO read this from config
    #Application.get_env(:dashb, SonoffNet)[:devices]

    config = [
      ESP_E69CC4: "192.168.1.116",
      ESP_FA88E7: "192.168.1.101",
      ESP_E68C6C: "192.168.1.128",
      ESP_FAC76E: "192.168.1.130"
    ]

    devices =
      config
      |> List.keysort(0)
      |> Enum.reduce(status, fn {name, ip}, acc ->
        {:ok, pid} = Sonoff.start_link(%{name: Atom.to_string(name), ip: ip})
        location = get_location(name)
        Sonoff.set_location(pid, location)
        Map.put(acc, name, pid)
      end)

    IO.puts("Initialized Sonoff processes")

    {:ok, devices}
  end

  def get_devices(pid) do
    GenServer.call(pid, {:get_devices})
  end

  # console call: SonoffNet.switch_device(ser, "ESP_E68C6C")
  def switch_device(pid, name) when is_binary(name) do
    GenServer.call(pid, {:switch_device, name})
  end

  @impl true
  def handle_call({:switch_device, name}, _from, state) do
    case Map.fetch(state,String.to_atom(name)) do
      {:ok, proc} -> Sonoff.switch_mode(proc)
      _ -> IO.puts("Cannot find process with name #{name} in #{Map.keys(state)}")
    end

    {:reply, :ok, state}
  end

  def handle_call({:get_devices}, _from, state) do
    #IO.inspect( state, label: "Function get_devices >>>>")
    {:reply, state, state}
  end

  def get_location(name) when is_atom(name) do
    case name do
      :ESP_E68C6C -> "Bed lamp"
      :ESP_E69CC4 -> "n/a"
      :ESP_FA88E7 -> "Mirror"
      :ESP_FAC76E -> "n/a"
    end
  end

end
