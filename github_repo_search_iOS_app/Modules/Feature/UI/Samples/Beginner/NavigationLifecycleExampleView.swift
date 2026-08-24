//
//  NavigationLifecycleExampleView.swift
//  github_repo_search_iOS_app
//
//  Navigation Controller Lifecycle Sample
//  Demonstrates the interleaving of lifecycle methods during UINavigationController push/pop.
//

import SwiftUI
import UIKit

struct NavigationLifecycleExampleView: View {
    @State private var currentStep: Int = 0
    @State private var activeTransition: TransitionType = .push
    @State private var isAutoPlaying: Bool = false
    @State private var logs: [LifecycleLogEntry] = []

    enum TransitionType: String, CaseIterable {
        case push = "Push (A → B)"
        case pop = "Pop (B → A)"
    }

    private let pushSteps: [InterleavingStep] = [
        InterleavingStep(
            order: 1,
            caller: "System",
            method: "NavigationController.pushViewController(B, animated: true)",
            target: "Stack",
            explanation: "Push operation is queued on navigation controller."
        ),
        InterleavingStep(
            order: 2,
            caller: "VC B",
            method: "init()",
            target: "VC B",
            explanation: "ViewController B is allocated in memory."
        ),
        InterleavingStep(
            order: 3,
            caller: "VC B",
            method: "loadView() & viewDidLoad()",
            target: "VC B",
            explanation: "B creates its view hierarchy. Note: A is STILL fully visible!"
        ),
        InterleavingStep(
            order: 4,
            caller: "VC A",
            method: "viewWillDisappear(true)",
            target: "VC A",
            explanation: "A receives notice that it is about to leave the screen."
        ),
        InterleavingStep(
            order: 5,
            caller: "VC B",
            method: "viewWillAppear(true)",
            target: "VC B",
            explanation: "B receives notice that it is about to appear on screen."
        ),
        InterleavingStep(
            order: 6,
            caller: "UIKit CoreAnimation",
            method: "Push Transition Animation Runs (0.35s)",
            target: "Screen",
            explanation: "Both views are visible simultaneously in transition."
        ),
        InterleavingStep(
            order: 7,
            caller: "VC A",
            method: "viewDidDisappear(true)",
            target: "VC A",
            explanation: "A is now offscreen (remains in memory on the stack)."
        ),
        InterleavingStep(
            order: 8,
            caller: "VC B",
            method: "viewDidAppear(true)",
            target: "VC B",
            explanation: "B is now fully interactive on screen."
        )
    ]

    private let popSteps: [InterleavingStep] = [
        InterleavingStep(
            order: 1,
            caller: "System",
            method: "NavigationController.popViewController(animated: true)",
            target: "Stack",
            explanation: "Pop operation is queued on navigation controller."
        ),
        InterleavingStep(
            order: 2,
            caller: "VC B",
            method: "viewWillDisappear(true)",
            target: "VC B",
            explanation: "B is about to be popped off screen."
        ),
        InterleavingStep(
            order: 3,
            caller: "VC A",
            method: "viewWillAppear(true)",
            target: "VC A",
            explanation: "A is about to reappear from the stack."
        ),
        InterleavingStep(
            order: 4,
            caller: "UIKit CoreAnimation",
            method: "Pop Transition Animation Runs (0.35s)",
            target: "Screen",
            explanation: "Both views animate in reverse coordination."
        ),
        InterleavingStep(
            order: 5,
            caller: "VC B",
            method: "viewDidDisappear(true)",
            target: "VC B",
            explanation: "B is completely offscreen."
        ),
        InterleavingStep(
            order: 6,
            caller: "VC A",
            method: "viewDidAppear(true)",
            target: "VC A",
            explanation: "A is active and interactive again."
        ),
        InterleavingStep(
            order: 7,
            caller: "VC B",
            method: "deinit",
            target: "VC B",
            explanation: "B is released from the navigation stack and deallocated."
        )
    ]

