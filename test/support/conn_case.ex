defmodule SSE.ConnCase do
  @moduledoc """
  Conveniences for testing Plug endpoints
  """

  @doc false
  defmacro __using__(_) do
    quote do
      use SSE.ConnTest
    end
  end
end
