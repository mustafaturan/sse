defmodule SSE do
  @moduledoc """
  Server Sent Events handler
  """

  alias SSE.Server

  @doc """
  Deliver EventBus SSE events to the given process
  """
  def process({%{pid: pid}, topic, id}) do
    send(pid, {:sse, topic, id})
  end

  @doc """
  Serv the SSE stream
  """
  @spec stream(Plug.Conn.t(), tuple()) :: no_return()
  defdelegate stream(conn, data),
    to: Server,
    as: :stream
end
