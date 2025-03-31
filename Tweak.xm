#import <UIKit/UIKit.h>

@interface UIScrollView (UIScroller)
@property (nonatomic,readonly) UIPanGestureRecognizer *panGestureRecognizer;
- (void)startUIScroller;
- (void)stopUIScroller;
- (void)autoScroll;
- (void)handleTaps:(UITapGestureRecognizer *)gesture;
@end

NSTimer *timer = nil;
NSTimer *autoDisableTimer = nil;
BOOL verticalDown = NO;
int scrollSpeedType = 0; // 0: Slow, 1: Normal, 2: Medium, 3: Fast
int autoDisableMinutes = 0; // 0: Disabled, >0: Minutes until auto-disable

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
        UIAlertAction *speed = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Speed: %@", scrollSpeedType == 3 ? @"Fast" : (scrollSpeedType == 2 ? @"Medium" : (scrollSpeedType == 1 ? @"Normal" : @"Slow"))] style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    if (scrollSpeedType == 3) scrollSpeedType = 0; 
                                    else scrollSpeedType += 1;
                                }];
        UIAlertAction *autoDisable = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Auto-disable: %@", autoDisableMinutes == 0 ? @"Off" : [NSString stringWithFormat:@"%d min", autoDisableMinutes]] style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    // Show input alert
                                    UIAlertController *inputAlert = [UIAlertController alertControllerWithTitle:@"Set auto-disable Timer"
                                                                                                      message:@"Enter minutes (0 to disable)"
                                                                                               preferredStyle:UIAlertControllerStyleAlert];
                                    
                                    [inputAlert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                                        textField.keyboardType = UIKeyboardTypeNumberPad;
                                        textField.placeholder = @"Minutes";
                                        textField.text = [NSString stringWithFormat:@"%d", autoDisableMinutes];
                                    }];
                                    
                                    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action) {
                                            NSString *input = inputAlert.textFields.firstObject.text;
                                            int minutes = [input intValue];
                                            
                                            // Validate input (max 180 minutes = 3 hours)
                                            if (minutes < 0) minutes = 0;
                                            if (minutes > 180) minutes = 180;
                                            
                                            autoDisableMinutes = minutes;
                                            
                                            // Cancel existing auto-disable timer
                                            if (autoDisableTimer) {
                                                [autoDisableTimer invalidate];
                                                autoDisableTimer = nil;
                                            }
                                            
                                            // Show confirmation
                                            NSString *message = autoDisableMinutes == 0 ? 
                                                @"Auto-disable timer disabled" : 
                                                [NSString stringWithFormat:@"Auto-disable timer set to %d minutes", autoDisableMinutes];
                                            
                                            UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Timer Updated"
                                                                                                                message:message
                                                                                                         preferredStyle:UIAlertControllerStyleAlert];
                                            [confirmation addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                                            [topViewController() presentViewController:confirmation animated:YES completion:nil];
                                    }];
                                    
                                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
                                    
                                    [inputAlert addAction:confirmAction];
                                    [inputAlert addAction:cancelAction];
                                    
                                    [topViewController() presentViewController:inputAlert animated:YES completion:nil];
                                }];
        UIAlertAction *toggle = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"%@ for this app", isDisabled ? @"Enable" : @"Disable"] style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction *action) {
                                    if (isDisabled) [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"uiscroller_disabled"];
                                    else [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"uiscroller_disabled"];
                                }];
        UIAlertAction *dismiss = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        // Add Action to the Alert Controller
        [alert addAction:speed];
        [alert addAction:autoDisable];
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
        
        // Set up auto-disable timer if enabled
        if (autoDisableMinutes > 0) {
            // Cancel existing auto-disable timer if any
            if (autoDisableTimer) {
                [autoDisableTimer invalidate];
                autoDisableTimer = nil;
            }
            
            // Create new auto-disable timer
            autoDisableTimer = [NSTimer scheduledTimerWithTimeInterval:autoDisableMinutes * 60 
                                                              target:self 
                                                            selector:@selector(autoDisableScrolling) 
                                                            userInfo:nil 
                                                             repeats:NO];
        }
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
        if (scrollSpeedType == 0) scrollSpeed = 0.5; // Slow
        else if (scrollSpeedType == 1) scrollSpeed = 1.0; // Normal
        else if (scrollSpeedType == 2) scrollSpeed = 1.5; // Medium
        else if (scrollSpeedType == 3) scrollSpeed = 2.0; // Fast

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

    %new
    - (void)autoDisableScrolling {
        // Stop the scrolling
        [self stopUIScroller];
        
        // Reset the auto-disable timer
        [autoDisableTimer invalidate];
        autoDisableTimer = nil;
        
        // Show a notification to the user
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"UIScroller"
                                                                     message:@"Auto-scrolling has been automatically disabled"
                                                              preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
        [alert addAction:ok];
        [topViewController() presentViewController:alert animated:YES completion:nil];
    }

%end

%ctor {
    // Only run on user installed apps
    NSString *executablePath = NSProcessInfo.processInfo.arguments[0];
    if ([executablePath containsString:@"/var/containers/Bundle/Application"]) %init;
}