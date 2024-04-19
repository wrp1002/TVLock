

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