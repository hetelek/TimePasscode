#import <substrate.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import "include/AES.m"

#define PREFERENCE_IDENTIFIER CFSTR("com.expetelek.timepasscodepreferences")
#define ENABLED_KEY CFSTR("isEnabled")
#define TRUE_PASSCODE_KEY CFSTR("truePasscode")
#define ALLOW_TRUE_PASSCODE_KEY CFSTR("allowTruePasscodeUnlock")
#define REVERSE_PASSCODE_KEY CFSTR("reverseTimePasscode")

// settings
static BOOL isEnabled;
static BOOL allowTruePasscode;
static BOOL reverseTimePasscode;
static NSData *truePasscode;

static BOOL truePasscodeFailed;
static char dateFormatterHolder;

@interface SBDeviceLockController : UIViewController
- (NSString *)getCurrentPasscode;
@end

%hook SBDeviceLockController
- (BOOL)attemptDeviceUnlockWithPassword:(NSString *)passcode appRequested:(BOOL)requested
{
	if (![passcode isKindOfClass:[NSString class]])
		return %orig;

	NSString *key = [[[UIDevice currentDevice] identifierForVendor] UUIDString];

	if (truePasscodeFailed)
	{
		BOOL result = %orig;
		if (result)
		{
			truePasscode = [[passcode dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:key];
			CFPreferencesSetAppValue(TRUE_PASSCODE_KEY, (CFDataRef)truePasscode, PREFERENCE_IDENTIFIER);

			if (CFPreferencesAppSynchronize(PREFERENCE_IDENTIFIER))
			{
				UIAlertView *alert = [[UIAlertView alloc]
					initWithTitle:@"Passcode Updated"
					message:@"Your passcode has been updated."
					delegate:nil
					cancelButtonTitle:@"OK"
					otherButtonTitles:nil];
				[alert show];
				
				truePasscodeFailed = NO;
			}
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc]
				initWithTitle:@"Passcode Changed"
				message:@"It seems like you've changed your passcode. Please unlock your device using the true passcode to reconfigure your device."
				delegate:nil
				cancelButtonTitle:@"OK"
				otherButtonTitles:nil];
			[alert show];
		}
		
		return result;
	}
	
	if (truePasscode == nil)
	{
		BOOL result = %orig;
		if (result)
		{
			truePasscode = [[passcode dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:key];
			CFPreferencesSetAppValue(TRUE_PASSCODE_KEY, (CFDataRef)truePasscode, PREFERENCE_IDENTIFIER);

			if (CFPreferencesAppSynchronize(PREFERENCE_IDENTIFIER))
			{
				UIAlertView *alert = [[UIAlertView alloc]
					initWithTitle:@"Device Configured"
					message:@"You have now configured TimePasscode to work with your device."
					delegate:nil
					cancelButtonTitle:@"OK"
					otherButtonTitles:nil];
				[alert show];
			}
		}
		else
		{
			UIAlertView *alert = [[UIAlertView alloc]
				initWithTitle:@"Not Configured"
				message:@"TimePasscode has not yet been configured to work with your device. Please unlock your device using the true passcode to configure it."
				delegate:nil
				cancelButtonTitle:@"OK"
				otherButtonTitles:nil];
			[alert show];
		}
		
		return result;
	}
	else if ([truePasscode isKindOfClass:[NSString class]])
	{
		truePasscode = [[(NSString *)truePasscode dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:key];

		CFPreferencesSetAppValue(TRUE_PASSCODE_KEY, (CFDataRef)truePasscode, PREFERENCE_IDENTIFIER);
    	CFPreferencesAppSynchronize(PREFERENCE_IDENTIFIER);
	}
	
	BOOL didAnswerCorrectly = NO;
	if (isEnabled)
	{
		NSString *timePasscode = [self getCurrentPasscode];
		if (reverseTimePasscode)		
		{
			NSMutableString *reversedString = [NSMutableString string];		
			NSInteger charIndex = [timePasscode length];		
			while (charIndex-- > 0)		
				[reversedString appendString:[timePasscode substringWithRange:NSMakeRange(charIndex, 1)]];		
					
			timePasscode = reversedString;		
		}
			
		if ([timePasscode isEqualToString:passcode])
		{
			didAnswerCorrectly = YES;
			
			NSData *passcodeDecrypt = [truePasscode AES256DecryptWithKey:key];
			passcode = [NSString stringWithUTF8String:[[[NSString alloc] initWithData:passcodeDecrypt encoding:NSUTF8StringEncoding] UTF8String]];
		}
		else if (!allowTruePasscode)
			passcode = [NSString string];
	}
	
	BOOL alteredResult = %orig(passcode, requested);
	if (didAnswerCorrectly && !alteredResult)
	{
		UIAlertView *alert = [[UIAlertView alloc]
			initWithTitle:@"Passcode Changed"
			message:@"It seems like you've changed your passcode. Please unlock your device using the true passcode to reconfigure your device."
			delegate:nil
			cancelButtonTitle:@"OK"
			otherButtonTitles:nil];
		[alert show];
		
		truePasscodeFailed = YES;
	}
	
	return alteredResult;
}

%new
- (NSString *)getCurrentPasscode
{
	NSDate *date = [NSDate date];
	NSDateFormatter *dateFormatter = objc_getAssociatedObject(self, &dateFormatterHolder);
	if (!dateFormatter)
	{
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		
		objc_setAssociatedObject(self, &dateFormatterHolder, dateFormatter, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];

	NSString *dateString = [[dateFormatter stringFromDate:date] stringByReplacingOccurrencesOfString:@":" withString:[NSString string]];

	NSMutableString *strippedString = [NSMutableString stringWithCapacity:dateString.length];
	NSScanner *scanner = [NSScanner scannerWithString:dateString];
	NSCharacterSet *numbers = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];

	while (![scanner isAtEnd])
	{
		NSString *buffer;
		if ([scanner scanCharactersFromSet:numbers intoString:&buffer])
			[strippedString appendString:buffer];
		else
			[scanner setScanLocation:([scanner scanLocation] + 1)];
	}
	
	dateString = strippedString;
	if (strippedString.length != 4)
		dateString = [@"0" stringByAppendingString:dateString];
	
	return dateString;
}
%end

static void loadSettings()
{
	CFPreferencesAppSynchronize(PREFERENCE_IDENTIFIER);
	
	Boolean keyExists;
	isEnabled = CFPreferencesGetAppBooleanValue(ENABLED_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	isEnabled = (isEnabled || !keyExists);

	allowTruePasscode = CFPreferencesGetAppBooleanValue(ALLOW_TRUE_PASSCODE_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	reverseTimePasscode = CFPreferencesGetAppBooleanValue(REVERSE_PASSCODE_KEY, PREFERENCE_IDENTIFIER, &keyExists);
	truePasscode = (NSData *)CFBridgingRelease(CFPreferencesCopyAppValue(TRUE_PASSCODE_KEY, PREFERENCE_IDENTIFIER));
}

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	loadSettings();
}

%ctor
{
    // listen for changes in settings, load settings
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChanged, CFSTR("com.expetelek.timepasscodepreferences/settingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
    loadSettings();
}
