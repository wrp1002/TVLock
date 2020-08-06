#import <Cephei/HBPreferences.h>

#define kIdentifier @"com.wrp1002.tvlock"
#define kSettingsChangedNotification (CFStringRef)@"com.wrp1002.tvlock/ReloadPrefs"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.wrp1002.tvlock.plist"



//	=========================== Preference vars ===========================

bool enabled = true;
bool disableInLPM = false;
bool glowEffect = true;
bool smoothAnim = false;

int lineThickness = 4;
int dotSize = 3;

float animTime1 = 0.15;
float pauseTime1 = 0.05;
float animTime2 = 0.15;
float animTime3 = 0.40;
float totalTime = 1.0;



//	=========================== Debugging stuff ===========================

NSString *LogTweakName = @"TVLock13";
bool springboardReady = false;

UIWindow* GetKeyWindow() {
    UIWindow        *foundWindow = nil;
    NSArray         *windows = [[UIApplication sharedApplication]windows];
    for (UIWindow   *window in windows) {
        if (window.isKeyWindow) {
            foundWindow = window;
            break;
        }
    }
    return foundWindow;
}

//	Shows an alert box. Used for debugging 
void ShowAlert(NSString *msg, NSString *title) {
	UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert];

    //Add Buttons
    UIAlertAction* dismissButton = [UIAlertAction
                                actionWithTitle:@"Cool!"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle dismiss button action here
									
                                }];

    //Add your buttons to alert controller
    [alert addAction:dismissButton];

    [GetKeyWindow().rootViewController presentViewController:alert animated:YES completion:nil];
}

//	Show log with tweak name as prefix for easy grep
void Log(NSString *msg) {
	NSLog(@"%@: %@", LogTweakName, msg);
}

//	Log exception info
void LogException(NSException *e) {
	NSLog(@"%@: NSException caught", LogTweakName);
	NSLog(@"%@: Name:%@", LogTweakName, e.name);
	NSLog(@"%@: Reason:%@", LogTweakName, e.reason);
	//ShowAlert(@"TVLock Crash Avoided!", @"Alert");
}



//	=========================== Classes stuff ===========================

extern UIImage* _UICreateScreenUIImage();


@interface SBBacklightController : NSObject
	@property (nonatomic,readonly) BOOL screenIsOn; 
	@property (nonatomic,readonly) BOOL screenIsDim;
@end



@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end


@interface TVLock:NSObject {
	UIWindow *springboardWindow;
	UIView *mainView;
	UIView *subView;
	UIImageView *imageView;
	UIView *whiteOverlay;
}
	-(id)init;
	//-(UIImage*)screenshot;
	-(void)showLockAnimation:(float)arg1;
	-(void)reset;
@end




static TVLock *__strong tvLock;



@implementation TVLock
	-(id)init {
		Log(@"init()");
		self = [super init];

		if(self != nil) {
			@try {
				springboardWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
				springboardWindow.windowLevel = UIWindowLevelAlert + 2;
				[springboardWindow setHidden:YES];
				[springboardWindow _setSecure:YES];
				[springboardWindow setUserInteractionEnabled:NO];
				[springboardWindow setAlpha:1.0];
				springboardWindow.backgroundColor = [UIColor blackColor];
				//[springboardWindow makeKeyAndVisible];
				
				mainView = [[UIView alloc] initWithFrame:springboardWindow.bounds];
				[mainView setAlpha:1.0f];
				mainView.backgroundColor = [UIColor clearColor];
				mainView.layer.shadowColor = [UIColor whiteColor].CGColor;
				mainView.layer.shadowOffset = CGSizeZero;
				mainView.layer.shadowOpacity = 200.0f;
				mainView.layer.shadowRadius = 200.0f;
				mainView.layer.shouldRasterize = true;
				[springboardWindow addSubview:mainView];

				subView = [[UIView alloc] initWithFrame:springboardWindow.bounds];
				[subView setAlpha:1.0f];
				subView.backgroundColor = [UIColor blackColor];
				subView.layer.masksToBounds = YES;
				[mainView addSubview:subView];

				imageView = [[UIImageView alloc] initWithFrame:springboardWindow.bounds];
				imageView.frame = springboardWindow.bounds;
				imageView.contentMode = UIViewContentModeScaleAspectFill;
				[subView addSubview:imageView];

				whiteOverlay = [[UIView alloc] initWithFrame:springboardWindow.bounds];
				whiteOverlay.frame = springboardWindow.bounds;
				whiteOverlay.backgroundColor = [UIColor whiteColor];
				whiteOverlay.alpha = 0.0f;
				[imageView addSubview:whiteOverlay];
				
			} @catch (NSException *e) {
				LogException(e);
			}
		}
		return self;
	}

	-(void)showLockAnimation:(float)totalTime {
		Log(@"showLockAnimation()");
		
		@try {
			[self reset];
			
			//	This is stupid and took too long to figure out. _UICreateScreenUIImage returns 
			//	a UIImage but doesn't give ownership to ARC, so it is done manually.
			CFTypeRef ref = (__bridge CFTypeRef)_UICreateScreenUIImage();
			UIImage *img = (__bridge_transfer UIImage*)ref;
			imageView.image = img;
			
			if (glowEffect) {
				mainView.layer.shadowOpacity = 200.0f;
				mainView.layer.shadowRadius = 200.0f;
			}
			else {
				mainView.layer.shadowOpacity = 0.0f;
				mainView.layer.shadowRadius = 0.0f;
			}

			//	Show animation window
			[springboardWindow setHidden:NO];

			//	Setup third animation
			void (^anim3)(void) = ^{
				[UIView animateWithDuration:animTime3
						delay:0.0f
						options:(smoothAnim ? UIViewAnimationOptionCurveEaseInOut : UIViewAnimationOptionCurveLinear)
						animations:^{
							//	Third part of animation
							whiteOverlay.backgroundColor = [UIColor blackColor];
						} 
						completion:^(BOOL finished) {
							[self reset];
						}
				];
			};

			//	Setup second animation
			void (^anim2)(void) = ^{
				[UIView animateWithDuration:animTime2
						delay:pauseTime1
						options:(smoothAnim ? UIViewAnimationOptionCurveEaseInOut : UIViewAnimationOptionCurveLinear)
						animations:^{
							//	Second part of animation
							mainView.transform = CGAffineTransformScale(imageView.transform, dotSize / (float)mainView.bounds.size.width, dotSize / (float)mainView.bounds.size.height);
							subView.layer.cornerRadius = 300;
						} 
						completion:^(BOOL finished) {
							anim3();
						}
				];
			};

			//	Setup first animation
			void (^anim1)(void) = ^{
				[UIView animateWithDuration:animTime1
					delay:0.0f
                    options:(smoothAnim ? UIViewAnimationOptionCurveEaseInOut : UIViewAnimationOptionCurveLinear)
					animations:^{

						//	First part of animation
						mainView.transform = CGAffineTransformScale(imageView.transform, 1, lineThickness / (float)mainView.bounds.size.height);
						whiteOverlay.alpha = 1.0f;

					} completion:^(BOOL finished) {
						anim2();
					}
				];
			};
			
			//	Play first animation, which will also play the second one
			anim1();

		}
		@catch (NSException *e) {
			LogException(e);
		}
		
	}

	-(void)reset {
		Log(@"reset()");

		mainView.alpha = 1.0f;
		mainView.frame = springboardWindow.bounds;
		mainView.transform = CGAffineTransformIdentity;

		subView.layer.cornerRadius = 0;

		imageView.frame = springboardWindow.bounds;
		imageView.transform = CGAffineTransformIdentity;
		imageView.image = nil;

		whiteOverlay.alpha = 0.0f;
		whiteOverlay.backgroundColor = [UIColor whiteColor];
		whiteOverlay.frame = springboardWindow.bounds;
		whiteOverlay.transform = CGAffineTransformIdentity;

		[springboardWindow setHidden:YES];
	}

