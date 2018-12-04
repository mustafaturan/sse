defmodule SSE.ServerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  use SSE.ConnCase
  alias SSE.{Chunk, Server}
  require Logger

  doctest SSE

  @topic :test_sse_sent

  setup do
    Application.put_env(:sse, :keep_alive, "250")
    {:ok, conn: SSE.ConnTest.build_conn()}
  end

  test "stream", %{conn: conn} do
    Process.send_after(self(), {:close}, 300)

    chunk = %Chunk{data: "Hi there!"}
    conn = Server.stream(conn, {@topic, chunk})

    refute is_nil(Process.get(:timer_ref))
    assert conn.state == :chunked
    assert conn.status == 200
  end

  test "stream multiple topics", %{conn: conn} do
    Process.send_after(self(), {:close}, 300)

    chunk = %Chunk{data: "Hi there!"}
    conn = Server.stream(conn, {[@topic, :another_event_occured], chunk})

    refute is_nil(Process.get(:timer_ref))
    assert conn.state == :chunked
    assert conn.status == 200
  end

  test "stream and close conn", %{conn: conn} do
    pid = spawn(fn -> stream_chunk(conn) end)
    :erlang.trace(pid, true, [:receive])
    send(pid, {:close})

    assert_received {:trace, ^pid, :receive, {:close}}
  end


  test "stream and send_iddle to keep alive", %{conn: conn} do
    pid = spawn(fn -> stream_chunk(conn) end)
    :erlang.trace(pid, true, [:receive])

    Process.sleep(300)
    send(pid, {:close})

    assert_receive {:trace, ^pid, :receive, {:send_iddle}}
  end

  test "stream and send a new event chunk", %{conn: conn} do
    pid = spawn(fn -> stream_chunk(conn) end)
    event_watcher_id = Process.whereis EventBus.Manager.Observation

    :erlang.trace(pid, true, [:receive])
    :erlang.trace(event_watcher_id, true, [:receive])

    Process.sleep(1000)

    chunk = %Chunk{data: "Hi again!"}
    event = %EventBus.Model.Event{id: 1, data: chunk, topic: @topic}
    EventBus.notify(event)

    Process.send_after(pid, {:close}, 3000)
    assert_receive {:trace, ^pid, :receive, {:sse, :test_sse_sent, _}}, 3000
    assert_receive {:trace, ^event_watcher_id, :receive,
      {:"$gen_cast", {:mark_as_completed, _}}}, 3000
  end

  defp stream_chunk(conn) do
    chunk = %Chunk{data: "test sse event data"}
    Server.stream(conn, {:test_sse_sent, chunk})
  end
end
