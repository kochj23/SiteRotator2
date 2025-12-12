//
//  ViewControllerTests.m
//  Site Rotator 2.0 Tests
//
//  Unit tests for ViewController
//

#import <XCTest/XCTest.h>
#import "ViewController.h"

@interface ViewController (Testing)
// Expose private methods for testing
- (void)handleConfigResponse:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error;
- (void)handleConfigError:(NSString *)message;
- (void)updateStatusLabel:(NSString *)message;
- (void)updateDurationLabel;
- (void)updateButtonStates;
@property (strong, nonatomic) NSArray<NSURL *> *dashboardURLs;
@property (assign, nonatomic) BOOL isRotating;
@property (assign, nonatomic) double scrollDuration;
@property (strong, nonatomic) NSTextField *statusLabel;
@property (strong, nonatomic) NSTextField *durationLabel;
@property (strong, nonatomic) NSButton *startButton;
@property (strong, nonatomic) NSButton *stopButton;
@property (strong, nonatomic) NSButton *reloadButton;
@end

@interface ViewControllerTests : XCTestCase
@property (strong, nonatomic) ViewController *viewController;
@end

@implementation ViewControllerTests

#pragma mark - Setup & Teardown

- (void)setUp {
    [super setUp];
    self.viewController = [[ViewController alloc] initWithNibName:nil bundle:nil];
    XCTAssertNotNil(self.viewController, @"ViewController should be created");

    // Load the view
    [self.viewController loadView];
    [self.viewController viewDidLoad];
}

- (void)tearDown {
    self.viewController = nil;
    [super tearDown];
}

#pragma mark - Initialization Tests

- (void)testViewControllerInitialization {
    XCTAssertNotNil(self.viewController.view, @"View should be created");
    XCTAssertFalse(self.viewController.isRotating, @"Should not be rotating initially");
    XCTAssertEqual(self.viewController.scrollDuration, 10.0, @"Default scroll duration should be 10.0");
    XCTAssertNotNil(self.viewController.dashboardURLs, @"Dashboard URLs array should be initialized");
}

- (void)testUIComponentsCreation {
    XCTAssertNotNil(self.viewController.startButton, @"Start button should exist");
    XCTAssertNotNil(self.viewController.stopButton, @"Stop button should exist");
    XCTAssertNotNil(self.viewController.reloadButton, @"Reload button should exist");
    XCTAssertNotNil(self.viewController.durationLabel, @"Duration label should exist");
    XCTAssertNotNil(self.viewController.statusLabel, @"Status label should exist");
}

#pragma mark - URL Validation Tests

- (void)testValidURLParsing {
    // Create mock config data
    NSString *configContent = @"https://dashboard1.example.com\nhttps://dashboard2.example.com\n";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    // Create mock response
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    // Handle the response
    [self.viewController handleConfigResponse:data response:response error:nil];

    // Verify URLs were parsed
    XCTAssertEqual(self.viewController.dashboardURLs.count, 2, @"Should parse 2 valid URLs");
}

- (void)testInvalidURLsAreSkipped {
    // Create config with invalid URLs
    NSString *configContent = @"https://valid.com\ninvalid-url\nhttp://another-valid.com\n";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    // Should only include valid URLs
    XCTAssertEqual(self.viewController.dashboardURLs.count, 2, @"Should only include valid URLs");
}

- (void)testEmptyLinesAreIgnored {
    NSString *configContent = @"https://dashboard1.com\n\n\nhttps://dashboard2.com\n";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 2, @"Empty lines should be ignored");
}

- (void)testCommentsAreIgnored {
    NSString *configContent = @"# This is a comment\nhttps://dashboard1.com\n# Another comment\nhttps://dashboard2.com";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 2, @"Comments should be ignored");
}

#pragma mark - Error Handling Tests

- (void)testNetworkErrorHandling {
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorNotConnectedToInternet userInfo:nil];

    [self.viewController handleConfigResponse:nil response:nil error:error];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 0, @"Should have no URLs after error");
    XCTAssertFalse(self.viewController.isRotating, @"Should not be rotating after error");
}

- (void)testHTTPErrorHandling {
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:404
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:nil response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 0, @"Should have no URLs after HTTP error");
}

