defmodule Mix.Tasks.Flutter.InstallTools do
  @shortdoc "Ensures tools and runtime libs are installed."
  @moduledoc """
  Installs runtime libs and tools for Flutter support on Nerves.
  """

  use Mix.Task

  alias NervesFlutterSupport.ToolInstaller

  @impl Mix.Task
  def run(_argv) do
    IO.puts("Checking tools and runtime libraries for Flutter...")
    :ok = ToolInstaller.perform_checks()
    IO.puts("Tool check complete!")
  end
end
