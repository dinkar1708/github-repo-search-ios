//
//  PerformanceMonitoringView.swift
//  github_repo_search_iOS_app
//
//  Performance Monitoring Examples
//
//  Demonstrates how to monitor and optimize performance in iOS/SwiftUI
//  using Instruments, Xcode profiling tools, and best practices.
//

import SwiftUI

struct PerformanceMonitoringView: View {
    @State private var activeExample: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "speedometer")
                                .foregroundColor(.blue)
                            Text("Performance Monitoring")
                                .font(.headline)
                        }

                        Text("""
                        Monitor and optimize performance using:
                        • Instruments (Time Profiler, SwiftUI)
                        • Xcode View Debugger
                        • Rendering performance tracking
                        • Memory and CPU profiling
                        """)
                        .font(.caption)
                        .lineSpacing(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                    // Example 1: View Update Counter
                    PerformanceExampleCard(
                        title: "1. View Update Counter",
                        description: "Track how many times view body is called",
                        isActive: activeExample == "updates",
                        onToggle: { activeExample = activeExample == "updates" ? nil : "updates" }
                    ) {
                        ViewUpdateCounterExample()
                    }

                    // Example 2: List Performance
                    PerformanceExampleCard(
                        title: "2. List Performance",
                        description: "Measure list scrolling with/without id",
                        isActive: activeExample == "list",
                        onToggle: { activeExample = activeExample == "list" ? nil : "list" }
                    ) {
                        ListPerformanceExample()
                    }

                    // Example 3: Expensive Calculations
                    PerformanceExampleCard(
                        title: "3. Expensive Calculations",
                        description: "Compare computed vs cached values",
                        isActive: activeExample == "expensive",
                        onToggle: { activeExample = activeExample == "expensive" ? nil : "expensive" }
                    ) {
                        ExpensiveCalculationExample()
                    }

                    // Example 4: Rendering Optimization
                    PerformanceExampleCard(
                        title: "4. Rendering Optimization",
                        description: "Minimize view updates with proper state",
                        isActive: activeExample == "render",
                        onToggle: { activeExample = activeExample == "render" ? nil : "render" }
                    ) {
                        RenderingOptimizationExample()
                    }

                    // Monitoring Tools
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Performance Monitoring Tools")
                            .font(.headline)

                        Text("""
                        1. Instruments - Time Profiler:
                           • Product → Profile (⌘I)
                           • Select "Time Profiler"
                           • Record and interact with app
                           • Analyze hot methods

                        2. Instruments - SwiftUI:
                           • Shows view body execution
                           • Tracks property changes
                           • Identifies update cycles

                        3. Xcode View Debugger:
                           • Debug → View Debugging → Capture View Hierarchy
                           • Inspect view layers
                           • Check rendering complexity

                        4. MetricKit (for production):
                           • Collect performance metrics
                           • Monitor hangs and crashes
                           • Track startup time
                        """)
                        .font(.caption)
                        .lineSpacing(3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                    // Best Practices
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Performance Best Practices")
                            .font(.headline)

                        Text("""
                        ✓ Use @State/@StateObject appropriately
                        ✓ Minimize view body complexity
                        ✓ Cache expensive computations
                        ✓ Use LazyVStack/LazyHStack for long lists
                        ✓ Provide stable ids for List items
                        ✓ Avoid frequent State updates
                        ✓ Use GeometryReader sparingly
                        ✓ Profile in Release builds
                        ✓ Enable Build for Profiling scheme
                        """)
                        .font(.caption)
                        .lineSpacing(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Performance Monitoring")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Performance Example Card

struct PerformanceExampleCard<Content: View>: View {
    let title: String
    let description: String
    let isActive: Bool
    let onToggle: () -> Void
    let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { isActive },
                    set: { _ in onToggle() }
                ))
                .labelsHidden()
            }

            if isActive {
                Divider()
                content()
            }
        }
        .padding()
        .background(isActive ? Color.gray.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Example 1: View Update Counter

struct ViewUpdateCounterExample: View {
    @State private var counter = 0
    @State private var updateCount = 0

    var body: some View {
        let _ = incrementUpdateCount()

        return VStack(spacing: 12) {
            Text("Button taps: \(counter)")
                .font(.subheadline)

            Text("Body called: \(updateCount) times")
                .font(.subheadline)
                .foregroundColor(.blue)
                .fontWeight(.bold)

            Button("Increment Counter") {
                counter += 1
            }
            .buttonStyle(.borderedProminent)

            Text("""
            ℹ️ Each tap should call body once.
            Use Instruments SwiftUI template to verify.

            If body is called multiple times per tap, check:
            • Parent view updates
            • ObservableObject changes
            • Environment value changes
            """)
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(8)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(4)
        }
    }

    private func incrementUpdateCount() {
        DispatchQueue.main.async {
            updateCount += 1
            print("ViewUpdateCounter body called: \(updateCount) times")
        }
    }
}

// MARK: - Example 2: List Performance

struct ListPerformanceExample: View {
    @State private var useStableIds = true
    @State private var items: [ListItem] = (0..<50).map { ListItem(id: $0, name: "Item \($0)") }

    struct ListItem: Identifiable {
        let id: Int
        var name: String
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Use stable IDs:")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $useStableIds)
                    .labelsHidden()
            }

            Button("Shuffle List") {
                items.shuffle()
                print("List shuffled - observe rendering behavior")
            }
            .buttonStyle(.bordered)

            ScrollView {
                if useStableIds {
                    // GOOD: Stable ids prevent full re-render
                    LazyVStack {
                        ForEach(items) { item in
                            ListItemView(item: item)
                        }
                    }
                } else {
                    // BAD: No stable id, uses index
                    LazyVStack {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            ListItemView(item: item)
                        }
                    }
                }
            }
            .frame(height: 200)
            .border(Color.gray.opacity(0.3))

            Text(useStableIds ?
                "✓ With IDs: SwiftUI reuses existing views" :
                "✗ Without IDs: Full re-render on shuffle"
            )
            .font(.caption)
            .foregroundColor(useStableIds ? .green : .orange)
        }
    }
}

