//
//  UserOrdersView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserOrdersView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var showLoginSheet: Bool

    var body: some View {
        NavigationStack {
            Group {
                if authViewModel.isAuthenticated {
                    ordersContent
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("Past Orders")
        }
    }

    private var loginPrompt: some View {
        ContentUnavailableView {
            Label("Not Logged In", systemImage: "person.crop.circle.badge.xmark")
        } description: {
            Text("Please log in to view your orders")
        } actions: {
            Button("Log In") {
                showLoginSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.primaryColor)
        }
    }

    private var ordersContent: some View {
        List {
            ContentUnavailableView("No orders yet", systemImage: "clock")
                .listRowBackground(Color.clear)
        }
    }
}
