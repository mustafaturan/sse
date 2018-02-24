defmodule SSE.MixProject do
  use Mix.Project

  def project do
    [
      app: :sse,
      version: "0.1.1",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [extras: ["README.md"]],
      test_coverage: [tool: ExCoveralls],
      dialyzer: [plt_add_deps: :transitive]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {SSE.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp description do
    """
    Server Sent Events for Elixir/Plug
    """
  end

  defp package do
    [
      name: :sse,
      files: ["lib", "mix.exs", "README.md"],
      maintainers: ["Mustafa Turan"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/mustafaturan/sse"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:event_bus, ">= 1.2.0"},
      {:plug, "~> 1.4.4"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
    ]
  end
end
