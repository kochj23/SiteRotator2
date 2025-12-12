# Site Rotator 2.0 - Dashboard Rotator

A macOS application for automatically cycling through multiple web dashboards with smooth scrolling. Perfect for displaying rotating dashboards on large screens, monitoring walls, or information displays.

## Features

- 🔄 **Automatic Rotation** - Cycles through multiple dashboards continuously
- 📜 **Smooth Scrolling** - Animated scroll from top to bottom of each page
- ⚙️ **Configurable Timing** - Adjust scroll speed, load delays, and post-scroll delays
- 📁 **CSV File Support** - Load dashboard URLs from CSV files with drag & drop
- 💾 **Persistent Storage** - URLs are saved and restored automatically on app restart
- 🎛️ **Menu-Driven Management** - Add, view, and manage URLs through intuitive menus
- 🌐 **Multiple Input Methods** - Load from CSV, add URLs individually, or use remote config
- 🛑 **Start/Stop Control** - Pause and resume rotation at any time
- 📊 **Status Updates** - Real-time display of current dashboard and progress
- 🔒 **Secure** - HTTPS enforcement for configuration URLs
- 💬 **Error Handling** - Clear error messages and recovery options

## Requirements

- macOS 10.13 (High Sierra) or later
- Internet connection for loading dashboards
- HTTPS-accessible configuration file

## Installation

1. Open `Site Rotator 2.0.xcodeproj` in Xcode
2. Build and run the application (⌘R)
3. The application will open and automatically load the default configuration

## Quick Start

### Method 1: Load from CSV File
1. **Launch the app**
2. **Go to File > Load CSV File...** (or press ⌘O)
3. Select a CSV file containing dashboard URLs (one per line)
4. **Click "Start"** to begin rotation
5. URLs are automatically saved for next app launch

### Method 2: Add URLs Manually
1. **Launch the app**
2. **Go to URLs > Add URL...** (or press ⌘N)
3. Enter a dashboard URL
4. Repeat to add more URLs
5. **Click "Start"** to begin rotation

### Method 3: Use Remote Configuration (Legacy)
1. **Launch the app** - If you have no stored URLs, it loads from the default remote config
2. **Click "Reload Config"** - Fetches the latest dashboard list from the remote URL

### Common Operations
- **Adjust scroll duration** - Use the slider to change how long each scroll takes (5-30 seconds)
- **Click "Stop"** - Pauses the rotation at any time
- **Settings > Adjust Timing...** - Configure all timing parameters (scroll speed, delays)

## Configuration

### CSV File Format

The simplest way to configure dashboards is using a CSV file:

```csv
https://dashboard1.example.com
https://dashboard2.example.com
https://metrics.company.com/realtime
# Comments are supported
"https://url-with-special-characters.com/path?param=value"
https://status.example.com
```

**CSV File Rules:**
- ✅ One URL per line
- ✅ URLs can be quoted with double quotes (for special characters)
- ✅ Lines starting with `#` are treated as comments
- ✅ Empty lines are ignored
- ✅ URLs must include `http://` or `https://`
- ❌ Invalid URLs are skipped with a warning

### URL Management

**Add URLs via Menu:**
1. Go to **URLs > Add URL...** (⌘N)
2. Enter the complete URL
3. Click "Add"
4. URLs are automatically saved

**View All URLs:**
- Go to **URLs > Manage URLs...** (⌘M)
- See a list of all stored dashboard URLs

**Clear All URLs:**
- Go to **URLs > Clear All URLs**
- Confirms before deleting all stored URLs

### Persistent Storage

All URLs added through the app or loaded from CSV files are automatically saved using macOS UserDefaults. They will be restored when you restart the application.

To reset: Use **URLs > Clear All URLs** or delete the app's preferences:
```bash
defaults delete Koch.Site-Rotator-2-0
```

### Remote Configuration (Legacy)

For backwards compatibility, you can still use remote configuration files:

1. Create a text file with your dashboard URLs (one per line)
2. Host it on a web server with HTTPS
3. Update the configuration URL in the code:

```objective-c
// In ViewController.m, line 162:
self.configURL = @"https://your-domain.com/dashboards.txt";
```

The app will only use the remote config if no URLs are stored locally.

## How It Works

### Rotation Cycle

For each dashboard in the configuration:

1. **Load** (0.5-10 seconds, default 2s) - Page is loaded and rendered
2. **Scroll** (5-30 seconds, default 10s) - Smooth animated scroll from top to bottom
3. **Dwell** (1-60 seconds, default 20s) - View the bottom of the page
4. **Next** - Move to the next dashboard and repeat

