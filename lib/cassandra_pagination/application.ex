defmodule CassandraPagination.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @config  Application.compile_env(:cassandra_pagination, :xandra)

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      CassandraPaginationWeb.Telemetry,

      {Xandra, @config ++ [name: :xandra_conn]},
      # Start the Ecto repository
      CassandraPagination.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: CassandraPagination.PubSub},
      # Start Finch
      {Finch, name: CassandraPagination.Finch},
      # Start the Endpoint (http/https)
      CassandraPaginationWeb.Endpoint
      # Start a worker by calling: CassandraPagination.Worker.start_link(arg)
      # {CassandraPagination.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CassandraPagination.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CassandraPaginationWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
