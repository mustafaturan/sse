defmodule SSE.Config do
  @moduledoc """
  Config vars
  """

  @app :sse

  @doc """
  Keep alive
  """
  def keep_alive do
    @app
    |> Application.get_env(:keep_alive, 3000)
    |> get_env_var()
    |> String.to_integer()
  end

  defp get_env_var({:system, name, default}) do
    System.get_env(name) || "#{default}"
  end

  defp get_env_var(val) do
    "#{val}"
  end
end
