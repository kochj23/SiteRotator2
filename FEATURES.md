# Site Rotator 2.0 - Complete Features Documentation

## Overview

**Site Rotator 2.0** (Dashboard Rotator) is a macOS application that automatically cycles through multiple web dashboards with smooth scrolling and configurable timing. Perfect for monitoring displays, status boards, and information dashboards.

## Core Features

### 1. Automatic Dashboard Rotation

**Continuous Cycling**
- Automatically rotates through a list of dashboard URLs
- Smooth transitions between dashboards
- Configurable timing for each stage
- Start/Stop controls for manual override

**Smart Scrolling**
- Automatically scrolls down each dashboard
- Smooth, animated scrolling with easing
- Dynamically calculates page height
- Ensures entire dashboard content is viewed

### 2. URL Management

#### Load from Remote Configuration
- **Default URL**: `https://digitalnoise.net/dashboards.txt`
- **Custom Remote URLs**: Specify your own configuration file
- **Format**: One URL per line
- **Comments**: Lines starting with `#` are ignored
- **Auto-reload**: Can refresh configuration from remote

**Example dashboards.txt:**
```
# Production Dashboards
https://status.company.com/dashboard
https://metrics.company.com/overview
https://monitoring.company.com/live

# Analytics
https://analytics.company.com/realtime
```

#### Manual URL Entry
- Add individual URLs via menu
- Input dialog with validation
- HTTP/HTTPS URLs only
- Duplicate detection

#### CSV/Text File Import
- Load multiple URLs from local files
- Supports CSV and TXT formats
- One URL per line
- Quoted or unquoted URLs accepted
- Invalid URLs automatically filtered

#### URL List Management
- View all configured URLs
- Remove individual URLs
- Clear all URLs at once
- Persistent between app launches

### 3. Configurable Timing

#### Scroll Duration (5-30 seconds)
- **Purpose**: How long the dashboard scrolls
- **Default**: 10 seconds
- **Range**: 5 to 30 seconds
- **Control**: Slider in main window

**Use cases:**
- Short pages: 5-10 seconds
- Medium pages: 10-15 seconds
- Long pages: 15-30 seconds

#### Page Load Delay (0.5-10 seconds)
- **Purpose**: Wait time after loading before scrolling starts
- **Default**: 2 seconds
- **Range**: 0.5 to 10 seconds
- **Reason**: Allows page to fully load and render

**Recommended settings:**
- Fast loading pages: 0.5-1 second
- Standard pages: 2-3 seconds
- Heavy/slow pages: 5-10 seconds

#### Post-Scroll Delay (1-60 seconds)
- **Purpose**: Wait time after scrolling before switching dashboards
- **Default**: 20 seconds
- **Range**: 1 to 60 seconds
- **Reason**: Allows viewing bottom content

**Recommended settings:**
- Quick rotation: 5-10 seconds
- Standard viewing: 20-30 seconds
- Extended viewing: 40-60 seconds

### 4. User Interface

#### Main Window
- **Size**: 1024×700 pixels (default)
- **Minimum**: 800×600 pixels
- **Resizable**: Yes
- **Title**: "Dashboard Rotator"

#### Controls
- **Start Button**: Begin rotation cycle
- **Stop Button**: Pause rotation
- **Scroll Duration Slider**: Adjust scroll time (5-30s)
- **Status Label**: Shows current dashboard and state

#### Status Display
Shows current state:
- "Loading dashboard 1 of 5: [URL]"
- "Scrolling... (8s remaining)"
- "Viewing dashboard... (15s remaining)"
- "Rotation stopped"
- "No dashboards loaded"

### 5. Menu System

#### App Menu
- **About Dashboard Rotator**: App information
- **Quit Dashboard Rotator**: Exit application

#### File Menu
- **Load CSV File...**: Import URLs from file
- **Close Window**: Close main window (quits app)

#### URLs Menu
- **Add URL...**: Manually add single URL
- **Manage URLs...**: View and edit URL list
- **Load from Remote URL...**: Fetch from custom remote config
- **Clear All URLs**: Remove all configured URLs

#### Settings Menu
- **Adjust Timing...**: Configure all timing parameters
  - Scroll duration
  - Page load delay
  - Post-scroll delay

### 6. Persistence & Storage

**Saved Settings** (via UserDefaults):
- Scroll duration preference
- Page load delay
- Post-scroll delay
- Complete list of dashboard URLs
- Last used configuration

