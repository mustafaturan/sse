defmodule SSE.MixProject do
  use Mix.Project

  def project do
    [
      app: :sse,
      version: "0.1.5",
      elixir: "~> 1.5",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: [extras: ~w(README.md)],
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

  defp elixirc_paths(:test) do
    ~w(lib test/support)
  end

  defp elixirc_paths(_) do
    ~w(lib)
  end

  defp description do
    """
    Server Sent Events for Elixir/Plug
    """
  end

  defp package do
    [
      name: :sse,
      files: ~w(lib mix.exs README.md),
      maintainers: ["Mustafa Turan"],
      licenses: ~w(MIT),
      links: %{"GitHub" => "https://github.com/mustafaturan/sse"}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:event_bus, ">= 1.4.1"},
      {:plug, ">= 1.4.5"},
      {:credo, "~> 0.10.0", only: :dev},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false},
      {:excoveralls, "~> 0.8", only: :test},
    ]
  end
end
