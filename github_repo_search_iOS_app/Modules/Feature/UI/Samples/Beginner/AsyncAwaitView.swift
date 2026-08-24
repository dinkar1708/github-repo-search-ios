//
//  AsyncAwaitView.swift
//  github_repo_search_iOS_app
//
//  Swift Concurrency: Async/Await Examples
//
//  Demonstrates async/await, Task, async sequences, actors,
//  and modern Swift concurrency patterns.
//

import SwiftUI

struct AsyncAwaitView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HeaderCard()
                    AsyncFunctionExample()
                    TaskExample()
                    TaskGroupExample()
                    BestPracticesCard()
                }
                .padding()
            }
            .navigationTitle("Async/Await")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Header

struct HeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
                Text("Swift Concurrency")
                    .font(.headline)
            }

            Text("""
            Modern async/await replaces completion handlers:

            • async: Function can suspend execution
            • await: Wait for async result
            • Task: Launch concurrent work
            • Task.detached: Background work
            • TaskGroup: Parallel execution
            • Actor: Thread-safe state
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

// MARK: - Async Function Example

struct AsyncFunctionExample: View {
    @State private var userData: String = ""
    @State private var isLoading = false

    var body: some View {
        ExampleCard(
            title: "1. Async Functions & Await",
            description: "Replace completion handlers with async/await"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                }

                if !userData.isEmpty {
                    Text(userData)
                        .font(.subheadline)
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(4)
                }

                Button("Fetch User Data") {
                    Task {
                        await loadUserData()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                CodeExample("""
                // ❌ OLD WAY: Completion handlers
                func fetchUser(completion: @escaping (User?, Error?) -> Void) {
                    URLSession.shared.dataTask(with: url) { data, _, error in
                        if let error = error {
                            completion(nil, error)
                            return
                        }
                        // Parse and call completion
                        completion(user, nil)
                    }.resume()
                }

                // ✅ NEW WAY: async/await
                func fetchUser() async throws -> User {
                    let (data, _) = try await URLSession.shared.data(from: url)
                    let user = try JSONDecoder().decode(User.self, from: data)
                    return user
                }

                // Usage in SwiftUI:
                Button("Load") {
                    Task {
                        do {
                            let user = try await fetchUser()
                            self.user = user
                        } catch {
                            print("Error: \\(error)")
                        }
                    }
                }
                """)
            }
        }
    }

    private func loadUserData() async {
        isLoading = true
        userData = ""

        // Simulate network delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        userData = "✅ User loaded: John Doe\\nEmail: john@example.com\\nID: 12345"
        isLoading = false
    }
}

// MARK: - Task Example

struct TaskExample: View {
    @State private var results: [String] = []
    @State private var isRunning = false

    var body: some View {
        ExampleCard(
            title: "2. Task - Launch Concurrent Work",
            description: "Create and manage async tasks"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button("Run Multiple Tasks") {
                    runMultipleTasks()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)

                if isRunning {
                    ProgressView("Running tasks...")
                }

                if !results.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(results, id: \.self) { result in
                            Text("• \(result)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }

                CodeExample("""
                // Task runs async code from sync context
                Button("Load") {
                    Task {  // ← Creates new async context
                        await loadData()
                    }
                }

                // Task with priority
                Task(priority: .high) {
                    await criticalOperation()
                }

                // Task.detached - Fully independent
                Task.detached {
                    await backgroundWork()  // Doesn't inherit context
                }

                // Cancel tasks
                let task = Task {
                    await longRunningWork()
                }
                task.cancel()  // Cancel if needed

                // Check cancellation
                Task {
                    if Task.isCancelled { return }
                    await moreWork()
                }
                """)
            }
        }
    }

    private func runMultipleTasks() {
        isRunning = true
        results = []

        Task {
            // Launch multiple independent tasks
            async let task1 = performTask(id: 1, duration: 1)
            async let task2 = performTask(id: 2, duration: 2)
            async let task3 = performTask(id: 3, duration: 1.5)

            // Wait for all to complete
            let result1 = await task1
            results.append(result1)

            let result2 = await task2
            results.append(result2)

            let result3 = await task3
            results.append(result3)

            isRunning = false
        }
    }

    private func performTask(id: Int, duration: Double) async -> String {
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        return "Task \(id) completed (\(duration)s)"
    }
}

// MARK: - TaskGroup Example

struct TaskGroupExample: View {
    @State private var images: [String] = []
    @State private var isLoading = false

    var body: some View {
        ExampleCard(
            title: "3. TaskGroup - Parallel Execution",
            description: "Run multiple tasks in parallel and collect results"
        ) {
            VStack(alignment: .leading, spacing: 12) {
                Button("Download Images (Parallel)") {
                    Task {
                        await downloadImages()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading)

                if isLoading {
                    ProgressView("Downloading...")
                }

                if !images.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(images, id: \.self) { image in
                            HStack {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                                Text(image)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
                }

                CodeExample("""
                func downloadImages() async -> [UIImage] {
                    await withTaskGroup(of: UIImage?.self) { group in
                        // Add tasks to group
                        for url in imageURLs {
                            group.addTask {
                                await downloadImage(from: url)
                            }
                        }

                        // Collect results
                        var images: [UIImage] = []
                        for await image in group {
                            if let image = image {
                                images.append(image)
                            }
                        }
                        return images
                    }
                }

                // Alternative with throwing:
                func fetchData() async throws -> [Data] {
                    try await withThrowingTaskGroup(of: Data.self) { group in
                        for id in ids {
                            group.addTask {
                                try await fetchItem(id: id)
                            }
                        }

                        var results: [Data] = []
                        for try await data in group {
                            results.append(data)
                        }
                        return results
                    }
                }
                """)
            }
        }
    }

    private func downloadImages() async {
        isLoading = true
        images = []

        let imageNames = ["Photo 1", "Photo 2", "Photo 3", "Photo 4", "Photo 5"]

        await withTaskGroup(of: String.self) { group in
            for name in imageNames {
                group.addTask {
                    await self.downloadSingleImage(name: name)
                }
            }

            for await image in group {
                images.append(image)
            }
        }

        isLoading = false
    }

    private func downloadSingleImage(name: String) async -> String {
        // Simulate random download time
        let duration = Double.random(in: 0.5...2.0)
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        return "\(name) (\(String(format: "%.1f", duration))s)"
    }
}

// MARK: - Best Practices

struct BestPracticesCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Best Practices")
                .font(.headline)

            Text("""
            ✅ DO:
            • Use async/await instead of completion handlers
            • Use Task to bridge sync → async code
            • Check Task.isCancelled for long operations
            • Use TaskGroup for parallel execution
            • Use actors for thread-safe state
            • Handle errors with do-try-catch

            ❌ DON'T:
            • Mix completion handlers with async/await
            • Block main thread with sleep() (use Task.sleep)
            • Forget to await async calls
            • Use Task.detached unless necessary (loses context)
            • Ignore cancellation (check Task.isCancelled)

            Common Patterns:
            • SwiftUI: Use Task { } in button actions
            • ViewModels: Use Task in init or methods
            • Network: Use async URLSession methods
            • Actors: Protect mutable state

            Interview Tips:
            • Explain how async/await improves readability
            • Describe Task lifecycle and cancellation
            • Know difference between Task and Task.detached
            • Understand actors for thread safety
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

struct AsyncAwaitView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncAwaitView()
    }
}
