################################################################################
#
# sony-flutter-embedded-linux
#
#################################################################################

SONY_FLUTTER_EMBEDDED_LINUX_VERSION = a18df97ca5
SONY_FLUTTER_EMBEDDED_LINUX_SITE = $(call github,sony,flutter-embedded-linux,$(SONY_FLUTTER_EMBEDDED_LINUX_VERSION))
SONY_FLUTTER_EMBEDDED_LINUX_LICENSE = MIT
SONY_FLUTTER_EMBEDDED_LINUX_LICENSE_FILES = LICENSE
SONY_FLUTTER_EMBEDDED_LINUX_EXTRA_DOWNLOADS=https://github.com/sony/flutter-embedded-linux/releases/download/$(SONY_FLUTTER_EMBEDDED_LINUX_VERSION)/elinux-arm64-release.zip

SONY_FLUTTER_EMBEDDED_LINUX_CONF_OPTS = -DBACKEND_TYPE=DRM-GBM -DENABLE_ELINUX_EMBEDDER_LOG=ON -DUSER_PROJECT_PATH=examples/flutter-drm-gbm-backend -DNDEBUG=ON -DCMAKE_BUILD_TYPE=Debug -DFLUTTER_RELEASE=ON

SONY_FLUTTER_EMBEDDED_LINUX_DEPENDENCIES = mesa3d libinput libxkbcommon xkeyboard-config libuv

define EXTRACT_ENGINE
	mkdir -p $(@D)/build
	$(UNZIP) -o $(SONY_FLUTTER_EMBEDDED_LINUX_DL_DIR)/elinux-arm64-release.zip -d $(@D)/build
endef

define INSTALL_BIN
	$(INSTALL) -D -m 755 $(@D)/flutter-drm-gbm-backend $(TARGET_DIR)/usr/bin/flutter-embedder
endef

SONY_FLUTTER_EMBEDDED_LINUX_PRE_CONFIGURE_HOOKS += EXTRACT_ENGINE
SONY_FLUTTER_EMBEDDED_LINUX_POST_BUILD_HOOKS += INSTALL_BIN

$(eval $(cmake-package))
