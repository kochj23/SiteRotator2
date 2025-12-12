//
//  ViewController.m
//  Site Rotator 2.0
//
//  Dashboard rotation controller that loads URLs from a remote config and cycles through them
//

#import "ViewController.h"
@import UniformTypeIdentifiers;

// MARK: - Constants

/// Timing constants for dashboard rotation
static const NSTimeInterval kMinPageLoadDelay = 0.5;       // Minimum page load delay
static const NSTimeInterval kMaxPageLoadDelay = 10.0;      // Maximum page load delay
static const NSTimeInterval kDefaultPageLoadDelay = 2.0;   // Default page load delay
static const NSTimeInterval kMinPostScrollDelay = 1.0;     // Minimum post-scroll delay
static const NSTimeInterval kMaxPostScrollDelay = 60.0;    // Maximum post-scroll delay
static const NSTimeInterval kDefaultPostScrollDelay = 20.0; // Default post-scroll delay
static const double kMinScrollDuration = 5.0;              // Minimum scroll duration in seconds
static const double kMaxScrollDuration = 30.0;             // Maximum scroll duration in seconds
static const double kDefaultScrollDuration = 10.0;         // Default scroll duration in seconds

/// UserDefaults keys for persistent storage
static NSString *const kStoredURLsKey = @"StoredDashboardURLs";
static NSString *const kScrollDurationKey = @"ScrollDuration";
static NSString *const kPageLoadDelayKey = @"PageLoadDelay";
static NSString *const kPostScrollDelayKey = @"PostScrollDelay";

/// UI Layout constants
static const CGFloat kWindowWidth = 1024.0;
static const CGFloat kWindowHeight = 700.0;
static const CGFloat kControlsHeight = 60.0;
static const CGFloat kButtonWidth = 80.0;
static const CGFloat kButtonHeight = 30.0;
static const CGFloat kButtonSpacing = 10.0;
static const CGFloat kLeftMargin = 20.0;

// MARK: - Interface

@interface ViewController ()

// UI Components
@property (strong, nonatomic) WKWebView *webView;
@property (strong, nonatomic) NSButton *startButton;
@property (strong, nonatomic) NSButton *stopButton;
@property (strong, nonatomic) NSSlider *durationSlider;
@property (strong, nonatomic) NSTextField *durationLabel;
@property (strong, nonatomic) NSTextField *statusLabel;

// Data
@property (strong, nonatomic) NSArray<NSURL *> *dashboardURLs;
@property (copy, nonatomic) NSString *configURL;
@property (strong, nonatomic) NSMutableArray<NSString *> *storedURLStrings;

// State
@property (assign, nonatomic) NSInteger currentIndex;
@property (assign, nonatomic) BOOL isRotating;
@property (assign, nonatomic) double scrollDuration;
@property (assign, nonatomic) NSTimeInterval pageLoadDelay;
@property (assign, nonatomic) NSTimeInterval postScrollDelay;

// Tasks (for cancellation)
@property (strong, nonatomic) NSURLSessionDataTask *configTask;

@end

// MARK: - Implementation

@implementation ViewController

// MARK: - Lifecycle

- (void)dealloc {
    // Stop rotation
    self.isRotating = NO;

    // Cancel any pending network requests
    [self.configTask cancel];

    // Clean up WebView delegate
    self.webView.navigationDelegate = nil;

    NSLog(@"✅ ViewController deallocated");
}

- (void)loadView {
    // Create main container view
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, kWindowWidth, kWindowHeight)];

    // Create and configure WebView
    CGFloat webViewHeight = kWindowHeight - kControlsHeight;
    self.webView = [[WKWebView alloc] initWithFrame:NSMakeRect(0, kControlsHeight, kWindowWidth, webViewHeight)];
    self.webView.navigationDelegate = self;
    self.webView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [view addSubview:self.webView];

    // Create control buttons
    [self createControlsInView:view];

    self.view = view;
}

