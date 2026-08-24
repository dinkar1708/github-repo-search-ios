//
//  MainTabView.swift
//  github_repo_search_iOS_app
//
//  Created for Tab Navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showSamplesList = false

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                UserSearchView()
                    .tabItem {
                        Label("Users", systemImage: "person.circle")
                    }
                    .tag(0)

                HomeView()
                    .tabItem {
                        Label("Repositories", systemImage: "folder")
                    }
                    .tag(1)

                FavoritesView()
                    .tabItem {
                        Label("Favorites", systemImage: "star")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }

            // Floating Action Button - Only show on first tab
            if selectedTab == 0 {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            showSamplesList = true
                        }) {
                            Label("Open Samples", systemImage: "list.bullet.rectangle")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 90) // Account for tab bar
                    }
                }
            }
        }
        .sheet(isPresented: $showSamplesList) {
            SamplesListView()
        }
    }
}

// Sample Item Model
struct SampleItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let category: String
    let destination: AnyView
}

// Samples List View
struct SamplesListView: View {
    @Environment(\.dismiss) var dismiss

    // Sample items organized by category
    private let samples: [SampleItem] = [
        // Beginner Examples
        SampleItem(
            title: "Optionals",
            description: "Optional types, unwrapping, nil coalescing, optional chaining",
            category: "Beginner",
            destination: AnyView(OptionalsExampleView())
        ),
        SampleItem(
            title: "State & Property Wrappers",
            description: "@State, @Binding, @StateObject, state management",
            category: "Beginner",
            destination: AnyView(StatePropertyWrappersView())
        ),
        SampleItem(
            title: "Async/Await",
            description: "Swift Concurrency, Task, async functions, TaskGroup",
            category: "Beginner",
            destination: AnyView(AsyncAwaitView())
        ),
        SampleItem(
            title: "App Lifecycle",
            description: "App states, ScenePhase transitions, background tasks",
            category: "Beginner",
            destination: AnyView(AppLifecycleExampleView())
        ),
        SampleItem(
            title: "Scene Lifecycle",
            description: "Multi-window UIScene lifecycle, @SceneStorage state persistence",
            category: "Beginner",
            destination: AnyView(SceneLifecycleExampleView())
        ),
        SampleItem(
            title: "SwiftUI View Lifecycle",
            description: "View init, onAppear, onDisappear, .task cancellation, .onChange",
            category: "Beginner",
            destination: AnyView(SwiftUIViewLifecycleExampleView())
        ),
        SampleItem(
            title: "UIViewController Lifecycle",
            description: "loadView, viewDidLoad, viewWillAppear/viewDidAppear flow in UIKit",
            category: "Beginner",
            destination: AnyView(ViewControllerLifecycleExampleView())
        ),
        SampleItem(
            title: "Navigation Controller Lifecycle",
            description: "Interleaving of methods during push/pop transitions in UIKit",
            category: "Beginner",
            destination: AnyView(NavigationLifecycleExampleView())
        ),
        SampleItem(
            title: "Lifecycle Methods Guide",
            description: "Comprehensive comparison matrix across UIKit, SwiftUI, and App states",
            category: "Beginner",
            destination: AnyView(LifecycleMethodsOverviewView())
        ),

        // Advanced / Dev Tools
        SampleItem(
            title: "Memory Leak Detection",
            description: "Detect and fix leaks using Instruments, Memory Debugger",
            category: "Advanced",
            destination: AnyView(MemoryLeakDetectionView())
        ),
        SampleItem(
            title: "Performance Monitoring",
            description: "Optimize rendering, measure performance with Instruments",
            category: "Advanced",
            destination: AnyView(PerformanceMonitoringView())
        )
    ]

    private var beginnerSamples: [SampleItem] {
        samples.filter { $0.category == "Beginner" }
    }

    private var intermediateSamples: [SampleItem] {
        samples.filter { $0.category == "Intermediate" }
    }

    private var advancedSamples: [SampleItem] {
        samples.filter { $0.category == "Advanced" }
    }

    var body: some View {
        NavigationView {
            List {
                // Header
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iOS Training Examples")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Interactive examples for Swift, SwiftUI & iOS")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }

                // Beginner Section (if any)
                if !beginnerSamples.isEmpty {
                    Section("Beginner (\(beginnerSamples.count))") {
                        ForEach(beginnerSamples) { sample in
                            NavigationLink(destination: sample.destination) {
                                SampleRow(sample: sample)
                            }
                        }
                    }
                }

                // Intermediate Section (if any)
                if !intermediateSamples.isEmpty {
                    Section("Intermediate (\(intermediateSamples.count))") {
                        ForEach(intermediateSamples) { sample in
                            NavigationLink(destination: sample.destination) {
                                SampleRow(sample: sample)
                            }
                        }
                    }
                }

                // Advanced Section
                if !advancedSamples.isEmpty {
                    Section("Advanced / Dev Tools (\(advancedSamples.count))") {
                        ForEach(advancedSamples) { sample in
                            NavigationLink(destination: sample.destination) {
                                SampleRow(sample: sample)
                            }
                        }
                    }
                }

                // Footer
                Section {
                    Text("More examples coming soon!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
            .navigationTitle("Samples")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Sample Row Component
struct SampleRow: View {
    let sample: SampleItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sample.title)
                .font(.headline)
            Text(sample.description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    MainTabView()
}
