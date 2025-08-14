defmodule Mix.Tasks.Flutter.InstallTools do
  @shortdoc "Ensures tools and runtime libs are installed."
  @moduledoc """
  Installs runtime libs and tools for Flutter support on Nerves.
  """

  use Mix.Task

  alias NervesFlutterSupport.ToolInstaller

  @impl Mix.Task
  def run(_argv) do
    :ok = ToolInstaller.perform_checks()
  end
end
