defmodule Mix.Tasks.Flutter.BuildAot do
  @shortdoc "Builds a flutter app in AOT mode for firmware"
  @moduledoc """
  Builds a Flutter app using the version of Flutter shipped with `nerves_flutter_support`.

  Usage: `mix flutter.build_aot /path/to/flutter_app /output/bunlde/dir`
  """

  use Mix.Task

  alias NervesFlutterSupport.BuildFlutterApp

  @impl Mix.Task
  def run(argv) do
    if length(argv) != 2 do
      raise Mix.Error.exception("You must specify both the input and output directories!")
    end

    [project_dir, output_dir] = argv

    BuildFlutterApp.run(%Mix.Release{
      options: [
        project_dir: project_dir,
        output_dir: output_dir
      ]
    })
  end
end
