# Performance Monitoring in iOS/SwiftUI

## Purpose

Learn how to monitor and optimize performance in iOS applications using Instruments, Xcode profiling tools, and SwiftUI best practices.

## 📁 Code Examples in Project

**Complete working example:** [`Modules/Feature/UI/Samples/Advanced/PerformanceMonitoringView.swift`](../../../../github_repo_search_iOS_app/Modules/Feature/UI/Samples/Advanced/PerformanceMonitoringView.swift)

This file demonstrates:
- ✅ Performance metrics collection
- ✅ FPS monitoring
- ✅ Memory usage tracking
- ✅ CPU profiling
- ✅ Interactive performance tests
- ✅ Optimization techniques

**Real usage in production code:**
- `Modules/Feature/UI/Home/View/HomeView.swift` - Optimized list rendering
- `github_repo_search_iOS_app_PerformanceTests/` - App launch performance tests
- `Modules/Feature/UI/Favorites/View/FavoritesView.swift` - Efficient data updates

---

## Why Performance Matters

Poor performance leads to:
- Janky scrolling (dropped frames)
- Slow app launch
- Battery drain
- User frustration and uninstalls
- Poor App Store ratings

**Target**: 60 FPS (16.67ms per frame) or 120 FPS (8.33ms) on ProMotion displays

---

## Monitoring Tools

### 1. Instruments - Time Profiler

**Access**: Product → Profile (⌘I) → Select "Time Profiler"

**What it shows**:
- CPU usage per method
- Call tree showing time spent
- Hot methods (expensive operations)

**Usage**:
```
1. Product → Profile (⌘I)
2. Select "Time Profiler"
3. Click Record
4. Interact with your app
5. Stop recording
6. Analyze call tree
7. Find expensive methods
```

### 2. Instruments - SwiftUI Template

**For SwiftUI apps**:
1. Product → Profile (⌘I)
2. Select "SwiftUI" template
3. Track:
   - View body executions
   - Property updates
   - State changes

**What to check**:
- Excessive body evaluations
- Frequent state updates
- View hierarchy complexity

### 3. Xcode View Debugger

**For layout inspection**:
1. Debug → View Debugging → Capture View Hierarchy (⌘⇧V)
2. Check:
   - View hierarchy depth
   - Offscreen views
   - Complex layouts

### 4. FPS Counter (Debug Overlay)

```swift
import SwiftUI

struct FPSView: View {
    @State private var fps: Double = 60

    var body: some View {
        TimelineView(.animation) { timeline in
            let _ = updateFPS(timeline.date)

            Text("FPS: \(Int(fps))")
                .font(.caption)
                .padding(4)
                .background(fpsColor)
                .cornerRadius(4)
        }
    }

    private var fpsColor: Color {
        fps >= 50 ? .green : fps >= 30 ? .orange : .red
    }

    private func updateFPS(_ date: Date) {
        // FPS calculation logic
    }
}
```

### 5. MetricKit (Production Metrics)

```swift
import MetricKit

class MetricsManager: NSObject, MXMetricManagerSubscriber {
    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            // Analyze metrics
            print("App launch time: \(payload.applicationLaunchMetrics)")
            print("Hang time: \(payload.applicationResponsivenessMetrics)")
        }
    }
}
```

---

## Common Performance Issues

### 1. Excessive View Updates

**Problem**: View body called too frequently

```swift
// BAD - State changes on every animation frame
struct AnimatedView: View {
    @State private var offset: CGFloat = 0

    var body: some View {
        Text("Hello")
            .offset(x: offset)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                    offset += 1  // Triggers body re-evaluation 60 times/sec!
                }
            }
    }
}

// GOOD - Use animation modifiers
struct AnimatedView: View {
    @State private var isAnimating = false

    var body: some View {
        Text("Hello")
            .offset(x: isAnimating ? 100 : 0)
            .animation(.linear(duration: 2), value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}
```

### 2. Expensive Computations

**Problem**: Computing expensive values on every render