**Session Restoration**:
- URLs persist between app launches
- Timing settings remembered
- Last configuration restored on startup

### 7. Web Rendering

**Technology**: WKWebView (modern WebKit)
- Full HTML5/CSS3/JavaScript support
- Same rendering as Safari
- Hardware accelerated
- Secure sandboxed environment

**Capabilities**:
- Interactive dashboards
- Real-time data updates
- Animations and transitions
- WebSockets support
- Modern web standards

### 8. Scrolling Mechanism

**Custom JavaScript Implementation**:
- Smooth animated scrolling
- Easing function for natural movement
- Dynamic page height calculation
- Proportional scroll speed
- Frame-by-frame animation (60fps)

**Algorithm**:
1. Calculate total scrollable height
2. Determine scroll distance per frame
3. Apply easing function (ease-in-out)
4. Animate at 60fps for smooth motion
5. Complete scroll over configured duration

### 9. Error Handling & Validation

**URL Validation**:
- Must start with http:// or https://
- Valid URL format required
- Duplicate URLs rejected
- Empty URLs filtered out

**Network Error Handling**:
- Connection failures handled gracefully
- Timeout protection
- User-friendly error messages
- Automatic retry on next cycle

**Configuration Errors**:
- Invalid remote URLs detected
- Malformed CSV files handled
- Empty configuration files reported
- Logging for troubleshooting

### 10. Logging & Debugging

**Console Logging**:
- App lifecycle events (launch, terminate)
- Dashboard loading events
- Rotation state changes
- Timing adjustments
- Error conditions
- URL additions/removals

**Log Examples**:
```
✅ Dashboard Rotator window created
📊 Loaded 5 dashboards from remote config
▶️ Starting rotation with 5 dashboards
📄 Loading dashboard 1: https://status.company.com
⏸️ Rotation stopped by user
```

## Use Cases

### 1. Status Board Display
**Setup**:
- Multiple status dashboards
- 10-second scroll duration
- 20-second post-scroll delay
- Continuous rotation

**Perfect for**:
- NOC (Network Operations Center)
- Server monitoring rooms
- Customer support displays

### 2. Executive Dashboard
**Setup**:
- Business metrics dashboards
- 15-second scroll duration
- 30-second post-scroll delay
- Slow, deliberate rotation

**Perfect for**:
- Conference room displays
- Executive office screens
- Board meeting rooms

### 3. Development Team Display
**Setup**:
- CI/CD pipelines
- Build status
- Test results
- Code metrics
- 5-second scroll duration
- 10-second post-scroll delay

**Perfect for**:
- Dev team common areas
- Agile war rooms
- Sprint dashboards

### 4. Real-Time Monitoring
**Setup**:
- Live data feeds
- Real-time analytics
- Quick rotation (5s scroll, 5s delay)
- Many dashboards

**Perfect for**:
- Operations centers
- Security monitoring
- Traffic monitoring

## Technical Specifications

### System Requirements
- **OS**: macOS 10.13 (High Sierra) or later
- **Architecture**: Intel and Apple Silicon (Universal)
- **Network**: Internet connection for remote dashboards
- **Display**: 800×600 minimum resolution

### Performance
- **Memory**: Low memory footprint
- **CPU**: Minimal CPU usage during rotation
- **Network**: Bandwidth depends on dashboards
- **Refresh**: Page reloads on each cycle

### Security
- **Sandboxed**: Runs in secure sandbox
- **HTTPS**: Supports secure connections
- **No Storage**: Doesn't store dashboard data
- **Read-Only**: Doesn't modify remote content

### Networking
- **Protocol**: HTTPS/HTTP
- **Timeout**: Configurable page load timeout
- **Retry**: Automatic retry on network errors
- **Headers**: Standard browser headers

## Configuration Files

### Remote Configuration Format

**Location**: Any HTTPS/HTTP URL

**Format**: Plain text, one URL per line

**Example**:
```
# Comments start with #
# Production Monitoring
https://grafana.company.com/dashboard/prod
https://kibana.company.com/overview

# Development
https://jenkins.company.com/view/all
https://sonarqube.company.com/dashboard

# Analytics
https://analytics.company.com/realtime
```

**Rules**:
- One URL per line
- Blank lines ignored
- Lines starting with # are comments
- URLs must be valid HTTP/HTTPS
- No trailing spaces

