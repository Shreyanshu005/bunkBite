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

    var body: some View {
        Group {
            if isCheckingAuth {
                ProgressView()
            } else {
                // Check role: "admin" = owner, anything else = user
                if userRole == "admin" {
                    NewOwnerMainView()
                } else {
                    NewUserMainView()
                }
            }
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
            print("❌ No user data found")
        }
        isCheckingAuth = false
    }
}
