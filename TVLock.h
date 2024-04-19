#import <UIKit/UIKit.h>
#import "Globals.h"
#import "Tweak.h"

@interface TVLock:NSObject {
	UIWindow *springboardWindow;
	UIView *mainView;
	UIView *subView;
	UIImageView *imageView;
	UIView *whiteOverlay;
	BOOL landscape;
	BOOL animationInProgress;
}
	-(id)init;
	-(UIImage*)getScreenshot;
	-(void)showLockAnimation:(float)arg1;
	-(void)orientationChanged:(NSNotification *)note;
	-(void)resetToPortrait;
	-(void)reset;
@end
