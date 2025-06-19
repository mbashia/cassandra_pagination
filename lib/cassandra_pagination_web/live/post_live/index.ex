defmodule CassandraPaginationWeb.PostLive.Index do
  use CassandraPaginationWeb, :live_view

  alias CassandraPagination.Blogs

  require Logger

  @impl true

  def mount(_params, _session, socket) do
    {:ok, blogs, paging_state} = Blogs.fetch_posts()

    {:ok,
     socket
     |> assign(:current_paging_state, paging_state)
     # Track the paging states that got us to each page
     |> assign(:page_history, [nil])
     |> assign(:blogs, blogs)}
  end

  def handle_event("next", _, socket) do
    current_state = socket.assigns.current_paging_state

    if current_state do
      case Blogs.fetch_posts(current_state) do
        {:ok, blogs, new_paging_state} ->
          # Add current state to history
          new_history = socket.assigns.page_history ++ [current_state]

          {:noreply,
           socket
           |> assign(:current_paging_state, new_paging_state)
           |> assign(:page_history, new_history)
           |> assign(:blogs, blogs)}

        {:error, reason} ->
          Logger.error("Error: #{inspect(reason)}")
          {:noreply, socket}
      end
    else
      {:noreply,
       socket
       |> put_flash(:info, "No more data")}
    end
  end

  def handle_event("prev", _, socket) do
    history = socket.assigns.page_history

    if length(history) > 1 do
      # Remove the last state and get the previous one
      new_history = Enum.drop(history, -1)
      previous_state = List.last(new_history)

      case Blogs.fetch_posts(previous_state) do
        {:ok, blogs, paging_state} ->
          {:noreply,
           socket
           |> assign(:blogs, blogs)
           |> assign(:current_paging_state, paging_state)
           |> assign(:page_history, new_history)}

        {:error, _reason} ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to load previous page.")}
      end
    else
      # Already on first page
      {:noreply,
       socket
       |> put_flash(:info, "Already on first page")}
    end
  end
end
