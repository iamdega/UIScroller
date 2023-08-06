
# Install Destination
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

# Configurations
TWEAK_NAME = UIScroller
$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc
$(TWEAK_NAME)_FRAMEWORKS = UIKit

ARCHS = arm64e arm64
FINALPACKAGE = 1
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESSES = SpringBoard

# Comment this line for rootful jailbreak
THEOS_PACKAGE_SCHEME = rootless

# Theos
include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/tweak.mk
