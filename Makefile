THEOS_DEVICE_IP = 192.168.1.17 #iphone6+
#THEOS_DEVICE_IP = 192.168.1.5 #iphone4s
#THEOS_DEVICE_IP = 192.168.1.6 #ipad
#THEOS_DEVICE_IP = 192.168.1.11 #ipod

TARGET := iphone:8.1:2.0
ARCHS := armv7 arm64
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
