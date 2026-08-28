//
//  LauncherView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import SwiftUI
import SwiftData

@main
struct LauncherView: App {
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Register OS-Level BGTaskScheduler before application finishes launching
        OfflineBackgroundSyncScheduler.shared.register()
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .modelContainer(SwiftDataStack.shared.container)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("🟢 APP LIFECYCLE: Active (Foreground)")
            case .inactive:
                print("🟡 APP LIFECYCLE: Inactive")
            case .background:
                print("🔴 APP LIFECYCLE: Background — Scheduling Offline BGTaskScheduler...")
                OfflineBackgroundSyncScheduler.shared.scheduleBackgroundSync()
            @unknown default:
                print("⚪️ APP LIFECYCLE: Unknown")
            }
        }
    }
}
