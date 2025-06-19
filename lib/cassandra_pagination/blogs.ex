defmodule CassandraPagination.Blogs do
  @config Application.compile_env(:cassandra_pagination, :xandra)

  require Logger

  def insert_blogs do
    for i <- 1..10 do
      insert_blogs(gen_random_posts_statement(i))
    end
  end

  def gen_random_posts_statement(number) do
    now = DateTime.utc_now() |> DateTime.to_iso8601()

    """
    INSERT INTO #{@config[:keyspace]}.posts (id, title, body,identifier, inserted_at, updated_at)
    VALUES (uuid(), 'title#{number}', 'body#{number}', #{number}, '#{now}', '#{now}');
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
      end
    rescue
      e ->
        nil
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

  def fetch_posts(paging_state \\ nil) do
    conn = check_xandra_connection()

    opts = if paging_state, do: [page_size: 1, paging_state: paging_state], else: [page_size: 1]

    fetch_statement =
      """
      SELECT * FROM #{@config[:keyspace]}.posts;
      """

    case Xandra.execute(conn, fetch_statement, [], opts) do
      {:ok, result} ->
        {:ok,
         result
         |> Enum.to_list()
         |> Enum.sort_by(fn blog -> blog["identifier"] end)
         |> IO.inspect(label: "Blogs"), result.paging_state}

      {:error, reason} ->
        Logger.error("Error: #{inspect(reason)}")
    end
  end
end
