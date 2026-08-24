//
//  MemoryLeakDetectionView.swift
//  github_repo_search_iOS_app
//
//  Memory Leak Detection Examples
//
//  Demonstrates common memory leak patterns in iOS/SwiftUI and how to detect them
//  using Instruments, Xcode Memory Debugger, and proper coding practices.
//

import SwiftUI
import Combine

struct MemoryLeakDetectionView: View {
    @State private var activeExample: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Header Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "memorychip")
                                .foregroundColor(.blue)
                            Text("Memory Leak Detection")
                                .font(.headline)
                        }

                        Text("""
                        Monitor and fix memory leaks using:
                        • Xcode Memory Debugger (Debug → Memory → Debug Memory Graph)
                        • Instruments (Leaks, Allocations)
                        • Proper Swift patterns (weak, unowned)
                        • Lifecycle management
                        """)
                        .font(.caption)
                        .lineSpacing(4)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)

                    // Example 1: Timer Leak
                    LeakExampleCard(
                        title: "1. Timer Leak",
                        description: "Timer not invalidated causes retain cycle",
                        isActive: activeExample == "timer",
                        onToggle: { activeExample = activeExample == "timer" ? nil : "timer" }
                    ) {
                        TimerLeakExample()
                    }

                    // Example 2: Closure Capture Leak
                    LeakExampleCard(
                        title: "2. Closure Capture Leak",
                        description: "Strong self reference in closures",
                        isActive: activeExample == "closure",
                        onToggle: { activeExample = activeExample == "closure" ? nil : "closure" }
                    ) {
                        ClosureCaptureExample()
                    }

                    // Example 3: NotificationCenter Leak
                    LeakExampleCard(
                        title: "3. NotificationCenter Leak",
                        description: "Observer not removed on deinit",
                        isActive: activeExample == "notification",
                        onToggle: { activeExample = activeExample == "notification" ? nil : "notification" }
                    ) {
                        NotificationLeakExample()
                    }

                    // Example 4: Fixed Pattern
                    LeakExampleCard(
                        title: "4. Proper Cleanup",
                        description: "Using weak self and proper lifecycle",
                        isActive: activeExample == "fixed",
                        onToggle: { activeExample = activeExample == "fixed" ? nil : "fixed" }
                    ) {
                        FixedExample()
                    }

                    // Detection Tools
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detection Tools")
                            .font(.headline)

                        Text("""
                        1. Memory Debugger:
                           • Debug → Memory → Debug Memory Graph
                           • Look for retain cycles (purple icons)
                           • Inspect backtrace references

                        2. Instruments - Leaks:
                           • Product → Profile (⌘I)
                           • Select "Leaks" template
                           • Run app and navigate
                           • Check for red leak indicators

                        3. Instruments - Allocations:
                           • Track object allocations over time
                           • Monitor persistent memory growth
                           • Filter by class name

                        4. Xcode Runtime Issues:
                           • Enable malloc stack logging
                           • Check Issue Navigator for leaks
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
                        Text("Best Practices")
                            .font(.headline)

                        Text("""
                        ✓ Use [weak self] in closures
                        ✓ Invalidate timers in onDisappear/deinit
                        ✓ Remove NotificationCenter observers
                        ✓ Use onDisappear for cleanup in SwiftUI
                        ✓ Avoid static references to views
                        ✓ Use @StateObject for owned objects
                        ✓ Test with Debug Memory Graph regularly
                        ✓ Profile with Instruments before release
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
            .navigationTitle("Memory Leak Detection")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Example Components

struct LeakExampleCard<Content: View>: View {
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

// MARK: - Example 1: Timer Leak

struct TimerLeakExample: View {
    @State private var counter = 0
    @State private var isRunning = false

    // BAD: Timer stored directly without cleanup
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            Text("Counter: \(counter)")
                .font(.headline)

            HStack(spacing: 12) {
                Button("Start Timer (Leaks!)") {
                    startBadTimer()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)

                Button("Stop") {
                    stopTimer()
                }
                .buttonStyle(.bordered)
            }

            Text("""
            ⚠️ BAD: Timer continues running after view disappears.
            Timer holds strong reference to target.

            Navigate away and use Memory Debugger to see leak.
            """)
            .font(.caption)
            .foregroundColor(.orange)
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)
        }
    }

    private func startBadTimer() {
        isRunning = true
        // BAD: Timer not invalidated, causes leak
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            counter += 1
            print("Timer tick: \(counter)")
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isRunning = false
    }
}

// MARK: - Example 2: Closure Capture Leak

