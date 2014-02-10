THEOS_DEVICE_IP = 192.168.1.5
TARGET := iphone:7.0:2.0
ARCHS := armv6 arm64
ADDITIONAL_OBJCFLAGS = -fobjc-arc

include theos/makefiles/common.mk

TWEAK_NAME = TimePasscode
TimePasscode_FILES = Tweak.xm
TimePasscode_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += timepasscodepreferences
include $(THEOS_MAKE_PATH)/aggregate.mk
