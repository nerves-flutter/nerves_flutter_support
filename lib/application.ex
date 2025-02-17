defmodule NervesFlutterSupport.Application do
  @moduledoc """
  Main application for Nerves Flutter Support.
  Mostly just starts the eudev process, which is needed to properly handle input.
  """
  use Application

  def start(_type, _args) do
    eudev_args = Application.get_env(:nerves_flutter_support, :eudev_args, [])

    children = [
      # We always need to start the eudev background process
      NervesFlutterSupport.Udev.create_child(eudev_args)
    ]

    opts = [strategy: :one_for_one, name: NervesFlutterSupport.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
