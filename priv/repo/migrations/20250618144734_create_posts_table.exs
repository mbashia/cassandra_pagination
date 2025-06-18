defmodule CassandraPagination.Repo.Migrations.CreatePostsTable do
  use Ecto.Migration

  @config Application.compile_env(:cassandra_pagination, :xandra)
  @xandra_config  Application.get_env(:cassandra_pagination, :xandra_config)


  def up do
    conn = check_xandra_connection()

    keyspace_statement = """
    CREATE KEYSPACE IF NOT EXISTS #{@config[:keyspace]}
    WITH replication = {
      'class': '#{@xandra_config[:replication_strategy]}',
      'replication_factor': #{@xandra_config[:replication_options]["replication_factor"]}
    }
    """

    Xandra.execute(conn, keyspace_statement)
    |> IO.inspect(label: "Create key space")

    Xandra.execute!(conn, "USE #{@config[:keyspace]}")
    |> IO.inspect(label: "Cassandra keyspace")

    create_posts_statetement =
    """
    CREATE TABLE IF NOT EXISTS posts (
      id uuid PRIMARY KEY,
      title text,
      body text,
      inserted_at timestamp,
      updated_at timestamp
    )
    """

    Xandra.execute(conn, create_posts_statetement)
    |> case do
      {:ok, result} ->
        IO.inspect(result, label: "Result")
        {:ok, result}

      {:error, reason} ->
        Logger.error("======= Error when  invoices #{inspect(reason, pretty: true)} =======")

        {:error, reason}
    end
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
