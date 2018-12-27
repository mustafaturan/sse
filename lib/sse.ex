defmodule SSE do
  @moduledoc """
  Server Sent Events handler
  """

  alias SSE.Server

  @type config :: map()
  @type chunk :: SSE.Chunk.t()
  @type conn :: Plug.Conn.t()
  @type event_id :: integer() | String.t()
  @type event_shadow_with_config :: {config(), topic(), event_id()}
  @type matcher :: tuple()
  @type topic :: atom()
  @type topic_or_topics :: topic() | topics()
  @type topics :: list(topic())
  @type topics_with_chunk :: {topic_or_topics(), chunk()}

  @doc """
  Deliver EventBus SSE events to the given process
  """
  @spec process(event_shadow_with_config()) :: no_return()
  def process({%{pid: pid}, topic, id} = _event_shadow_with_config) do
    send(pid, {:sse, topic, id})
  end

  @doc """
  Serv the SSE stream
  """
  @spec stream(conn(), topics_with_chunk(), matcher()) :: conn()
  defdelegate stream(conn, data, matcher \\ {SSE, {}}),
    to: Server,
    as: :stream
end
