# Include custom packages
include $(BR2_EXTERNAL_CUSTOM_PATH)/package/sony-flutter-embedded-linux/sony-flutter-embedded-linux.mk

# Custom make targets
#
help: more-help

more-help:
	@echo "Buildroot Extension Help"
	@echo "------------------------------------------"
	@echo
	@echo "This build directory is configured to create the system described in:"
	@echo
	@echo "$(BR2_DEFCONFIG)"
	@echo
	@echo "Building:"
	@echo "  all                           - Build the current configuration"
	@echo "  clean                         - Clean everything"
	@echo
	@echo "Configuration:"
	@echo "  menuconfig                    - Run Buildroot's menuconfig"
	@echo "  linux-menuconfig              - Run menuconfig on the Linux kernel"
	@echo "  busybox-menuconfig            - Run menuconfig on Busybox to enable shell"
	@echo "                                  commands and more"
	@echo
	@echo "---------------------------------------------------------------------------"
	@echo
	@echo "Buildroot Help"
	@echo "--------------"

.PHONY: more-help