```swift
// BAD - Recalculates on every view update
struct ExpensiveView: View {
    let items: [Item]

    var body: some View {
        let processedItems = items.map { processItem($0) }  // Runs every render!

        List(processedItems) { item in
            Text(item.name)
        }
    }

    private func processItem(_ item: Item) -> ProcessedItem {
        // Expensive operation
        Thread.sleep(forTimeInterval: 0.01)
        return ProcessedItem(item)
    }
}

// GOOD - Cache expensive computation
struct OptimizedView: View {
    let items: [Item]

    // Computed once, only updates if items changes
    private var processedItems: [ProcessedItem] {
        items.map { processItem($0) }
    }

    var body: some View {
        List(processedItems) { item in
            Text(item.name)
        }
    }
}

// BETTER - Use @State for caching
struct BetterView: View {
    let items: [Item]
    @State private var processedItems: [ProcessedItem] = []

    var body: some View {
        List(processedItems) { item in
            Text(item.name)
        }
        .onAppear {
            processedItems = items.map { processItem($0) }
        }
    }
}
```

### 3. Missing List IDs

**Problem**: List items re-render unnecessarily

```swift
// BAD - No stable IDs
List(items) { item in
    ComplexItemView(item)
}

// GOOD - Stable IDs prevent re-render
List(items, id: \.id) { item in
    ComplexItemView(item)
}
```

### 4. Heavy View Hierarchies

**Problem**: Too many nested views

```swift
// BAD - Deep nesting
VStack {
    HStack {
        VStack {
            HStack {
                VStack {
                    Text("Deep")
                }
            }
        }
    }
}

// GOOD - Flatter hierarchy
VStack {
    CustomRow()
    CustomRow()
}

struct CustomRow: View {
    var body: some View {
        // Flatter structure
    }
}
```

### 5. GeometryReader Overuse

**Problem**: GeometryReader triggers layout recalculation

```swift
// BAD - GeometryReader in every subview
struct MyView: View {
    var body: some View {
        VStack {
            GeometryReader { geo in
                Text("1")
                    .frame(width: geo.size.width)
            }
            GeometryReader { geo in
                Text("2")
                    .frame(width: geo.size.width)
            }
        }
    }
}

// GOOD - Single GeometryReader with preference key
struct MyView: View {
    var body: some View {
        VStack {
            Text("1")
            Text("2")
        }
        .background(
            GeometryReader { geo in
                Color.clear
                    .preference(key: SizePreferenceKey.self, value: geo.size)
            }
        )
    }
}
```

---

## Optimization Techniques

### 1. Minimize State Changes

```swift
// Track only what changes
@State private var isLoading: Bool = false  // ✓
// Don't track everything in one object if not needed
```

### 2. Use Lazy Stacks for Long Lists

```swift
// For long lists, always use Lazy variants
ScrollView {
    LazyVStack {  // Only renders visible items
        ForEach(1...10000, id: \.self) { i in
            Text("Row \(i)")
        }
    }
}

// Not this for long lists:
ScrollView {
    VStack {  // Renders ALL items immediately
        ForEach(1...10000, id: \.self) { i in
            Text("Row \(i)")
        }
    }
}
```

### 3. Split Complex Views

```swift
// Instead of one large view
struct ComplexView: View {
    var body: some View {
        VStack {
            // 100 lines of code...
        }
    }
}

// Split into smaller views
struct ComplexView: View {
    var body: some View {
        VStack {
            HeaderSection()
            ContentSection()
            FooterSection()
        }
    }
}

// Smaller views = easier to optimize and reuse
```

### 4. Use EquatableView for Complex Views

```swift
struct ExpensiveView: View, Equatable {
    let data: ExpensiveData

    var body: some View {
        // Complex rendering
    }

    static func == (lhs: ExpensiveView, rhs: ExpensiveView) -> Bool {
        lhs.data.id == rhs.data.id
    }
}

// Usage
EquatableView(content: ExpensiveView(data: myData))
// Only re-renders if data.id changes
```

### 5. Defer Heavy Work

```swift
struct MyView: View {
    @State private var heavyData: [Item] = []

    var body: some View {
        List(heavyData) { item in
            Text(item.name)
        }
        .task {
            // Run on background thread
            let data = await loadHeavyData()
            heavyData = data
        }
    }

    private func loadHeavyData() async -> [Item] {
        // Heavy work on background thread
        await withCheckedContinuation { continuation in
            DispatchQueue.global().async {
                let result = performExpensiveOperation()
                continuation.resume(returning: result)
            }
        }
    }
}
```

---

## Measuring Performance

### 1. Time Profiler

```swift
// Measure specific code sections
func expensiveOperation() {
    let start = CFAbsoluteTimeGetCurrent()

    // Your code

    let diff = CFAbsoluteTimeGetCurrent() - start
    print("Operation took \(diff * 1000)ms")
}
```

### 2. Signposts for Instruments