/// Creates all UI controls (buttons, slider, labels)
- (void)createControlsInView:(NSView *)view {
    CGFloat xPos = kLeftMargin;

    // Start Button
    self.startButton = [[NSButton alloc] initWithFrame:NSMakeRect(xPos, 20, kButtonWidth, kButtonHeight)];
    self.startButton.title = @"Start";
    self.startButton.bezelStyle = NSBezelStyleRounded;
    self.startButton.target = self;
    self.startButton.action = @selector(onStartClicked:);
    [view addSubview:self.startButton];
    xPos += kButtonWidth + kButtonSpacing;

    // Stop Button
    self.stopButton = [[NSButton alloc] initWithFrame:NSMakeRect(xPos, 20, kButtonWidth, kButtonHeight)];
    self.stopButton.title = @"Stop";
    self.stopButton.bezelStyle = NSBezelStyleRounded;
    self.stopButton.target = self;
    self.stopButton.action = @selector(onStopClicked:);
    self.stopButton.enabled = NO;
    [view addSubview:self.stopButton];
    xPos += kButtonWidth + kButtonSpacing;

    // Duration Slider (moved closer since Reload Config button removed)
    self.durationSlider = [[NSSlider alloc] initWithFrame:NSMakeRect(xPos, 24, 200, 22)];
    self.durationSlider.minValue = kMinScrollDuration;
    self.durationSlider.maxValue = kMaxScrollDuration;
    self.durationSlider.doubleValue = kDefaultScrollDuration;
    self.durationSlider.target = self;
    self.durationSlider.action = @selector(onDurationSliderChanged:);
    [view addSubview:self.durationSlider];
    xPos += 200 + kButtonSpacing + 10;

    // Duration Label
    self.durationLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(xPos, 24, 200, 22)];
    self.durationLabel.editable = NO;
    self.durationLabel.bezeled = NO;
    self.durationLabel.drawsBackground = NO;
    self.durationLabel.font = [NSFont systemFontOfSize:13 weight:NSFontWeightRegular];
    [view addSubview:self.durationLabel];

    // Status Label
    self.statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(kLeftMargin, 0, kWindowWidth - 40, 20)];
    self.statusLabel.editable = NO;
    self.statusLabel.bezeled = NO;
    self.statusLabel.drawsBackground = NO;
    self.statusLabel.font = [NSFont systemFontOfSize:11 weight:NSFontWeightRegular];
    self.statusLabel.textColor = [NSColor secondaryLabelColor];
    [view addSubview:self.statusLabel];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Initialize state
    self.configURL = @"https://digitalnoise.net/dashboards.txt";
    self.isRotating = NO;
    self.currentIndex = 0;
    self.dashboardURLs = @[];

    // Load persistent settings from UserDefaults
    [self loadSettings];

    // Load stored URLs
    [self loadStoredURLs];

    // Create application menus
    [self createMenus];

    // Update UI with loaded settings
    self.durationSlider.doubleValue = self.scrollDuration;
    [self updateDurationLabel];
    [self updateStatusLabel:@"Ready to load dashboards"];

    // If we have stored URLs, use them; otherwise try loading from config
    if (self.storedURLStrings.count > 0) {
        [self loadURLsFromStoredStrings];
    } else {
        [self readDashboardConfig];
    }

    NSLog(@"✅ Dashboard Rotator initialized");
}

// MARK: - UI Actions

/// Called when Start button is clicked
- (void)onStartClicked:(id)sender {
    if (self.isRotating) {
        NSLog(@"⚠️ Already rotating");
        return;
    }

    if (self.dashboardURLs.count == 0) {
        [self updateStatusLabel:@"No dashboards loaded. Click 'Reload Config' to try again."];
        NSLog(@"⚠️ Cannot start - no dashboards loaded");
        return;
    }

    NSLog(@"▶️ Starting rotation with %ld dashboards", (long)self.dashboardURLs.count);
    self.isRotating = YES;
    self.currentIndex = 0;
    [self updateButtonStates];
    [self rotateToNextDashboard];
}

/// Called when Stop button is clicked
- (void)onStopClicked:(id)sender {
    if (!self.isRotating) return;

    NSLog(@"⏹ Stopping rotation");
    self.isRotating = NO;
    [self updateButtonStates];
    [self updateStatusLabel:@"Rotation stopped"];
}

/// Show dialog to load from remote URL
- (void)showRemoteConfigDialog:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Load from Remote URL";
    alert.informativeText = @"Enter the HTTPS URL of a remote configuration file containing dashboard URLs (one per line):";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"Load"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 400, 24)];
    input.placeholderString = @"https://example.com/dashboards.txt";
    input.stringValue = self.configURL ?: @"";
    alert.accessoryView = input;

    [alert.window setInitialFirstResponder:input];

    NSModalResponse response = [alert runModal];

    if (response == NSAlertFirstButtonReturn) {
        NSString *urlString = [input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (urlString.length == 0) {
            NSAlert *errorAlert = [[NSAlert alloc] init];
            errorAlert.messageText = @"Empty URL";
            errorAlert.informativeText = @"Please enter a remote configuration URL";
            errorAlert.alertStyle = NSAlertStyleWarning;
            [errorAlert runModal];
            return;
        }

        NSURL *url = [NSURL URLWithString:urlString];
        if (!url || !url.scheme || ![url.scheme isEqualToString:@"https"]) {
            NSAlert *errorAlert = [[NSAlert alloc] init];
            errorAlert.messageText = @"Invalid URL";
            errorAlert.informativeText = @"Remote configuration URL must use HTTPS for security.\n\nExample: https://example.com/dashboards.txt";
            errorAlert.alertStyle = NSAlertStyleWarning;
            [errorAlert runModal];
            NSLog(@"⚠️ Invalid remote config URL: %@", urlString);
            return;
        }

        // Save the URL and load from it
        self.configURL = urlString;
        NSLog(@"🔄 Loading dashboard configuration from: %@", urlString);
        [self readDashboardConfig];
    }
}

/// Called when duration slider value changes
- (void)onDurationSliderChanged:(NSSlider *)slider {
    self.scrollDuration = slider.doubleValue;
    [self updateDurationLabel];
}

// MARK: - UI Updates