struct ListItemView: View {
    let item: ListPerformanceExample.ListItem
    @State private var renderCount = 0

    var body: some View {
        let _ = incrementRenderCount()

        return HStack {
            Text(item.name)
                .font(.subheadline)
            Spacer()
            Text("Renders: \(renderCount)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }

    private func incrementRenderCount() {
        DispatchQueue.main.async {
            renderCount += 1
        }
    }
}

// MARK: - Example 3: Expensive Calculations

struct ExpensiveCalculationExample: View {
    @State private var counter = 0
    @State private var useCache = true
    @State private var executionTime: Double = 0

    // Cached expensive result
    @State private var cachedResult = 0

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Use cache:")
                    .font(.subheadline)
                Spacer()
                Toggle("", isOn: $useCache)
                    .labelsHidden()
            }

            Text("Counter: \(counter)")
                .font(.subheadline)

            Text("Result: \(result)")
                .font(.subheadline)

            Text(String(format: "Execution: %.2fms", executionTime))
                .font(.subheadline)
                .foregroundColor(executionTime < 1 ? .green : .orange)
                .fontWeight(.bold)

            Button("Increment") {
                counter += 1
            }
            .buttonStyle(.borderedProminent)

            Text(useCache ?
                "✓ Cached: Only recalculates when counter changes" :
                "✗ Not cached: Recalculates on every view update!"
            )
            .font(.caption)
            .foregroundColor(useCache ? .green : .orange)
            .padding(8)
            .background((useCache ? Color.green : Color.orange).opacity(0.1))
            .cornerRadius(4)
        }
        .onChange(of: counter) { _ in
            if useCache {
                recalculateCached()
            }
        }
    }

    private var result: Int {
        if useCache {
            return cachedResult
        } else {
            return calculateExpensive()
        }
    }

    private func recalculateCached() {
        cachedResult = calculateExpensive()
    }

    private func calculateExpensive() -> Int {
        let start = CFAbsoluteTimeGetCurrent()

        // Simulate expensive work
        var sum = 0
        for i in 1...10000 {
            sum += i
        }

        let diff = CFAbsoluteTimeGetCurrent() - start
        DispatchQueue.main.async {
            executionTime = diff * 1000
        }

        print("Expensive calculation: \(diff * 1000)ms")
        return counter * 100
    }
}

// MARK: - Example 4: Rendering Optimization

struct RenderingOptimizationExample: View {
    @State private var scrollPosition: CGFloat = 0
    @State private var updateCount = 0

    var body: some View {
        VStack(spacing: 12) {
            Text(String(format: "Scroll: %.0f", scrollPosition))
                .font(.subheadline)

            Text("Threshold crossed: \(isScrolled ? "Yes" : "No")")
                .font(.subheadline)

            Text("Updates: \(updateCount)")
                .font(.subheadline)
                .foregroundColor(.blue)
                .fontWeight(.bold)

            ScrollView {
                VStack(spacing: 8) {
                    ForEach(0..<20) { i in
                        Text("Row \(i)")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .frame(height: 200)
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollPosition = -value
            }

            Text("""
            ✓ Optimized: Only updates when threshold changes, not on every scroll pixel.

            Compare with Instruments to see minimal body calls.
            """)
            .font(.caption)
            .foregroundColor(.green)
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)
        }
        .onChange(of: isScrolled) { _ in
            updateCount += 1
            print("Threshold changed, update: \(updateCount)")
        }
    }

    // Computed property - only changes when threshold crossed
    private var isScrolled: Bool {
        scrollPosition > 50
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

struct PerformanceMonitoringView_Previews: PreviewProvider {
    static var previews: some View {
        PerformanceMonitoringView()
    }
}
