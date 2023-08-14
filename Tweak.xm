
#import <UIKit/UIKit.h>

@interface UIScrollView (UIScroller)
@property (nonatomic,readonly) UIPanGestureRecognizer *panGestureRecognizer;
- (void)startUIScroller;
- (void)stopUIScroller;
- (void)autoScroll;
- (void)handleTaps:(UITapGestureRecognizer *)gesture;
@end

NSTimer *timer = nil;
BOOL verticalDown = NO;
int scrollSpeedType = 0; // 0: Normal, 1: Medium, 2: Fast

id topViewController() {
    // Initialize a UIWindow instance to store the key window
    UIWindow *keyWindow = nil;
    // Get all windows of the application
    NSArray *windows = [[UIApplication sharedApplication] windows];
    // Iterate through all windows to find the key window
    for (UIWindow *window in windows) {
        if (window.isKeyWindow) {
            keyWindow = window;
            break;
        }
    }
    // Get the root view controller of the key window
    UIViewController *rootController = keyWindow.rootViewController;
    // Initialize a UIViewController instance to store the top-most view controller
    UIViewController *topController = rootController;
    // Iterate to the top-most view controller that is presented
    while (topController.presentedViewController) topController = topController.presentedViewController;
    // Check if the top-most view controller is a UINavigationController
    // If yes, get its visible view controller
    if ([topController isKindOfClass:[UINavigationController class]]) {
        UIViewController *visibleController = ((UINavigationController *)topController).visibleViewController;
        if (visibleController) topController = visibleController;
    }
    // Return the top-most view controller if it is not the root controller
    // Otherwise, return the root controller
    if (topController != rootController) return topController;
    else return rootController;
}

void openSimpleMenu() {
    // Make sure to only show this once
    if (![topViewController() isKindOfClass:[UIAlertController class]]) {
        // Variables
        BOOL isDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"uiscroller_disabled"];
        // Alert Controller
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"UIScroller Quick Menu"
                                        message:nil
                                        preferredStyle:UIAlertControllerStyleAlert];
        // Action(s)
        UIAlertAction *speed = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Speed: %@", scrollSpeedType == 2 ? @"Fast" : (scrollSpeedType == 1 ? @"Medium" : @"Normal")] style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    if (scrollSpeedType == 2) scrollSpeedType = 0; 
                                    else scrollSpeedType += 1;
                                }];
        UIAlertAction *toggle = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ for this app", isDisabled ? @"Enable" : @"Disable"] style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    if (isDisabled) [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"uiscroller_disabled"];
                                    else [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"uiscroller_disabled"];
                                }];
        UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        // Add Action to the Alert Controller
        [alert addAction:speed];
        [alert addAction:toggle];
        [alert addAction:dismiss];
        // Show the alert to the most top view controller
        [topViewController() presentViewController:alert animated:YES completion:nil];
    }
}

%hook UIWindow

    - (void)becomeKeyWindow {
        %orig;
        // Add tap gesture recognizer (menu)
        UILongPressGestureRecognizer *menuGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMenuLongPress:)];
        menuGestureRecognizer.numberOfTouchesRequired = 2;
        [self addGestureRecognizer:menuGestureRecognizer];
    }

    %new
    - (void)handleMenuLongPress:(UITapGestureRecognizer *)gesture {
        openSimpleMenu();
    }

%end

%hook UIScrollView

    - (void)didMoveToWindow {
        %orig;

        // Add tap gesture recognizer (stop)
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTaps:)];
        singleTapGestureRecognizer.numberOfTapsRequired = 1;
        singleTapGestureRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:singleTapGestureRecognizer];

    }

    - (void)_scrollViewWillBeginDragging {
        %orig;

        CGPoint velocity = [self.panGestureRecognizer velocityInView:self];

        // Only run if enabled
        BOOL isDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"uiscroller_disabled"];
        if (!isDisabled) {
            if (fabs(velocity.y) > fabs(velocity.x)) {
                if (velocity.y > 0) {
                    // User scrolling down
                    verticalDown = NO;
                    [self startUIScroller];
                } else {
                    // User scrolling up
                    verticalDown = YES;
                    [self startUIScroller];
                }
            }
        }

    }

    - (BOOL)_scrollViewWillEndDraggingWithDeceleration:(BOOL)arg1 {
        if (!%orig && !arg1) [self stopUIScroller];
        return %orig;
    }

    %new
    - (void)handleTaps:(UITapGestureRecognizer *)gesture {  
        // UIScroller will still scroll previous page if not stopped
        [self stopUIScroller];
    }

    %new
    - (void)startUIScroller {
        // Invalidate first
        [self stopUIScroller];
        // Then start scrolling
        timer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(autoScroll) userInfo:nil repeats:YES];
    }

    %new
    - (void)stopUIScroller {
        // Invalidate
        [timer invalidate];
        timer = nil;
    }

    %new
    - (void)autoScroll {

        // Variables
        float scrollSpeed = 1.0; // Default scrolling speed
        CGPoint offset = self.contentOffset;

        // Adjust based on user's prefs
        if (scrollSpeedType == 1) scrollSpeed = 1.5;
        else if (scrollSpeedType == 2) scrollSpeed = 2.0;

        // Condition
        if (verticalDown) offset.y += scrollSpeed;
        else offset.y -= scrollSpeed;

        // Stop scrolling when exceed the top or bottom
        float endPoint = offset.y + self.frame.size.height;
        if (self.contentOffset.y < 0 || endPoint >= self.contentSize.height) {
            [self stopUIScroller];
        }

        // Scroll the target content offset
        [self setContentOffset:offset animated:NO];
    }

%end

%ctor {
    // Only run on user installed apps
    NSString *executablePath = NSProcessInfo.processInfo.arguments[0];
    if ([executablePath containsString:@"/var/containers/Bundle/Application"]) %init;
}