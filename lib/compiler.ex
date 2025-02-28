defmodule Mix.Tasks.Compile.NervesFlutterSupport do
  @moduledoc """
  Compiler module used to ensure that pre-compiled tools are properly installed at compile time
  """
  alias NervesFlutterSupport.ToolInstaller
  use Mix.Task

  def run(_args) do
    ToolInstaller.perform_checks()
    :ok
  end
end
