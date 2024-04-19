#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <UIKit/UIWindow+Private.h>
#import "Tweak.h"
#import "TVLock.h"
#import "Globals.h"

//	=============================== Globals ===============================

#define TWEAK_NAME @"TVLock"
#define BUNDLE [NSString stringWithFormat:@"com.wrp1002.%@", [TWEAK_NAME lowercaseString]]
#define BUNDLE_NOTIFY (CFStringRef)[NSString stringWithFormat:@"%@/ReloadPrefs", BUNDLE]

static TVLock *__strong tvLock;
double totalTime = 1.0;
double lockTime = 0.25;

// For @available to work. needs commented out for github to compile
//int __isOSVersionAtLeast(int major, int minor, int patch) { NSOperatingSystemVersion version; version.majorVersion = major; version.minorVersion = minor; version.patchVersion = patch; return [[NSProcessInfo processInfo] isOperatingSystemAtLeastVersion:version]; }


//	=========================== Preference vars ===========================

BOOL enabled;
BOOL disableInLPM;
BOOL glowEffect;
BOOL smoothAnim;
BOOL landscapeEnabled;

NSInteger lineThickness;
NSInteger dotSize;

double animTime1;
double pauseTime1;
double animTime2;
double animTime3;
double totalTime;
double lockTime;

NSUserDefaults *prefs = nil;

static void InitPrefs(void) {
	if (!prefs) {
		NSDictionary *defaultPrefs = @{
			@"kEnabled": @YES,
			@"kLPM": @NO,
			@"kGlow": @YES,
			@"kSmooth": @NO,
			@"kLandscape": @NO,
			@"kLine": @4,
			@"kDot": @3,
			@"kAnim1": @0.15,
			@"kPause1": @0.05,
			@"kAnim2": @0.15,
			@"kAnim3": @0.40,
		};
		prefs = [[NSUserDefaults alloc] initWithSuiteName:BUNDLE];
		[prefs registerDefaults:defaultPrefs];
	}
}

static void UpdatePrefs() {
	enabled = [prefs boolForKey: @"kEnabled"];
	disableInLPM = [prefs boolForKey: @"kLPM"];
	glowEffect = [prefs boolForKey: @"kGlow"];
	smoothAnim = [prefs boolForKey: @"kSmooth"];
	landscapeEnabled = [prefs boolForKey: @"kLandscape"];

	animTime1 = [prefs floatForKey:@"kAnim1"];
	pauseTime1 = [prefs floatForKey:@"kPause1"];
	animTime2 = [prefs floatForKey:@"kAnim2"];
	animTime3 = [prefs floatForKey:@"kAnim3"];

	lineThickness = [prefs integerForKey: @"kLine"];
	dotSize = [prefs integerForKey: @"kDot"];

	totalTime = animTime1 + pauseTime1 + animTime2 + animTime3;
	if (!landscapeEnabled)
		[tvLock resetToPortrait];
}

static void PrefsChangeCallback(CFNotificationCenterRef center, void *observer, CFNotificationName name, const void *object, CFDictionaryRef userInfo) {
	UpdatePrefs();
}


//	=========================== Hooks ===========================

%group allVersionHooks
	%hook SpringBoard
		//	Called when springboard is finished launching
		-(void)applicationDidFinishLaunching:(id)application {
			%orig;

			tvLock = [[TVLock alloc] init];
		}
	%end
%end


%group under16hooks
	%hook SBBacklightController
		-(void)_animateBacklightToFactor:(float)arg1 duration:(double)arg2 source:(long long)arg3 silently:(BOOL)arg4 completion:(id)arg5 {
			if(enabled &&
				(!disableInLPM || (![[NSProcessInfo processInfo] isLowPowerModeEnabled])) &&
				(arg1==0 && [self screenIsOn])) {

				arg2 = totalTime;

				[tvLock showLockAnimation:arg2];
			}

			%orig(arg1, arg2, arg3, arg4, arg5);
		}
	%end
%end


%group iOS16hooks
	// Temporary fix to avoid safe mode issues. Animation only triggers when lock button is used
	%hook SBSleepWakeHardwareButtonInteraction
		-(void)_performSleep {
			if (enabled && (!disableInLPM || (![[NSProcessInfo processInfo] isLowPowerModeEnabled]))) {

				[tvLock showLockAnimation:totalTime];

				// Play start sound at beginning of animation
				// otherwise it'll play very late
				[self _playLockSound];

				// Wait for animation to complete and then lock screen
				double delayInSeconds = totalTime - lockTime;
				dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
				dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
					%orig;
				});
			}
			else {
				%orig;
			}
		}
	%end

	// Also trigger animation for auto lock
	%hook SBIdleTimerPolicyAggregator
		-(void)idleTimerDidExpire:(id)arg1 {
			if (enabled && (!disableInLPM || (![[NSProcessInfo processInfo] isLowPowerModeEnabled]))) {
				[tvLock showLockAnimation:totalTime];

				// Wait for animation to complete and then lock screen
				double delayInSeconds = totalTime - lockTime;
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
					%orig;
				});
			}
			else {
				%orig;
			}

		}
	%end
%end



//	=========================== Constructor ===========================

%ctor {
	InitPrefs();
	UpdatePrefs();

	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		&PrefsChangeCallback,
		BUNDLE_NOTIFY,
		NULL,
		0
	);

	%init(allVersionHooks);

	NSOperatingSystemVersion systemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
	if (systemVersion.majorVersion >= 16) {
		%init(iOS16hooks);
	}
	else {
		%init(under16hooks);
	}
}
