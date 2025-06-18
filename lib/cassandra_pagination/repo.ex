defmodule CassandraPagination.Repo do
  use Ecto.Repo,
    otp_app: :cassandra_pagination,
    adapter: Ecto.Adapters.Postgres
end
