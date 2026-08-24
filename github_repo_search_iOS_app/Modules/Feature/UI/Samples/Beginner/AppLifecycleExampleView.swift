//
//  AppLifecycleExampleView.swift
//  github_repo_search_iOS_app
//
//  iOS App Lifecycle Sample & Live Monitor
//  Demonstrates scenePhase transitions, background tasks, and application state handling.
//

import SwiftUI

struct AppLifecycleExampleView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var lifecycleLogs: [LifecycleLogEntry] = []
    @State private var simulatedState: String = "Active (Foreground)"
    @State private var backgroundTaskTimeRemaining: Double = 30.0
    @State private var isSimulatingBackgroundTask: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppLifecycleHeaderCard()

                    // Live ScenePhase Monitor
                    LiveScenePhaseCard(currentPhase: scenePhase)

                    // Simulated Lifecycle Transitions
                    AppLifecycleSimulationCard(
                        simulatedState: $simulatedState,
                        onStateChange: { newState in
                            addLog("Simulated transition: \(newState)")
                        }
                    )

                    // Background Task Simulator
                    BackgroundTaskSimulatorCard(
                        isSimulating: $isSimulatingBackgroundTask,
                        timeRemaining: backgroundTaskTimeRemaining,
                        onStart: startBackgroundTaskSimulation
                    )

                    // Event Log
                    LifecycleEventLogCard(
                        logs: lifecycleLogs,
                        onClear: { lifecycleLogs.removeAll() }
                    )

                    // Best Practices
                    AppLifecycleBestPracticesCard()
                }
                .padding()
            }
            .navigationTitle("App Lifecycle")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                let transition = "Phase changed from \(phaseName(oldPhase)) to \(phaseName(newPhase))"
                addLog(transition)
            }
            .onAppear {
                addLog("AppLifecycleExampleView appeared - Initial phase: \(phaseName(scenePhase))")
            }
        }
    }

    private func phaseName(_ phase: ScenePhase) -> String {
        switch phase {
        case .active: return "🟢 Active"
        case .inactive: return "🟡 Inactive"
        case .background: return "🔴 Background"
        @unknown default: return "⚪️ Unknown"
        }
    }

    private func addLog(_ message: String) {
        let entry = LifecycleLogEntry(
            timestamp: Date(),
            message: message
        )
        lifecycleLogs.insert(entry, at: 0)
        print("📱 [AppLifecycle] \(message)")
    }

    private func startBackgroundTaskSimulation() {
        isSimulatingBackgroundTask = true
        backgroundTaskTimeRemaining = 30.0
        addLog("Background Task Started: beginBackgroundTask(expirationHandler: ...)")

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if backgroundTaskTimeRemaining > 0 {
                backgroundTaskTimeRemaining -= 5.0
                addLog("Background task progress: \(Int(backgroundTaskTimeRemaining))s remaining")
            } else {
                timer.invalidate()
                isSimulatingBackgroundTask = false
                addLog("Background Task Ended: endBackgroundTask(identifier)")
            }
        }
    }
}

// MARK: - Log Entry Model

struct LifecycleLogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
}

// MARK: - Header Card