### Timing Settings

All timing parameters can be adjusted through the **Settings > Adjust Timing...** menu (⌘,):

**Scroll Duration (5-30 seconds)**
- How long the smooth scroll animation takes
- Also adjustable via the slider in the main window
- Default: 10 seconds

**Page Load Delay (0.5-10 seconds)**
- Wait time after loading a page before starting scroll
- Allows page content to fully render
- Default: 2 seconds

**Post-Scroll Delay (1-60 seconds)**
- Wait time at the bottom of the page before moving to next dashboard
- Gives time to view the full content
- Default: 20 seconds

All settings are automatically saved and restored on app restart.

## User Interface

### Controls

- **Start Button** - Begins dashboard rotation
- **Stop Button** - Pauses rotation (enabled only when rotating)
- **Reload Config Button** - Fetches the latest dashboard list
- **Duration Slider** - Adjusts scroll duration (5-30 seconds)
- **Status Label** - Shows current operation and progress

### Application Menus

**File Menu**
- **Load CSV File...** (⌘O) - Import dashboard URLs from a CSV file
- **Close Window** (⌘W) - Close the application window

**URLs Menu**
- **Add URL...** (⌘N) - Add a single dashboard URL
- **Manage URLs...** (⌘M) - View all stored URLs in a list
- **Clear All URLs** - Delete all stored URLs (with confirmation)

**Settings Menu**
- **Adjust Timing...** (⌘,) - Configure all timing parameters (scroll duration, load delay, post-scroll delay)

### Status Messages

The status label displays helpful information:

- `Ready to load dashboards` - Initial state
- `Loaded X dashboards from storage` - Restored URLs from previous session
- `Loading dashboard configuration...` - Fetching remote config
- `Loaded X dashboards` - Configuration loaded successfully
- `Loading dashboard X of Y: domain.com` - Loading a dashboard
- `Scrolling dashboard X of Y...` - Scrolling in progress
- `Rotation stopped` - Rotation paused by user
- `Settings updated` - Timing settings saved
- `All URLs cleared` - URL storage cleared
- Error messages when issues occur

## Troubleshooting

### Configuration Not Loading

**Problem:** "Network error loading config" or "HTTP XXX: Failed to load config"

**Solutions:**
- Verify the configuration URL is accessible in a web browser
- Ensure the URL uses HTTPS (not HTTP)
- Check your internet connection
- Verify the server is online and responding

### Invalid URLs in Config

**Problem:** Some dashboards don't load

**Solutions:**
- Check the console log for "⚠️ Skipping invalid URL" messages
- Ensure URLs include the protocol (`https://`)
- Verify URLs are correctly formatted
- Test URLs in a web browser

### Page Not Scrolling

**Problem:** Dashboard loads but doesn't scroll

**Solutions:**
- Page may not be tall enough to scroll
- Check console for "Page is not scrollable" message
- Some pages prevent scrolling via JavaScript
- Try a different dashboard

### Rotation Stops Unexpectedly

**Problem:** Rotation stops after one or two dashboards

**Solutions:**
- Check console logs for error messages
- Network issues may cause failures
- Click "Reload Config" to refresh
- Verify all URLs in config are accessible

## Console Logging

The application provides detailed logging with emoji indicators:

- ✅ Success messages (green checkmark)
- ❌ Error messages (red X)
- ⚠️ Warning messages (yellow warning)
- 🌐 Network operations
- 📄 Page loading
- 📜 Scrolling operations
- ▶️ Start/stop actions

View logs in Xcode's console or Console.app when running the built application.

## Development

### Project Structure

```
Site Rotator 2.0/
├── Site Rotator 2.0/
│   ├── AppDelegate.h/m          # Application delegate
│   ├── ViewController.h/m       # Main view controller (core logic)
│   ├── main.m                   # Application entry point
│   └── Info.plist              # Application metadata
└── Site Rotator 2.0.xcodeproj  # Xcode project
```

### Key Components

**ViewController.m**
- Configuration loading and parsing
- Dashboard rotation logic
- Smooth scroll implementation
- Error handling
- UI management

**AppDelegate.m**
- Window creation and configuration
- Application lifecycle management

### Building from Source

```bash
cd "/Users/kochj/Desktop/xcode/Site Rotator 2.0"
xcodebuild -project "Site Rotator 2.0.xcodeproj" \
           -scheme "Site Rotator 2.0" \
           -destination 'platform=macOS' \
           build
```

