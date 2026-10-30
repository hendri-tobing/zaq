defmodule ZaqWeb.Live.BO.Communication.NotificationLogsLive do
  @moduledoc """
  BO LiveView for browsing notification audit logs.

  Paginated table of all `notification_logs` rows, ordered newest-first.
  A "View more" modal shows the full payload (subject + body) for a row.
  """

  use ZaqWeb, :live_view
  on_mount {ZaqWeb.Live.BO.Communication.ServiceGate, [:channels]}

  alias ZaqWeb.Helpers.Timezone
  alias ZaqWeb.Live.BO.EngineDispatch

  @per_page 20

  @impl true
  def mount(_params, _session, socket) do
    available = socket.assigns.service_available

    socket =
      socket
      |> assign(:page_title, "Notification Logs")
      |> assign(:current_path, "/bo/channels/notifications/logs")
      |> assign(:page, 1)
      |> assign(:per_page, @per_page)
      |> assign(:selected_log, nil)
      |> assign(:recipient_filter, "")

    socket = if available, do: load_logs(socket), else: socket

    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("next_page", _params, socket) do
    total_pages = ceil(socket.assigns.total / socket.assigns.per_page)

    socket =
      if socket.assigns.page < total_pages do
        socket |> assign(:page, socket.assigns.page + 1) |> load_logs()
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("prev_page", _params, socket) do
    socket =
      if socket.assigns.page > 1 do
        socket |> assign(:page, socket.assigns.page - 1) |> load_logs()
      else
        socket
      end

    {:noreply, socket}
  end

  def handle_event("filter_recipient", %{"value" => value}, socket) do
    socket =
      socket
      |> assign(:recipient_filter, value)
      |> assign(:page, 1)
      |> load_logs()

    {:noreply, socket}
  end

  def handle_event("view_log", %{"id" => id}, socket) do
    log =
      case EngineDispatch.dispatch_confidential(:notification_logs, %{action: :get, id: id}) do
        %{id: _} = found -> found
        _ -> nil
      end

    {:noreply, assign(socket, :selected_log, log)}
  end

  def handle_event("close_modal", _params, socket) do
    {:noreply, assign(socket, :selected_log, nil)}
  end

  # ---------------------------------------------------------------------------
  # Private
  # ---------------------------------------------------------------------------

  defp load_logs(socket) do
    {logs, total} =
      case EngineDispatch.dispatch_confidential(
             :notification_logs,
             %{
               action: :list,
               opts: [
                 page: socket.assigns.page,
                 per_page: socket.assigns.per_page,
                 recipient_filter: socket.assigns.recipient_filter
               ]
             }
           ) do
        %{logs: logs, total: total} when is_list(logs) and is_integer(total) -> {logs, total}
        _ -> {[], 0}
      end

    socket
    |> assign(:logs, logs)
    |> assign(:total, total)
  end
end
