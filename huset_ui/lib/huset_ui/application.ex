defmodule HusetUI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HusetUIWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: HusetUI.PubSub},
      # Start the Endpoint (http/https)
      HusetUIWeb.Endpoint
      # Start a worker by calling: HusetUI.Worker.start_link(arg)
      # {HusetUI.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HusetUI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HusetUIWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
