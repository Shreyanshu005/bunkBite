//
//  NewOwnerMainView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct NewOwnerMainView: View {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var canteenViewModel = CanteenViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    @StateObject private var scannerViewModel = ScannerViewModel()

    @State private var showLoginSheet = false
    @State private var showCanteenSelector = false
    @State private var showScanner = false
    @State private var showScannedOrder = false
    @State private var selectedTab = 0
    @State private var orderCompletedTrigger = false

    var body: some View {
        Group {
            if !authViewModel.isAuthenticated {
                // Show login prompt
                loginPromptView
            } else {
                // Show main tabs (even if no canteen selected)
                mainTabView
            }
        }
        .onAppear {
            authViewModel.checkExistingAuth()
        }
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet(authViewModel: authViewModel)
        }
        .sheet(isPresented: $showCanteenSelector) {
            OwnerCanteenSelectorSheet(
                canteenViewModel: canteenViewModel,
                authViewModel: authViewModel
            )
        }
    }

    private var loginPromptView: some View {
        NavigationStack {
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
            .navigationTitle("Owner Panel")
        }
    }

    private var mainTabView: some View {
        TabView(selection: $selectedTab) {
            // Menu/Inventory Tab
            OwnerMenuTab(
                canteen: canteenViewModel.selectedCanteen,
                menuViewModel: menuViewModel,
                authViewModel: authViewModel,
                canteenViewModel: canteenViewModel,
                onSelectCanteen: {
                    showCanteenSelector = true
                }
            )
            .tabItem {
                Label("Inventory", systemImage: "fork.knife")
            }
            .tag(0)

            // Orders Tab
            OwnerOrdersTab(
                canteen: canteenViewModel.selectedCanteen,
                authViewModel: authViewModel,
                orderCompletedTrigger: $orderCompletedTrigger,
                onSelectCanteen: {
                    showCanteenSelector = true
                }
            )
            .tabItem {
                Label("Orders", systemImage: "list.clipboard")
            }
            .tag(1)

            // Profile Tab
            OwnerProfileView2(authViewModel: authViewModel, showLoginSheet: $showLoginSheet)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
                .tag(2)
            
            // Scanner Tab
            Color.clear
                .tabItem {
                    Label("Scan QR", systemImage: "qrcode.viewfinder")
                }
                .tag(3)
        }
        .tint(Constants.primaryColor)
        .onChange(of: selectedTab) {
            if selectedTab == 3 {
                showScanner = true
                // Reset to previous tab after opening scanner
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    selectedTab = 1 // Go back to Orders tab
                }
            }
        }
        .fullScreenCover(isPresented: $showScanner) {
            ZStack(alignment: .topLeading) {
                QRScannerView(viewModel: scannerViewModel, token: authViewModel.authToken ?? "")
                
                Button {
                    showScanner = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                        .padding()
                }
            }
        }
        .sheet(isPresented: $showScannedOrder) {
            if let order = scannerViewModel.scannedOrder {
                ScannedOrderSheet(
                    order: order,
                    qrData: scannerViewModel.lastScannedCode,
                    token: authViewModel.authToken ?? "",
                    viewModel: scannerViewModel,
                    isPresented: $showScannedOrder,
                    onPickupComplete: {
                        // Toggle trigger to refresh orders
                        orderCompletedTrigger.toggle()
                    }
                )
            }
        }
        .onChange(of: scannerViewModel.scannedOrder) {
            if scannerViewModel.scannedOrder != nil {
                showScanner = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showScannedOrder = true
                }
            }
        }
    }
}

