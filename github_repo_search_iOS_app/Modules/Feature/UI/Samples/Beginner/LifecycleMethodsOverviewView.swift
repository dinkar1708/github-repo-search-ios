//
//  LifecycleMethodsOverviewView.swift
//  github_repo_search_iOS_app
//
//  iOS Lifecycle Methods Overview & Matrix Sample
//  Comprehensive guide comparing UIKit UIViewController, SwiftUI View, App, and Scene lifecycles.
//

import SwiftUI

struct LifecycleMethodsOverviewView: View {
    @State private var selectedDomain: LifecycleDomain = .uikit
    @State private var selectedQuizAnswer: Int? = nil
    @State private var showQuizResult: Bool = false

    enum LifecycleDomain: String, CaseIterable {
        case uikit = "UIKit (VC)"
        case swiftui = "SwiftUI"
        case app = "App & Scene"
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    LifecycleOverviewHeaderCard()

                    // Domain Switcher & Matrix
                    DomainComparisonCard(selectedDomain: $selectedDomain)

                    // Interactive Technical Knowledge Check
                    LifecycleKnowledgeCheckCard(
                        selectedAnswer: $selectedQuizAnswer,
                        showResult: $showQuizResult
                    )

                    // Summary Cheat Sheet
                    LifecycleCheatSheetCard()
                }
                .padding()
            }
            .navigationTitle("Lifecycle Guide")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                print("📚 [LifecycleOverview] Opened Lifecycle Methods Overview")
            }
            .onChange(of: selectedDomain) { oldDomain, newDomain in
                print("📚 [LifecycleOverview] Switched domain to: \(newDomain.rawValue)")
            }
        }
    }
}

// MARK: - Header Card

struct LifecycleOverviewHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .foregroundColor(.blue)
                Text("iOS Lifecycle Methods Matrix")
                    .font(.headline)
            }

            Text("""
            Lifecycle methods determine when code executes as components are created, displayed, updated, and destroyed.

            Key Pillars:
            • UIViewController: Imperative, view hierarchy loading, layout & visibility
            • SwiftUI View: Declarative, struct re-creation, identity & state hooks
            • App Lifecycle: Process state, backgrounding, terminations
            • Scene Lifecycle: Multi-window session & scenePhase management
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

// MARK: - Domain Comparison Card

struct DomainComparisonCard: View {
    @Binding var selectedDomain: LifecycleMethodsOverviewView.LifecycleDomain

    var body: some View {
        ExampleCard(
            title: "1. Framework Lifecycle Matrix",
            description: "Select domain to review methods and responsibilities"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Domain", selection: $selectedDomain) {
                    ForEach(LifecycleMethodsOverviewView.LifecycleDomain.allCases, id: \.self) { domain in
                        Text(domain.rawValue).tag(domain)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedDomain {
                case .uikit:
                    UIKitDomainDetails()
                case .swiftui:
                    SwiftUIDomainDetails()
                case .app:
                    AppDomainDetails()
                }
            }
        }
    }
}

struct UIKitDomainDetails: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LifecycleMethodRow(name: "viewDidLoad()", purpose: "One-time setup (subviews, initial bindings)")
            LifecycleMethodRow(name: "viewWillAppear(_:)", purpose: "Prepare UI before appearing on screen")
            LifecycleMethodRow(name: "viewDidLayoutSubviews()", purpose: "Frame/bounds geometry is final and calculated")
            LifecycleMethodRow(name: "viewDidAppear(_:)", purpose: "Start animations, keyboard focus, timers")
            LifecycleMethodRow(name: "viewWillDisappear(_:)", purpose: "Resign first responder, pause media")
            LifecycleMethodRow(name: "deinit", purpose: "Clean up strong references, remove observers")
        }
    }
}

struct SwiftUIDomainDetails: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LifecycleMethodRow(name: "init()", purpose: "Lightweight view struct initialization (no side-effects)")
            LifecycleMethodRow(name: "body", purpose: "Declarative UI calculation evaluated whenever state changes")
            LifecycleMethodRow(name: ".onAppear {}", purpose: "View inserted into UI hierarchy on screen")
            LifecycleMethodRow(name: ".task {}", purpose: "Async work with automatic cooperative cancellation")
            LifecycleMethodRow(name: ".onChange(of:) {}", purpose: "Observe mutations to @State, @Binding, or @Published")
            LifecycleMethodRow(name: ".onDisappear {}", purpose: "View removed from UI hierarchy")
        }
    }
}

struct AppDomainDetails: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            LifecycleMethodRow(name: ".active", purpose: "App is running in foreground and receiving events")
            LifecycleMethodRow(name: ".inactive", purpose: "Temporarily interrupted by system UI, phone call, etc.")
            LifecycleMethodRow(name: ".background", purpose: "App running in background; save state immediately")
            LifecycleMethodRow(name: "sceneDidDisconnect", purpose: "UI Window closed by user in iPadOS/macOS")
        }
    }
}

struct LifecycleMethodRow: View {
    let name: String
    let purpose: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.blue)
            Text(purpose)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.06))
        .cornerRadius(4)
    }
}

// MARK: - Knowledge Check Card

struct LifecycleKnowledgeCheckCard: View {
    @Binding var selectedAnswer: Int?
    @Binding var showResult: Bool

    private let question = "Where is it safe to read final subview frame/bounds dimensions in UIKit?"
    private let options = [
        "1. viewDidLoad()",
        "2. viewWillAppear(_:)",
        "3. viewDidLayoutSubviews()",
        "4. loadView()"
    ]
    private let correctIndex = 2

    var body: some View {
        ExampleCard(
            title: "2. Technical Knowledge Check",
            description: "Test your understanding of iOS lifecycle fundamentals"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text(question)
                    .font(.caption)
                    .fontWeight(.bold)

                ForEach(0..<options.count, id: \.self) { index in
                    Button(action: {
                        selectedAnswer = index
                        showResult = true
                    }) {
                        HStack {
                            Text(options[index])
                                .font(.caption)
                                .foregroundColor(.primary)
                            Spacer()
                            if showResult && index == correctIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else if showResult && selectedAnswer == index {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(8)
                        .background(
                            showResult && index == correctIndex ? Color.green.opacity(0.15) :
                            (showResult && selectedAnswer == index ? Color.red.opacity(0.15) : Color.gray.opacity(0.05))
                        )
                        .cornerRadius(6)
                    }
                }

                if showResult {
                    Text(selectedAnswer == correctIndex
                         ? "✅ Correct! In viewDidLayoutSubviews(), AutoLayout has solved constraints and final frame dimensions are computed."
                         : "❌ Incorrect. In viewDidLoad and viewWillAppear, AutoLayout hasn't resolved frames yet. Use viewDidLayoutSubviews().")
                        .font(.caption2)
                        .foregroundColor(selectedAnswer == correctIndex ? .green : .red)
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Cheat Sheet Card

struct LifecycleCheatSheetCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(.green)
                Text("Golden Rules of iOS Lifecycles")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("1. SwiftUI: Do not store state or launch tasks inside View init().")
                Text("2. UIKit: Never call loadView() directly; override it only to set custom root view.")
                Text("3. UIKit: Pair notification subscriptions in viewWillAppear with removals in viewWillDisappear.")
                Text("4. Concurrency: Prefer .task in SwiftUI for automatic cancellation.")
                Text("5. Memory: Always verify deinit executes to detect retain cycles early.")
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

struct LifecycleMethodsOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        LifecycleMethodsOverviewView()
    }
}