/// Updates the duration label to show current scroll duration
- (void)updateDurationLabel {
    self.durationLabel.stringValue = [NSString stringWithFormat:@"Scroll: %.1f sec", self.scrollDuration];
}

/// Updates the status label with a message
- (void)updateStatusLabel:(NSString *)message {
    self.statusLabel.stringValue = message ?: @"";
}

/// Updates button enabled states based on current rotation state
- (void)updateButtonStates {
    BOOL hasURLs = self.dashboardURLs.count > 0;
    self.startButton.enabled = !self.isRotating && hasURLs;
    self.stopButton.enabled = self.isRotating;
}

// MARK: - Configuration Loading

/// Loads dashboard URLs from the remote configuration file
- (void)readDashboardConfig {
    // Cancel any existing config load
    [self.configTask cancel];

    // Validate config URL
    NSURL *url = [NSURL URLWithString:self.configURL];
    if (!url) {
        [self handleConfigError:@"Invalid configuration URL"];
        NSLog(@"❌ Invalid config URL: %@", self.configURL);
        return;
    }

    // Enforce HTTPS for security
    if (![url.scheme isEqualToString:@"https"]) {
        [self handleConfigError:@"Configuration URL must use HTTPS"];
        NSLog(@"❌ Config URL is not HTTPS: %@", url);
        return;
    }

    [self updateStatusLabel:@"Loading dashboard configuration..."];
    NSLog(@"🌐 Fetching config from: %@", url);

    // Create and start network request
    self.configTask = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                   completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleConfigResponse:data response:response error:error];
        });
    }];
    [self.configTask resume];
}

/// Handles the response from the configuration URL request
- (void)handleConfigResponse:(NSData *)data response:(NSURLResponse *)response error:(NSError *)error {
    // Check for network errors
    if (error) {
        NSString *errorMsg = [NSString stringWithFormat:@"Network error: %@", error.localizedDescription];
        [self handleConfigError:errorMsg];
        NSLog(@"❌ Config load failed: %@", error);
        return;
    }

    // Validate HTTP response
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (httpResponse.statusCode != 200) {
            NSString *errorMsg = [NSString stringWithFormat:@"HTTP %ld: Failed to load config", (long)httpResponse.statusCode];
            [self handleConfigError:errorMsg];
            NSLog(@"❌ Config HTTP error: %ld", (long)httpResponse.statusCode);
            return;
        }
    }

    // Parse configuration data
    NSString *fileContent = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!fileContent || fileContent.length == 0) {
        [self handleConfigError:@"Configuration file is empty"];
        NSLog(@"❌ Config file is empty");
        return;
    }

    // Parse URLs from configuration
    NSMutableArray *urls = [NSMutableArray array];
    NSArray *lines = [fileContent componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

    for (NSString *line in lines) {
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // Skip empty lines and comments
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) {
            continue;
        }

        // Validate and add URL
        NSURL *url = [NSURL URLWithString:trimmed];
        if (url && url.scheme && url.host) {
            [urls addObject:url];
            NSLog(@"✅ Loaded dashboard: %@", url);
        } else {
            NSLog(@"⚠️ Skipping invalid URL: %@", trimmed);
        }
    }

    // Update state with loaded URLs
    self.dashboardURLs = [urls copy];
    self.isRotating = NO;
    self.currentIndex = 0;
    [self updateButtonStates];

    // Update status and load first dashboard
    if (self.dashboardURLs.count > 0) {
        // Save loaded URLs to storage (convert NSURL to NSString)
        NSMutableArray<NSString *> *urlStrings = [NSMutableArray arrayWithCapacity:urls.count];
        for (NSURL *url in urls) {
            [urlStrings addObject:url.absoluteString];
        }
        self.storedURLStrings = urlStrings;
        [self saveStoredURLs];

        NSString *status = [NSString stringWithFormat:@"Loaded %ld dashboard%@ from remote URL",
                           (long)self.dashboardURLs.count,
                           self.dashboardURLs.count == 1 ? @"" : @"s"];
        [self updateStatusLabel:status];
        [self loadCurrentDashboard];
        NSLog(@"✅ Successfully loaded %ld dashboards from remote URL", (long)self.dashboardURLs.count);

        // Show success dialog
        NSAlert *successAlert = [[NSAlert alloc] init];
        successAlert.messageText = @"Remote Config Loaded";
        successAlert.informativeText = [NSString stringWithFormat:@"Successfully loaded %ld dashboard URL%@ from remote configuration.\n\nURLs have been saved and will be available on next app start.", (long)self.dashboardURLs.count, self.dashboardURLs.count == 1 ? @"" : @"s"];
        successAlert.alertStyle = NSAlertStyleInformational;
        [successAlert runModal];
    } else {
        [self handleConfigError:@"No valid dashboard URLs found in configuration"];
        NSLog(@"⚠️ No valid URLs found in config");

        // Show error dialog
        NSAlert *errorAlert = [[NSAlert alloc] init];
        errorAlert.messageText = @"No Valid URLs";
        errorAlert.informativeText = @"The remote configuration file did not contain any valid dashboard URLs.";
        errorAlert.alertStyle = NSAlertStyleWarning;
        [errorAlert runModal];
    }
}

