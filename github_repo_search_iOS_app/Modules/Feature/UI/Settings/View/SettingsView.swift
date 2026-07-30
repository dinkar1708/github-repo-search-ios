//
//  SettingsView.swift
//  github_repo_search_iOS_app
//
//  Created for Settings feature (Feature 4.0)
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("isDarkMode") private var isDarkMode = false
    @AppStorage("selectedLanguage") private var selectedLanguage = "en"
    @State private var showingClearCacheAlert = false
    @State private var cacheCleared = false

    var body: some View {
        NavigationView {
            List {
                // MARK: - Appearance Section
                Section {
                    Toggle(isOn: $isDarkMode) {
                        Label("Dark Mode", systemImage: "moon.fill")
                    }
                } header: {
                    Text("Appearance")
                }

                // MARK: - Language Section
                Section {
                    Picker("Language", selection: $selectedLanguage) {
                        Text("English").tag("en")
                        Text("日本語").tag("ja")
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("Language")
                } footer: {
                    Text("Change the app language preference")
                }

                // MARK: - Data & Storage Section
                Section {
                    Button(action: {
                        showingClearCacheAlert = true
                    }) {
                        HStack {
                            Label("Clear Cache", systemImage: "trash")
                                .foregroundColor(.red)
                            Spacer()
                        }
                    }

                    if cacheCleared {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Cache cleared successfully")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Data & Storage")
                }

                // MARK: - About Section
                Section {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Build Number")
                        Spacer()
                        Text(buildNumber)
                            .foregroundColor(.secondary)
                    }

                    if let githubURL = URL(string: "https://github.com") {
                        Link(destination: githubURL) {
                            HStack {
                                Label("GitHub", systemImage: "link")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .preferredColorScheme(isDarkMode ? .dark : .light)
            .alert("Clear Cache", isPresented: $showingClearCacheAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    clearCache()
                }
            } message: {
                Text("This will clear all cached data. Are you sure?")
            }
        }
    }

    // MARK: - Helper Methods

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func clearCache() {
        // Clear URLCache
        URLCache.shared.removeAllCachedResponses()

        // Clear temporary directory
        let tempDirectory = FileManager.default.temporaryDirectory
        do {
            let tempFiles = try FileManager.default.contentsOfDirectory(
                at: tempDirectory,
                includingPropertiesForKeys: nil
            )
            for file in tempFiles {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to clear temp directory: \(error)")
        }

        cacheCleared = true

        // Reset the flag after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            cacheCleared = false
        }
    }
}

#Preview {
    SettingsView()
}
