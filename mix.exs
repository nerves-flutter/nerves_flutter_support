defmodule NervesFlutterSupport.MixProject do
  alias Kernel.ParallelCompiler
  use Mix.Project

  def project do
    [
      app: :nerves_flutter_support,
      version: "1.3.0",
      description: "Supporting libraries and runtime engine for Flutter on Nerves.",
      elixir: "~> 1.17",
      compilers: [:nerves_flutter_prep | Mix.compilers()],
      aliases: ["compile.nerves_flutter_prep": &nerves_flutter_prep/1],
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

  defp nerves_flutter_prep(_args) do
    # A small hack to ensure that the tools and runtime binaries are present before actual compilation.
    # If we don't run this before `Mix.compilers()`, the `priv/` directory content will not be included in later release steps.
    # We only need these modules to download and cache artifacts, so we compile them before anything else.
    ParallelCompiler.compile([
      "lib/download_cache.ex",
      "lib/downloader.ex",
      "lib/util.ex",
      "lib/tool_installer.ex"
    ])
    NervesFlutterSupport.ToolInstaller.perform_checks()
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
