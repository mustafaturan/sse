defmodule SSETest do
  use ExUnit.Case
  doctest SSE

  test "process" do
    topic = :test_event_sent
    id = 123456

    SSE.process({%{pid: self()}, topic, id})

    assert_received {:sse, ^topic, ^id}
  end
end
