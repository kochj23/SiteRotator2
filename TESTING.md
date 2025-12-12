# Site Rotator 2.0 - Testing Guide

This document describes the testing strategy and how to run tests for Site Rotator 2.0.

## Test Coverage

The test suite covers:

- ✅ View controller initialization
- ✅ UI component creation
- ✅ URL validation and parsing
- ✅ Configuration file parsing
- ✅ Error handling (network, HTTP, empty configs)
- ✅ State management (rotation, button states)
- ✅ UI updates (labels, status messages)
- ✅ Edge cases (whitespace, comments, invalid URLs)
- ✅ Performance (large configurations)

## Running Tests

### From Xcode

1. Open `Site Rotator 2.0.xcodeproj` in Xcode
2. Select the test target: **Site Rotator 2.0 Tests**
3. Press `⌘U` or select **Product > Test** from the menu
4. View results in the Test Navigator (`⌘6`)

### From Command Line

```bash
cd "/Users/kochj/Desktop/xcode/Site Rotator 2.0"

# Run all tests
xcodebuild test \
  -project "Site Rotator 2.0.xcodeproj" \
  -scheme "Site Rotator 2.0" \
  -destination 'platform=macOS'

# Run specific test class
xcodebuild test \
  -project "Site Rotator 2.0.xcodeproj" \
  -scheme "Site Rotator 2.0" \
  -destination 'platform=macOS' \
  -only-testing:Site\ Rotator\ 2.0\ Tests/ViewControllerTests
```

## Test Structure

### ViewControllerTests.m

**Initialization Tests** (`testViewControllerInitialization`, `testUIComponentsCreation`)
- Verify view controller creates properly
- Check all UI components exist
- Validate initial state

**URL Validation Tests** (`testValidURLParsing`, `testInvalidURLsAreSkipped`, etc.)
- Test URL parsing from configuration
- Verify invalid URLs are filtered out
- Check comment and empty line handling

**Error Handling Tests** (`testNetworkErrorHandling`, `testHTTPErrorHandling`, etc.)
- Network error scenarios
- HTTP error codes (404, 500, etc.)
- Empty or malformed configurations

**State Management Tests** (`testRotationStateChanges`, `testButtonStatesWithoutURLs`, etc.)
- Rotation state changes
- Button enable/disable logic
- State consistency

**UI Update Tests** (`testDurationLabelUpdate`, `testStatusLabelUpdate`)
- Label text updates
- Nil handling

**Configuration Format Tests** (`testWhitespaceHandling`, `testMixedValidAndInvalidURLs`)
- Whitespace trimming
- Mixed valid/invalid URLs
- Complex formatting

**Performance Tests** (`testLargeConfigurationPerformance`)
- Loading 100+ URLs
- Parsing speed

**Edge Case Tests** (`testConfigWithOnlyComments`, `testSingleURLConfig`, etc.)
- Only comments or whitespace
- Single URL configurations
- Boundary conditions

## Test Results

Expected test counts:
- **Total Tests**: 20+
- **Expected Pass**: All tests should pass
- **Expected Fail**: 0
- **Expected Duration**: < 5 seconds

## Writing New Tests

### Test Naming Convention

```objective-c
- (void)test[Component][Scenario]
```

Examples:
- `testViewControllerInitialization`
- `testValidURLParsing`
- `testNetworkErrorHandling`

### Test Structure

```objective-c
- (void)testExampleTest {
    // 1. Setup (if needed beyond setUp method)
    NSString *configContent = @"test data";

    // 2. Execute
    [self.viewController someMethod:configContent];

    // 3. Verify
    XCTAssertEqual(expected, actual, @"Description of what should happen");
}
```

### Available Assertions

- `XCTAssertTrue(condition, message)` - Condition should be true
- `XCTAssertFalse(condition, message)` - Condition should be false
- `XCTAssertEqual(a, b, message)` - Values should be equal
- `XCTAssertNotEqual(a, b, message)` - Values should not be equal
- `XCTAssertNil(object, message)` - Object should be nil
- `XCTAssertNotNil(object, message)` - Object should not be nil
- `XCTAssertEqualObjects(a, b, message)` - Objects should be equal
- `XCTFail(message)` - Force test failure

