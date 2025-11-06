//
//  OwnerCanteensView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerCanteensView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @Binding var showLoginSheet: Bool

    @State private var showCreateCanteen = false
    @State private var showInventory = false

    var body: some View {
        NavigationStack {
            Group {
                if authViewModel.isAuthenticated {
                    canteensContent
                } else {
                    loginPrompt
                }
            }
            .navigationTitle("My Canteens")
            .toolbar {
                if authViewModel.isAuthenticated {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            showCreateCanteen = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateCanteen) {
                CreateCanteenSheet(
                    canteenViewModel: canteenViewModel,
                    authViewModel: authViewModel
                )
            }
            .sheet(isPresented: $showInventory) {
                if let canteen = canteenViewModel.selectedCanteen {
                    InventorySheet(
                        canteen: canteen,
                        menuViewModel: menuViewModel,
                        authViewModel: authViewModel
                    )
                }
            }
        }
    }

    private var loginPrompt: some View {
        ContentUnavailableView {
            Label("Not Logged In", systemImage: "person.crop.circle.badge.xmark")
        } description: {
            Text("Please log in to manage your canteens")
        } actions: {
            Button("Log In") {
                showLoginSheet = true
            }
            .buttonStyle(.borderedProminent)
            .tint(Constants.primaryColor)
        }
    }

    private var canteensContent: some View {
        List {
            if canteenViewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else if canteenViewModel.canteens.isEmpty {
                ContentUnavailableView {
                    Label("No Canteens", systemImage: "building.2")
                } description: {
                    Text("Create your first canteen to get started")
                } actions: {
                    Button("Create Canteen") {
                        showCreateCanteen = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.primaryColor)
                }
            } else {
                ForEach(canteenViewModel.canteens) { canteen in
                    CanteenCard(canteen: canteen) {
                        canteenViewModel.selectedCanteen = canteen
                        showInventory = true
                    }
                }
            }
        }
        .refreshable {
            if let token = authViewModel.authToken {
                await canteenViewModel.fetchMyCanteens(token: token)
            }
        }
        .task {
            if let token = authViewModel.authToken {
                await canteenViewModel.fetchMyCanteens(token: token)
            }
        }
    }
}

struct CanteenCard: View {
    let canteen: Canteen
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "building.2.fill")
                        .font(.title2)
                        .foregroundStyle(Constants.primaryColor)
                        .frame(width: 50, height: 50)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(canteen.name)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Label(canteen.place, systemImage: "mappin.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
    }
}
