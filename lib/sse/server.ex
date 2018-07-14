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
  @spec stream(Conn.t(), {atom() | list(atom()), Chunk.t()}) :: Conn.t()
  def stream(conn, {topics, %Chunk{} = chunk}) do
    {:ok, conn} = init_sse(conn, chunk)
    {:ok, listener} = subscribe_sse(topics)
    reset_timeout()
    listen_sse(conn, listener)
  end

  # Init SSE connection
  @spec init_sse(Conn.t(), Chunk.t()) :: Conn.t()
  defp init_sse(conn, %Chunk{} = chunk) do
    Logger.info("SSE connection (#{inspect(self())}) opened!")

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
        data = EventBus.fetch_event_data({topic, id})
        EventBus.mark_as_completed({listener, topic, id})
        send_sse(conn, data, listener)

      {:send_iddle} ->
        send_sse(conn, keep_alive_chunk(), listener)

      {:close} ->
        unsubscribe_sse(listener)

      _ ->
        listen_sse(conn, listener)
    end

    conn
  end

  # Subscribe process to EventBus events for SSE chunks
  @spec subscribe_sse(atom()) :: {:ok, {SSE, map()}}
  defp subscribe_sse(topic) when is_atom(topic) do
    subscribe_sse([topic])
  end

  @spec subscribe_sse(list(atom())) :: {:ok, {SSE, map()}}
  defp subscribe_sse(topics) when is_list(topics) do
    listener = {SSE, %{pid: self()}}
    topics = Enum.map(topics, fn topic -> "^#{topic}$" end)
    {EventBus.subscribe({listener, topics}), listener}
  end

  # Unsubscribe process from EventBus events
  @spec unsubscribe_sse(tuple()) :: :ok
  defp unsubscribe_sse({_, %{pid: pid}} = listener) do
    Logger.info("SSE connection (#{inspect(pid)}) closed!")
    EventBus.unsubscribe(listener)
  end

  # Reset iddle timer
  @spec reset_timeout() :: no_return()
  defp reset_timeout do
    new_ref = Process.send_after(self(), {:send_iddle}, Config.keep_alive())
    old_ref = Process.put(:timer_ref, new_ref)
    unless is_nil(old_ref), do: Process.cancel_timer(old_ref)
  end

  # Keep alive Chunk struct
  @spec keep_alive_chunk() :: Chunk.t()
  defp keep_alive_chunk do
    %Chunk{comment: "KA", data: []}
  end
end