### Testing Private Methods

Private methods are exposed for testing using a category:

```objective-c
@interface ViewController (Testing)
- (void)privateMethodToTest;
@property (strong, nonatomic) NSArray *privateProperty;
@end
```

## Mock Data

### Valid Configuration

```
https://dashboard1.example.com
https://dashboard2.example.com
```

### Configuration with Comments

```
# Production Dashboards
https://dashboard1.example.com

# Development Dashboards
https://dev-dashboard.example.com
```

### Mixed Valid/Invalid

```
https://valid.com
invalid-url
https://another-valid.com
not-a-url
```

## Common Test Failures

### Test: `testViewControllerInitialization`
**Failure**: View not created
**Solution**: Ensure `loadView` and `viewDidLoad` are called in setUp

### Test: `testValidURLParsing`
**Failure**: Wrong URL count
**Solution**: Check URL validation logic in `handleConfigResponse`

### Test: `testButtonStatesWithURLs`
**Failure**: Button states incorrect
**Solution**: Verify `updateButtonStates` logic

## Continuous Integration

For CI/CD pipelines:

```bash
#!/bin/bash
# run_tests.sh

set -e  # Exit on error

echo "Running Site Rotator 2.0 Tests..."

xcodebuild clean test \
  -project "Site Rotator 2.0.xcodeproj" \
  -scheme "Site Rotator 2.0" \
  -destination 'platform=macOS' \
  -resultBundlePath TestResults \
  | xcpretty

# Check exit code
if [ $? -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Tests failed!"
    exit 1
fi
```

## Code Coverage

To enable code coverage:

1. Edit scheme (⌘<)
2. Select **Test** action
3. Check **Options** tab
4. Enable **Code Coverage**
5. Select targets to track

Expected coverage targets:
- **ViewController.m**: > 80%
- **AppDelegate.m**: > 70%
- **Overall**: > 75%

## Performance Benchmarks

Current performance metrics:

- **Large config parsing** (100 URLs): < 50ms
- **Single URL validation**: < 1ms
- **UI update**: < 5ms
- **Full test suite**: < 5 seconds

## Test Maintenance

### When to Update Tests

- ✅ Adding new features
- ✅ Fixing bugs (add regression test)
- ✅ Changing behavior
- ✅ Refactoring (tests should still pass)

### Test Review Checklist

- [ ] Test name clearly describes what it tests
- [ ] Test has single responsibility
- [ ] Assertions include descriptive messages
- [ ] Test is deterministic (no random behavior)
- [ ] Test cleans up after itself
- [ ] Test doesn't depend on other tests
- [ ] Test runs quickly (< 100ms per test)

## Troubleshooting Tests

### Tests Won't Build

**Issue**: "Use of undeclared identifier"
**Solution**: Ensure test target has access to source files

**Issue**: "Linker command failed"
**Solution**: Check test target's build settings and dependencies

### Tests Are Flaky

**Issue**: Tests pass/fail randomly
**Solution**:
- Remove timing dependencies
- Use XCTestExpectation for async code
- Avoid shared state between tests

### Tests Are Slow

**Issue**: Tests take > 5 seconds
**Solution**:
- Mock network calls
- Reduce test data size
- Parallelize tests
- Profile with Instruments

## Future Test Additions

Planned test additions:

- [ ] WebView navigation delegate tests
- [ ] JavaScript execution tests
- [ ] Animation timing tests
- [ ] Memory leak tests
- [ ] Scroll behavior tests
- [ ] Configuration caching tests
- [ ] Network retry logic tests
- [ ] UI interaction tests (button clicks)

## Resources

- [XCTest Framework Reference](https://developer.apple.com/documentation/xctest)
- [Testing with Xcode](https://developer.apple.com/library/archive/documentation/DeveloperTools/Conceptual/testing_with_xcode/)
- [WWDC Testing Videos](https://developer.apple.com/videos/testing)

## Support

For test-related issues:

1. Check test output in Xcode's Test Navigator
2. Review console logs for error messages
3. Verify test data and mock objects
4. Check that setUp and tearDown are working correctly
5. Run tests individually to isolate failures