### CSV Import Format

**Supported Extensions**: .csv, .txt

**Format**: One URL per line

**Example**:
```
https://dashboard1.com
https://dashboard2.com
https://dashboard3.com
```

**Or with quotes**:
```
"https://dashboard1.com"
"https://dashboard2.com"
"https://dashboard3.com"
```

## Keyboard Shortcuts

Currently, the app uses standard macOS shortcuts:
- **⌘Q**: Quit application
- **⌘W**: Close window (quits app)
- **⌘,**: Preferences (if implemented)

## Tips & Best Practices

### Optimal Dashboard Design

For best results with Site Rotator 2.0:

1. **Fixed Layout**: Use fixed-width dashboards
2. **Vertical Flow**: Design for vertical scrolling
3. **High Contrast**: Ensure readability from distance
4. **Auto-Refresh**: Dashboards should auto-update
5. **No Login**: Use public/token-based access

### Timing Recommendations

**Short Pages** (1-2 screens):
- Scroll: 5-8 seconds
- Load delay: 1-2 seconds
- Post-scroll: 10-15 seconds

**Medium Pages** (2-4 screens):
- Scroll: 10-15 seconds
- Load delay: 2-3 seconds
- Post-scroll: 20-30 seconds

**Long Pages** (4+ screens):
- Scroll: 20-30 seconds
- Load delay: 3-5 seconds
- Post-scroll: 30-60 seconds

### URL Management

**Organization**:
- Group related dashboards together
- Use remote config for team sharing
- Comment your configuration files
- Test URLs before adding to rotation

**Maintenance**:
- Regular cleanup of unused URLs
- Update remote configs centrally
- Monitor for broken links
- Version control your config files

## Troubleshooting

### Dashboards Not Loading
**Symptoms**: Blank screen, no content
**Solutions**:
- Check internet connection
- Verify URL is accessible in browser
- Increase page load delay
- Check for authentication requirements

### Scrolling Too Fast/Slow
**Symptoms**: Misses content or takes too long
**Solutions**:
- Adjust scroll duration slider
- Fine-tune in Settings → Adjust Timing
- Consider page length vs. scroll time
- Test with actual dashboards

### Rotation Stops
**Symptoms**: Gets stuck on one dashboard
**Solutions**:
- Check console logs for errors
- Verify all URLs are valid
- Restart rotation
- Check network connectivity

### High CPU/Memory Usage
**Symptoms**: Slow performance, fans spinning
**Solutions**:
- Reduce number of dashboards
- Simplify dashboard content
- Increase delays between rotations
- Close other applications

## Future Enhancements

Potential features for future versions:
- [ ] Fullscreen mode
- [ ] Multiple monitor support
- [ ] Keyboard shortcuts for rotation control
- [ ] Dashboard groups/categories
- [ ] Scheduled rotation (time-based)
- [ ] Custom scroll patterns (top to bottom, bottom to top)
- [ ] Dashboard health monitoring
- [ ] Rotation history/logs
- [ ] Dark mode support
- [ ] Touch Bar controls

## Version History

### v2.0 (Current)
- macOS application with AppKit
- WKWebView integration
- Custom smooth scrolling
- Remote configuration support
- CSV import capability
- Persistent settings
- **Fixed**: Secure state restoration warning

### v1.0
- Basic rotation functionality
- Manual URL management

## Support & Resources

### Console Logs
View detailed logs:
1. Open Console.app
2. Filter by "Site Rotator" or "Dashboard Rotator"
3. View startup, rotation, and error messages

### Configuration Testing
Test your remote configuration:
```bash
curl https://digitalnoise.net/dashboards.txt
```

Should return plain text with URLs.

## Summary

**Site Rotator 2.0** is a powerful, flexible dashboard rotation tool designed for unattended displays, monitoring rooms, and status boards. With configurable timing, multiple URL loading methods, smooth scrolling, and persistent settings, it provides a professional solution for cycling through web-based dashboards.

**Key Strengths**:
- ✅ Automatic rotation with smooth scrolling
- ✅ Multiple URL loading methods
- ✅ Highly configurable timing
- ✅ Persistent settings
- ✅ Modern WebKit rendering
- ✅ Professional logging
- ✅ User-friendly interface

**Perfect for organizations that need to display multiple dashboards on shared screens without manual intervention.**
