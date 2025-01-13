defmodule NervesFlutterSupport.Flutter.Engine do
  @moduledoc """
  Module to create Flutter's runtime child
  """
  require Logger

  alias NervesFlutterSupport.Udev

  @doc """
  Kills all currently running instances of the flutter engine
  """
  @spec kill() :: :ok
  def kill() do
    # Kill any existing flutter-pi instances, then wait a moment to ensure they're dead
    _ = System.cmd("killall", ["flutter-embedder"])
    Process.sleep(1_000)
  end

  @doc """
  Ensures existing running Flutter engines are killed.
  Returns a `child_spec()` that can be supervised, which starts the flutter app

  Arguments:
    `:app_name` - This should be the atom name of the application that contains the Flutter app.
                  It's expected that the compiled AOT Flutter bundle will be found at `priv/flutter_app`.

    `:env` - A map of additions environment variables to set when launching the Flutter engine.
            `%{binary() => binary()}`

    `:bundle_path` - A string that's a path to an AOT Flutter bundle. This will override the computed
                     path from `:app_name`.
  """
  @spec create_child(list()) :: Supervisor.child_spec()
  def create_child(args) do
    app_name = Keyword.get(args, :app_name)
    bundle_path = Keyword.get(args, :bundle_path)
    additional_env = Keyword.get(args, :env, %{})
    bin_path = get_embedder_path()
    args = create_flutter_args(app_name, bundle_path)
    env = create_flutter_env(additional_env)

    Logger.debug("Flutter Env: #{inspect(env)}")
    Logger.debug("Flutter Args: #{inspect(args)}")

    :ok = Udev.setup()

    Supervisor.child_spec(
      {MuonTrap.Daemon,
       [
         bin_path,
         args,
         [
           name: :flutter_app,
           stderr_to_stdout: true,
           log_output: :info,
           log_prefix: "[flutter]",
           env: Map.merge(NervesTimeZones.tz_environment(), env)
         ]
       ]},
      id: :flutter_ui,
      restart: :permanent
    )
  end

  defp create_flutter_env(additional_env) do
    # TODO: Allow the parent project to add to this this env map
    %{
      "ON_EMBEDDED_DEVICE" => "1",
      "XKB_CONFIG_ROOT" => get_xkb_path(),
      "LD_LIBRARY_PATH" => "#{get_lib_path()}:#{System.get_env("LD_LIBRARY_PATH")}",
      "LIBINPUT_QUIRKS_DIR" => get_quirks_path()
    }
    |> Map.merge(additional_env)
  end

  defp create_flutter_args(app_name, nil) do
    Logger.warning("Loading Flutter asset bundle from app priv: #{app_name}")
    asset_path = get_asset_path(app_name)
    ["--bundle=#{asset_path}"]
  end

  defp create_flutter_args(_app_name, path) when is_binary(path) do
    Logger.warning("Loading Flutter asset bundle from directory: #{path}")
    path
  end

  defp get_embedder_path() do
    :code.priv_dir(:nerves_flutter_support) |> Path.join("bin/flutter-embedder")
  end

  defp get_asset_path(app_name) do
    :code.priv_dir(app_name) |> Path.join("flutter_app/")
  end

  defp get_xkb_path() do
    :code.priv_dir(:nerves_flutter_support) |> Path.join("xkb/")
  end

  defp get_quirks_path() do
    :code.priv_dir(:nerves_flutter_support) |> Path.join("libinput-quirks/")
  end

  defp get_lib_path() do
    :code.priv_dir(:nerves_flutter_support) |> Path.join("lib/")
  end
end
