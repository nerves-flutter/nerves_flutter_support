defmodule NervesFlutterSupport.BuildFlutterApp do
  @moduledoc """
  A Mix release module that can be included into a parent mix project.
  This takes care of packing up all the flutter assets in a project.
  It also aids in compiling them into an AOT application for optimal perf on the target.
  """

  alias NervesFlutterSupport.ToolInstaller
  alias NervesFlutterSupport.Util

  def run(%Mix.Release{} = release) do
    if System.get_env("SKIP_FLUTTER_BUILD", nil) != nil do
      Mix.shell().info(
        "NOTE: Skipping Flutter app build because SKIP_FLUTTER_BUILD env var was defined!"
      )

      release
    else
      ToolInstaller.perform_checks()
      build_flutter_app(release)
    end
  end

  @spec get_flutter_sdk_path() :: String.t() | no_return
  def get_flutter_sdk_path() do
    info = get_flutter_info()

    if info == :error do
      Mix.shell().info(
        "ERROR: Could not get information about your Flutter install. Is it in your PATH?"
      )

      System.halt(1)
    end

    info["flutterRoot"]
  end

  defp build_flutter_app(%Mix.Release{options: options} = release) do
    # Compute directories that point to the flutter project and passed in options
    project_dir = Mix.Project.project_file() |> Path.dirname()
    sdk_dir = get_flutter_sdk_path()
    sdk_bin_dir = Path.join(sdk_dir, "bin/")
    flutter_dir = Keyword.get(options, :project_dir, Path.join(project_dir, "flutter_app/"))

    output_priv_dir =
      Keyword.get(options, :output_dir, Path.join(project_dir, "priv/flutter_app/"))

    flutter_output_dir =
      Path.join(flutter_dir, ["build/", "linux-embedded-arm64/", "release/", "bundle/"])

    # Parse the pubspec.yaml file for information about the flutter app,
    # like the name of the package, so we can build AOT bundles properly
    pub_path = Path.join(flutter_dir, ["pubspec.yaml"])
    {:ok, pub_spec} = YamlElixir.read_from_file(pub_path)

    pub_name = pub_spec["name"]
    pub_version = pub_spec["version"]

    Mix.shell().info("---Flutter App Info---")
    Mix.shell().info("Flutter App Src: #{flutter_dir} | #{pub_name}@#{pub_version}")
    Mix.shell().info("Build Output: #{output_priv_dir}")
    Mix.shell().info("SDK Path: #{sdk_dir}")
    Mix.shell().info("")

    script_path = Path.join(Util.self_path(), ["bin/", "build_aot.sh"])

    # Attempt to run the AOT build script for packaging up the app into a fw release
    case System.cmd(script_path, [Util.self_path(), pub_name, sdk_bin_dir],
           cd: flutter_dir,
           into: IO.stream()
         ) do
      {_, 0} ->
        Mix.shell().info("Flutter App Built!")

      {_, error_code} ->
        Mix.shell().info("ERROR: Could not build flutter app! (exit #{error_code})")
        System.halt(1)
    end

    # Copy to final priv output of the parent project
    File.mkdir_p!(output_priv_dir)
    File.cp_r!(flutter_output_dir, output_priv_dir)

    release
  end

  defp get_flutter_info() do
    with {output, 0} <- System.cmd("flutter", ["--version", "--machine"]),
         {:ok, decoded} <- Jason.decode(output) do
      decoded
    else
      _ -> :error
    end
  end
end
