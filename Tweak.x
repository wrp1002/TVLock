
bool enabled = true;

bool springboardReady = false;

float speed = 0.3f;

//speed = 1.5;


//	=========================== Debugging stuff ===========================

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
			
			//	Prepare for first animation
			CGRect newFrameImage = CGRectMake(imageView.frame.origin.x,-imageView.center.y,imageView.frame.size.width,imageView.frame.size.height);
			CGRect newFrameBack = CGRectMake(0,imageView.center.y,imageView.frame.size.width,5);
			CGAffineTransform newTransformImage = CGAffineTransformScale(imageView.transform, 1, 0.5);
			
			
			//	This is stupid and took too long to figure out. _UICreateScreenUIImage returns 
			//	a UIImage but doesn't give ownership to ARC, so it is done manually.
			CFTypeRef ref = (__bridge CFTypeRef)_UICreateScreenUIImage();
			UIImage *img = (__bridge_transfer UIImage*)ref;
			imageView.image = img;
			
			//	Show animation window
			[springboardWindow setHidden:NO];

			//	Setup second animation
			void (^anim2)(void) = ^{
				[UIView animateWithDuration:speed*0.5 
						delay:0.00f
						options:UIViewAnimationOptionCurveLinear
						animations:^{
							//	Second part of animation
							mainView.frame = CGRectMake(imageView.bounds.size.width / 2, imageView.bounds.size.height / 2, 1, 1);
						} 
						completion:^(BOOL finished) {
							[self reset];
						}
				];
			};

			//	Setup first animation
			void (^anim1)(void) = ^{
				[UIView animateWithDuration:speed*0.5 
					delay:0.0f
                    options:UIViewAnimationOptionCurveLinear
					animations:^{

						//	First part of animation
						imageView.frame = newFrameImage;
						imageView.transform = newTransformImage;

						mainView.frame = newFrameBack;

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

		imageView.frame = springboardWindow.bounds;
		imageView.transform = CGAffineTransformIdentity;
		imageView.image = nil;

		whiteOverlay.alpha = 0.0f;
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
		ShowAlert(@"TVLock started", @"Title");

		springboardReady = true;
	}

%end



%hook SBBacklightController
	-(void)_animateBacklightToFactor:(float)arg1 duration:(double)arg2 source:(long long)arg3 silently:(BOOL)arg4 completion:(id)arg5 {
		if(enabled && (arg1==0 && [self screenIsOn]) ) {
			Log([NSString stringWithFormat:@"_animateBacklightToFactor()  Backlight:%f Duration:%f Source:%llx Silently:%i", arg1, arg2, arg3, arg4]);
			arg2 = speed;


			//for (int i = 0; i < 20; i++)	// For stress testing memory leak (all fixed now)
			[tvLock showLockAnimation:arg2];
		}

		%orig(arg1, arg2, arg3, arg4, arg5);
	}
%end




%ctor {
	//reloadPrefs();
	//CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}