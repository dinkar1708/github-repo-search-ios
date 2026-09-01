//
//  StatePropertyWrappersView.swift
//  github_repo_search_iOS_app
//
//  State & Property Wrappers Examples
//
//  Demonstrates @State, @Binding, @StateObject, @ObservedObject,
//  state hoisting, and SwiftUI's reactive update system.
//

import SwiftUI
import Observation

struct StatePropertyWrappersView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    StateHeaderCard()
                    StateExample()
                    BindingExample()
                    StateObjectExample()
                    BestPracticesCard()
                }
                .padding()
            }
            .navigationTitle("State & Property Wrappers")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Header

struct StateHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("SwiftUI State Management")
                    .font(.headline)
            }

            Text("""
            Property wrappers manage state in SwiftUI:

            • @State: Private mutable state owned by view
            • @Binding: Two-way connection to parent's state
            • @StateObject: Observable object owned by view
            • @ObservedObject: Observable object from parent
            • @EnvironmentObject: Shared dependency injection
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

// MARK: - @State Example

struct StateExample: View {
    @State private var counter = 0
    @State private var isOn = false
    @State private var name = ""

    var body: some View {
        ExampleCard(
            title: "1. @State - Private Mutable State",
            description: "Local state that triggers view updates when changed"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Counter: \(counter)")
                    .font(.headline)

                HStack {
                    Button("Increment") {
                        counter += 1
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Decrement") {
                        counter -= 1
                    }
                    .buttonStyle(.bordered)

                    Button("Reset") {
                        counter = 0
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                Divider()

                Toggle("Switch is \(isOn ? "ON" : "OFF")", isOn: $isOn)

                TextField("Enter name", text: $name)
                    .textFieldStyle(.roundedBorder)

                if !name.isEmpty {
                    Text("Hello, \(name)!")
                        .foregroundColor(.blue)
                }

                CodeExample("""
                struct MyView: View {
                    @State private var counter = 0  // ← Mutable state
                    @State private var isOn = false

                    var body: some View {
                        Button("Count: \\(counter)") {
                            counter += 1  // ← Triggers re-render
                        }
                    }
                }

                Key Points:
                • @State creates source of truth
                • Changes trigger view update
                • Private to the view
                • Use for simple value types (Int, String, Bool)
                """)
            }
        }
    }
}

// MARK: - @Binding Example

struct BindingExample: View {
    @State private var volume: Double = 50
    @State private var isPlaying = false

    var body: some View {
        ExampleCard(
            title: "2. @Binding - Two-Way Connection",
            description: "Pass state down and allow children to mutate it"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Parent View")
                    .font(.headline)

                Text("Volume: \(Int(volume))%")
                Text("Status: \(isPlaying ? "Playing" : "Paused")")
                    .foregroundColor(isPlaying ? .green : .gray)

                Divider()

                // Child components with bindings
                VolumeSlider(volume: $volume)
                PlayPauseButton(isPlaying: $isPlaying)

                CodeExample("""
                // Parent (has @State)
                struct ParentView: View {
                    @State private var volume: Double = 50

                    var body: some View {
                        VolumeSlider(volume: $volume)  // ← Pass binding
                    }
                }

                // Child (receives @Binding)
                struct VolumeSlider: View {
                    @Binding var volume: Double  // ← Two-way connection

                    var body: some View {
                        Slider(value: $volume, in: 0...100)
                        // Child can modify parent's state!
                    }
                }

                Key: $ creates binding from @State
                """)
            }
        }
    }
}

struct VolumeSlider: View {
    @Binding var volume: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Volume Slider (Child)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Slider(value: $volume, in: 0...100)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
}

struct PlayPauseButton: View {
    @Binding var isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Play/Pause (Child)")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(isPlaying ? "Pause" : "Play") {
                isPlaying.toggle()
            }
            .buttonStyle(.borderedProminent)
            .tint(isPlaying ? .orange : .green)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(4)
    }
}

// MARK: - @Observable (iOS 17+) & @StateObject Comparison

@Observable
class CounterViewModel {
    var count = 0
    var history: [String] = []

    func increment() {
        count += 1
        history.append("Incremented to \(count)")
    }

    func decrement() {
        count -= 1
        history.append("Decremented to \(count)")
    }

    func reset() {
        count = 0
        history.append("Reset to 0")
    }
}

struct StateObjectExample: View {
    @State private var viewModel = CounterViewModel()

    var body: some View {
        ExampleCard(
            title: "3. @Observable (iOS 17+) vs @StateObject",
            description: "Modern Swift Observation without @Published boilerplate"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Count: \(viewModel.count)")
                    .font(.title)
                    .fontWeight(.bold)

                HStack {
                    Button("Increment") {
                        viewModel.increment()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Decrement") {
                        viewModel.decrement()
                    }
                    .buttonStyle(.bordered)

                    Button("Reset") {
                        viewModel.reset()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                if !viewModel.history.isEmpty {
                    Text("History:")
                        .font(.headline)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(viewModel.history.indices, id: \.self) { index in
                                Text("\(index + 1). \(viewModel.history[index])")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxHeight: 100)
                }

                CodeExample("""
                // ✅ Modern iOS 17+: @Observable with standard variables
                @Observable
                class CounterViewModel {
                    var count = 0  // ← Automatically observable!

                    func increment() {
                        count += 1
                    }
                }

                struct MyView: View {
                    @State private var viewModel = CounterViewModel()
                    // ↑ Standard @State manages @Observable lifecycle

                    var body: some View {
                        Text("\\(viewModel.count)")
                        Button("Add") { viewModel.increment() }
                    }
                }

                When to use:
                • @Observable + @State: Modern standard (iOS 17+)
                • @Bindable: When passing two-way $ bindings to child views
                """)
            }
        }
    }
}

// MARK: - Best Practices

struct StateBestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Practices")
                .font(.headline)

            Text("""
            ✅ DO:
            • Use @State for simple local state (Int, String, Bool)
            • Use @StateObject when view OWNS the observable object
            • Use @Binding to pass state down the hierarchy
            • Mark @State as private
            • Keep state as minimal as possible

            ❌ DON'T:
            • Use @State for complex objects (use @StateObject)
            • Use @ObservedObject when view should own object
            • Mutate @State directly from child (use @Binding)
            • Share @State across views (use @StateObject)

            Decision Tree:
            Simple value? → @State
            Complex object you own? → @StateObject
            Object from parent? → @ObservedObject
            Need to modify parent state? → @Binding
            Shared dependency? → @EnvironmentObject
            """)
            .font(.caption)
            .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct StatePropertyWrappersView_Previews: PreviewProvider {
    static var previews: some View {
        StatePropertyWrappersView()
    }
}
