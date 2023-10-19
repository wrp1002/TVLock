#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>

//	=============================== Globals ===============================

HBPreferences *preferences;

//	=========================== Preference vars ===========================

BOOL enabled = true;
BOOL disableInLPM = false;
BOOL glowEffect = true;
BOOL smoothAnim = false;

NSInteger lineThickness = 4;
NSInteger dotSize = 3;

double animTime1 = 0.15;
double pauseTime1 = 0.05;
double animTime2 = 0.15;
double animTime3 = 0.40;
double totalTime = 1.0;



//	=========================== Debugging stuff ===========================

NSString *LogTweakName = @"TVLock13";
bool springboardReady = false;

UIWindow* GetKeyWindow() {
	if (@available(iOS 13, *)) {
		NSSet *connectedScenes = [UIApplication sharedApplication].connectedScenes;
		for (UIScene *scene in connectedScenes) {
			if ([scene isKindOfClass:[UIWindowScene class]]) {
				UIWindowScene *windowScene = (UIWindowScene *)scene;
				for (UIWindow *window in windowScene.windows) {
					if (window.isKeyWindow) {
						return window;
					}
				}
			}
		}
	} else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		NSArray		 *windows = [[UIApplication sharedApplication] windows];
#pragma clang diagnostic pop
		for (UIWindow   *window in windows) {
			if (window.isKeyWindow) {
				return window;
			}
		}
	}
	return nil;
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



static void prefsDidUpdate() {
	Log(@"prefsDidUpdate()");
	totalTime = animTime1 + pauseTime1 + animTime2 + animTime3;
}

%ctor {
	preferences = [[HBPreferences alloc] initWithIdentifier:@"com.wrp1002.tvlock"];

    [preferences registerBool:&enabled default:enabled forKey:@"kEnabled"];
    [preferences registerBool:&disableInLPM default:disableInLPM forKey:@"kLPM"];
    [preferences registerBool:&glowEffect default:glowEffect forKey:@"kGlow"];
    [preferences registerBool:&smoothAnim default:smoothAnim forKey:@"kSmooth"];

    [preferences registerDouble:&animTime1 default:animTime1 forKey:@"kAnim1"];
    [preferences registerDouble:&pauseTime1 default:pauseTime1 forKey:@"kPause1"];
    [preferences registerDouble:&animTime2 default:animTime2 forKey:@"kAnim2"];
    [preferences registerDouble:&animTime3 default:animTime3 forKey:@"kAnim3"];

    [preferences registerInteger:&lineThickness default:lineThickness forKey:@"kLine"];
    [preferences registerInteger:&dotSize default:dotSize forKey:@"kDot"];

    [preferences registerPreferenceChangeBlock:^{
        prefsDidUpdate();
    }];
}
