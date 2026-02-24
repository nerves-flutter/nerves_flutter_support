# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.3.2

* Changes
  * Relax versions of deps so downstream apps can use minor version bumps.
  * Fix engine switch map code ([#18](https://github.com/nerves-flutter/nerves_flutter_support/pull/18))

## v1.3.1

* Changes
  * Removes LLVMPipe backend from Gallium build. This means we no longer depend on or ship the entire LLVM library.
  * Include `libfontconfig` in artifact package.
  * Include `libfreetype` in artifact package.
  * Bump Buildroot to `2025.05.2`.
  * Add `:engine_switches` option to the `Engine` module. This allows users to pass Flutter engine flags to the embedder.
  * Copy legal info into artifact package.

## v1.3.0

* Changes
  * Bump Flutter to `3.32.8-stable`, engine hash `ef0cd00091`.
  * Update CI workflows to use GH Actions.

## v1.2.0

* Changes
  * Bump Flutter to `3.29.3-stable`, engine hash `cf56914b32`.
  * Bump/Patch Mesa3D to `25.0.2`, this fixes a blank screen issue on latest Nerves systems.