@end



//	=========================== Hooks ===========================

%hook SpringBoard

	//	Called when springboard is finished launching
	-(void)applicationDidFinishLaunching:(id)application {
		%orig;

		Log(@"============== TVLock started ==============");

		//[TVLock sharedInstance];
		tvLock = [[TVLock alloc] init];
		//ShowAlert(@"TVLock started", @"Title");

		springboardReady = true;
	}

%end



%hook SBBacklightController
	-(void)_animateBacklightToFactor:(float)arg1 duration:(double)arg2 source:(long long)arg3 silently:(BOOL)arg4 completion:(id)arg5 {
		if(enabled && 
			(!disableInLPM || (![[NSProcessInfo processInfo] isLowPowerModeEnabled])) && 
			(arg1==0 && [self screenIsOn])) {

			Log([NSString stringWithFormat:@"_animateBacklightToFactor()  Backlight:%f Duration:%f Source:%llx Silently:%i", arg1, arg2, arg3, arg4]);
			arg2 = totalTime;


			//for (int i = 0; i < 20; i++)	// For stress testing memory leak (all fixed now)
			[tvLock showLockAnimation:arg2];
		}

		%orig(arg1, arg2, arg3, arg4, arg5);
	}
%end


//	Called whenever any preferences are changed to update variables
static void reloadPrefs() {
	Log(@"reloadPrefs()");
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);
	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList != nil) {
			prefs = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
			if (prefs == nil)
				prefs = [NSDictionary dictionary];
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}


	enabled = [prefs objectForKey:@"kEnabled"] ? [(NSNumber *)[prefs objectForKey:@"kEnabled"] boolValue] : enabled;
	disableInLPM = [prefs objectForKey:@"kLPM"] ? [(NSNumber *)[prefs objectForKey:@"kLPM"] boolValue] : disableInLPM;
	glowEffect = [prefs objectForKey:@"kGlow"] ? [(NSNumber *)[prefs objectForKey:@"kGlow"] boolValue] : glowEffect;
	smoothAnim = [prefs objectForKey:@"kSmooth"] ? [(NSNumber *)[prefs objectForKey:@"kSmooth"] boolValue] : smoothAnim;

	animTime1 = [prefs objectForKey:@"kAnim1"] ? [(NSNumber *)[prefs objectForKey:@"kAnim1"] floatValue] : animTime1;
	pauseTime1 = [prefs objectForKey:@"kPause1"] ? [(NSNumber *)[prefs objectForKey:@"kPause1"] floatValue] : pauseTime1;
	animTime2 = [prefs objectForKey:@"kAnim2"] ? [(NSNumber *)[prefs objectForKey:@"kAnim2"] floatValue] : animTime2;
	animTime3 = [prefs objectForKey:@"kAnim3"] ? [(NSNumber *)[prefs objectForKey:@"kAnim3"] floatValue] : animTime3;
	totalTime = animTime1 + pauseTime1 + animTime2 + animTime3;

	lineThickness = [prefs objectForKey:@"kLine"] ? [(NSNumber *)[prefs objectForKey:@"kLine"] intValue] : lineThickness;
	dotSize = [prefs objectForKey:@"kDot"] ? [(NSNumber *)[prefs objectForKey:@"kDot"] intValue] : dotSize;
}

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	totalTime = animTime1 + pauseTime1 + animTime2 + animTime3;
}