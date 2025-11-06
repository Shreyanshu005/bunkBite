//
//  CanteenSelectorSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
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
                    ForEach(filteredCanteens) { canteen in
                        Button {
                            canteenViewModel.selectedCanteen = canteen
                            // Clear menu when changing canteen
                            menuViewModel.menuItems = []
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(canteen.name)
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Label(canteen.place, systemImage: "mappin.circle")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if canteenViewModel.selectedCanteen?.id == canteen.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Constants.primaryColor)
                                        .font(.title3)
                                }
                            }
                            .padding(.vertical, 4)
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
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            if let token = authViewModel.authToken {
                await canteenViewModel.fetchAllCanteens(token: token)
            }
        }
    }
}
