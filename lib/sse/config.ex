defmodule SSE.Config do
  @moduledoc false
  # Config vars

  @app :sse

  @doc """
  Keep alive
  """
  @spec keep_alive() :: integer()
  def keep_alive do
    @app
    |> Application.get_env(:keep_alive, 3000)
    |> get_env_var()
    |> to_integer()
  end

  defp get_env_var({:system, name, default}) do
    System.get_env(name) || default
  end

  defp get_env_var(val) do
    val
  end

  defp to_integer(val) when is_integer(val) do
    val
  end

  defp to_integer(val) do
    String.to_integer(val)
  end
end
