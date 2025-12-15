#!/bin/bash

# configs/xyz_defconfig
config="$1"

echo "Creating $config..."
./create-build.sh $config
if [[ $? != 0 ]]; then
    echo "--> './create-build.sh $config' failed!"
    exit 1
fi

base=$(basename -s _defconfig $config)

echo "Building $base..."

# Make sure that local build products don't affect these builds.
rm -f ../src/*.o

# If rebuilding, force a rebuild of sony-flutter-embedded-linux.
rm -fr "o/$base/build/sony-flutter-embedded-linux*"
rm -fr "dl/sony-flutter-embedded"

make -C o/$base
if [[ $? != 0 ]]; then
    echo "--> 'Building $base' failed!"
    exit 1
fi

mkdir -p ../priv/lib
mkdir -p ../priv/lib/gbm
mkdir -p ../priv/bin
mkdir -p ../priv/libinput-quirks
mkdir -p ../priv/etc/udev/hwdb.d

# copy the flutter-embedder binary to priv
cp o/$base/target/usr/bin/flutter-embedder ../priv/bin

# copy the runtime libs to priv
cp o/$base/target/lib/libdl.so* ../priv/lib
cp o/$base/target/lib/libblkid.so* ../priv/lib
cp o/$base/target/usr/lib/libdrm.so* ../priv/lib
cp o/$base/target/usr/lib/libEGL.so* ../priv/lib
cp o/$base/target/usr/lib/libevdev.so* ../priv/lib
cp o/$base/target/usr/lib/libflutter_engine.so ../priv/lib
cp o/$base/target/usr/lib/libinput.so* ../priv/lib
cp o/$base/target/usr/lib/libmtdev.so* ../priv/lib
cp o/$base/target/lib/libudev.so* ../priv/lib
cp o/$base/target/usr/lib/libuv.so* ../priv/lib
cp o/$base/target/usr/lib/libxkbcommon.so* ../priv/lib
cp o/$base/target/usr/lib/libkmod.so* ../priv/lib
cp o/$base/target/usr/lib/libfontconfig.so* ../priv/lib
cp o/$base/target/usr/lib/libfreetype.so* ../priv/lib
cp o/$base/target/usr/lib/libgallium* ../priv/lib
cp o/$base/target/usr/lib/libz* ../priv/lib
cp o/$base/target/usr/lib/libexpat* ../priv/lib
cp o/$base/target/usr/lib/libgbm* ../priv/lib
cp o/$base/target/usr/lib/gbm/dri_gbm.so ../priv/lib/gbm

make -C o/$base legal-info
cp -r o/$base/legal-info/licenses ../priv/licenses/

# eudev + udev rules
cp o/$base/target/usr/bin/udevadm ../priv/bin
cp o/$base/target/sbin/udevd ../priv/bin/
cp -r o/$base/target/lib/udev/rules.d ../priv/rules.d

# copy quirks
cp o/$base/target/usr/share/libinput/*.quirks ../priv/libinput-quirks

# copy xkb config to priv
cp -r o/$base/target/usr/share/X11/xkb/ ../priv/xkb

# Copy out the `gen_snapshot` binary, this is needed to build AOT snapshots of user's apps
cp o/$base/build/sony-flutter-embedded-linux-*/build/linux-x64/gen_snapshot ../bin/
