defmodule NervesFlutterSupport.Util do
  @moduledoc """
  Utility functions used in various internal parts of this package.
  You probably do not need to use any of these.
  """

  alias NervesFlutterSupport.Downloader

  @doc """
  Returns the directory in which the package `nerves_flutter_support` is installed to.

  This is only ever used at compile time. Otherwise the return value makes no sense.
  """
  @spec self_path() :: String.t()
  def self_path() do
    __ENV__.file
    |> Path.dirname()
    |> Path.split()
    |> List.delete_at(-1)
    |> Path.join()
  end

  def host_tools_installed?() do
    stamp_path = Path.join(self_path(), ["bin/", ".gen_snapshot_hash"])
    bin_path = Path.join(self_path(), ["bin/", "gen_snapshot"])
    expected_hash = Downloader.get_flutter_hash()
    stamp_exists? = File.exists?(stamp_path)
    bin_exists? = File.exists?(bin_path)

    if stamp_exists? and bin_exists? do
      File.read!(stamp_path) == expected_hash
    else
      false
    end
  end

  def runtime_artifacts_installed?() do
    stamp_path = Path.join(self_path(), ["priv/", ".runtime_hash"])
    expected_hash = Downloader.get_flutter_hash()
    stamp_exists? = File.exists?(stamp_path)

    if stamp_exists? do
      File.read!(stamp_path) == expected_hash
    else
      false
    end
  end
end
