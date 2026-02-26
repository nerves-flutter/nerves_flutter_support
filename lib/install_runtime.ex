defmodule NervesFlutterSupport.InstallRuntime do
  @moduledoc """
  A Mix release step that copies the runtime artifacts from `NervesFlutterSupport`'s `priv` directory
  into the properly location in the release `_build` directory. This is required, because sometimes `mix`
  will not re-copy artifacts if they were not present at the initial `mix deps.get` command.

  Since we install runtime artifacts afterwords, this step ensures they wind up in the final release bundle.
  """

  alias NervesFlutterSupport.ToolInstaller
  alias NervesFlutterSupport.Util

  def run(%Mix.Release{} = release) do
    if System.get_env("NERVES_FLUTTER_SKIP_TOOL_INSTALL") == nil do
      :ok = ToolInstaller.perform_checks()
    else
      Mix.shell().info(
        "NERVES_FLUTTER_SKIP_TOOL_INSTALL was set! This will skip downloading runtime artifacts..."
      )
    end

    release_path =
      release.applications |> Map.get(:nerves_flutter_support, []) |> Keyword.get(:path)

    if release_path == nil do
      raise """
      For some reason, `nerves_flutter_support` is not present in this release, yet you've included it in your release steps.
      This does not make sense.
      Please ensure `nerves_flutter_support` is actually included in this target's mix.exs deps!
      """
    end

    src_path = Path.join(Util.self_path(), ["priv/"])
    dest_path = Path.join(release_path, ["priv/"])

    Mix.shell().info("Installing runtime artifacts from #{src_path} -> #{dest_path}")

    File.rm_rf!(dest_path)
    File.cp_r!(src_path, dest_path)

    release
  end
end
