defmodule TrivialCsv.MixProject do
  use Mix.Project

  def project do
    [
      app: :trivial_csv,
      version: "0.0.1",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: "Trivial CSV",
      aliases: aliases(),
      package: package(),
      deps: deps()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]

  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def package do
    [
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Fiodor Baczyński"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/fiodorbaczynski/trivial-csv"}
    ]
  end

  defp deps do
    [
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: :dev, runtime: false},
      {:csv, "~> 2.3"}
    ]
  end

  defp aliases do
    [
      precommit: ["format --check-formatted", "credo --strict", "dialyzer"]
    ]
  end
end