/// Handles configuration loading errors
- (void)handleConfigError:(NSString *)message {
    self.dashboardURLs = @[];
    self.isRotating = NO;
    [self updateButtonStates];
    [self updateStatusLabel:message];

    // Display error in web view
    NSString *html = [NSString stringWithFormat:
        @"<html><head><style>"
        "body { font-family: -apple-system; padding: 40px; text-align: center; }"
        "h2 { color: #ff3b30; }"
        "p { color: #666; }"
        "</style></head><body>"
        "<h2>⚠️ Configuration Error</h2>"
        "<p>%@</p>"
        "<p style='margin-top: 40px;'><small>Config URL: %@</small></p>"
        "</body></html>",
        message, self.configURL];

    [self.webView loadHTMLString:html baseURL:nil];
}

// MARK: - Dashboard Rotation

/// Loads the dashboard at the current index
- (void)loadCurrentDashboard {
    // Validate array bounds
    if (self.currentIndex < 0 || self.currentIndex >= self.dashboardURLs.count) {
        NSLog(@"❌ Invalid dashboard index: %ld", (long)self.currentIndex);
        return;
    }

    NSURL *url = self.dashboardURLs[self.currentIndex];
    NSString *status = [NSString stringWithFormat:@"Loading dashboard %ld of %ld: %@",
                       (long)(self.currentIndex + 1),
                       (long)self.dashboardURLs.count,
                       url.host ?: url.absoluteString];
    [self updateStatusLabel:status];

    NSLog(@"📄 Loading dashboard %ld: %@", (long)self.currentIndex, url);

    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
}

/// Rotates to the next dashboard in the sequence
- (void)rotateToNextDashboard {
    // Check if rotation was stopped
    if (!self.isRotating || self.dashboardURLs.count == 0) {
        NSLog(@"⏹ Rotation stopped or no dashboards");
        return;
    }

    // Load current dashboard
    [self loadCurrentDashboard];

    // Wait for page to load, then scroll
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pageLoadDelay * NSEC_PER_SEC)),
                  dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.isRotating) return;

        [strongSelf scrollCurrentDashboard];

        // After scroll completes + delay, move to next dashboard
        NSTimeInterval totalDelay = strongSelf.scrollDuration + strongSelf.postScrollDelay;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(totalDelay * NSEC_PER_SEC)),
                      dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || !strongSelf.isRotating || strongSelf.dashboardURLs.count == 0) return;

            // Move to next dashboard (wrap around to start)
            strongSelf.currentIndex = (strongSelf.currentIndex + 1) % strongSelf.dashboardURLs.count;
            [strongSelf rotateToNextDashboard];
        });
    });
}

/// Smoothly scrolls the current dashboard from top to bottom
- (void)scrollCurrentDashboard {
    if (!self.isRotating) return;

    NSLog(@"📜 Scrolling dashboard over %.1f seconds", self.scrollDuration);
    [self updateStatusLabel:[NSString stringWithFormat:@"Scrolling dashboard %ld of %ld...",
                           (long)(self.currentIndex + 1),
                           (long)self.dashboardURLs.count]];

    // JavaScript to perform smooth scroll animation
    NSString *javascript = [NSString stringWithFormat:
        @"(function() {"
        "  try {"
        "    var totalHeight = Math.max("
        "      document.body.scrollHeight,"
        "      document.body.offsetHeight,"
        "      document.documentElement.clientHeight,"
        "      document.documentElement.scrollHeight,"
        "      document.documentElement.offsetHeight"
        "    ) - window.innerHeight;"
        "    "
        "    if (totalHeight <= 0) {"
        "      console.log('Page is not scrollable');"
        "      return;"
        "    }"
        "    "
        "    var duration = %.0f;"  // Duration in milliseconds
        "    var start = window.scrollY || window.pageYOffset;"
        "    var startTime = performance.now();"
        "    "
        "    function easeInOutQuad(t) {"
        "      return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;"
        "    }"
        "    "
        "    function step(now) {"
        "      var elapsed = now - startTime;"
        "      var progress = Math.min(elapsed / duration, 1);"
        "      var eased = easeInOutQuad(progress);"
        "      window.scrollTo(0, start + totalHeight * eased);"
        "      "
        "      if (progress < 1) {"
        "        requestAnimationFrame(step);"
        "      } else {"
        "        console.log('Scroll complete');"
        "      }"
        "    }"
        "    "
        "    requestAnimationFrame(step);"
        "  } catch(e) {"
        "    console.error('Scroll error:', e);"
        "  }"
        "})();",
        self.scrollDuration * 1000.0  // Convert to milliseconds
    ];

    // Execute JavaScript with error handling
    [self.webView evaluateJavaScript:javascript completionHandler:^(id result, NSError *error) {
        if (error) {
            NSLog(@"⚠️ JavaScript error: %@", error.localizedDescription);
        }
    }];
}

