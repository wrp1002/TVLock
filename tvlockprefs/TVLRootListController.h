#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <SpringBoardServices/SBSRestartRenderServerAction.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <Preferences/PreferencesAppController.h>

#define TWEAK_NAME @"TVLock"
#define BUNDLE [NSString stringWithFormat:@"com.wrp1002.%@", [TWEAK_NAME lowercaseString]]
#define BUNDLE_NOTIFY (CFStringRef)[NSString stringWithFormat:@"%@/ReloadPrefs", BUNDLE]

@interface TVLRootListController : PSListController
@end
