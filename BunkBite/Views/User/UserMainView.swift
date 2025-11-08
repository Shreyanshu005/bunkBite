//
//  UserMainView.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct UserMainView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showLoginSheet = false
    @Namespace private var animation

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                UserHomeView(viewModel: viewModel)
                    .tag(0)

                UserPastOrdersView()
                    .tag(1)

                UserProfileView(viewModel: viewModel, showLoginSheet: $showLoginSheet)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Bottom Navigation Bar
            HStack(spacing: 0) {
                TabBarButton(
                    icon: "house.fill",
                    title: "Home",
                    isSelected: selectedTab == 0,
                    namespace: animation
                ) {
                    withAnimation(Constants.bouncyAnimation) {
                        selectedTab = 0
                    }
                }

                TabBarButton(
                    icon: "clock.fill",
                    title: "Past Orders",
                    isSelected: selectedTab == 1,
                    namespace: animation
                ) {
                    withAnimation(Constants.bouncyAnimation) {
                        selectedTab = 1
                    }
                }

                TabBarButton(
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
        .sheet(isPresented: $showLoginSheet) {
            LoginSheet(authViewModel: viewModel)
        }
    }
}

struct TabBarButton: View {
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
