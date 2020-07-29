#include "TVLRootListController.h"

@implementation TVLRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

-(void)Respring {
    pid_t pid;
	int status;
	const char* args[] = {"killall", "-9", "SpringBoard", NULL};
	posix_spawn(&pid, "/usr/bin/killall", NULL, NULL, (char* const*)args, NULL);
	waitpid(pid, &status, WEXITED);//wait untill the process completes (only if you need to do that)
}

-(void)OpenGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://github.com/wrp1002/TVLock"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenPaypal {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://paypal.me/wrp1002"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenReddit {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"https://reddit.com/u/wes_hamster"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)OpenEmail {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *URL = [NSURL URLWithString:@"mailto:wes.hamster@gmail.com?subject=TVLock13"];
	[application openURL:URL options:@{} completionHandler:^(BOOL success) {
		if (success) {
			NSLog(@"Opened url");
		}
	}];
}

-(void)Reset {
	[[[HBPreferences alloc] initWithIdentifier: @"com.wrp1002.tvlock"] removeAllObjects];

	NSFileManager *fm = [NSFileManager defaultManager];
	[fm removeItemAtPath: @"/var/mobile/Library/Preferences/com.wrp1002.tvlock.plist" error: nil];

	[self Respring];
}

@end
