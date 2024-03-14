#import <UIKit/UIKit.h>
#import <Cephei/HBPreferences.h>
#import <objc/runtime.h>
#import <UIKit/UIWindow+Private.h>

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
double lockTime = 0.25;



//	=========================== Debugging stuff ===========================

//	=========================== Classes stuff ===========================

extern UIImage* _UICreateScreenUIImage();


@interface SBBacklightController : NSObject
	@property (nonatomic,readonly) BOOL screenIsOn;
	@property (nonatomic,readonly) BOOL screenIsDim;
@end


@interface SBSleepWakeHardwareButtonInteraction : NSObject
	-(void)_playLockSound;
@end

@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
- (BOOL)_shouldCreateContextAsSecure;
@end


@interface TVLock:NSObject {
	UIWindow *springboardWindow;
	UIView *mainView;
	UIView *subView;
	UIImageView *imageView;
	UIView *whiteOverlay;
	BOOL landscape;
}
	-(id)init;
	//-(UIImage*)screenshot;
	-(void)showLockAnimation:(float)arg1;
	-(void)reset;
@end




static TVLock *__strong tvLock;



@implementation TVLock
	-(id)init {
		self = [super init];

		if(self != nil) {
			@try {
				landscape = false;

				springboardWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
				springboardWindow.windowLevel = UIWindowLevelAlert + 2;
				[springboardWindow setHidden:YES];
				[springboardWindow _setSecure:YES];
				[springboardWindow setUserInteractionEnabled:NO];
				[springboardWindow setAlpha:1.0];
				springboardWindow.backgroundColor = [UIColor blackColor];
				springboardWindow.windowScene = [UIApplication sharedApplication].keyWindow.windowScene;

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

				[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
				[[NSNotificationCenter defaultCenter]
					addObserver:self selector:@selector(orientationChanged:)
					name:UIDeviceOrientationDidChangeNotification
					object:[UIDevice currentDevice]
				];

			} @catch (NSException *e) {
			}
		}
		return self;
	}

	-(void)showLockAnimation:(float)totalTime {
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
							mainView.transform = CGAffineTransformConcat(springboardWindow.transform, CGAffineTransformScale(CGAffineTransformIdentity, dotSize / (float)mainView.bounds.size.width, dotSize / (float)mainView.bounds.size.height));
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
						mainView.transform = CGAffineTransformConcat(springboardWindow.transform, CGAffineTransformScale(CGAffineTransformIdentity, 1, lineThickness / (float)mainView.bounds.size.height));
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
		}

	}

	- (void)orientationChanged:(NSNotification *)note {
		NSLog(@"TVLock: updating orientation");

		UIDevice *device = note.object;
		UIDeviceOrientation orientation = device.orientation;
		CGRect screenBounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

		NSLog([NSString stringWithFormat:@"TVLock %f x %f", CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds)]);

		switch (orientation) {
			case UIInterfaceOrientationPortrait:
			case UIInterfaceOrientationPortraitUpsideDown:
				self->landscape = false;
				self->springboardWindow.transform = CGAffineTransformIdentity;
				self->imageView.transform = CGAffineTransformIdentity;
				self->springboardWindow.frame = CGRectMake(0, 0, CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));
				break;
			case UIInterfaceOrientationLandscapeLeft:
			case UIInterfaceOrientationLandscapeRight:
				self->landscape = true;
				self->springboardWindow.transform = CGAffineTransformMakeRotation(M_PI_2);
				self->imageView.transform = CGAffineTransformMakeRotation(M_PI);
				self->springboardWindow.frame = CGRectMake(0, 0, CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));
				break;
			default:
				break;
		}
		[self reset];
	}

	- (void)reset {
		mainView.alpha = 1.0f;
		mainView.frame = springboardWindow.bounds;
		mainView.transform = springboardWindow.transform;

		subView.layer.cornerRadius = 0;

		if (landscape)
			imageView.frame = CGRectMake(0, 0, CGRectGetHeight(springboardWindow.bounds), CGRectGetWidth(springboardWindow.bounds));
		else
			imageView.frame = springboardWindow.bounds;
		imageView.image = nil;

		whiteOverlay.alpha = 0.0f;
		whiteOverlay.backgroundColor = [UIColor whiteColor];
		if (landscape)
			whiteOverlay.frame = CGRectMake(0, 0, CGRectGetHeight(springboardWindow.bounds), CGRectGetWidth(springboardWindow.bounds));
		else
			whiteOverlay.frame = springboardWindow.bounds;
		whiteOverlay.transform = springboardWindow.transform;

		[springboardWindow setHidden:YES];
	}


@end



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
	%end

	// Also trigger animation for auto lock
	%hook SBIdleTimerPolicyAggregator
		-(void)idleTimerDidExpire:(id)arg1 {
			[tvLock showLockAnimation:totalTime];

			// Wait for animation to complete and then lock screen
			double delayInSeconds = totalTime - lockTime;
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
				%orig;
			});

		}
	%end
%end

static void prefsDidUpdate() {
	totalTime = animTime1 + pauseTime1 + animTime2 + animTime3;
}

%ctor {
	%init(allVersionHooks);

	NSOperatingSystemVersion systemVersion = [NSProcessInfo processInfo].operatingSystemVersion;
	if (systemVersion.majorVersion >= 16) {
		%init(iOS16hooks);
	}
	else {
		%init(under16hooks);
	}


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
