defmodule SSE.ChunkTest do
  use ExUnit.Case
  alias SSE.Chunk

  doctest SSE

  test "build with all fields" do
    comment = "test"
    id = "123456"
    event = "message"
    data = ["one line"]
    retry = 15_000

    chunk =
      %Chunk{
        comment: comment,
        data: data,
        event: event,
        id: id,
        retry: retry
      }

    expected = ": #{comment}\nid: #{id}\nevent: #{event}\n" <>
      "data: #{data}\nretry: #{retry}\n\n"
    assert Chunk.build(chunk) == expected
  end

  test "build with all fields multiple data" do
    comment = "test"
    id = "123456"
    event = "message"
    first = "first line"
    second = "second line"
    third = "third line"
    data = [first, second, third]
    retry = 15_000

    chunk =
      %Chunk{
        comment: comment,
        data: data,
        event: event,
        id: id,
        retry: retry
      }

    expected = ": #{comment}\nid: #{id}\nevent: #{event}\n" <>
      "data: #{first}\ndata: #{second}\ndata: #{third}\nretry: #{retry}\n\n"
    assert Chunk.build(chunk) == expected
  end

  test "build with nil data" do
    comment = "test"
    id = "123456"
    event = "message"
    data = nil
    retry = 15_000

    chunk =
      %Chunk{
        comment: comment,
        data: data,
        event: event,
        id: id,
        retry: retry
      }

    assert_raise RuntimeError, "Chunk data can't be blank!",
      fn -> Chunk.build(chunk) end
  end

  test "build with empty list" do
    chunk = %Chunk{data: []}

    assert Chunk.build(chunk) == "\n"
  end

  test "build with string data" do
    data = "{\"name\": \"MT\""
    chunk = %Chunk{data: data}

    assert Chunk.build(chunk) == "data: #{data}\n\n"
  end
end