// MARK: - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"✅ Page loaded successfully");
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"❌ Page load failed: %@", error.localizedDescription);
    [self updateStatusLabel:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"❌ Page load failed (provisional): %@", error.localizedDescription);
    [self updateStatusLabel:[NSString stringWithFormat:@"Failed to load: %@", error.localizedDescription]];
}

// MARK: - Settings Management

/// Load settings from UserDefaults
- (void)loadSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // Load scroll duration (default to kDefaultScrollDuration if not set)
    if ([defaults objectForKey:kScrollDurationKey]) {
        self.scrollDuration = [defaults doubleForKey:kScrollDurationKey];
    } else {
        self.scrollDuration = kDefaultScrollDuration;
    }

    // Load page load delay
    if ([defaults objectForKey:kPageLoadDelayKey]) {
        self.pageLoadDelay = [defaults doubleForKey:kPageLoadDelayKey];
    } else {
        self.pageLoadDelay = kDefaultPageLoadDelay;
    }

    // Load post-scroll delay
    if ([defaults objectForKey:kPostScrollDelayKey]) {
        self.postScrollDelay = [defaults doubleForKey:kPostScrollDelayKey];
    } else {
        self.postScrollDelay = kDefaultPostScrollDelay;
    }

    NSLog(@"✅ Loaded settings - scroll: %.1fs, load delay: %.1fs, post delay: %.1fs",
          self.scrollDuration, self.pageLoadDelay, self.postScrollDelay);
}

/// Save settings to UserDefaults
- (void)saveSettings {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:self.scrollDuration forKey:kScrollDurationKey];
    [defaults setDouble:self.pageLoadDelay forKey:kPageLoadDelayKey];
    [defaults setDouble:self.postScrollDelay forKey:kPostScrollDelayKey];
    [defaults synchronize];
    NSLog(@"💾 Settings saved");
}

// MARK: - URL Storage Management

/// Load stored URLs from UserDefaults
- (void)loadStoredURLs {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *stored = [defaults arrayForKey:kStoredURLsKey];

    if (stored) {
        self.storedURLStrings = [stored mutableCopy];
    } else {
        self.storedURLStrings = [NSMutableArray array];
    }

    NSLog(@"✅ Loaded %ld stored URLs", (long)self.storedURLStrings.count);
}

/// Save stored URLs to UserDefaults
- (void)saveStoredURLs {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.storedURLStrings forKey:kStoredURLsKey];
    [defaults synchronize];
    NSLog(@"💾 Saved %ld URLs", (long)self.storedURLStrings.count);
}

