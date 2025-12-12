//
//  AppDelegate.m
//  Site Rotator 2.0
//
//  Application delegate that creates and manages the main window
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()
@property (strong, nonatomic) NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Create main window
    NSRect frame = NSMakeRect(0, 0, 1024, 700);
    NSUInteger style = NSWindowStyleMaskTitled |
                       NSWindowStyleMaskClosable |
                       NSWindowStyleMaskResizable |
                       NSWindowStyleMaskMiniaturizable;

    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];

    self.window.title = @"Dashboard Rotator";
    self.window.minSize = NSMakeSize(800, 600);

    // Create and set view controller
    ViewController *viewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
    if (viewController) {
        self.window.contentViewController = viewController;
        [self.window center];
        [self.window makeKeyAndOrderFront:nil];
        NSLog(@"✅ Dashboard Rotator window created");
    } else {
        NSLog(@"❌ Failed to create ViewController");
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSLog(@"🛑 Dashboard Rotator terminating");
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}

@end
