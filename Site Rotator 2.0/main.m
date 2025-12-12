//
//  main.m
//  Site Rotator 2.0
//
//  Created by Jordan Koch on 10/16/25.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // Create the application
        NSApplication *app = [NSApplication sharedApplication];

        // Create and set the delegate
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];

        // Run the app
        [app run];
    }
    return 0;
}