- (void)testEmptyConfigHandling {
    NSData *emptyData = [@"" dataUsingEncoding:NSUTF8StringEncoding];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:emptyData response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 0, @"Empty config should result in no URLs");
}

#pragma mark - State Management Tests

- (void)testRotationStateChanges {
    // Start with some URLs
    NSString *configContent = @"https://dashboard1.com\nhttps://dashboard2.com";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    // Initially not rotating
    XCTAssertFalse(self.viewController.isRotating, @"Should not be rotating initially");

    // After setting to rotating
    self.viewController.isRotating = YES;
    [self.viewController updateButtonStates];

    XCTAssertFalse(self.viewController.startButton.enabled, @"Start button should be disabled when rotating");
    XCTAssertTrue(self.viewController.stopButton.enabled, @"Stop button should be enabled when rotating");
}

- (void)testButtonStatesWithoutURLs {
    self.viewController.dashboardURLs = @[];
    [self.viewController updateButtonStates];

    XCTAssertFalse(self.viewController.startButton.enabled, @"Start button should be disabled without URLs");
}

- (void)testButtonStatesWithURLs {
    self.viewController.dashboardURLs = @[[NSURL URLWithString:@"https://test.com"]];
    self.viewController.isRotating = NO;
    [self.viewController updateButtonStates];

    XCTAssertTrue(self.viewController.startButton.enabled, @"Start button should be enabled with URLs");
    XCTAssertFalse(self.viewController.stopButton.enabled, @"Stop button should be disabled when not rotating");
}

#pragma mark - UI Update Tests

- (void)testDurationLabelUpdate {
    self.viewController.scrollDuration = 15.5;
    [self.viewController updateDurationLabel];

    NSString *expected = @"Scroll: 15.5 sec";
    XCTAssertEqualObjects(self.viewController.durationLabel.stringValue, expected, @"Duration label should show correct value");
}

- (void)testStatusLabelUpdate {
    NSString *testMessage = @"Test status message";
    [self.viewController updateStatusLabel:testMessage];

    XCTAssertEqualObjects(self.viewController.statusLabel.stringValue, testMessage, @"Status label should show correct message");
}

- (void)testStatusLabelUpdateWithNil {
    [self.viewController updateStatusLabel:nil];

    XCTAssertEqualObjects(self.viewController.statusLabel.stringValue, @"", @"Status label should be empty with nil message");
}

#pragma mark - Configuration Format Tests

- (void)testWhitespaceHandling {
    NSString *configContent = @"  https://dashboard1.com  \n\t\thttps://dashboard2.com\t\n";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 2, @"Should handle whitespace correctly");
}

- (void)testMixedValidAndInvalidURLs {
    NSString *configContent = @"https://valid1.com\ninvalid\nhttps://valid2.com\nnotaurl\nhttps://valid3.com";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 3, @"Should only include valid URLs");
}

#pragma mark - Performance Tests

- (void)testLargeConfigurationPerformance {
    // Generate a large config with 100 URLs
    NSMutableString *configContent = [NSMutableString string];
    for (int i = 0; i < 100; i++) {
        [configContent appendFormat:@"https://dashboard%d.example.com\n", i];
    }

    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self measureBlock:^{
        [self.viewController handleConfigResponse:data response:response error:nil];
    }];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 100, @"Should parse all 100 URLs");
}

#pragma mark - Edge Case Tests

- (void)testConfigWithOnlyComments {
    NSString *configContent = @"# Comment 1\n# Comment 2\n# Comment 3";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 0, @"Config with only comments should have no URLs");
}

- (void)testConfigWithOnlyWhitespace {
    NSString *configContent = @"   \n\t\n  \n\t\t\n";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 0, @"Config with only whitespace should have no URLs");
}

- (void)testSingleURLConfig {
    NSString *configContent = @"https://single-dashboard.com";
    NSData *data = [configContent dataUsingEncoding:NSUTF8StringEncoding];

    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"https://test.com"]
                                                               statusCode:200
                                                              HTTPVersion:@"1.1"
                                                             headerFields:nil];

    [self.viewController handleConfigResponse:data response:response error:nil];

    XCTAssertEqual(self.viewController.dashboardURLs.count, 1, @"Single URL config should work");
    XCTAssertEqualObjects(self.viewController.dashboardURLs[0].absoluteString, @"https://single-dashboard.com", @"URL should match");
}

@end
