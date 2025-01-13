defmodule NervesFlutterSupport.Application do
  @moduledoc """
  Main application for Nerves Flutter Support.
  Mostly just starts the eudev process, which is needed to properly handle input.
  """
  use Application

  def start(_type, _args) do
    children = [
      NervesFlutterSupport.Udev.create_child()
    ]

    opts = [strategy: :one_for_one, name: NervesFlutterSupport.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
