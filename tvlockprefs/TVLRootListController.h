#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Cephei/HBPreferences.h>
#import <Cephei/HBRespringController.h>

#define TWEAK_NAME @"TVLock"
#define BUNDLE [NSString stringWithFormat:@"com.wrp1002.%@", [TWEAK_NAME lowercaseString]]
#define BUNDLE_NOTIFY "com.wrp1002.tvlock/ReloadPrefs"

@interface TVLRootListController : PSListController
@end
