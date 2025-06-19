defmodule CassandraPagination.Repo.Migrations.AddIdentifierToPosts do
  use Ecto.Migration
  require Logger

  @config Application.compile_env(:cassandra_pagination, :xandra)

  def up do
    conn = check_xandra_connection()

    Xandra.execute!(conn, "USE #{@config[:keyspace]}")

    Xandra.execute!(conn, "ALTER TABLE #{@config[:keyspace]}.posts ADD identifier int")
  end

  def down do
  end

  defp check_xandra_connection do
    case Process.whereis(:xandra_conn) do
      nil ->
        {:ok, conn} = Xandra.start_link(nodes: @config[:nodes], keyspace: @config[:keyspace])

        conn

      pid ->
        pid
    end
  end
end
