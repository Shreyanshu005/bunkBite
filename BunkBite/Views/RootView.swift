import SwiftUI

struct RootView: View {
    @State private var userRole: String? = nil
    @State private var isCheckingAuth = true
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome = false
    @StateObject private var versionManager = VersionManager()

    var body: some View {
        Group {
            if versionManager.needsUpdate {

                VersionCheckView(
                    currentVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
                    minimumVersion: versionManager.minimumVersion,
                    appStoreURL: "https://apps.apple.com/in/app/bunkbite/id6755028590"
                )
            } else if isCheckingAuth {
                ProgressView()
            } else if !hasSeenWelcome {

                WelcomeScreen(hasSeenWelcome: $hasSeenWelcome)
            } else {

                if userRole?.lowercased() == "admin" {
                    OwnerMainView()
                } else {

                    NewUserMainView()
                }
            }
        }
        .task {

            await versionManager.checkVersion()
        }
        .onAppear {
            checkUserRole()

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
