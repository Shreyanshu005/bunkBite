//
//  CanteenSelectorSheet.swift
//  BunkBite
//
//  Created by Anjali on 06/11/25.
//

import SwiftUI

struct CanteenSelectorSheet: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var menuViewModel: MenuViewModel

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""

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
        NavigationStack {
            List {
                if canteenViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if filteredCanteens.isEmpty {
                    ContentUnavailableView("No canteens found", systemImage: "building.2")
                } else {
                    Section {
                        ForEach(filteredCanteens) { canteen in
                            Button {
                                canteenViewModel.selectedCanteen = canteen
                                // Clear menu when changing canteen
                                menuViewModel.menuItems = []
                                dismiss()
                            } label: {
                            HStack(spacing: 16) {
                                // Icon
                                Circle()
                                    .fill(Constants.primaryColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "building.2.fill")
                                            .foregroundStyle(Constants.primaryColor)
                                            .font(.title3)
                                    )

                                // Details
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(canteen.name)
                                        .font(.urbanist(size: 17, weight: .semibold))
                                        .foregroundStyle(.black)

                                    Label(canteen.place, systemImage: "mappin.circle.fill")
                                        .font(.urbanist(size: 14, weight: .regular))
                                        .foregroundStyle(.gray)
                                }

                                Spacer()

                                if canteenViewModel.selectedCanteen?.id == canteen.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Constants.primaryColor)
                                        .font(.title2)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                    }
                }
            }
            .navigationTitle("Select Canteen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search canteens")
            .refreshable {
                if let token = authViewModel.authToken {
                    await canteenViewModel.fetchAllCanteens(token: token)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            if let token = authViewModel.authToken {
                await canteenViewModel.fetchAllCanteens(token: token)
            }
        }
    }
}