struct AppLifecycleHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "app.badge.checkmark")
                    .foregroundColor(.blue)
                Text("iOS App Lifecycle")
                    .font(.headline)
            }

            Text("""
            The App Lifecycle manages the application's overall state from launch to termination:

            • Active: Running in foreground, receiving events
            • Inactive: Foreground but not receiving events (e.g. system alert, App Switcher)
            • Background: Executing code while not visible to user
            • Suspended: In memory but paused by iOS to conserve battery
            • Not Running: Terminated or not yet launched
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

// MARK: - Live ScenePhase Card

struct LiveScenePhaseCard: View {
    let currentPhase: ScenePhase

    var body: some View {
        ExampleCard(
            title: "1. Real-time ScenePhase Monitor",
            description: "Observing @Environment(\\.scenePhase) in SwiftUI"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(phaseColor)
                        .frame(width: 16, height: 16)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current State: \(phaseTitle)")
                            .font(.subheadline)
                            .fontWeight(.bold)
                        Text(phaseDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(phaseColor.opacity(0.1))
                .cornerRadius(8)

                CodeExample("""
                @Environment(\\.scenePhase) private var scenePhase

                .onChange(of: scenePhase) { oldPhase, newPhase in
                    switch newPhase {
                    case .active:     print("Active")
                    case .inactive:   print("Inactive")
                    case .background: print("Background")
                    }
                }
                """)
            }
        }
    }

    private var phaseColor: Color {
        switch currentPhase {
        case .active: return .green
        case .inactive: return .orange
        case .background: return .red
        @unknown default: return .gray
        }
    }

    private var phaseTitle: String {
        switch currentPhase {
        case .active: return "Active (Foreground)"
        case .inactive: return "Inactive (Temporary)"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }

    private var phaseDescription: String {
        switch currentPhase {
        case .active: return "App is interactive and visible on screen."
        case .inactive: return "Interrupted by phone call, notification shade, or app switcher."
        case .background: return "App is hidden. Perform cleanup or schedule background work."
        @unknown default: return "Unspecified scene phase."
        }
    }
}

// MARK: - Simulation Card

struct AppLifecycleSimulationCard: View {
    @Binding var simulatedState: String
    let onStateChange: (String) -> Void

    var body: some View {
        ExampleCard(
            title: "2. Lifecycle State Simulator",
            description: "Test how apps handle incoming interruptions and backgrounding"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Simulate Scenario:")
                    .font(.caption)
                    .fontWeight(.semibold)

                HStack(spacing: 8) {
                    Button("📞 Phone Call") {
                        simulatedState = "Inactive (Phone Call Interruption)"
                        onStateChange(simulatedState)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("🔒 Lock Screen") {
                        simulatedState = "Background (Device Locked)"
                        onStateChange(simulatedState)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("🏠 Home Button") {
                        simulatedState = "Background (Home Pressed)"
                        onStateChange(simulatedState)
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }

                HStack {
                    Text("State:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(simulatedState)
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding(.top, 4)
            }
        }
    }
}

// MARK: - Background Task Simulator

struct BackgroundTaskSimulatorCard: View {
    @Binding var isSimulating: Bool
    let timeRemaining: Double
    let onStart: () -> Void

    var body: some View {
        ExampleCard(
            title: "3. Background Task Execution",
            description: "UIApplication.shared.beginBackgroundTask demo"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Request extra background execution time before suspension:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if isSimulating {
                    ProgressView(value: timeRemaining, total: 30.0) {
                        Text("Task running... (\(Int(timeRemaining))s remaining)")
                            .font(.caption)
                    }
                    .progressViewStyle(.linear)
                } else {
                    Button("Start Simulated Background Task") {
                        onStart()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }

                CodeExample("""
                let taskId = UIApplication.shared.beginBackgroundTask {
                    // Expiration handler: clean up before suspension
                    UIApplication.shared.endBackgroundTask(taskId)
                }
                """)
            }
        }
    }
}

// MARK: - Event Log Card

struct LifecycleEventLogCard: View {
    let logs: [LifecycleLogEntry]
    let onClear: () -> Void

    var body: some View {
        ExampleCard(
            title: "4. Live Event Log",
            description: "Sequence of captured lifecycle events"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(logs.count) Events Logged")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Clear", action: onClear)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                if logs.isEmpty {
                    Text("No events logged yet.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(logs.prefix(6)) { log in
                            HStack(alignment: .top, spacing: 6) {
                                Text(formattedTime(log.timestamp))
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                                Text(log.message)
                                    .font(.system(size: 11))
                            }
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SS"
        return formatter.string(from: date)
    }
}

// MARK: - Best Practices Card

struct AppLifecycleBestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(.green)
                Text("App Lifecycle Best Practices")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("• Save unsaved user work immediately when entering .background")
                Text("• Pause animations, timers, and audio when entering .inactive")
                Text("• Refresh stale network data and re-authenticate when entering .active")
                Text("• Release heavy cached objects during memory pressure")
                Text("• Use BGTaskScheduler for scheduled background tasks in iOS 13+")
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

struct AppLifecycleExampleView_Previews: PreviewProvider {
    static var previews: some View {
        AppLifecycleExampleView()
    }
}
