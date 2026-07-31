# Stress Tests Setup

Quick guide to run stress tests on iOS app.

## Files Location

```
github_repo_search_iOS_app_UITests/StressTests/
├── HeavyScrollingStressTests.swift  (6 tests)
└── RapidSearchStressTests.swift     (5 tests)
```

## Run Tests

### In Xcode
```bash
Cmd + U  # Run all tests
```

Or click the play button next to any test name.

### Command Line
```bash
xcodebuild test -project github_repo_search_iOS_app.xcodeproj \
  -scheme github_repo_search_iOS_app \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.6'
```

## What Gets Tested

### Heavy Scrolling Tests (6 tests)
- 60 seconds continuous scrolling
- 100 rapid swipes
- Scrolling during pagination
- Momentum scrolling
- Scrolling with images
- Rapid direction changes

### Rapid Search Tests (5 tests)
- 30 seconds rapid searching
- Search cancellation
- Alternating empty/full searches
- Search while scrolling
- Rapid search variations

## Monitor Performance

While tests run, open Debug Navigator (Cmd+7):
- Memory: Should stay under 150MB
- CPU: Should average under 40%
- No crashes or freezes

## Expected Results

PASS:
- Memory stable (no growth)
- 60 FPS scrolling
- App responsive
- No crashes

FAIL:
- Memory keeps growing
- CPU over 60%
- UI freezes
- Crashes

## Troubleshooting

Build fails with TabSwitchingStressTests not found:
1. Open Xcode
2. Remove TabSwitchingStressTests.swift reference (shows in red)
3. Add RapidSearchStressTests.swift to project
4. Build again

For detailed stress testing guide, see STRESS_TESTING.md
