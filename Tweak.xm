
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

%hook UIScrollView

    - (void)_scrollViewWillBeginDragging {
        %orig;

        CGPoint velocity = [self.panGestureRecognizer velocityInView:self];
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

        // Add tap gesture recognizer
        UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTaps:)];
        singleTapGestureRecognizer.numberOfTapsRequired = 1;
        singleTapGestureRecognizer.cancelsTouchesInView = NO;
        [self addGestureRecognizer:singleTapGestureRecognizer];

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