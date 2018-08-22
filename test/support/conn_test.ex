defmodule SSE.ConnTest do
  @moduledoc """
  Conveniences for testing Plug endpoints
  """

  @doc false
  defmacro __using__(_) do
    quote do
      import Plug.Conn
      import Plug.Test
    end
  end

  alias Plug.Conn

  @doc """
  Creates a connection to be used in upcoming requests.
  """
  @spec build_conn() :: Conn.t()
  def build_conn do
    build_conn(:get, "/", nil)
  end

  @doc """
  Creates a connection to be used in upcoming requests
  with a preset method, path and body.
  This is useful when a specific connection is required
  for testing a plug or a particular function.
  """
  @spec build_conn(atom | binary, binary, binary | list | map) :: Conn.t()
  def build_conn(method, path, params_or_body \\ nil) do
    %Conn{}
    |> Plug.Adapters.Test.Conn.conn(method, path, params_or_body)
    |> Conn.put_private(:plug_skip_csrf_protection, true)
  end
end