/// Load URLs from the stored strings array
- (void)loadURLsFromStoredStrings {
    NSMutableArray<NSURL *> *urls = [NSMutableArray array];

    for (NSString *urlString in self.storedURLStrings) {
        NSURL *url = [NSURL URLWithString:urlString];
        if (url && (url.scheme && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"]))) {
            [urls addObject:url];
        } else {
            NSLog(@"⚠️ Skipping invalid stored URL: %@", urlString);
        }
    }

    self.dashboardURLs = [urls copy];
    [self updateButtonStates];
    [self updateStatusLabel:[NSString stringWithFormat:@"Loaded %ld dashboards from storage", (long)self.dashboardURLs.count]];
    NSLog(@"✅ Loaded %ld valid URLs from storage", (long)self.dashboardURLs.count);
}

// MARK: - Menu Management

/// Create application menus
- (void)createMenus {
    NSMenu *mainMenu = [[NSMenu alloc] init];

    // App Menu (first menu)
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [mainMenu addItem:appMenuItem];

    NSMenu *appMenu = [[NSMenu alloc] init];
    [appMenuItem setSubmenu:appMenu];

    [appMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Quit Dashboard Rotator" action:@selector(terminate:) keyEquivalent:@"q"]];

    // File Menu
    NSMenuItem *fileMenuItem = [[NSMenuItem alloc] initWithTitle:@"File" action:nil keyEquivalent:@""];
    [mainMenu addItem:fileMenuItem];

    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    [fileMenuItem setSubmenu:fileMenu];

    [fileMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Load CSV File..." action:@selector(loadCSVFile:) keyEquivalent:@"o"]];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    [fileMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Close Window" action:@selector(performClose:) keyEquivalent:@"w"]];

    // URLs Menu
    NSMenuItem *urlsMenuItem = [[NSMenuItem alloc] initWithTitle:@"URLs" action:nil keyEquivalent:@""];
    [mainMenu addItem:urlsMenuItem];

    NSMenu *urlsMenu = [[NSMenu alloc] initWithTitle:@"URLs"];
    [urlsMenuItem setSubmenu:urlsMenu];

    [urlsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Add URL..." action:@selector(addURL:) keyEquivalent:@"n"]];
    [urlsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Manage URLs..." action:@selector(manageURLs:) keyEquivalent:@"m"]];
    [urlsMenu addItem:[NSMenuItem separatorItem]];
    [urlsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Load from Remote URL..." action:@selector(showRemoteConfigDialog:) keyEquivalent:@""]];
    [urlsMenu addItem:[NSMenuItem separatorItem]];
    [urlsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Clear All URLs" action:@selector(clearAllURLs:) keyEquivalent:@""]];

    // Settings Menu
    NSMenuItem *settingsMenuItem = [[NSMenuItem alloc] initWithTitle:@"Settings" action:nil keyEquivalent:@""];
    [mainMenu addItem:settingsMenuItem];

    NSMenu *settingsMenu = [[NSMenu alloc] initWithTitle:@"Settings"];
    [settingsMenuItem setSubmenu:settingsMenu];

    [settingsMenu addItem:[[NSMenuItem alloc] initWithTitle:@"Adjust Timing..." action:@selector(showTimingSettings:) keyEquivalent:@","]];

    // Set the menu
    [NSApp setMainMenu:mainMenu];

    NSLog(@"✅ Menus created");
}

// MARK: - Menu Actions

/// Load CSV file with URLs
- (void)loadCSVFile:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.canChooseFiles = YES;
    openPanel.canChooseDirectories = NO;
    openPanel.allowsMultipleSelection = NO;
    if (@available(macOS 11.0, *)) {
        openPanel.allowedContentTypes = @[[UTType typeWithFilenameExtension:@"csv"], [UTType typeWithFilenameExtension:@"txt"]];
    } else {
        openPanel.allowedFileTypes = @[@"csv", @"txt"];
    }
    openPanel.message = @"Select a CSV file with dashboard URLs (one per line)";

    [openPanel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSURL *fileURL = openPanel.URL;
            [self parseCSVFile:fileURL];
        }
    }];
}

/// Parse CSV file and load URLs
- (void)parseCSVFile:(NSURL *)fileURL {
    NSError *error = nil;
    NSString *content = [NSString stringWithContentsOfURL:fileURL encoding:NSUTF8StringEncoding error:&error];

    if (error) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Error Reading File";
        alert.informativeText = [NSString stringWithFormat:@"Failed to read CSV file: %@", error.localizedDescription];
        alert.alertStyle = NSAlertStyleWarning;
        [alert runModal];
        NSLog(@"❌ Error reading CSV file: %@", error);
        return;
    }

    // Handle empty file
    if (content.length == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Empty File";
        alert.informativeText = @"The selected file is empty";
        alert.alertStyle = NSAlertStyleWarning;
        [alert runModal];
        return;
    }

    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray<NSString *> *newURLs = [NSMutableArray array];
    NSMutableArray<NSString *> *skippedLines = [NSMutableArray array];
    NSInteger lineNumber = 0;

    for (NSString *line in lines) {
        lineNumber++;
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // Skip empty lines and comments
        if (trimmed.length == 0 || [trimmed hasPrefix:@"#"]) {
            continue;
        }

        // Remove quotes if present (handle both single and double quotes)
        if (([trimmed hasPrefix:@"\""] && [trimmed hasSuffix:@"\""]) ||
            ([trimmed hasPrefix:@"'"] && [trimmed hasSuffix:@"'"])) {
            if (trimmed.length >= 2) {
                trimmed = [trimmed substringWithRange:NSMakeRange(1, trimmed.length - 2)];
            }
        }

        // Trim again after removing quotes
        trimmed = [trimmed stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        // Validate URL
        NSURL *url = [NSURL URLWithString:trimmed];
        if (url && url.scheme && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"])) {
            // Check for duplicate before adding
            if (![newURLs containsObject:trimmed]) {
                [newURLs addObject:trimmed];
            } else {
                NSLog(@"⚠️ Skipping duplicate URL on line %ld: %@", (long)lineNumber, trimmed);
            }
        } else {
            [skippedLines addObject:[NSString stringWithFormat:@"Line %ld: %@", (long)lineNumber, trimmed.length > 50 ? [trimmed substringToIndex:50] : trimmed]];
            NSLog(@"⚠️ Skipping invalid URL on line %ld: %@", (long)lineNumber, trimmed);
        }
    }

    if (newURLs.count > 0) {
        self.storedURLStrings = newURLs;
        [self saveStoredURLs];
        [self loadURLsFromStoredStrings];

        NSMutableString *message = [NSMutableString stringWithFormat:@"Successfully loaded %ld URL%@ from CSV file", (long)newURLs.count, newURLs.count == 1 ? @"" : @"s"];
        if (skippedLines.count > 0) {
            [message appendFormat:@"\n\n%ld line%@ skipped (invalid URLs)", (long)skippedLines.count, skippedLines.count == 1 ? @"" : @"s"];
        }

        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"CSV Loaded";
        alert.informativeText = message;
        alert.alertStyle = NSAlertStyleInformational;
        [alert runModal];

        NSLog(@"✅ Loaded %ld URLs from CSV file (%ld skipped)", (long)newURLs.count, (long)skippedLines.count);
    } else {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"No Valid URLs";
        alert.informativeText = @"The CSV file did not contain any valid URLs.\n\nEach line should be a complete URL starting with http:// or https://";
        alert.alertStyle = NSAlertStyleWarning;
        [alert runModal];
        NSLog(@"⚠️ No valid URLs found in CSV file");
    }
}

/// Add a single URL
- (void)addURL:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Add Dashboard URL";
    alert.informativeText = @"Enter the complete URL of the dashboard:";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"Add"];
    [alert addButtonWithTitle:@"Cancel"];

    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 350, 24)];
    input.placeholderString = @"https://example.com/dashboard";
    alert.accessoryView = input;

    [alert.window setInitialFirstResponder:input];

    NSModalResponse response = [alert runModal];

    if (response == NSAlertFirstButtonReturn) {
        NSString *urlString = [input.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if (urlString.length == 0) {
            NSAlert *errorAlert = [[NSAlert alloc] init];
            errorAlert.messageText = @"Empty URL";
            errorAlert.informativeText = @"Please enter a URL";
            errorAlert.alertStyle = NSAlertStyleWarning;
            [errorAlert runModal];
            return;
        }

        NSURL *url = [NSURL URLWithString:urlString];
        if (url && url.scheme && ([url.scheme isEqualToString:@"http"] || [url.scheme isEqualToString:@"https"])) {
            // Check for duplicate
            if ([self.storedURLStrings containsObject:urlString]) {
                NSAlert *errorAlert = [[NSAlert alloc] init];
                errorAlert.messageText = @"Duplicate URL";
                errorAlert.informativeText = @"This URL is already in your dashboard list";
                errorAlert.alertStyle = NSAlertStyleWarning;
                [errorAlert runModal];
                NSLog(@"⚠️ Attempted to add duplicate URL: %@", urlString);
                return;
            }

            [self.storedURLStrings addObject:urlString];
            [self saveStoredURLs];
            [self loadURLsFromStoredStrings];

            NSAlert *successAlert = [[NSAlert alloc] init];
            successAlert.messageText = @"URL Added";
            successAlert.informativeText = [NSString stringWithFormat:@"Successfully added dashboard URL.\n\nYou now have %ld URL%@ in your list.", (long)self.storedURLStrings.count, self.storedURLStrings.count == 1 ? @"" : @"s"];
            successAlert.alertStyle = NSAlertStyleInformational;
            [successAlert runModal];

            NSLog(@"✅ Added URL: %@", urlString);
        } else {
            NSAlert *errorAlert = [[NSAlert alloc] init];
            errorAlert.messageText = @"Invalid URL";
            errorAlert.informativeText = @"Please enter a valid HTTP or HTTPS URL.\n\nExample: https://example.com/dashboard";
            errorAlert.alertStyle = NSAlertStyleWarning;
            [errorAlert runModal];
            NSLog(@"⚠️ Attempted to add invalid URL: %@", urlString);
        }
    }
}

