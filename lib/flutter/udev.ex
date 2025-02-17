defmodule NervesFlutterSupport.Udev do
  @moduledoc """
  The Flutter engine requires that udev is running to register input devices.
  This module provides utility functions to start `eudev` (a more minimal udev) and register devices.
  It also provides a number of utility methods to fetch the current DRI cards, and get info about them.
  """

  require Logger

  @doc """
  Reloads and triggers udev rules using `udevadm`
  """
  @spec setup() :: :ok
  def setup() do
    Logger.info("Reloading and triggering udev rules...")

    bin_path = get_udevadm_path()
    {_, 0} = System.cmd(bin_path, ["control", "--reload-rules"], env: create_env())
    {_, 0} = System.cmd(bin_path, ["trigger"], env: create_env())

    :ok
  end

  @doc """
  Returns a `child_spec()` that monitors the eudev daemon
  """
  @spec create_child(list()) :: Supervisor.child_spec()
  def create_child(args) do
    # Ensure that the symlink to the udev rules are present
    # Our `eudevd` is patched to look at `/tmp/rules.d` as an additional
    # directory to load from.
    case File.ln_s(get_rules_dir(), "/tmp/rules.d") do
      :ok ->
        :ok

      {:error, :eexist} ->
        :ok

      {:error, other_error} ->
        Logger.error(
          "Failed to create symlink to udev rules, input will probably not work! (#{other_error})"
        )
    end

    Supervisor.child_spec(
      {MuonTrap.Daemon,
       [
         get_udevd_path(),
         args,
         [
           name: :eudev_daemon,
           stderr_to_stdout: true,
           log_output: :info,
           log_prefix: "[eudev_daemon]",
           env: create_env()
         ]
       ]},
      id: :eudev_daemon,
      restart: :permanent
    )
  end

  @doc """
  Returns a list of named devices under `/dev/dri`
  """
  @spec get_cards() :: [binary()]
  def get_cards() do
    if File.exists?("/dev/dri") do
      File.ls!("/dev/dri")
      |> Enum.reject(fn name ->
        File.dir?("/dev/dri/#{name}")
      end)
    else
      []
    end
  end

  @doc """
  Returns a list of tuples that contain information about the specified DRI card name
  """
  @spec get_card_info(binary()) :: [tuple()] | :error
  def get_card_info(card_name) do
    case System.cmd(get_udevadm_path(), ["info", "--query=all", "--name=/dev/dri/#{card_name}"],
           env: create_env()
         ) do
      {output, 0} -> parse_card_output(output)
      _ -> :error
    end
  end

  @doc """
  On some devices like the Raspberry Pi, `/dev/dri/card0` and  `/dev/dri/card1` are not deterministically named.
  Generally one of the cards will only be the 3D accelerator, while the other is actually the display card.

  This function will return `true` if the passed in card name is a output card (can actually draw to a display.)
  """
  @spec is_output_card?(binary()) :: boolean()
  def is_output_card?(card_name) do
    info = get_card_info(card_name)

    Enum.any?(info, fn {type, value} ->
      type == "E" and String.contains?(value, "gpu-card")
    end)
  end

  defp parse_card_output(raw_output) do
    String.trim_trailing(raw_output)
    |> String.split("\n")
    |> Enum.map(fn str -> String.split(str, ":", parts: 2) end)
    |> Enum.map(fn [type, value] -> {type, String.trim(value)} end)
  end

  defp create_env() do
    %{
      "LD_LIBRARY_PATH" => "#{get_lib_path()}:#{System.get_env("LD_LIBRARY_PATH")}",
      "LIBINPUT_QUIRKS_DIR" => get_quirks_path()
    }
  end

  defp get_quirks_path(),
    do: :code.priv_dir(:nerves_flutter_support) |> Path.join("libinput-quirks/")

  defp get_lib_path(), do: :code.priv_dir(:nerves_flutter_support) |> Path.join("lib/")
  defp get_udevd_path(), do: :code.priv_dir(:nerves_flutter_support) |> Path.join("bin/udevd")
  defp get_udevadm_path(), do: :code.priv_dir(:nerves_flutter_support) |> Path.join("bin/udevadm")
  defp get_rules_dir(), do: :code.priv_dir(:nerves_flutter_support) |> Path.join("rules.d/")
end
