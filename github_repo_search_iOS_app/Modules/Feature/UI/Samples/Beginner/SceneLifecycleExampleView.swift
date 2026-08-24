//
//  SceneLifecycleExampleView.swift
//  github_repo_search_iOS_app
//
//  iOS Scene Lifecycle Sample
//  Demonstrates UIScene lifecycle, multi-window support, and @SceneStorage state restoration.
//

import SwiftUI

struct SceneLifecycleExampleView: View {
    @Environment(\.scenePhase) private var scenePhase
    @SceneStorage("scene_sample_note") private var savedNote: String = ""
    @State private var currentNote: String = ""
    @State private var sceneLogs: [LifecycleLogEntry] = []
    @State private var simulatedSceneState: String = "Foreground Active"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    SceneLifecycleHeaderCard()

                    // Scene Storage Demo
                    SceneStorageExampleCard(
                        savedNote: $savedNote,
                        currentNote: $currentNote,
                        onSave: {
                            savedNote = currentNote
                            addLog("Saved to @SceneStorage: \"\(currentNote)\"")
                        }
                    )

                    // Multi-Window & Scene Phase States
                    SceneStatesVisualizerCard(
                        simulatedState: $simulatedSceneState,
                        onTransition: { state in
                            addLog("Scene transitioned: \(state)")
                        }
                    )

                    // UIKit SceneDelegate vs SwiftUI Scene
                    SceneDelegateComparisonCard()

                    // Live Event Log
                    LifecycleEventLogCard(
                        logs: sceneLogs,
                        onClear: { sceneLogs.removeAll() }
                    )

                    // Best Practices
                    SceneBestPracticesCard()
                }
                .padding()
            }
            .navigationTitle("Scene Lifecycle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                currentNote = savedNote
                addLog("Scene initialized - Restored note: \"\(savedNote)\"")
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                addLog("Scene phase changed to: \(phaseName(newPhase))")
            }
        }
    }

    private func phaseName(_ phase: ScenePhase) -> String {
        switch phase {
        case .active: return "Foreground Active"
        case .inactive: return "Foreground Inactive"
        case .background: return "Background"
        @unknown default: return "Unknown"
        }
    }

    private func addLog(_ message: String) {
        let entry = LifecycleLogEntry(timestamp: Date(), message: message)
        sceneLogs.insert(entry, at: 0)
        print("🪟 [SceneLifecycle] \(message)")
    }
}

// MARK: - Header Card

struct SceneLifecycleHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rectangle.split.2x1")
                    .foregroundColor(.blue)
                Text("iOS Scene Lifecycle (iOS 13+)")
                    .font(.headline)
            }

            Text("""
            Introduced in iOS 13 for multiple windows on iPad & Mac Catalyst:

            • App Lifecycle manages process-level events (memory, termination)
            • Scene Lifecycle manages individual UI windows/instances
            • Each Scene has its own lifecycle independent of other scenes
            • State restoration per scene is enabled via @SceneStorage
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

// MARK: - Scene Storage Card

struct SceneStorageExampleCard: View {
    @Binding var savedNote: String
    @Binding var currentNote: String
    let onSave: () -> Void

    var body: some View {
        ExampleCard(
            title: "1. Scene State Restoration (@SceneStorage)",
            description: "Persists UI state per-window independently across app sessions"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                TextField("Type draft note here...", text: $currentNote)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button("Save to Scene") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)

                    Spacer()

                    Text("Stored: \"\(savedNote)\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                CodeExample("""
                // State restored automatically for this window
                @SceneStorage("user_draft") private var draftText: String = ""
                """)
            }
        }
    }
}

// MARK: - Scene States Visualizer

struct SceneStatesVisualizerCard: View {
    @Binding var simulatedState: String
    let onTransition: (String) -> Void

    var body: some View {
        ExampleCard(
            title: "2. Scene State Transitions",
            description: "Simulate multi-scene lifecycle phases"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 6) {
                    SceneStateBadge(name: "Unattached", active: simulatedState == "Unattached")
                    Image(systemName: "arrow.right").font(.system(size: 9))
                    SceneStateBadge(name: "Inactive", active: simulatedState == "Foreground Inactive")
                    Image(systemName: "arrow.right").font(.system(size: 9))
                    SceneStateBadge(name: "Active", active: simulatedState == "Foreground Active")
                }

                HStack(spacing: 8) {
                    Button("Connect Scene") {
                        simulatedState = "Foreground Active"
                        onTransition("Scene Connected & Active")
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("Resign Active") {
                        simulatedState = "Foreground Inactive"
                        onTransition("Scene Resigned Active")
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("Disconnect") {
                        simulatedState = "Unattached"
                        onTransition("Scene Disconnected by OS")
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }
}

struct SceneStateBadge: View {
    let name: String
    let active: Bool

    var body: some View {
        Text(name)
            .font(.system(size: 10, weight: active ? .bold : .regular))
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(active ? Color.blue : Color.gray.opacity(0.15))
            .foregroundColor(active ? .white : .primary)
            .cornerRadius(4)
    }
}

// MARK: - Comparison Card

struct SceneDelegateComparisonCard: View {
    var body: some View {
        ExampleCard(
            title: "3. UIKit SceneDelegate vs SwiftUI Scene",
            description: "How scene callbacks map between frameworks"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                CodeExample("""
                // UIKit (SceneDelegate.swift):
                func sceneDidBecomeActive(_ scene: UIScene)
                func sceneWillResignActive(_ scene: UIScene)
                func sceneDidEnterBackground(_ scene: UIScene)
                func sceneDidDisconnect(_ scene: UIScene)

                // SwiftUI (@main struct App):
                WindowGroup { ContentView() }
                    .onChange(of: scenePhase) { old, new in ... }
                """)
            }
        }
    }
}

// MARK: - Best Practices Card

struct SceneBestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(.green)
                Text("Scene Lifecycle Best Practices")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("• Store lightweight UI draft state in @SceneStorage")
                Text("• Store persistent business data in CoreData/SwiftData or AppStorage")
                Text("• Clean up memory when sceneDidDisconnect is called (window closed)")
                Text("• Do not assume a single key window in iOS 13+ apps")
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

struct SceneLifecycleExampleView_Previews: PreviewProvider {
    static var previews: some View {
        SceneLifecycleExampleView()
    }
}