```swift
import os.signpost

let log = OSLog(subsystem: "com.myapp", category: "Performance")

func loadData() {
    os_signpost(.begin, log: log, name: "Load Data")

    // Load data...

    os_signpost(.end, log: log, name: "Load Data")
}

// View in Instruments for precise timing
```

### 3. View Update Counter

```swift
struct DebugView: View {
    @State private var updateCount = 0

    var body: some View {
        let _ = incrementCount()

        Text("Updated \(updateCount) times")
    }

    private func incrementCount() {
        DispatchQueue.main.async {
            updateCount += 1
            print("View updated: \(updateCount) times")
        }
    }
}
```

---

## Best Practices

### 1. @State vs @StateObject vs @ObservedObject

```swift
// Use @State for simple values
@State private var count: Int = 0

// Use @StateObject when view OWNS the object
@StateObject private var viewModel = MyViewModel()

// Use @ObservedObject for PASSED objects
@ObservedObject var viewModel: MyViewModel
```

### 2. Minimize Body Complexity

```swift
// Keep view body simple
var body: some View {
    contentView
}

private var contentView: some View {
    VStack {
        // Complex layout
    }
}

// Or extract to separate views
```

### 3. Use DrawingGroup for Heavy Graphics

```swift
// For complex drawing/animations
VStack {
    ForEach(0..<100) { i in
        Circle()
            .fill(Color.blue)
    }
}
.drawingGroup()  // Flattens into single view for Metal rendering
```

### 4. Avoid Frequent State Updates

```swift
// BAD - Updates on every pixel scrolled
.onScroll { position in
    scrollPosition = position  // Triggers re-render constantly
}

// GOOD - Only update when threshold crossed
.onScroll { position in
    let wasScrolled = isScrolled
    let nowScrolled = position > 100
    if wasScrolled != nowScrolled {
        isScrolled = nowScrolled  // Only updates when boolean changes
    }
}
```

### 5. Profile in Release Mode

```swift
// Always profile with Release build
// Edit Scheme → Run → Build Configuration → Release
// Or use "Profile" which uses Release by default
```

---

## Debugging Slow Performance

### Checklist

1. ✓ Profile with Time Profiler
2. ✓ Check SwiftUI Instruments for excessive body calls
3. ✓ Add update counters to suspicious views
4. ✓ Verify lazy loading for lists
5. ✓ Check for expensive computed properties
6. ✓ Test in Release build
7. ✓ Monitor memory alongside CPU

### Investigation Steps

```
1. Identify slow screen/interaction
2. Profile with Time Profiler
3. Find hot methods in call tree
4. Add signposts around suspect code
5. Profile again with signposts
6. Optimize identified bottlenecks
7. Measure improvement
8. Repeat until target met
```

---

## App Launch Optimization

### Measure Launch Time

```swift
// In AppDelegate or App struct
func application(...) {
    let start = CFAbsoluteTimeGetCurrent()

    // App initialization

    let diff = CFAbsoluteTimeGetCurrent() - start
    print("App launch: \(diff * 1000)ms")
}
```

### Launch Optimization Tips

1. **Defer non-critical work**
   ```swift
   DispatchQueue.main.async {
       // Non-critical initialization
   }
   ```

2. **Lazy load resources**
   ```swift
   lazy var expensiveResource = loadResource()
   ```

3. **Use App Thinning**
   - Enable bitcode
   - Use asset catalogs
   - On-demand resources

4. **Profile with App Launch Instrument**
   - Product → Profile
   - Select "App Launch"
   - Analyze initialization time

---

## Memory and Performance

### Monitor Memory Usage

```swift
func reportMemory() {
    var info = mach_task_basic_info()
    var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

    let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
        $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
            task_info(mach_task_self_,
                     task_flavor_t(MACH_TASK_BASIC_INFO),
                     $0,
                     &count)
        }
    }

    if kerr == KERN_SUCCESS {
        let usedMB = Double(info.resident_size) / 1024 / 1024
        print("Memory used: \(usedMB)MB")
    }
}
```

---

## Resources

- [Optimizing SwiftUI Performance](https://developer.apple.com/videos/play/wwdc2021/10022/)
- [Instruments Help](https://help.apple.com/instruments/mac/current/)
- [MetricKit](https://developer.apple.com/documentation/metrickit)

---

## Code Reference

See project example:
- `Modules/Feature/UI/Samples/Advanced/PerformanceMonitoringView.swift`

Remember: **Measure first, optimize second. Always profile in Release builds!**
