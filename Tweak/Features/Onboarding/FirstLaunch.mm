#import "../../YTKACE.h"
#import "../../UI/Notice.h"
#import "../../Runtime/Localization.h"

#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>

static NSString * const YTKACEOnboardingKey = @"YTKACE.Preference.Onboarding.Shown";

@interface YTKACEFirstLaunchFlow : NSObject <NSNetServiceBrowserDelegate>
@property(nonatomic, strong) NSNetServiceBrowser *browser;
@property(nonatomic, assign) NSInteger attempts;
@end

static YTKACEFirstLaunchFlow *YTKACEFirstLaunchInstance;

static UIViewController *YTKACEFirstLaunchPresenter(void) {
    UIWindow *window = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class] ||
            scene.activationState != UISceneActivationStateForegroundActive) continue;
        for (UIWindow *candidate in ((UIWindowScene *)scene).windows) {
            if (candidate.isKeyWindow) {
                window = candidate;
                break;
            }
        }
    }
    UIViewController *controller = window.rootViewController;
    while (controller.presentedViewController != nil) {
        controller = controller.presentedViewController;
    }
    return controller;
}

@implementation YTKACEFirstLaunchFlow

- (void)startCastRequest {
    self.browser = [NSNetServiceBrowser new];
    self.browser.delegate = self;
    [self.browser searchForServicesOfType:@"_googlecast._tcp." inDomain:@"local."];
    YTKACEStartCastDiscovery();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 15 * NSEC_PER_SEC),
        dispatch_get_main_queue(), ^{
            [self.browser stop];
            self.browser = nil;
        });
}

- (void)showSponsorBlockFrom:(UIViewController *)presenter {
    (void)presenter;
    if (YTKACEShowYouTubeDialog(
        YTKACELocalized(@"SponsorBlock"),
        YTKACELocalized(@"YTKACE uses SponsorBlock data.\nLicensed under CC BY-NC-SA 4.0."))) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{ [self startCastRequest]; });
        return;
    }
    YTKACEShowNotice(YTKACELocalized(@"SponsorBlock data: CC BY-NC-SA 4.0"));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 400 * NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{ [self startCastRequest]; });
}

- (void)show {
    UIViewController *presenter = YTKACEFirstLaunchPresenter();
    if (presenter == nil || presenter.view.window == nil) {
        self.attempts += 1;
        if (self.attempts < 20) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC),
                dispatch_get_main_queue(), ^{ [self show]; });
        }
        return;
    }
    [NSUserDefaults.standardUserDefaults setBool:YES forKey:YTKACEOnboardingKey];
    if (YTKACEShowYouTubeDialog(
        @"YTKACE",
        YTKACELocalized(@"To change these, open the YTKACE tab and use the gear icon above."))) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{
                UIViewController *nextPresenter = YTKACEFirstLaunchPresenter();
                if (nextPresenter != nil) [self showSponsorBlockFrom:nextPresenter];
            });
        return;
    }
    YTKACEShowNotice(YTKACELocalized(@"Settings live in the YTKACE tab, behind the gear icon."));
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 300 * NSEC_PER_MSEC),
        dispatch_get_main_queue(), ^{
            UIViewController *nextPresenter = YTKACEFirstLaunchPresenter();
            if (nextPresenter != nil) [self showSponsorBlockFrom:nextPresenter];
        });
}

@end

void YTKACEScheduleFirstLaunch(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4 * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{
                YTKACEPerformWithRealBundleIdentifier(^{
                    [[UNUserNotificationCenter currentNotificationCenter]
                        requestAuthorizationWithOptions:(UNAuthorizationOptionAlert |
                                                         UNAuthorizationOptionSound |
                                                         UNAuthorizationOptionBadge)
                                      completionHandler:^(__unused BOOL granted, __unused NSError *error) {}];
                });
            });
        if ([NSUserDefaults.standardUserDefaults boolForKey:YTKACEOnboardingKey]) return;
        YTKACEFirstLaunchInstance = [YTKACEFirstLaunchFlow new];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC),
            dispatch_get_main_queue(), ^{ [YTKACEFirstLaunchInstance show]; });
    });
}