### Running Tests

```bash
xcodebuild -project "Site Rotator 2.0.xcodeproj" \
           -scheme "Site Rotator 2.0" \
           -destination 'platform=macOS' \
           test
```

## Customization

### Window Size

Adjust in `AppDelegate.m`:

```objective-c
NSRect frame = NSMakeRect(0, 0, 1024, 700);  // Width x Height
```

Or in `ViewController.m` constants:

```objective-c
static const CGFloat kWindowWidth = 1024.0;
static const CGFloat kWindowHeight = 700.0;
```

### Scroll Animation

The scroll uses an easing function for smooth motion. To change the easing:

```javascript
// In ViewController.m, scrollCurrentDashboard method
function easeInOutQuad(t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
}
```

Available easing functions:
- Linear: `return t;`
- Ease In: `return t * t;`
- Ease Out: `return t * (2 - t);`
- Ease In Out (current): `return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;`

## Best Practices

### Dashboard Design

For best results with Site Rotator:

- ✅ Design dashboards with vertical scrolling in mind
- ✅ Use responsive designs that work at 1024px width
- ✅ Ensure content is readable from a distance
- ✅ Use high contrast colors
- ✅ Avoid time-sensitive content that expires quickly
- ❌ Avoid dashboards requiring user interaction
- ❌ Avoid pages with auto-refresh that might interfere

### Configuration Management

- Keep your configuration file under version control
- Use comments to document what each dashboard shows
- Test URLs before adding them to rotation
- Group related dashboards together
- Remove dashboards that are temporarily unavailable

### Display Setup

- Use a dedicated display or monitor
- Disable screen sleep in System Preferences
- Enable "Prevent sleep when display is off" if needed
- Consider using a presentation mode or kiosk mode
- Set display resolution to match dashboard designs

## Security Considerations

- Configuration URL must use HTTPS to prevent tampering
- Dashboard URLs are validated before loading
- The app enforces URL scheme and host validation
- No authentication credentials are stored or transmitted
- Network requests use standard URLSession security

## Performance

The application is optimized for:

- **Low memory usage** - Uses weak/strong references to prevent leaks
- **Efficient rendering** - WebKit handles page rendering
- **Smooth animations** - RequestAnimationFrame for 60fps scrolling
- **Network efficiency** - Cancels duplicate configuration requests

## Limitations

- Dashboards must be web-based (no native apps)
- Requires internet connectivity
- Configuration file must be HTTPS-accessible
- Scroll speed limited to 5-30 seconds
- No authentication for private dashboards (use VPN if needed)
- WebView may not support all modern web features

## Support

For issues, suggestions, or contributions:

1. Check the console logs for detailed error messages
2. Review the Troubleshooting section above
3. Verify your configuration file is correctly formatted
4. Test individual dashboard URLs in a web browser

## License

Copyright © 2024. All rights reserved.

## Changelog

### Version 2.1 (Current)

- ✨ **CSV File Support** - Load dashboard URLs from CSV files with drag & drop
- ✨ **Persistent Storage** - URLs automatically saved and restored using UserDefaults
- ✨ **Menu-Driven Management** - Add, view, and manage URLs through intuitive menus
- ✨ **Configurable Timing** - Adjust all timing parameters (scroll speed, load delay, post-scroll delay)
- ✨ **Multiple Input Methods** - CSV files, manual URL entry, or remote configuration
- ✨ **URL Management Menu** - Add URL (⌘N), Manage URLs (⌘M), Clear All URLs
- ✨ **Settings Menu** - Adjust Timing dialog (⌘,) for all timing parameters
- ✨ **File Menu** - Load CSV File (⌘O) with automatic quote handling
- 💾 All settings persist across app restarts
- 📝 Updated documentation with new features

### Version 2.0

- ✨ Complete rewrite with improved error handling
- ✨ Added Stop button for better control
- ✨ Added real-time status updates
- ✨ Implemented HTTPS enforcement
- ✨ Added comprehensive logging
- ✨ Improved scroll animation with easing
- ✨ Better memory management
- ✨ Added URL validation
- ✨ Support for comments in configuration
- ✨ Enhanced error messages
- 🐛 Fixed potential memory leaks
- 🐛 Fixed array bounds checking
- 🐛 Fixed configuration reload issues
- 📝 Added extensive code documentation
- 📝 Added this README
- 🧪 Added comprehensive unit tests (21 tests)

### Version 1.0

- Initial release
- Basic dashboard rotation
- Configuration from remote URL
- Adjustable scroll duration
