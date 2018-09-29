defmodule SSE.Server do
  @moduledoc false
  # Server for SSE

  alias Plug.Conn
  alias SSE.{Chunk, Config}

  require Logger

  @type chunk :: Chunk.t()
  @type chunk_conn :: {:ok, conn()} | {:error, term()}
  @type conn :: Conn.t()
  @type listener_with_config :: {module(), map()}
  @type topic :: atom()
  @type topic_or_topics :: topic() | topics()
  @type topics :: list(topic())
  @type topics_with_chunk :: {topic_or_topics(), chunk()}

  @doc """
  Serv the SSE stream
  """
  @spec stream(conn(), topics_with_chunk()) :: conn()
  def stream(conn, {topics, %Chunk{} = chunk} = _topics_with_chunk) do
    {:ok, conn} = init_sse(conn, chunk)
    {:ok, listener} = subscribe_sse(topics)
    reset_timeout()
    listen_sse(conn, listener)
  end

  # Init SSE connection
  @spec init_sse(conn(), chunk()) :: chunk_conn()
  defp init_sse(conn, chunk) do
    Logger.info("SSE connection (#{inspect(self())}) opened!")

    conn
    |> Conn.put_resp_content_type("text/event-stream")
    |> Conn.send_chunked(200)
    |> Conn.chunk(Chunk.build(chunk))
  end

  # Send new SSE chunk
  @spec send_sse(conn(), chunk(), listener_with_config()) :: conn()
  defp send_sse(conn, chunk, listener) do
    case Conn.chunk(conn, Chunk.build(chunk)) do
      {:ok, conn} ->
        reset_timeout()
        listen_sse(conn, listener)

      {:error, _reason} ->
        unsubscribe_sse(listener)
        conn
    end
  end

  # Listen EventBus events for SSE chunks
  @spec listen_sse(conn(), listener_with_config()) :: conn()
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
  @spec subscribe_sse(topic()) :: {:ok, {SSE, map()}}
  defp subscribe_sse(topic) when is_atom(topic) do
    subscribe_sse([topic])
  end

  @spec subscribe_sse(topics()) :: {:ok, {SSE, map()}}
  defp subscribe_sse(topics) when is_list(topics) do
    listener = {SSE, %{pid: self()}}
    topics = Enum.map(topics, fn topic -> "^#{topic}$" end)
    {EventBus.subscribe({listener, topics}), listener}
  end

  # Unsubscribe process from EventBus events
  @spec unsubscribe_sse(listener_with_config()) :: :ok
  defp unsubscribe_sse({_, %{pid: pid}} = listener) do
    Logger.info("SSE connection (#{inspect(pid)}) closed!")
    EventBus.unsubscribe(listener)
  end

  # Reset iddle timer
  @spec reset_timeout() :: :ok
  defp reset_timeout do
    new_ref = Process.send_after(self(), {:send_iddle}, Config.keep_alive())
    old_ref = Process.put(:timer_ref, new_ref)
    unless is_nil(old_ref), do: Process.cancel_timer(old_ref)
    :ok
  end

  # Keep alive Chunk struct
  @spec keep_alive_chunk() :: chunk()
  defp keep_alive_chunk do
    %Chunk{comment: "KA", data: []}
  end
end
