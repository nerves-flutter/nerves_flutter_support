defmodule NervesFlutterSupport.BuildFlutterApp do
  @moduledoc """
  A Mix release module that can be included into a parent mix project.
  This takes care of packing up all the flutter assets in a project.
  It also aids in compiling them into an AOT application for optimal perf on the target.
  """

  def run(%Mix.Release{options: options} = release) do
    # Compute directories that point to the flutter project and passed in options
    project_dir = Mix.Project.project_file() |> Path.dirname()

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

    Mix.shell().info("Flutter App: #{flutter_dir} | #{pub_name}@#{pub_version}")
    Mix.shell().info("Output: #{output_priv_dir}")

    # This computes the path to the directory of `nerves_flutter_support`
    self_path =
      __ENV__.file
      |> Path.dirname()
      |> Path.split()
      |> List.delete_at(-1)
      |> Path.join()

    script_path = Path.join(self_path, ["bin/", "build_aot.sh"])

    # Attempt to run the AOT build script for packaging up the app into a fw release
    case System.cmd(script_path, [self_path, pub_name], cd: flutter_dir, into: IO.stream()) do
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
end
