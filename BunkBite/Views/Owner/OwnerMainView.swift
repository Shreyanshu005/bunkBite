//
//  OwnerMainView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerMainView: View {
    @ObservedObject var viewModel: AuthViewModel
    @StateObject private var scannerViewModel = ScannerViewModel()
    @State private var selectedTab = 0
    @State private var showScanner = false
    @State private var showScannedOrder = false
    @Namespace private var animation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                OwnerInventoryView()
                    .tag(0)

                OwnerOrdersView()
                    .tag(1)

                OwnerProfileView(viewModel: viewModel)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Bottom Navigation Bar
            HStack(spacing: 0) {
                OwnerTabBarButton(
                    icon: "cube.box.fill",
                    title: "Inventory",
                    isSelected: selectedTab == 0,
                    namespace: animation
                ) {
                    withAnimation(Constants.bouncyAnimation) {
                        selectedTab = 0
                    }
                }
                
                // Scanner FAB
                Button {
                    showScanner = true
                } label: {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(Constants.primaryColor)
                                .frame(width: 64, height: 64)
                                .shadow(color: Constants.primaryColor.opacity(0.4), radius: 12, x: 0, y: 6)
                            
                            Image(systemName: "qrcode.viewfinder")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Scan")
                            .font(.urbanist(size: 11, weight: .semibold))
                            .foregroundColor(Constants.primaryColor)
                    }
                }
                .offset(y: -28)
                .padding(.horizontal, 12)

                OwnerTabBarButton(
                    icon: "list.bullet.clipboard.fill",
                    title: "Orders",
                    isSelected: selectedTab == 1,
                    namespace: animation
                ) {
                    withAnimation(Constants.bouncyAnimation) {
                        selectedTab = 1
                    }
                }

                OwnerTabBarButton(
                    icon: "person.fill",
                    title: "Profile",
                    isSelected: selectedTab == 2,
                    namespace: animation
                ) {
                    withAnimation(Constants.bouncyAnimation) {
                        selectedTab = 2
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Color.white
                    .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: -5)
            )
            .edgesIgnoringSafeArea(.bottom)
        }
        .fullScreenCover(isPresented: $showScanner) {
            ZStack(alignment: .topLeading) {
                QRScannerView(viewModel: scannerViewModel, token: viewModel.authToken ?? "")
                
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
                    token: viewModel.authToken ?? "",
                    viewModel: scannerViewModel,
                    isPresented: $showScannedOrder
                )
            }
        }
        .onChange(of: scannerViewModel.scannedOrder) {
            if scannerViewModel.scannedOrder != nil {
                showScanner = false
                // Small delay to allow scanner to close before opening sheet
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showScannedOrder = true
                }
            }
        }
    }
}

struct OwnerTabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Constants.primaryColor.opacity(0.1))
                            .frame(width: 56, height: 56)
                            .matchedGeometryEffect(id: "tab", in: namespace)
                    }

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? Constants.primaryColor : Constants.darkGray)
                        .scaleEffect(isSelected ? 1.1 : 1.0)
                }
                .frame(height: 56)

                Text(title)
                    .font(.urbanist(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? Constants.primaryColor : Constants.darkGray)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
