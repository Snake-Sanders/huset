defmodule Huset.Sonoff.Net do
  @moduledoc """
  A client API implemented with HTTPoison wrapper for interfacing
  Sonoff Mini R2 smart switch
  """

  use GenServer
  require Logger
  alias Huset.Sonoff.Node

  @server_name SonoffServer

  @doc """
  Interface for starting this as supervised child process
  """
  def start_link(_arg) do
    GenServer.start_link(__MODULE__, %{}, name: SonoffServer)
  end

  def get_devices() do
    # TODO: use multi_call
    GenServer.call(@server_name, :get_devices)
  end

  def toggle_status(dev_id) do
    GenServer.call(@server_name, {:toggle_status, dev_id})
  end

  @impl true
  def init(_status) do
    # TODO: monitor the spawn GenServers

    nodes =
      get_nodes_in_config()
      |> Enum.reduce(%{}, fn node, acc ->
        {:ok, pid} = Node.start_link(node)
        maybe_log_stating_process(node, pid)
        Map.put(acc, node.id, pid)
      end)

    Logger.debug(" Sonoff network Ready")

    {:ok, %{nodes: nodes}}
  end

  @impl true
  def handle_call({:toggle_status, dev_id}, _from, state) do
    state
    |> Map.get(:nodes)
    |> Enum.find(fn {node_id, _node_pid} -> node_id == dev_id end)
    |> case do
      nil = _node ->
        Logger.error("Cannot find process with dev_id #{dev_id} in #{Map.keys(state)}")
        {:reply, {:error, "no process found"}, state}

      {_id, pid} = _node ->
        Node.toggle_status(pid)
        {:reply, :ok, state}
    end
  end

  def handle_call(:get_devices, _from, state) do
    devices =
      state
      |> Map.get(:nodes)
      |> Enum.map(fn {_node_id, node_pid} -> Node.get_info(node_pid) end)

    {:reply, devices, state}
  end

  defp get_nodes_in_config() do
    Application.fetch_env!(:huset, Huset.SonoffNet)
    |> get_in([:nodes])
    |> case do
      nil ->
        Logger.error("cannot load SonoffNet nodes from 'config.exs'")
        []

      devices ->
        devices
    end
  end

  defp maybe_log_stating_process(node, pid) do
    %{id: id, ip: ip, description: desc} = node
    Logger.debug("started process pid:#{inspect(pid)}, id: #{id} ip: #{ip} for #{desc}")
  end
end