/// Show URL management window
- (void)manageURLs:(id)sender {
    if (self.storedURLStrings.count == 0) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"No URLs Stored";
        alert.informativeText = @"You don't have any dashboard URLs yet. Use \"Add URL...\" or \"Load CSV File...\" to add some.";
        alert.alertStyle = NSAlertStyleInformational;
        [alert runModal];
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Manage URLs";
    alert.informativeText = [NSString stringWithFormat:@"You have %ld stored URL%@", (long)self.storedURLStrings.count, self.storedURLStrings.count == 1 ? @"" : @"s"];
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"OK"];

    // Create a table view to show URLs
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 450, 250)];
    NSTableView *tableView = [[NSTableView alloc] initWithFrame:scrollView.bounds];
    tableView.usesAlternatingRowBackgroundColors = YES;
    tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask;

    NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:@"url"];
    column.title = @"Dashboard URLs";
    column.width = 430;
    [tableView addTableColumn:column];

    tableView.dataSource = (id<NSTableViewDataSource>)self;
    scrollView.documentView = tableView;
    scrollView.hasVerticalScroller = YES;

    alert.accessoryView = scrollView;

    // Force table to reload data
    [tableView reloadData];

    [alert runModal];
}

/// Clear all stored URLs
- (void)clearAllURLs:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Clear All URLs?";
    alert.informativeText = [NSString stringWithFormat:@"This will delete all %ld stored dashboard URLs. This action cannot be undone.", (long)self.storedURLStrings.count];
    alert.alertStyle = NSAlertStyleWarning;
    [alert addButtonWithTitle:@"Clear All"];
    [alert addButtonWithTitle:@"Cancel"];

    NSModalResponse response = [alert runModal];

    if (response == NSAlertFirstButtonReturn) {
        [self.storedURLStrings removeAllObjects];
        [self saveStoredURLs];
        self.dashboardURLs = @[];
        [self updateButtonStates];
        [self updateStatusLabel:@"All URLs cleared"];
        NSLog(@"🗑 Cleared all stored URLs");
    }
}

