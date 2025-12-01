//
//  CanteenSelectorSheet.swift
//  BunkBite
//
//  Created by Anjali on 06/11/25.
//

import SwiftUI
import Shimmer

struct CanteenSelectorSheet: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var isAnimating = false

    var filteredCanteens: [Canteen] {
        if searchText.isEmpty {
            return canteenViewModel.canteens
        }
        return canteenViewModel.canteens.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.place.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [
                    Constants.primaryColor.opacity(0.05),
                    Color.white
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Constants.primaryColor.opacity(0.1))
                            .frame(width: 80, height: 80)
                            .scaleEffect(isAnimating ? 1 : 0.8)

                        Image(systemName: "building.2.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(Constants.primaryColor)
                            .scaleEffect(isAnimating ? 1 : 0.5)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 8) {
                        Text("Select Canteen")
                            .font(.urbanist(size: 28, weight: .bold))
                            .foregroundStyle(.black)

                        Text("Choose your favorite canteen")
                            .font(.urbanist(size: 15, weight: .regular))
                            .foregroundStyle(.gray)
                    }
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.gray)

                    TextField("Search canteens", text: $searchText)
                        .font(.urbanist(size: 16, weight: .regular))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .opacity(isAnimating ? 1 : 0)

                // Canteen List
                ScrollView {
                    VStack(spacing: 12) {
                        if canteenViewModel.isLoading {
                            ForEach(0..<4, id: \.self) { _ in
                                ShimmerCanteenCard()
                            }
                        } else if filteredCanteens.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.gray.opacity(0.5))
                                    .padding(.top, 60)

                                Text("No canteens found")
                                    .font(.urbanist(size: 20, weight: .semibold))
                                    .foregroundStyle(.gray)
                            }
                        } else if let errorMessage = canteenViewModel.errorMessage {
                            VStack(spacing: 24) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.orange.opacity(0.7))
                                    .padding(.top, 60)

                                Text("Failed to load canteens")
                                    .font(.urbanist(size: 20, weight: .semibold))
                                    .foregroundStyle(.black)

                                Text(errorMessage)
                                    .font(.urbanist(size: 15, weight: .regular))
                                    .foregroundStyle(.gray)
                                    .multilineTextAlignment(.center)

                                Button {
                                    Task {
                                        let token = authViewModel.authToken ?? "guest_token"
                                        await canteenViewModel.fetchAllCanteens(token: token)
                                    }
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Retry")
                                    }
                                    .font(.urbanist(size: 16, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .background(Constants.primaryColor)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal, 24)
                        } else {
                            ForEach(filteredCanteens) { canteen in
                                Button {
                                    canteenViewModel.selectedCanteen = canteen
                                    menuViewModel.menuItems = []
                                    dismiss()
                                } label: {
                                    CanteenCard(
                                        canteen: canteen,
                                        isSelected: canteenViewModel.selectedCanteen?.id == canteen.id
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
                .opacity(isAnimating ? 1 : 0)
            }

            // Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.system(size: 32))
                            Text("Back")
                                .font(.urbanist(size: 16, weight: .semibold))
                        }
                        .foregroundStyle(.gray.opacity(0.6))
                    }
                    .padding()
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimating = true
            }
        }
        .task {
            // GUEST ACCESS: Fetch canteens with guest token if not authenticated
            let token = authViewModel.authToken ?? "guest_token"
            await canteenViewModel.fetchAllCanteens(token: token)
        }
    }
}

// MARK: - Canteen Card
struct CanteenCard: View {
    let canteen: Canteen
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Circle()
                .fill(Constants.primaryColor.opacity(0.1))
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Constants.primaryColor)
                )

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(canteen.name)
                    .font(.urbanist(size: 18, weight: .semibold))
                    .foregroundStyle(.black)

                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.gray)

                    Text(canteen.place)
                        .font(.urbanist(size: 15, weight: .regular))
                        .foregroundStyle(.gray)
                }
            }

            Spacer()

            if isSelected {
                Circle()
                    .fill(Constants.primaryColor)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                    )
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16))
                    .foregroundStyle(.gray.opacity(0.5))
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Constants.primaryColor : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Shimmer Loading Skeleton
struct ShimmerCanteenCard: View {
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder icon
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 60, height: 60)
                .shimmering()

            // Placeholder text
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 140, height: 18)
                    .shimmering()

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 15)
                    .shimmering()
            }

            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
