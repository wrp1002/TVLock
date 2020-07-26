#line 1 "Tweak.x"

bool enabled = true;

bool springboardReady = false;

float speed = 0.5f;




void ShowAlert(NSString *msg, NSString *title) {
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
	message:msg
	delegate:nil
	cancelButtonTitle:@"Cool!"
	otherButtonTitles:nil];
	[alert show];
}

void Log(NSString *msg) {
	NSLog(@"TVLock: %@", msg);
}

void LogException(NSException *e) {
	NSLog(@"TVLock NSException caught");
	NSLog(@"Name: %@", e.name);
	NSLog(@"Name: %@", e.reason);
	ShowAlert(@"TVLock Crash Avoided!", @"Alert");
}





@interface SBBacklightController : NSObject
	@property (nonatomic,readonly) BOOL screenIsOn; 
	@property (nonatomic,readonly) BOOL screenIsDim;
@end



@interface UIWindow ()
- (void)_setSecure:(BOOL)arg1;
@end



@interface TVLock:NSObject {
	UIWindow* springboardWindow;
	UIView *mainView;
	UIImageView *imageView;
	UIView *whiteOverlay;
}



+ (id)sharedInstance;
-(id)init;
-(void)showLockAnimation:(float)arg1;
-(void)reset;
@end


@implementation TVLock

static id __strong _sharedObject;


+(id)sharedInstance {
	Log(@"sharedInstance()");

	if (!_sharedObject) {
		Log(@"sharedInstance() Creating new!");
		_sharedObject = [[self alloc] init];
	}
	return _sharedObject;
}

-(id)init {
	Log(@"init()");
	self = [super init];

	if(self != nil) {
		@try {
			springboardWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
			springboardWindow.windowLevel = UIWindowLevelStatusBar + 10000;
			[springboardWindow setHidden:YES];
			[springboardWindow _setSecure:YES];
			springboardWindow.alpha = 1;
			[springboardWindow setUserInteractionEnabled:NO];
			
			
			
			springboardWindow.backgroundColor = [UIColor blackColor];
			
			mainView = [[UIView alloc] initWithFrame:springboardWindow.bounds];
			mainView.backgroundColor = [UIColor blackColor];
			mainView.alpha = 1.0f;
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
		
		CGRect newFrameImage = CGRectMake(imageView.frame.origin.x,-imageView.center.y,imageView.frame.size.width,imageView.frame.size.height);
		CGRect newFrameBack = CGRectMake(0,imageView.center.y,imageView.frame.size.width,5);
		CGAffineTransform newTransformImage = CGAffineTransformScale(imageView.transform, 1, 0.5);

		
		extern UIImage *_UICreateScreenUIImage();
		imageView.image = _UICreateScreenUIImage();

		
		springboardWindow.hidden = NO;
		
		[UIView animateWithDuration:speed*0.3 animations:^{

			
			imageView.frame = newFrameImage;
			imageView.transform = newTransformImage;

			mainView.frame = newFrameBack;

			whiteOverlay.alpha = 1.0f;
			

		} completion:^(BOOL finished) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, speed*0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[UIView animateWithDuration:speed*0.3 animations:^{

					
					mainView.frame = CGRectMake(imageView.bounds.size.width / 2, imageView.bounds.size.height / 2, 1, 1);

				} completion:^(BOOL finished) {
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, speed*0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

						[self reset];
						
					});
				}];

			});
		}];
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

	imageView.alpha = 1.0f;
	imageView.frame = mainView.bounds;
	imageView.transform = CGAffineTransformIdentity;
	imageView.image = nil;

	whiteOverlay.alpha = 0.0f;
	whiteOverlay.frame = whiteOverlay.bounds;
	mainView.transform = CGAffineTransformIdentity;

	springboardWindow.hidden = YES;
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

#line 194 "Tweak.x"


	
	static void _logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$(_LOGOS_SELF_TYPE_NORMAL SpringBoard* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, id application) {
		_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$(self, _cmd, application);

		Log(@"============== TVLock started ==============");

		[TVLock sharedInstance];
		ShowAlert(@"TVLock started", @"Title");

		springboardReady = true;
	}






	static void _logos_method$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$(_LOGOS_SELF_TYPE_NORMAL SBBacklightController* _LOGOS_SELF_CONST __unused self, SEL __unused _cmd, float arg1, double arg2, long long arg3, BOOL arg4, id arg5) {
		if(enabled && (arg1==0 && [self screenIsOn]) ) {
			Log(@"_animateBacklightToFactor()");
			arg2 = speed;
			
			
			
			if([TVLock sharedInstance]) {
				[[TVLock sharedInstance] showLockAnimation:arg2];
			}
		}

		_logos_orig$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$(self, _cmd, arg1, arg2, arg3, arg4, arg5);
	}



static __attribute__((constructor)) void _logosLocalCtor_912512e6(int __unused argc, char __unused **argv, char __unused **envp) {
	
	
}
static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); { MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(applicationDidFinishLaunching:), (IMP)&_logos_method$_ungrouped$SpringBoard$applicationDidFinishLaunching$, (IMP*)&_logos_orig$_ungrouped$SpringBoard$applicationDidFinishLaunching$);}Class _logos_class$_ungrouped$SBBacklightController = objc_getClass("SBBacklightController"); { MSHookMessageEx(_logos_class$_ungrouped$SBBacklightController, @selector(_animateBacklightToFactor:duration:source:silently:completion:), (IMP)&_logos_method$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$, (IMP*)&_logos_orig$_ungrouped$SBBacklightController$_animateBacklightToFactor$duration$source$silently$completion$);}} }
#line 234 "Tweak.x"