/// Show timing settings dialog
- (void)showTimingSettings:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Timing Settings";
    alert.informativeText = @"Adjust rotation timing parameters:";
    alert.alertStyle = NSAlertStyleInformational;
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Cancel"];

    // Create form
    NSView *formView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 320, 120)];

    // Scroll Duration
    NSTextField *scrollLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 90, 180, 20)];
    scrollLabel.stringValue = @"Scroll Duration (5-30s):";
    scrollLabel.editable = NO;
    scrollLabel.bordered = NO;
    scrollLabel.drawsBackground = NO;
    [formView addSubview:scrollLabel];

    NSTextField *scrollField = [[NSTextField alloc] initWithFrame:NSMakeRect(185, 90, 135, 24)];
    scrollField.doubleValue = self.scrollDuration;
    scrollField.placeholderString = [NSString stringWithFormat:@"%.1f", kDefaultScrollDuration];
    [formView addSubview:scrollField];

    // Page Load Delay
    NSTextField *loadLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 60, 180, 20)];
    loadLabel.stringValue = @"Page Load Delay (0.5-10s):";
    loadLabel.editable = NO;
    loadLabel.bordered = NO;
    loadLabel.drawsBackground = NO;
    [formView addSubview:loadLabel];

    NSTextField *loadField = [[NSTextField alloc] initWithFrame:NSMakeRect(185, 60, 135, 24)];
    loadField.doubleValue = self.pageLoadDelay;
    loadField.placeholderString = [NSString stringWithFormat:@"%.1f", kDefaultPageLoadDelay];
    [formView addSubview:loadField];

    // Post-Scroll Delay
    NSTextField *postLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 30, 180, 20)];
    postLabel.stringValue = @"Post-Scroll Delay (1-60s):";
    postLabel.editable = NO;
    postLabel.bordered = NO;
    postLabel.drawsBackground = NO;
    [formView addSubview:postLabel];

    NSTextField *postField = [[NSTextField alloc] initWithFrame:NSMakeRect(185, 30, 135, 24)];
    postField.doubleValue = self.postScrollDelay;
    postField.placeholderString = [NSString stringWithFormat:@"%.1f", kDefaultPostScrollDelay];
    [formView addSubview:postField];

    // Current values label
    NSTextField *currentLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 320, 20)];
    currentLabel.stringValue = @"Current values shown above";
    currentLabel.editable = NO;
    currentLabel.bordered = NO;
    currentLabel.drawsBackground = NO;
    currentLabel.textColor = [NSColor secondaryLabelColor];
    currentLabel.font = [NSFont systemFontOfSize:10];
    [formView addSubview:currentLabel];

    alert.accessoryView = formView;

    NSModalResponse response = [alert runModal];

    if (response == NSAlertFirstButtonReturn) {
        double newScroll = scrollField.doubleValue;
        double newLoad = loadField.doubleValue;
        double newPost = postField.doubleValue;

        // Track which values were changed
        BOOL hasChanges = NO;
        NSMutableString *invalidValues = [NSMutableString string];

        // Validate and update scroll duration
        if (newScroll >= kMinScrollDuration && newScroll <= kMaxScrollDuration) {
            if (fabs(self.scrollDuration - newScroll) > 0.01) {
                self.scrollDuration = newScroll;
                self.durationSlider.doubleValue = newScroll;
                hasChanges = YES;
            }
        } else if (newScroll != 0) {  // 0 means field was cleared
            [invalidValues appendFormat:@"Scroll Duration (%.1f) must be between %.1f and %.1f seconds\n", newScroll, kMinScrollDuration, kMaxScrollDuration];
        }

        // Validate and update page load delay
        if (newLoad >= kMinPageLoadDelay && newLoad <= kMaxPageLoadDelay) {
            if (fabs(self.pageLoadDelay - newLoad) > 0.01) {
                self.pageLoadDelay = newLoad;
                hasChanges = YES;
            }
        } else if (newLoad != 0) {
            [invalidValues appendFormat:@"Page Load Delay (%.1f) must be between %.1f and %.1f seconds\n", newLoad, kMinPageLoadDelay, kMaxPageLoadDelay];
        }

        // Validate and update post-scroll delay
        if (newPost >= kMinPostScrollDelay && newPost <= kMaxPostScrollDelay) {
            if (fabs(self.postScrollDelay - newPost) > 0.01) {
                self.postScrollDelay = newPost;
                hasChanges = YES;
            }
        } else if (newPost != 0) {
            [invalidValues appendFormat:@"Post-Scroll Delay (%.1f) must be between %.1f and %.1f seconds", newPost, kMinPostScrollDelay, kMaxPostScrollDelay];
        }

        // Show feedback
        if (invalidValues.length > 0) {
            NSAlert *warningAlert = [[NSAlert alloc] init];
            warningAlert.messageText = @"Invalid Values";
            warningAlert.informativeText = invalidValues;
            warningAlert.alertStyle = NSAlertStyleWarning;
            [warningAlert runModal];
        }

        if (hasChanges) {
            [self saveSettings];
            [self updateDurationLabel];
            [self updateStatusLabel:@"Settings updated"];
            NSLog(@"✅ Timing settings updated: scroll=%.1fs, load=%.1fs, post=%.1fs", self.scrollDuration, self.pageLoadDelay, self.postScrollDelay);
        } else if (invalidValues.length == 0) {
            [self updateStatusLabel:@"No changes made"];
        }
    }
}

// MARK: - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.storedURLStrings.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (row < self.storedURLStrings.count) {
        return self.storedURLStrings[row];
    }
    return nil;
}

@end
