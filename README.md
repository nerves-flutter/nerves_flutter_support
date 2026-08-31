# nerves_flutter_support

![Static Badge](https://img.shields.io/badge/Flutter%20Version-v3.32.8-cyan?style=plastic&labelColor=black&color=blue)

> ⚠️ NOTE: This is a fairly new project. Functionally everything is working on _tested_ Nerves systems.

## What Is This?

NervesFlutterSupport is the base library for running Flutter based UI applications on Nerves devices.

## Overview

NervesFlutterSupport contains the following components:

* Pre-compiled and patched runtime libraries for various dependencies. (See `builder/` for more info.)
  * Including a pre-compiled version of Sony's open source [Flutter Embedder](https://github.com/sony/flutter-embedded-linux).
* A pair of [Mix Release Steps](https://hexdocs.pm/mix/1.18.2/Mix.Tasks.Release.html#module-steps) that can be included in your existing Mix project.
  * Takes care of downloading the Flutter [embedder](https://github.com/sony/flutter-embedded-linux) and runtime libraries.
  * Will automatically compile your Flutter project using the `gen_snapshot` tool and output an AOT build.
  * Will help copy the runtime artifacts from the dependency source directory to the release directory at compile time.
* `NervesFlutterSupport.Flutter.Engine` - A module to create a [Muontrap](https://hexdocs.pm/muontrap/readme.html) child_spec for running the embedder.
* `NervesFlutterSupport.Udev` - (Automatically started for you) A module that ensure `eudevd` is running for input devices to function properly.

## Tested Platforms

NervesFlutterSupport has been tested on the following platforms:

* Raspberry Pi 4
* Raspberry Pi 5

However it should be noted that any aarch64 based Nerves System _should be compatible_ with this library.

Please file any issues if you run into any problems with your ARM64 platform. We also welcome Buildroot config contributions for other platforms.

## Getting Started

**Currently we only support Linux and macOS hosts when building firmware. Windows users should use WSL.**

**If you are a macOS user, please ensure you have `docker` installed!**

1. Install [Flutter](https://docs.flutter.dev/get-started/install). See the top of this readme file for which version to use. (Flutter versions may change with Hex package versions!)
2. Create a new Flutter app in your Mix project using: `flutter create flutter_app`.
3. Add this package to your `deps` in `mix.exs`.
4. Add the release steps to your existing firmware's `steps:`:
  ```elixir
    steps: [
      &Nerves.Release.init/1,
      &NervesFlutterSupport.InstallRuntime.run/1, # REQUIRED!! - Add this to install runtime artifacts into the release!
      &NervesFlutterSupport.BuildFlutterApp.run/1, # OPTIONAL - Add this if you want to auto-compile a flutter app!
      :assemble
    ],
  ```
5. Run `mix firmware` as you normally would, if all is well, you should see you Flutter app build and emit a bundle into your `priv/` directory.
6. To run the Flutter app you can add the following to your `Application` or `Supervisor` children:
  ```elixir
  # With no options, your Flutter app bundle is expected to be in `priv/flutter_app`
  NervesFlutterSupport.Flutter.Engine.create_child(
    app_name: :my_flutter_app,
  )
  ```

## Example Project

Example Project: [NervesFlutterExample](https://github.com/nerves-flutter/nerves_flutter_example)

`NervesFlutterExample` is a basic Flutter + Nerves firmware for `:rpi4` and `:rpi5` targets. It uses
gRPC and Protobufs to communicate between the Nerves firmware code and the Dart Flutter application.
