#import <UIKit/UIApplication.h>
#import <Preferences/PSListController.h>

@interface TimePasscodePreferencesListController : PSListController

- (void)openTwitter:(id)arg1;
- (void)openGithub:(id)arg1;
- (void)openColorize:(id)arg1;
- (void)openVineDownloader:(id)arg1;

@end

@implementation TimePasscodePreferencesListController

- (id)specifiers
{
	if(_specifiers == nil)
		_specifiers = [self loadSpecifiersFromPlistName:@"TimePasscodePreferences" target:self];
	return _specifiers;
}

- (void)openTwitter:(id)arg1
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/hetelek"]];   
}

- (void)openGithub:(id)arg1
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://github.com/hetelek/TimePasscode"]];   
}

- (void)openColorize:(id)arg1
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/org.thebigboss.colorize"]];
}

- (void)openVineDownloader:(id)arg1
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://package/org.thebigboss.vinedownloader"]];
}

@end
