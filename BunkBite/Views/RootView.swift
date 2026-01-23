//
//  RootView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct RootView: View {
    @State private var userRole: String? = nil
    @State private var isCheckingAuth = true
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @StateObject private var versionManager = VersionManager()

    var body: some View {
        Group {
            if versionManager.needsUpdate {
                // Force update screen
                VersionCheckView(
                    currentVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                    minimumVersion: versionManager.minimumVersion,
                    appStoreURL: "https://apps.apple.com/in/app/bunkbite/id6755028590"
                )
            } else if isCheckingAuth {
                ProgressView()
            } else if !hasSeenWelcome {
                // Show welcome screen for first-time users
                WelcomeScreen(hasSeenWelcome: $hasSeenWelcome)
            } else {
                // Check role: "admin" = owner, "user" = authenticated user, nil = guest
                if userRole?.lowercased() == "admin" {
                    OwnerMainView()
                } else {
                    // Always show user view (supports both authenticated and guest mode)
                    NewUserMainView()
                }
            }
        }
        .task {
            // Check version on app launch
            await versionManager.checkVersion()
        }
        .onAppear {
            checkUserRole()

            // Listen for authentication changes
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("UserDidLogin"),
                object: nil,
                queue: .main
            ) { notification in
                checkUserRole()
            }

            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("UserDidLogout"),
                object: nil,
                queue: .main
            ) { _ in
                userRole = nil
                isCheckingAuth = false
            }
        }
    }

    private func checkUserRole() {
        if let userData = UserDefaults.standard.data(forKey: "userData"),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            userRole = user.role
            print("✅ User role detected: \(user.role)")
        } else {
            userRole = nil
            print("ℹ️ No user data found - continuing as guest")
        }
        isCheckingAuth = false
    }
}
