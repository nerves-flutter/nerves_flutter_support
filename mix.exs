defmodule NervesFlutterSupport.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_flutter_support,
      version: "1.0.4",
      description: "Supporting libraries and runtime engine for Flutter on Nerves.",
      elixir: "~> 1.17",
      compilers: Mix.compilers() ++ [:nerves_flutter_support],
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "readme",
        extras: ["README.md"]
      ],
      package: package()
    ]
  end

  def package do
    [
      maintainers: ["Digit"],
      name: :nerves_flutter_support,
      licenses: ["Apache-2.0"],
      files:
        ~w(lib docker LICENSE VERSION FLUTTER_ENGINE_HASH .tool-versions .formatter.exs mix.exs README.md bin/build_aot.sh),
      links: %{
        "Github" => "https://github.com/nerves-flutter/nerves_flutter_support"
      }
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl, :inets],
      mod: {NervesFlutterSupport.Application, []}
    ]
  end

  defp deps do
    [
      {:castore, "~> 1.0"},
      {:jason, "~> 1.4.0"},
      {:muontrap, "~> 1.6.0"},
      {:nerves_runtime, "~> 0.13.0"},
      {:nerves_time_zones, "~> 0.3.0"},
      {:yaml_elixir, "~> 2.11"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
