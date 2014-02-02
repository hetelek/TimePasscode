#import <UIKit/UIKit.h>
#import "include/AES.m"

static BOOL truePasscodeFailed;

@interface SBDeviceLockController : UIViewController

- (NSString *)getCurrentPasscode;

@end

%hook SBDeviceLockController
static char dateFormatterHolder;

- (BOOL)attemptDeviceUnlockWithPassword:(NSString *)passcode appRequested:(BOOL)requested
{
	if (![passcode isKindOfClass:[NSString class]])
		return %orig;

	NSString *key = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
	
	static NSString *settingsPath = @"/var/mobile/Library/Preferences/com.expetelek.timepasscodepreferences.plist";
	NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:settingsPath];
	if (!prefs)
		prefs = [[NSMutableDictionary alloc] init];

	if (truePasscodeFailed)
	{
		BOOL result = %orig;
		if (result)
		{
			[prefs setObject:[[passcode dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:key] forKey:@"truePasscode"];
			if ([prefs writeToFile:settingsPath atomically:YES])
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
	
	if (![[prefs allKeys] containsObject:@"truePasscode"])
	{
		BOOL result = %orig;
		if (result)
		{
			[prefs setObject:[[passcode dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:key] forKey:@"truePasscode"];
			if ([prefs writeToFile:settingsPath atomically:YES])
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
	else if ([prefs[@"truePasscode"] isKindOfClass:[NSString class]])
	{
		prefs[@"truePasscode"] = [[prefs[@"truePasscode"] dataUsingEncoding:NSUTF8StringEncoding] AES256EncryptWithKey:key];
		[prefs writeToFile:settingsPath atomically:YES];
	}
	
	BOOL isEnabled = ![[prefs allKeys] containsObject:@"isEnabled"] || [prefs[@"isEnabled"] boolValue];
	BOOL didAnswerCorrectly = NO;
	if (isEnabled)
	{
		NSString *timePasscode = [self getCurrentPasscode];
		if ([prefs[@"reverseTimePasscode"] boolValue])
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
			
			NSData *passcodeDecrypt = [prefs[@"truePasscode"] AES256DecryptWithKey:key];
			passcode = [NSString stringWithUTF8String:[[[NSString alloc] initWithData:passcodeDecrypt encoding:NSUTF8StringEncoding] UTF8String]];
		}
		else if (![prefs[@"allowTruePasscodeUnlock"] boolValue])
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