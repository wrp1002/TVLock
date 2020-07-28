#line 1 "Tweak.x"

bool enabled = true;

bool springboardReady = false;

float speed = 0.3f;






NSString *LogTweakName = @"TVLock";


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


void ShowAlert(NSString *msg, NSString *title) {
	UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:msg
                                 preferredStyle:UIAlertControllerStyleAlert];

    
    UIAlertAction* dismissButton = [UIAlertAction
                                actionWithTitle:@"Cool!"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    
									
                                }];

    
    [alert addAction:dismissButton];

    [GetKeyWindow().rootViewController presentViewController:alert animated:YES completion:nil];
}


void Log(NSString *msg) {
	NSLog(@"%@: %@", LogTweakName, msg);
}


void LogException(NSException *e) {
	NSLog(@"%@: NSException caught", LogTweakName);
	NSLog(@"%@: Name:%@", LogTweakName, e.name);
	NSLog(@"%@: Reason:%@", LogTweakName, e.reason);
	
}





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
	UIImageView *imageView;
	UIView *whiteOverlay;
}
	-(id)init;
	
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
				
				
				mainView = [[UIView alloc] initWithFrame:springboardWindow.bounds];
				[mainView setAlpha:1.0f];
				mainView.backgroundColor = [UIColor blackColor];
				mainView.layer.masksToBounds = YES;
				[springboardWindow addSubview:mainView];

				imageView = [[UIImageView alloc] initWithFrame:springboardWindow.bounds];
				imageView.frame = springboardWindow.bounds;
				imageView.contentMode = UIViewContentModeScaleAspectFill;
				[mainView addSubview:imageView];

				whiteOverlay = [[UIView alloc] initWithFrame:springboardWindow.bounds];
				whiteOverlay.frame = springboardWindow.bounds;
				whiteOverlay.backgroundColor = [UIColor whiteColor];
				whiteOverlay.alpha = 0.0f;
				whiteOverlay.layer.masksToBounds = YES;
				[imageView addSubview:whiteOverlay];
				
			} @catch (NSException *e) {
				LogException(e);
			}
		}
		return self;
	}

	-(void)showLockAnimation:(float)speed {
		Log(@"showLockAnimation()");
		
		@try {
			[self reset];
			
			
			CGRect newFrameImage = CGRectMake(imageView.frame.origin.x,-imageView.center.y,imageView.frame.size.width,imageView.frame.size.height);
			CGRect newFrameBack = CGRectMake(0,imageView.center.y,imageView.frame.size.width,5);
			CGAffineTransform newTransformImage = CGAffineTransformScale(imageView.transform, 1, 0.5);
			
			
			
			
			CFTypeRef ref = (__bridge CFTypeRef)_UICreateScreenUIImage();
			UIImage *img = (__bridge_transfer UIImage*)ref;
			imageView.image = img;
			
			
			[springboardWindow setHidden:NO];

			
			void (^anim2)(void) = ^{
				[UIView animateWithDuration:speed*0.5 
						delay:0.00f
						options:UIViewAnimationOptionCurveLinear
						animations:^{
							
							mainView.frame = CGRectMake(imageView.bounds.size.width / 2, imageView.bounds.size.height / 2, 1, 1);
						} 
						completion:^(BOOL finished) {
							[self reset];
						}
				];
			};

			
			void (^anim1)(void) = ^{
				[UIView animateWithDuration:speed*0.5 
					delay:0.0f
                    options:UIViewAnimationOptionCurveLinear
					animations:^{

						
						imageView.frame = newFrameImage;
						imageView.transform = newTransformImage;

						mainView.frame = newFrameBack;

						whiteOverlay.alpha = 1.0f;

					} completion:^(BOOL finished) {
						anim2();
					}
				];
			};
			
			
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

		imageView.frame = springboardWindow.bounds;
		imageView.transform = CGAffineTransformIdentity;
		imageView.image = nil;

		whiteOverlay.alpha = 0.0f;
		whiteOverlay.frame = springboardWindow.bounds;
		whiteOverlay.transform = CGAffineTransformIdentity;

		[springboardWindow setHidden:YES];
	}

@end






#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class SpringBoard; @class SBBacklightController; 
static void (*_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$)(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST, SEL, id); static void (*_logos_orig$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$)(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL, float, double, long long, BOOL, id); static void _logos_method$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST, SEL, float, double, long long, BOOL, id); 

#line 233 "Tweak.x"


	
	static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application) {
		_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);

		Log(@"============== TVLock started ==============");

		
		tvLock = [[TVLock alloc] init];
		ShowAlert(@"TVLock started", @"Title");

		springboardReady = true;
	}






	static void _logos_method$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, float arg1, double arg2, long long arg3, BOOL arg4, id arg5) {
		if(enabled && (arg1==0 && [self screenIsOn]) ) {
			Log([NSString stringWithFormat:@"_animateBacklightToFactor()  Backlight:%f Duration:%f Source:%llx Silently:%i", arg1, arg2, arg3, arg4]);
			arg2 = speed;


			
			[tvLock showLockAnimation:arg2];
		}

		_logos_orig$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$(self, _cmd, arg1, arg2, arg3, arg4, arg5);
	}





static __attribute__((constructor)) void _logosLocalCtor_babeaf76(int __unused argc, char __unused **argv, char __unused **envp) {
	
	
}
static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); { MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);}Class _logos_class$_ungrouped$SBBacklightController = objc_getClass("SBBacklightController"); { MSHookMessageEx(_logos_class$_ungrouped$SBBacklightController, @selector(_animateBacklightToFactor:duration:source:silently:completion:), (IMP)&_logos_method$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$, (IMP*)&_logos_orig$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$);}} }
#line 274 "Tweak.x"
