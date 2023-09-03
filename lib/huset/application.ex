defmodule Huset.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      HusetWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Huset.PubSub},
      # Start the Endpoint (http/https)
      HusetWeb.Endpoint,
      # Start smart switch supervised entity
      Huset.Sonoff.Net
      # Start a worker by calling: Huset.Worker.start_link(arg)
      # {Huset.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Huset.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    HusetWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
