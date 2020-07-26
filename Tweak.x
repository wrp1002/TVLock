
bool enabled = true;

bool springboardReady = false;

float speed = 0.5f;



//	Shows an alert box. Used for debugging 
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
/*@property (nonatomic, strong) UIWindow* springboardWindow;
@property (nonatomic, strong) UIView *mainView;
@property (nonatomic, strong) UIImageView *imageView;*/
+ (id)sharedInstance;
-(id)init;
-(void)showLockAnimation:(float)arg1;
-(void)reset;
@end


@implementation TVLock
//@synthesize springboardWindow, mainView, imageView;
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
			//springboardWindow.layer.cornerRadius = 1.0f;
			//springboardWindow.layer.masksToBounds = YES;
			//springboardWindow.layer.shouldRasterize  = NO;
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
			//whiteOverlay.layer.masksToBounds = YES;
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
		//	Prepare for first animation
		CGRect newFrameImage = CGRectMake(imageView.frame.origin.x,-imageView.center.y,imageView.frame.size.width,imageView.frame.size.height);
		CGRect newFrameBack = CGRectMake(0,imageView.center.y,imageView.frame.size.width,5);
		CGAffineTransform newTransformImage = CGAffineTransformScale(imageView.transform, 1, 0.5);

		// Get screenshot
		extern UIImage *_UICreateScreenUIImage();
		imageView.image = _UICreateScreenUIImage();

		//	Show animation window
		springboardWindow.hidden = NO;
		
		[UIView animateWithDuration:speed*0.3 animations:^{

			//	First part of animation
			imageView.frame = newFrameImage;
			imageView.transform = newTransformImage;

			mainView.frame = newFrameBack;

			whiteOverlay.alpha = 1.0f;
			

		} completion:^(BOOL finished) {
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, speed*0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[UIView animateWithDuration:speed*0.3 animations:^{

					//	Second part of animation
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

%hook SpringBoard

	//	Called when springboard is finished launching
	-(void)applicationDidFinishLaunching:(id)application {
		%orig;

		Log(@"============== TVLock started ==============");

		[TVLock sharedInstance];
		ShowAlert(@"TVLock started", @"Title");

		springboardReady = true;
	}

%end



%hook SBBacklightController
	-(void)_animateBacklightToFactor:(float)arg1 duration:(double)arg2 source:(long long)arg3 silently:(BOOL)arg4 completion:(id)arg5 {
		if(enabled && (arg1==0 && [self screenIsOn]) ) {
			Log(@"_animateBacklightToFactor()");
			arg2 = speed;
			//Log(@"** -(void)_animateBacklightToFactor source:%@ duration:%@ Factor:%@ silently:%@", @(arg3), @(arg2), @(arg1), @(arg4));
			
			//ShowAlert(@"lock time");
			if([TVLock sharedInstance]) {
				[[TVLock sharedInstance] showLockAnimation:arg2];
			}
		}

		%orig(arg1, arg2, arg3, arg4, arg5);
	}
%end


%ctor {
	//reloadPrefs();
	//CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}