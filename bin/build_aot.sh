#! /bin/bash -e

###
# This is a script to help compile a Flutter app in AOT (ahead-of-time) mode.
# AOT compiled Flutter apps will run significantly faster than JIT apps when
# on embedded devices.
###

HOST_OS=$(uname -s)
HOST_ARCH=$(uname -m)

FLUTTER_SDK=$(dirname $(which flutter))
RESULT_DIR=build/linux-embedded-arm64
BUILD_MODE=release
SELF_PATH=$1
APP_PACKAGE_NAME=$2

# If we're on macOS or Linux non-x86_64 we need to use Docker to emulate x86_64
# this will be slower, but it still allows AOT builds. This is a limitation of Dart.
# the simarm64 target is only supported on x86_64 Linux hosts.
if [[ $HOST_ARCH != "x86_64" ]] || [[ $HOST_OS != "Linux" ]]; then
  echo "🐳 Not on Linux x86_64... going to try using Docker!"
  docker build $SELF_PATH -f $SELF_PATH/docker/Dockerfile.AOT -t flutter-aot-builder
  docker run --rm --platform=linux/amd64 -t -e APP_PACKAGE_NAME="$APP_PACKAGE_NAME" -v $(pwd):/data flutter-aot-builder
  exit
fi

# Clean up and rebuild everything to be sure we're in a clean build state
rm -rf build
flutter pub get

# Create required directories for bundle output
mkdir -p .dart_tool/flutter_build/flutter-embedded-linux
mkdir -p ${RESULT_DIR}/${BUILD_MODE}/bundle/lib/
mkdir -p ${RESULT_DIR}/${BUILD_MODE}/bundle/data/

echo "🔨 Building an AOT bundle for '$APP_PACKAGE_NAME' ($BUILD_MODE)..."

# Build assets bundle
flutter build bundle --asset-dir=${RESULT_DIR}/${BUILD_MODE}/bundle/data/flutter_assets --no-version-check

# Copy over icudtl.dat (unicode and globalization support data)
cp ${FLUTTER_SDK}/cache/artifacts/engine/linux-x64/icudtl.dat ${RESULT_DIR}/${BUILD_MODE}/bundle/data/

# Build the Dart app's kernel snapshot
${FLUTTER_SDK}/cache/dart-sdk/bin/dartaotruntime \
  --verbose \
  --disable-dart-dev ${FLUTTER_SDK}/cache/artifacts/engine/linux-x64/frontend_server_aot.dart.snapshot \
  --sdk-root ${FLUTTER_SDK}/cache/artifacts/engine/common/flutter_patched_sdk_product/ \
  --target=flutter \
  --no-print-incremental-dependencies \
  -Ddart.vm.profile=false \
  -Ddart.vm.product=true \
  --aot \
  --tfa \
  --packages .dart_tool/package_config.json \
  --output-dill .dart_tool/flutter_build/flutter-embedded-linux/app.dill \
  --depfile .dart_tool/flutter_build/flutter-embedded-linux/kernel_snapshot.d \
  package:${APP_PACKAGE_NAME}/main.dart

# Print version info, it's useful :)
flutter --version --no-version-check
$SELF_PATH/bin/gen_snapshot --version

# Build the ARM64 (simarm) shared library (AOT compilied Dart code)
$SELF_PATH/bin/gen_snapshot \
  --deterministic \
  --snapshot_kind=app-aot-elf \
  --elf=.dart_tool/flutter_build/flutter-embedded-linux/libapp.so \
  --strip \
  .dart_tool/flutter_build/flutter-embedded-linux/app.dill

# Copy AOT binary into result directory to complete the bundle
cp .dart_tool/flutter_build/flutter-embedded-linux/libapp.so ${RESULT_DIR}/${BUILD_MODE}/bundle/lib/
