defmodule NervesFlutterSupport.ToolInstaller do
  @moduledoc """
  This module contains functions to manage downloading, installing and removing of runtimes and tools.

  NervesFlutterSupport requires a few different host utilities, and runtime artifacts. This module ensures
  they are all properly installed and in the correct locations before attempting to build firmware.

  Generally you will not need to call these functions directly.
  """

  require Logger
  alias NervesFlutterSupport.Downloader
  alias NervesFlutterSupport.Util

  def perform_checks() do
    checks = [
      Task.async(&ensure_host_tools_installed/0),
      Task.async(&ensure_runtime_installed/0)
    ]

    results = Task.await_many(checks, :infinity)

    if Enum.all?(results, fn res -> res == :ok end) do
      :ok
    else
      :error
    end
  end

  def ensure_host_tools_installed() do
    Logger.info("[NervesFlutterSupport] Ensuring host tools are installed...")
    if not Util.host_tools_installed?() do
      Logger.warning(
        "Host utilities for Flutter engine hash #{Downloader.get_flutter_hash()} were not found. Installing them now."
      )

      case Downloader.download_host_tools() do
        {:ok, data} ->
          install_host_tools(data)
          :ok

        {:error, reason} ->
          Logger.error(
            "Failed to install the host utilities for Flutter hash #{Downloader.get_flutter_hash()}. #{inspect(reason)}"
          )
      end
    else
      :ok
    end
  end

  def ensure_runtime_installed() do
    Logger.info("[NervesFlutterSupport] Ensuring runtime artifacts are installed...")
    if not Util.runtime_artifacts_installed?() do
      Logger.warning(
        "Runtime for Flutter engine hash #{Downloader.get_flutter_hash()} was not found. Installing it now."
      )

      case Downloader.download_runtime_artifacts() do
        {:ok, data} ->
          install_runtime(data)
          :ok

        {:error, reason} ->
          Logger.error("Failed to installed Flutter runtime artifacts: #{inspect(reason)}")
          raise "Could not install Flutter runtime artifacts! #{Downloader.get_flutter_hash()}"
      end
    else
      :ok
    end
  end

  defp install_runtime(archive_binary) do
    priv_path = Util.self_path() |> Path.join("priv")
    self_path = Util.self_path() |> to_charlist()

    if File.exists?(priv_path) do
      File.rm_rf!(priv_path)
    end

    :erl_tar.extract({:binary, archive_binary}, [
      :compressed,
      :verbose,
      cwd: self_path
    ])

    write_runtime_stamp()
  end

  defp install_host_tools(archive_binary) do
    with {:ok, [{_file_name, gen_snapshot_bin}]} <-
           :zip.extract(archive_binary, [:memory, file_list: [~c"linux-x64/gen_snapshot"]]) do
      write_path =
        Util.self_path()
        |> Path.join(["bin/", "gen_snapshot"])

      Path.dirname(write_path) |> File.mkdir_p!()
      File.write!(write_path, gen_snapshot_bin)
      File.chmod!(write_path, 0o777)

      Logger.info("Wrote #{write_path}")
      write_tools_stamp()
    end
  end

  defp write_runtime_stamp() do
    stamp_path = Path.join(Util.self_path(), ["priv/", ".runtime_hash"])
    File.write!(stamp_path, Downloader.get_flutter_hash())
  end

  defp write_tools_stamp() do
    stamp_path = Path.join(Util.self_path(), ["bin/", ".gen_snapshot_hash"])
    File.write!(stamp_path, Downloader.get_flutter_hash())
  end
end
