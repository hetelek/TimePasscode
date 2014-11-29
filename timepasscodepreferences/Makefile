TARGET := iphone:8.1:2.0
ARCHS := armv7 arm64
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

BUNDLE_NAME = TimePasscodePreferences
TimePasscodePreferences_FILES = TimePasscodePreferences.mm
TimePasscodePreferences_INSTALL_PATH = /Library/PreferenceBundles
TimePasscodePreferences_FRAMEWORKS = UIKit
TimePasscodePreferences_PRIVATE_FRAMEWORKS = Preferences

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/TimePasscodePreferences.plist$(ECHO_END)
