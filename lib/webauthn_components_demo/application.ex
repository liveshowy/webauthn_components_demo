defmodule WebauthnComponentsDemo.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WebauthnComponentsDemoWeb.Telemetry,
      WebauthnComponentsDemo.Repo,
      {DNSCluster, query: Application.get_env(:webauthn_components_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WebauthnComponentsDemo.PubSub},
      # Start a worker by calling: WebauthnComponentsDemo.Worker.start_link(arg)
      # {WebauthnComponentsDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      WebauthnComponentsDemoWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebauthnComponentsDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WebauthnComponentsDemoWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
