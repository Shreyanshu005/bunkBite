//
//  BunkBiteApp.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import SafariServices

@main
struct BunkBiteApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .preferredColorScheme(.light)

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showLaunchScreen = false
                    }
                }
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Force light mode for all windows
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        if connectingSceneSession.role == .windowApplication {
            configuration.delegateClass = SceneDelegate.self
        }
        return configuration
    }

    // Handle deep link URLs for payment callback
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("\n🔗 Deep link received in AppDelegate: \(url.absoluteString)")
        handlePaymentDeepLink(url: url)
        return true
    }

    private func handlePaymentDeepLink(url: URL) {
        // Check if this is a payment status deep link
        if url.scheme == "myapp" && url.host == "payment-status" {
            print("✅ Payment callback detected")
            CashfreeWebCheckoutManager.shared.handlePaymentCallback(url: url)

            // Dismiss Safari VC if it's still open
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {

                var topController = rootViewController
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }

                if topController is SFSafariViewController {
                    topController.dismiss(animated: true)
                }
            }
        }
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            windowScene.windows.forEach { window in
                window.overrideUserInterfaceStyle = .light
            }
        }

        // Handle deep link if app was opened via URL
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(url: urlContext.url, scene: scene)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        // Handle deep links when app is already running
        if let urlContext = URLContexts.first {
            handleDeepLink(url: urlContext.url, scene: scene)
        }
    }

    private func handleDeepLink(url: URL, scene: UIScene) {
        print("\n🔗 Deep link received in SceneDelegate: \(url.absoluteString)")

        if url.scheme == "myapp" && url.host == "payment-status" {
            print("✅ Payment callback detected")
            CashfreeWebCheckoutManager.shared.handlePaymentCallback(url: url)

            // Dismiss Safari VC if it's still open
            if let windowScene = scene as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootViewController = window.rootViewController {

                var topController = rootViewController
                while let presentedViewController = topController.presentedViewController {
                    topController = presentedViewController
                }

                if topController is SFSafariViewController {
                    topController.dismiss(animated: true)
                }
            }
        }
    }
}
