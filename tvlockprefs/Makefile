TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

ARCHS = arm64 arm64e
SDKVERSION = 13.3

BUNDLE_NAME = TVLockPrefs

$(BUNDLE_NAME)_FILES = TVLRootListController.m
$(BUNDLE_NAME)_FRAMEWORKS = UIKit
$(BUNDLE_NAME)_PRIVATE_FRAMEWORKS = Preferences
$(BUNDLE_NAME)_INSTALL_PATH = /Library/PreferenceBundles
$(BUNDLE_NAME)_CFLAGS = -fobjc-arc
$(BUNDLE_NAME)_EXTRA_FRAMEWORKS = Cephei CepheiPrefs

include $(THEOS_MAKE_PATH)/bundle.mk
