TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = TVLockPrefs

TVLockPrefs_FILES = TVLRootListController.m
TVLockPrefs_FRAMEWORKS = UIKit
TVLockPrefs_PRIVATE_FRAMEWORKS = Preferences
TVLockPrefs_INSTALL_PATH = /Library/PreferenceBundles
TVLockPrefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
