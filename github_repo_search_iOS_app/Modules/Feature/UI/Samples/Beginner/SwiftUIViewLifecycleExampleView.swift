//
//  SwiftUIViewLifecycleExampleView.swift
//  github_repo_search_iOS_app
//
//  SwiftUI View Lifecycle Sample
//  Demonstrates view creation, onAppear, onDisappear, .task cancellation, and .onChange.
//

import SwiftUI

struct SwiftUIViewLifecycleExampleView: View {
    @State private var showChildView: Bool = true
    @State private var childViewId: UUID = UUID()
    @State private var counter: Int = 0
    @State private var logs: [LifecycleLogEntry] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SwiftUILifecycleHeaderCard()

                    // Child View Toggle & Lifecycle
                    ChildViewLifecycleCard(
                        showChild: $showChildView,
                        childId: childViewId,
                        onResetId: {
                            childViewId = UUID()
                            addLog("Forced new View Identity via .id(\(childViewId.uuidString.prefix(4)))")
                        },
                        onLog: { msg in addLog(msg) }
                    )

                    // .onChange Modifier Demo
                    OnChangeLifecycleCard(
                        counter: $counter,
                        onLog: { msg in addLog(msg) }
                    )

                    // .task vs .onAppear Demo
                    TaskLifecycleCard(
                        onLog: { msg in addLog(msg) }
                    )

                    // Live Event Log
                    LifecycleEventLogCard(
                        logs: logs,
                        onClear: { logs.removeAll() }
                    )

                    // Best Practices
                    SwiftUILifecycleBestPracticesCard()
                }
                .padding()
            }
            .navigationTitle("SwiftUI View Lifecycle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                addLog("Parent SwiftUIViewLifecycleExampleView onAppear")
            }
            .onDisappear {
                addLog("Parent SwiftUIViewLifecycleExampleView onDisappear")
            }
        }
    }

    private func addLog(_ message: String) {
        let entry = LifecycleLogEntry(timestamp: Date(), message: message)
        logs.insert(entry, at: 0)
        print("🧩 [SwiftUIViewLifecycle] \(message)")
    }
}

// MARK: - Header Card

struct SwiftUILifecycleHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "viewfinder.circle")
                    .foregroundColor(.blue)
                Text("SwiftUI View Lifecycle")
                    .font(.headline)
            }

            Text("""
            In SwiftUI, Views are lightweight structs, not persistent objects:

            • init(): Called frequently when parent recreates view hierarchy
            • body: Evaluated when state or environment changes
            • .onAppear: Triggered when view renders on screen
            • .onDisappear: Triggered when view is removed from screen
            • .task: Runs async work and cancels automatically on disappear
            • .onChange: Reacts to state changes with (oldValue, newValue)
            """)
            .font(.caption)
            .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Child View Lifecycle Card

struct ChildViewLifecycleCard: View {
    @Binding var showChild: Bool
    let childId: UUID
    let onResetId: () -> Void
    let onLog: (String) -> Void

    var body: some View {
        ExampleCard(
            title: "1. View Mounting & Identity",
            description: "Observe onAppear/onDisappear and explicit identity changes"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button(showChild ? "Hide Child View" : "Show Child View") {
                        showChild.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)

                    Button("Reset Identity (.id)") {
                        onResetId()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

                if showChild {
                    LifecycleChildView(onLog: onLog)
                        .id(childId)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("Child view is unmounted (onDisappear called).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Child View

struct LifecycleChildView: View {
    let onLog: (String) -> Void
    @State private var internalState: Int = 0

    init(onLog: @escaping (String) -> Void) {
        self.onLog = onLog
        // Note: init is called during layout calculation
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Child View Active (Internal State: \(internalState))")
                    .font(.caption)
                    .fontWeight(.semibold)
            }

            Button("Increment Child State") {
                internalState += 1
                onLog("Child View internalState modified: \(internalState)")
            }
            .buttonStyle(.bordered)
            .font(.caption)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(6)
        .onAppear {
            let msg = "🟢 Child View: .onAppear()"
            print("🧩 [SwiftUIViewLifecycle] \(msg)")
            onLog(msg)
        }
        .onDisappear {
            let msg = "🔴 Child View: .onDisappear()"
            print("🧩 [SwiftUIViewLifecycle] \(msg)")
            onLog(msg)
        }
    }
}

// MARK: - OnChange Card

struct OnChangeLifecycleCard: View {
    @Binding var counter: Int
    let onLog: (String) -> Void

    var body: some View {
        ExampleCard(
            title: "2. State Observation (.onChange)",
            description: "Reacting to state mutations with old and new values"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Counter: \(counter)")
                        .font(.subheadline)
                        .fontWeight(.bold)

                    Spacer()

                    Button("+ Increment") {
                        counter += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }

                CodeExample("""
                .onChange(of: counter) { oldValue, newValue in
                    print("Changed from \\(oldValue) to \\(newValue)")
                }
                """)
            }
        }
        .onChange(of: counter) { oldValue, newValue in
            onLog("🔄 .onChange: counter modified from \(oldValue) to \(newValue)")
        }
    }
}

// MARK: - Task Lifecycle Card

struct TaskLifecycleCard: View {
    let onLog: (String) -> Void
    @State private var isRunningTask: Bool = false
    @State private var taskProgress: Int = 0

    var body: some View {
        ExampleCard(
            title: "3. Async Lifecycle (.task)",
            description: "Automatic cooperative cancellation when view disappears"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Status: \(isRunningTask ? "Running (\(taskProgress)%)" : "Idle")")
                        .font(.caption)
                        .foregroundColor(isRunningTask ? .blue : .secondary)

                    Spacer()

                    Button(isRunningTask ? "Cancel Task" : "Start 3s Async Task") {
                        isRunningTask.toggle()
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

                CodeExample("""
                .task {
                    // Automatically cancelled if view is dismissed
                    await fetchData()
                }
                """)
            }
        }
        .task(id: isRunningTask) {
            guard isRunningTask else { return }
            onLog("⚡️ .task started")
            for i in 1...3 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if Task.isCancelled {
                    onLog("🛑 .task was cancelled")
                    return
                }
                taskProgress = i * 33
            }
            onLog("✅ .task completed successfully")
            isRunningTask = false
            taskProgress = 0
        }
    }
}

// MARK: - Best Practices Card

struct SwiftUILifecycleBestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(.green)
                Text("SwiftUI Lifecycle Best Practices")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("• Never make network calls or heavy calculations in View init()")
                Text("• Use .task instead of .onAppear for async operations")
                Text("• Use @StateObject for single-instance VM lifecycle ownership")
                Text("• Understand that View structs are created many times per second")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SwiftUIViewLifecycleExampleView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIViewLifecycleExampleView()
    }
}
