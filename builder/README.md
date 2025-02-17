# Nerves Flutter Support Builder

```
⚠️ HEY! ⚠️

You probably do not need to do anything in this directory if you're just looking to
create a Flutter + Nerves application. This directory contains the Buildroot packages and scripts
used to create the supporting libraries to run Flutter on Nerves devices without building entirely new systems.

These are pre-compiled and downloaded for you automatically.
```

If you want to customize/change any of these packages, here's a quick overview of the process:

In order to build the artifacts, your host machine **must** be Linux based!

Modify any packages inside the `package/` directory to your liking.

You may write custom patches for Buildroot and place them in the `patches/` directory.

To build the artifacts:

`./build.sh configs/configs/nerves_flutter_support_aarch64_defconfig`
