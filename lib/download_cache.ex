defmodule NervesFlutterSupport.DownloadCache do
  @moduledoc """
  A utility module to help cache and fetch cached data from a known cache namespace.
  """

  require Logger

  @cache_namespace "nerves_flutter_support"

  @doc """
  Given a cache key (sha256 hash) this function attempts to find the matching data
  in the on-disk cache. If the file isn't found, returns `:miss`.

  If the cache data is found, `{:hit, data}` is returned.

  Other error conditions will return an error tuple.
  """
  @spec fetch(binary()) :: {:hit, binary} | {:error, term()} | :miss
  def fetch(key) when is_binary(key) do
    cache_dir = get_cache_dir()
    hash = :crypto.hash(:sha256, key) |> Base.encode16()
    full_path = Path.join(cache_dir, "#{hash}.bin")

    case File.read(full_path) do
      {:ok, data} -> {:hit, data}
      {:error, :enoent} -> :miss
    end
  rescue
    err -> {:error, err}
  end

  @doc """
  Takes in a key (binary) and data (binary) and writes it to the cache on disk.

  Can return an error tuple if a write fails.
  """
  @spec put(binary(), binary()) :: :ok | {:error, term()}
  def put(key, data) do
    hash = :crypto.hash(:sha256, key) |> Base.encode16()
    key = "#{hash}.bin"
    cache_dir = get_cache_dir()
    full_path = Path.join(cache_dir, key)

    Logger.debug("Write cache file: #{full_path}")
    File.write(full_path, data, [:binary])
  end

  @doc """
  Attempts to delete the download cache directory.
  """
  @spec clear_cache() :: :ok | {:error, term()}
  def clear_cache do
    cache_dir = get_cache_dir()
    File.rm_rf!(cache_dir)
    :ok
  rescue
    err -> {:error, err}
  end

  defp get_cache_dir() do
    path = :filename.basedir(:user_cache, @cache_namespace) |> to_string()

    # Ensure this path exists
    case File.mkdir_p(path) do
      :ok ->
        path

      {:error, error_reason} ->
        Logger.error("Failed to create the cache directory: #{path}! (#{error_reason})")
        raise "Failed to rease cache directory."
    end
  end
end
