#import <SpringBoard/SpringBoard.h>
#import <UIKit/UIKit.h>

@interface TapSpring : NSObject {
}

@end
static NSDictionary *preferences;
@implementation TapSpring

+(void) showAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"I'm sorry Dave, I'm afraid I can't do that."
                                                    message:@"Enabling the Settings app will prevent you from being able to open it! That's not good!"
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}

@end

static void loadPreferences() {
    //read preferences
    if (preferences)
        [preferences release];
    CFStringRef appID = CFSTR("com.milodarling.tapspring");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID , kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if (!keyList) {
        NSLog(@"There's been an error getting the key list!");
        return;
    }
    preferences = (NSDictionary *)CFPreferencesCopyMultiple(keyList, appID , kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    CFRelease(keyList);
    
    if ([[preferences objectForKey:@"com.apple.Preferences"] boolValue]) {
        //set the settings app back to false
        CFPreferencesSetAppValue(CFSTR("com.apple.Preferences"), kCFBooleanFalse, appID);
        //reload the new preferences
        loadPreferences();
        //tell them that they can't enable Settings app
        [TapSpring showAlert];
    }
}

%hook SBIconController

// Hooking an instance method with an argument.
-(void)_launchIcon:(id)tapped {
    NSString *icon = [tapped applicationBundleID];
    if ([[preferences objectForKey:icon] boolValue]) {
        NSLog(@"[TapSpring] Enabled");
        [(SpringBoard *)[UIApplication sharedApplication] _relaunchSpringBoardNow];
    } else {
        NSLog(@"[TapSpring] Not enabled");
        %orig;
    }
}

%end

%ctor {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                NULL,
                                (CFNotificationCallback)loadPreferences,
                                CFSTR("com.milodarling.tapspring/prefsChanged"),
                                NULL,
                                CFNotificationSuspensionBehaviorDeliverImmediately);
    loadPreferences();
}