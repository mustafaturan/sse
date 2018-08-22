defmodule SSE.ConfigTest do
  use ExUnit.Case, async: false
  alias SSE.Config

  doctest SSE

  test "keep_alive returns default val" do
    Application.delete_env(:sse, :keep_alive)
    assert 3000 == Config.keep_alive()
  end

  test "keep_alive with app env var" do
    Application.put_env(:sse, :keep_alive, 100)

    assert 100 == Config.keep_alive
  end

  test "keep_alive with app env var as string" do
    Application.put_env(:sse, :keep_alive, "300")

    assert 300 == Config.keep_alive
  end

  test "keep_alive with sys env var" do
    Application.put_env(:sse, :keep_alive, {:system, "SSE_KEEP_ALIVE", "1000"})

    assert 1000 == Config.keep_alive
  end
end
