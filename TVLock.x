#import "TVLock.h"

@implementation TVLock
	-(id)init {
		self = [super init];

		if(self != nil) {
			@try {
				landscape = false;
				animationInProgress = false;

				springboardWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
				springboardWindow.windowLevel = UIWindowLevelAlert + 2;
				[springboardWindow setHidden:YES];
				[springboardWindow _setSecure:YES];
				[springboardWindow setUserInteractionEnabled:NO];
				[springboardWindow setAlpha:1.0];
				springboardWindow.backgroundColor = [UIColor blackColor];
				if (@available(iOS 13.0, *)) {
					springboardWindow.windowScene = [UIApplication sharedApplication].keyWindow.windowScene;
				}
				else {
					springboardWindow.screen = [UIScreen mainScreen];
				}

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

	-(UIImage*)getScreenshot {
		// This is stupid and took too long to figure out. _UICreateScreenUIImage returns
		// a UIImage but doesn't give ownership to ARC, so it is done manually.
		CFTypeRef ref = (__bridge CFTypeRef)_UICreateScreenUIImage();
		UIImage *img = (__bridge_transfer UIImage*)ref;
		return img;
	}

	-(void)showLockAnimation:(float)totalTime {
		@try {
			[self reset];
			animationInProgress = true;

			imageView.image = [self getScreenshot];

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
							animationInProgress = false;
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
							if (landscape)
								mainView.transform = CGAffineTransformConcat(springboardWindow.transform, CGAffineTransformScale(CGAffineTransformIdentity, dotSize / (float)mainView.bounds.size.height, dotSize / (float)mainView.bounds.size.width));
							else
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

	-(void)orientationChanged:(NSNotification *)note {
		if (!landscapeEnabled || animationInProgress)
			return;

		UIDevice *device = note.object;
		UIDeviceOrientation orientation = device.orientation;
		CGRect screenBounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

		switch (orientation) {
			case UIInterfaceOrientationPortrait:
			case UIInterfaceOrientationPortraitUpsideDown:
				self->landscape = false;
				self->springboardWindow.transform = CGAffineTransformIdentity;
				self->imageView.transform = CGAffineTransformIdentity;
				self->springboardWindow.frame = CGRectMake(0, 0, CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));
				[self reset];
				break;
			case UIInterfaceOrientationLandscapeLeft:
			case UIInterfaceOrientationLandscapeRight:
				self->landscape = true;
				self->springboardWindow.transform = CGAffineTransformMakeRotation(M_PI_2);
				self->imageView.transform = CGAffineTransformMakeRotation(M_PI);
				self->springboardWindow.frame = CGRectMake(0, 0, CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));
				[self reset];
				break;
			default:
				break;
		}
	}

	- (void)resetToPortrait {
		CGRect screenBounds = [UIScreen mainScreen].fixedCoordinateSpace.bounds;

		self->landscape = false;
		self->springboardWindow.transform = CGAffineTransformIdentity;
		self->springboardWindow.frame = CGRectMake(0, 0, CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));

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