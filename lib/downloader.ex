defmodule NervesFlutterSupport.Downloader do
  @moduledoc """
  Module that contains functions to download files from the `nerves_flutter_support` CDN and GitHub.
  """
  alias NervesFlutterSupport.DownloadCache
  require Logger

  @base_runtime_url "https://nerves-flutter-support.b-cdn.net/artifacts"
  @base_utils_url "https://github.com/sony/flutter-embedded-linux/releases/download"

  @doc """
  Computes and returns the URL to the host utilities archive that matches
  this release of `nerves_flutter_support`.

  In general this is tied to the `FLUTTER_ENGINE_HASH` value in the package.
  """
  @spec create_host_utils_url() :: String.t()
  def create_host_utils_url() do
    hash = get_flutter_hash()
    file_name = "/#{hash}/elinux-arm64-release.zip"

    URI.parse(@base_utils_url)
    |> URI.append_path(file_name)
    |> URI.to_string()
  end

  @doc """
  Computes and returns the URL to the runtime artifact archive that matches
  this release of `nerves_flutter_support`.

  In general this is tied to the `FLUTTER_ENGINE_HASH` value in the package.
  """
  @spec create_runtime_url() :: String.t()
  def create_runtime_url() do
    hash = get_flutter_hash()
    arch = get_target_arch()
    file_name = "/runtime-artifacts-#{arch}-#{hash}.tar"

    URI.parse(@base_runtime_url)
    |> URI.append_path(file_name)
    |> URI.to_string()
  end

  @doc """
  Gets the Flutter engine hash from the `FLUTTER_ENGINE_HASH` file.

  This is used to compute the URL to download pre-build artifacts.
  """
  @spec get_flutter_hash() :: String.t()
  def get_flutter_hash() do
    path =
      __ENV__.file
      |> Path.dirname()
      |> Path.join("../FLUTTER_ENGINE_HASH")

    File.read!(path) |> String.trim()
  end

  @doc """
  Downloads the Flutter Linux Embedded runtime artifact archive for this version of `nerves_flutter_support`.
  """
  @spec download_runtime_artifacts() :: {:ok, binary()} | {:error, term()}
  def download_runtime_artifacts() do
    create_runtime_url() |> maybe_download()
  end

  @doc """
  Downloads the Flutter Linux Embedded host tools archive for this version of `nerves_flutter_support`.
  """
  @spec download_host_tools() :: {:ok, binary()} | {:error, term()}
  def download_host_tools() do
    create_host_utils_url() |> maybe_download()
  end

  defp maybe_download(url) do
    case DownloadCache.fetch(url) do
      :miss ->
        do_http_request(url)

      {:hit, data} ->
        DownloadCache.put(url, data)
        {:ok, data}

      {:error, reason} ->
        Logger.error("Failed to fetch key #{url} from disk cache: #{reason}. Downloading it.")
        do_http_request(url)
    end
  end

  defp do_http_request(url) do
    url = String.to_charlist(url)
    Logger.debug("Making HTTP/HTTPS request for URL: #{url}")

    # Ensure we start required applications for downloading a file
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    # Proxy configuration (if set in user's environment)
    http_proxy_config = System.get_env("HTTP_PROXY")
    https_proxy_config = System.get_env("HTTPS_PROXY")

    if not is_nil(http_proxy_config) do
      http_config = URI.parse(http_proxy_config)

      :httpc.set_options([
        {:proxy, {{String.to_charlist(http_config.host), http_config.port}, []}}
      ])

      Logger.info("Using HTTP proxy config: #{http_proxy_config}")
    end

    if not is_nil(https_proxy_config) do
      https_config = URI.parse(https_proxy_config)

      :httpc.set_options([
        {:https_proxy, {{String.to_charlist(https_config.host), https_config.port}, []}}
      ])

      Logger.info("Using HTTPS proxy config: #{https_proxy_config}")
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = System.get_env("HEX_CACERTS_PATH", CAStore.file_path())

    options = [
      ssl: [
        verify: :verify_peer,
        cacertfile: cacertfile |> String.to_charlist(),
        depth: 3,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    resp = :httpc.request(:get, {url, []}, options, body_format: :binary)

    case resp do
      {:ok, {{_, 200, _}, _, body}} ->
        {:ok, body}

      bad_result ->
        Logger.error("Failed to run HTTP/HTTPS request #{url} \n\t #{inspect(bad_result)}")
        {:error, bad_result}
    end
  end

  defp get_target_arch() do
    # We currently only support ARM64 targets
    :aarch64
  end
end
