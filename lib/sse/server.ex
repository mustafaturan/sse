defmodule SSE.Server do
  @moduledoc """
  Server for SSE
  """

  alias Plug.Conn
  alias SSE.{Chunk, Config}
  require Logger

  @doc """
  Serv the SSE stream
  """
  @spec stream(Conn.t(), {atom(), Chunk.t()}) :: Conn.t()
  def stream(conn, {topic, %Chunk{} = chunk}) do
    {:ok, conn} = init_sse(conn, chunk)
    {:ok, listener} = subscribe_sse(topic)
    reset_timeout()
    listen_sse(conn, listener)
  end

  # Init SSE connection
  @spec init_sse(Conn.t(), Chunk.t()) :: Conn.t()
  defp init_sse(conn, %Chunk{} = chunk) do
    Logger.info("SSE connection opened!")

    conn
    |> Conn.put_resp_content_type("text/event-stream")
    |> Conn.send_chunked(200)
    |> Conn.chunk(Chunk.build(chunk))
  end

  # Send new SSE chunk
  @spec send_sse(Conn.t(), Chunk.t(), tuple()) :: Conn.t() | no_return()
  defp send_sse(conn, %Chunk{} = chunk, listener) do
    case Conn.chunk(conn, Chunk.build(chunk)) do
      {:ok, conn} ->
        reset_timeout()
        listen_sse(conn, listener)

      {:error, _reason} ->
        unsubscribe_sse(listener)
        conn

      _ ->
        conn
    end
  end

  # Listen EventBus events for SSE chunks
  @spec listen_sse(Conn.t(), tuple()) :: Conn.t()
  defp listen_sse(conn, listener) do
    receive do
      {:sse, topic, id} ->
        event = EventBus.fetch_event({topic, id})
        EventBus.mark_as_completed({listener, topic, id})
        send_sse(conn, event.data, listener)

      {:send_iddle} ->
        send_sse(conn, %Chunk{data: []}, listener)

      {:close} ->
        unsubscribe_sse(listener)

      _ ->
        listen_sse(conn, listener)
    end

    conn
  end

  # Subscribe process to EventBus events for SSE chunks
  @spec subscribe_sse(atom()) :: {:ok, {SSE, map()}}
  defp subscribe_sse(topic) do
    listener = {SSE, %{pid: self()}}
    {EventBus.subscribe({listener, ["^#{topic}$"]}), listener}
  end

  # Unsubscribe process from EventBus events
  @spec unsubscribe_sse(tuple()) :: :ok
  defp unsubscribe_sse(listener) do
    Logger.info("SSE connection closed!")
    EventBus.unsubscribe(listener)
  end

  # Reset iddle timer
  @spec reset_timeout() :: no_return()
  defp reset_timeout do
    new_ref = Process.send_after(self(), {:send_iddle}, Config.keep_alive())
    old_ref = Process.put(:timer_ref, new_ref)
    unless is_nil(old_ref), do: Process.cancel_timer(old_ref)
  end
end
