//
//  ViewController.h
//  Site Rotator 2.0
//
//  Dashboard rotation controller for displaying multiple web dashboards
//  Loads URLs from a remote configuration file and cycles through them with smooth scrolling
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>

/// Main view controller for the dashboard rotation application
/// Manages web view display, configuration loading, and automatic rotation between dashboards
@interface ViewController : NSViewController <WKNavigationDelegate, NSTableViewDataSource, NSTableViewDelegate>

@end