    private var activeSteps: [InterleavingStep] {
        activeTransition == .push ? pushSteps : popSteps
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    NavigationInterleavingHeaderCard()

                    // Transition Selector & Controls
                    TransitionSelectorCard(
                        activeTransition: $activeTransition,
                        currentStep: $currentStep,
                        totalSteps: activeSteps.count,
                        onReset: {
                            currentStep = 0
                            logs.removeAll()
                            addLog("Reset sequence for \(activeTransition.rawValue)")
                        },
                        onNextStep: executeNextStep
                    )

                    // Step Visualizer
                    StepVisualizerCard(
                        steps: activeSteps,
                        currentStep: currentStep
                    )

                    // Live Event Log
                    LifecycleEventLogCard(
                        logs: logs,
                        onClear: { logs.removeAll() }
                    )

                    // Interview Highlights
                    NavigationInterviewHighlightsCard()
                }
                .padding()
            }
            .navigationTitle("Navigation Lifecycle")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                addLog("Loaded Navigation Controller Lifecycle Interleaving Visualizer")
            }
        }
    }

    private func executeNextStep() {
        if currentStep < activeSteps.count {
            let step = activeSteps[currentStep]
            addLog("Step \(step.order): [\(step.caller)] \(step.method)")
            currentStep += 1
        }
    }

    private func addLog(_ message: String) {
        let entry = LifecycleLogEntry(timestamp: Date(), message: message)
        logs.insert(entry, at: 0)
        print("🧭 [NavigationLifecycle] \(message)")
    }
}

// MARK: - Models

struct InterleavingStep: Identifiable {
    let id = UUID()
    let order: Int
    let caller: String
    let method: String
    let target: String
    let explanation: String
}

// MARK: - Header Card

struct NavigationInterleavingHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.left.arrow.right.square")
                    .foregroundColor(.blue)
                Text("Navigation Lifecycle Interleaving")
                    .font(.headline)
            }

            Text("""
            When pushing or popping ViewControllers, lifecycle methods INTERLEAVE:

            • VC A does NOT completely disappear before VC B begins loading
            • VC B's viewDidLoad executes BEFORE VC A's viewWillDisappear
            • During transition animation, both views are active in the view hierarchy
            • During pop, VC B's deinit only occurs after viewDidDisappear
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

// MARK: - Transition Selector Card

struct TransitionSelectorCard: View {
    @Binding var activeTransition: NavigationLifecycleExampleView.TransitionType
    @Binding var currentStep: Int
    let totalSteps: Int
    let onReset: () -> Void
    let onNextStep: () -> Void

    var body: some View {
        ExampleCard(
            title: "1. Interactive Step-by-Step Interleaving",
            description: "Step through push and pop sequences to observe timing"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Transition", selection: $activeTransition) {
                    ForEach(NavigationLifecycleExampleView.TransitionType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: activeTransition) { _, _ in
                    onReset()
                }

                HStack {
                    Button(currentStep >= totalSteps ? "Sequence Finished" : "Next Step (\(currentStep)/\(totalSteps))") {
                        onNextStep()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(currentStep >= totalSteps)
                    .font(.caption)

                    Spacer()

                    Button("Restart", action: onReset)
                        .buttonStyle(.bordered)
                        .font(.caption)
                }
            }
        }
    }
}

// MARK: - Step Visualizer Card

struct StepVisualizerCard: View {
    let steps: [InterleavingStep]
    let currentStep: Int

    var body: some View {
        ExampleCard(
            title: "2. Execution Timeline",
            description: "Visual trace of method calls across VC A, VC B, and UIKit"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    let isCurrent = index == currentStep - 1
                    let isCompleted = index < currentStep

                    HStack(alignment: .top, spacing: 8) {
                        Text("\(step.order)")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 18, height: 18)
                            .background(isCurrent ? Color.blue : (isCompleted ? Color.green : Color.gray.opacity(0.2)))
                            .foregroundColor(isCompleted ? .white : .primary)
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text("[\(step.caller)]")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(isCurrent ? .blue : .primary)
                                Text(step.method)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(isCurrent ? .blue : .secondary)
                            }
                            Text(step.explanation)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(6)
                    .background(isCurrent ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(6)

                    if index < steps.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
}

// MARK: - Interview Highlights

struct NavigationInterviewHighlightsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "graduationcap")
                    .foregroundColor(.purple)
                Text("Classic Interview Traps")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("❓ Trap: \"Does VC A disappear before VC B is created?\"")
                    .fontWeight(.semibold)
                Text("👉 Answer: No. VC B's init, loadView, and viewDidLoad all finish BEFORE VC A's viewWillDisappear is called.")
                    .padding(.bottom, 4)

                Text("❓ Trap: \"When is VC B's deinit called on Pop?\"")
                    .fontWeight(.semibold)
                Text("👉 Answer: Only after VC B's viewDidDisappear finishes, assuming no retain cycle holds a reference.")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.purple.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NavigationLifecycleExampleView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationLifecycleExampleView()
    }
}
