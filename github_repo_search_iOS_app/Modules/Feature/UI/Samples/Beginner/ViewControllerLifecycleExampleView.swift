//
//  ViewControllerLifecycleExampleView.swift
//  github_repo_search_iOS_app
//
//  UIViewController Lifecycle Sample
//  Demonstrates UIKit UIViewController lifecycle callbacks using UIViewControllerRepresentable.
//

import SwiftUI
import UIKit

struct ViewControllerLifecycleExampleView: View {
    @State private var showModalVC: Bool = false
    @State private var showFullScreenVC: Bool = false
    @State private var logs: [LifecycleLogEntry] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ViewControllerLifecycleHeaderCard()

                    // Embedded UIKit Controller Demo
                    EmbeddedVCDemoCard(
                        onLog: { msg in addLog(msg) }
                    )

                    // Modal Presentation Lifecycle Demo
                    ModalPresentationLifecycleCard(
                        showModal: $showModalVC,
                        showFullScreen: $showFullScreenVC,
                        onLog: { msg in addLog(msg) }
                    )

                    // Lifecycle Method Flow Reference
                    VCLifecycleSequenceCard()

                    // Live Event Log
                    LifecycleEventLogCard(
                        logs: logs,
                        onClear: { logs.removeAll() }
                    )

                    // Best Practices
                    ViewControllerBestPracticesCard()
                }
                .padding()
            }
            .navigationTitle("UIViewController Lifecycle")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showModalVC) {
                TrackedViewControllerWrapper(presentationStyle: "Sheet Modal", onLog: { msg in addLog(msg) })
            }
            .fullScreenCover(isPresented: $showFullScreenVC) {
                TrackedViewControllerWrapper(presentationStyle: "Full Screen Cover", onLog: { msg in addLog(msg) })
            }
        }
    }

    private func addLog(_ message: String) {
        let entry = LifecycleLogEntry(timestamp: Date(), message: message)
        logs.insert(entry, at: 0)
        print("🏛️ [ViewControllerLifecycle] \(message)")
    }
}

// MARK: - Header Card

struct ViewControllerLifecycleHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "rectangle.stack")
                    .foregroundColor(.blue)
                Text("UIViewController Lifecycle")
                    .font(.headline)
            }

            Text("""
            UIKit ViewControllers follow an imperative, deterministic lifecycle:

            1. loadView(): Creates or loads the view hierarchy
            2. viewDidLoad(): One-time setup after view is loaded in memory
            3. viewWillAppear(_:): Called every time before view appears
            4. viewWillLayoutSubviews() / viewDidLayoutSubviews(): Frame calculations
            5. viewDidAppear(_:): View is visible on screen, safe for animations
            6. viewWillDisappear(_:) / viewDidDisappear(_:): Teardown & pausing
            7. deinit: Called when VC is deallocated from memory
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

// MARK: - Embedded VC Demo Card

struct EmbeddedVCDemoCard: View {
    let onLog: (String) -> Void
    @State private var isEmbeddedVisible: Bool = true

    var body: some View {
        ExampleCard(
            title: "1. Live Embedded UIViewController",
            description: "A real UIKit UIViewController logging each lifecycle event"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button(isEmbeddedVisible ? "Unmount UIKit VC" : "Mount UIKit VC") {
                        isEmbeddedVisible.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                    .font(.caption)
                }

                if isEmbeddedVisible {
                    TrackedViewControllerWrapper(presentationStyle: "Embedded View", onLog: onLog)
                        .frame(height: 90)
                        .cornerRadius(8)
                } else {
                    Text("UIViewController removed (viewDidDisappear & deinit called).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
    }
}

// MARK: - Modal Presentation Card

struct ModalPresentationLifecycleCard: View {
    @Binding var showModal: Bool
    @Binding var showFullScreen: Bool
    let onLog: (String) -> Void

    var body: some View {
        ExampleCard(
            title: "2. Presentation & Dismissal Lifecycle",
            description: "Observe willAppear / didAppear / willDisappear / didDisappear"
        ) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Present a UIViewController to inspect lifecycle transition callbacks:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Button("Present Sheet") {
                        showModal = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)

                    Button("Present Full Screen") {
                        showFullScreen = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
    }
}

// MARK: - Sequence Reference Card

struct VCLifecycleSequenceCard: View {
    var body: some View {
        ExampleCard(
            title: "3. Lifecycle Order Diagram",
            description: "Complete execution order from allocation to deallocation"
        ) {
            CodeExample("""
            init(nibName:bundle:)
              ↓
            loadView()
              ↓
            viewDidLoad()              [⭐ One-time configuration]
              ↓
            viewWillAppear(_:)         [Called before every appearance]
              ↓
            viewWillLayoutSubviews()
              ↓
            viewDidLayoutSubviews()    [Bounds/geometry are finalized]
              ↓
            viewDidAppear(_:)          [Start timers, animations, analytics]
              ↓
            viewWillDisappear(_:)      [Resign first responder, pause audio]
              ↓
            viewDidDisappear(_:)       [Stop heavy tasks]
              ↓
            deinit                     [Release delegates, notifications]
            """)
        }
    }
}

// MARK: - UIViewControllerRepresentable

struct TrackedViewControllerWrapper: UIViewControllerRepresentable {
    let presentationStyle: String
    let onLog: (String) -> Void

    func makeUIViewController(context: Context) -> TrackedLifecycleViewController {
        let vc = TrackedLifecycleViewController(style: presentationStyle, onLog: onLog)
        return vc
    }

    func updateUIViewController(_ uiViewController: TrackedLifecycleViewController, context: Context) {}
}

class TrackedLifecycleViewController: UIViewController {
    let style: String
    let onLog: (String) -> Void

    init(style: String, onLog: @escaping (String) -> Void) {
        self.style = style
        self.onLog = onLog
        super.init(nibName: nil, bundle: nil)
        onLog("[\(style)] 0. init()")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        super.loadView()
        onLog("[\(style)] 1. loadView()")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemTeal.withAlphaComponent(0.15)
        onLog("[\(style)] 2. viewDidLoad()")

        let label = UILabel()
        label.text = "UIKit UIViewController (\(style))"
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        onLog("[\(style)] 3. viewWillAppear(animated: \(animated))")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        onLog("[\(style)] 4. viewWillLayoutSubviews()")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        onLog("[\(style)] 5. viewDidLayoutSubviews()")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        onLog("[\(style)] 6. viewDidAppear(animated: \(animated))")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onLog("[\(style)] 7. viewWillDisappear(animated: \(animated))")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onLog("[\(style)] 8. viewDidDisappear(animated: \(animated))")
    }

    deinit {
        onLog("[\(style)] 9. deinit (Deallocated)")
    }
}

// MARK: - Best Practices Card

struct ViewControllerBestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(.green)
                Text("UIViewController Best Practices")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("• Always call super.methodName() in lifecycle overrides")
                Text("• Do not read frame/bounds in viewDidLoad (read in viewDidLayoutSubviews)")
                Text("• Start animations and heavy UI work in viewDidAppear")
                Text("• Use [weak self] in closures to avoid retain cycles blocking deinit")
                Text("• Pair setups in willAppear with matching teardowns in willDisappear")
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

struct ViewControllerLifecycleExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerLifecycleExampleView()
    }
}
