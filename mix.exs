defmodule NervesFlutterSupport.MixProject do
  use Mix.Project

  def project do
    [
      app: :nerves_flutter_support,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {NervesFlutterSupport.Application, []}
    ]
  end

  defp deps do
    [
      {:muontrap, "~> 1.5.0"},
      {:input_event, "~> 1.4.0"},
      {:nerves_time_zones, "~> 0.3.0"},
      {:yaml_elixir, "~> 2.11"}
    ]
  end
end