class LeakyViewModel: ObservableObject {
    @Published var count = 0
    var workItem: DispatchWorkItem?

    // BAD: Strong self in closure
    func startBadWork() {
        workItem = DispatchWorkItem {
            // This captures self strongly!
            for i in 1...10 {
                sleep(1)
                self.count = i  // Strong reference to self
                print("Work: \(i)")
            }
        }
        DispatchQueue.global().async(execute: workItem!)
    }

    deinit {
        print("⚠️ LeakyViewModel deinit - may not be called!")
        workItem?.cancel()
    }
}

struct ClosureCaptureExample: View {
    @StateObject private var viewModel = LeakyViewModel()

    var body: some View {
        VStack(spacing: 12) {
            Text("Count: \(viewModel.count)")
                .font(.headline)

            Button("Start Long Task (Leaks!)") {
                viewModel.startBadWork()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)

            Text("""
            ⚠️ BAD: Closure captures self strongly.
            Work continues even after view disappears.
            ViewModel won't deinit until work completes.

            Solution: Use [weak self] in closure.
            """)
            .font(.caption)
            .foregroundColor(.orange)
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)
        }
    }
}

// MARK: - Example 3: NotificationCenter Leak

class NotificationLeakyView: ObservableObject {
    @Published var message = "Waiting..."

    init() {
        // BAD: Observer added but never removed
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotification),
            name: Notification.Name("CustomEvent"),
            object: nil
        )
    }

    @objc func handleNotification(_ notification: Notification) {
        message = "Received: \(Date())"
        print("Notification received")
    }

    // Missing: removeObserver in deinit!
    deinit {
        print("⚠️ NotificationLeakyView deinit - may not be called!")
    }
}

struct NotificationLeakExample: View {
    @StateObject private var viewModel = NotificationLeakyView()

    var body: some View {
        VStack(spacing: 12) {
            Text(viewModel.message)
                .font(.headline)

            Button("Post Notification") {
                NotificationCenter.default.post(
                    name: Notification.Name("CustomEvent"),
                    object: nil
                )
            }
            .buttonStyle(.borderedProminent)

            Text("""
            ⚠️ BAD: NotificationCenter observer not removed.
            Observer retains object even after view is gone.

            Solution: Remove observer in deinit or use Combine.
            """)
            .font(.caption)
            .foregroundColor(.orange)
            .padding(8)
            .background(Color.orange.opacity(0.1))
            .cornerRadius(4)
        }
    }
}

// MARK: - Example 4: Fixed Pattern

class FixedViewModel: ObservableObject {
    @Published var count = 0
    @Published var message = "Ready"
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    // GOOD: Using weak self
    func startGoodWork() {
        DispatchQueue.global().async { [weak self] in
            for i in 1...10 {
                guard let self = self else {
                    print("✅ Self is nil, stopping work")
                    return
                }
                sleep(1)
                DispatchQueue.main.async {
                    self.count = i
                }
            }
        }
    }

    // GOOD: Using Combine for notifications
    func listenToNotifications() {
        NotificationCenter.default.publisher(for: Notification.Name("GoodEvent"))
            .sink { [weak self] _ in
                self?.message = "Event received ✅"
            }
            .store(in: &cancellables)
    }

    // GOOD: Cleanup in deinit
    deinit {
        print("✅ FixedViewModel properly deinitialized")
        timer?.invalidate()
        cancellables.removeAll()
    }
}

struct FixedExample: View {
    @StateObject private var viewModel = FixedViewModel()
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 12) {
            Text("Count: \(viewModel.count)")
                .font(.headline)

            Text("Message: \(viewModel.message)")
                .font(.subheadline)

            HStack(spacing: 12) {
                Button("Start Work") {
                    viewModel.startGoodWork()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)

                Button("Listen") {
                    viewModel.listenToNotifications()
                }
                .buttonStyle(.bordered)
            }

            Text("""
            ✅ GOOD: Using [weak self] in closures.
            ✅ GOOD: Combine cancellables for notifications.
            ✅ GOOD: Cleanup in deinit.

            ViewModel will deinit properly when view disappears.
            """)
            .font(.caption)
            .foregroundColor(.green)
            .padding(8)
            .background(Color.green.opacity(0.1))
            .cornerRadius(4)
        }
        .onDisappear {
            timer?.invalidate()
            print("✅ View cleanup executed")
        }
    }
}

// MARK: - Preview

struct MemoryLeakDetectionView_Previews: PreviewProvider {
    static var previews: some View {
        MemoryLeakDetectionView()
    }
}
