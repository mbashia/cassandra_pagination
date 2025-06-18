defmodule CassandraPagination.Blogs do
  @config Application.compile_env(:cassandra_pagination, :xandra)

  require Logger

  def insert_blogs do

    for i <- 1..1000 do
      insert_blogs(gen_random_posts_statement(i))
    end
  end

  def gen_random_posts_statement(number) do
      now = DateTime.utc_now() |> DateTime.to_iso8601()
    """
    INSERT INTO #{@config[:keyspace]}.posts (id, title, body, inserted_at, updated_at)
    VALUES (uuid(), 'title#{number}', 'body#{number}', '#{now}', '#{now}');
    """
  end

  def insert_blogs(blog_statement) do
    conn = check_xandra_connection()

    try do
      Xandra.execute(conn, blog_statement)
      |> case do
        {:ok, _result} ->
          Logger.info("Success")
          :ok

        {:error, reason} ->
          Logger.error("Error: #{inspect(reason)}")
          # factor in failed payments inserts
      end
    rescue
      e ->
        nil

        # factor in failed payments inserts
    end
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
