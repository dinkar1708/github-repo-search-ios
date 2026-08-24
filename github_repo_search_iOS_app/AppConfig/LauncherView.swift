//
//  LauncherView.swift
//  github_repo_search_iOS_app
//
//  Created by Dinakar Maurya on 2021/08/12.
//

import SwiftUI

@main
struct LauncherView: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            SplashView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("🟢 APP LIFECYCLE: Active (Foreground)")
            case .inactive:
                print("🟡 APP LIFECYCLE: Inactive")
            case .background:
                print("🔴 APP LIFECYCLE: Background")
            @unknown default:
                print("⚪️ APP LIFECYCLE: Unknown")
            }
        }
    }
}
