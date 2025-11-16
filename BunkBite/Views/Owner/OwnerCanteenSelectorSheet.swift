//
//  OwnerCanteenSelectorSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct OwnerCanteenSelectorSheet: View {
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var showCreateCanteen = false

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
                    .listRowBackground(Color.clear)
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
                    .listRowBackground(Color.clear)
                }
                
                ForEach(filteredCanteens) { canteen in
                    Button {
                        canteenViewModel.selectedCanteen = canteen
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
                                    .font(.headline)
                                    .foregroundStyle(.black)

                                Label(canteen.place, systemImage: "mappin.circle.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(.gray)
                            }

                            Spacer()

                            if canteenViewModel.selectedCanteen?.id == canteen.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Constants.primaryColor)
                                    .font(.title2)
                            }
                        }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 4)
                        }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.white)
                                .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                        )
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        .padding(.vertical, 4)
                }
            }
            .listStyle(.plain)
            .navigationTitle("Select Canteen")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateCanteen = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search canteens")
            .refreshable {
                if let token = authViewModel.authToken {
                    await canteenViewModel.fetchMyCanteens(token: token)
                }
            }
            .sheet(isPresented: $showCreateCanteen) {
                CreateCanteenSheet(
                    canteenViewModel: canteenViewModel,
                    authViewModel: authViewModel
                )
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(canteenViewModel.selectedCanteen == nil)
        .task {
            if let token = authViewModel.authToken {
                await canteenViewModel.fetchMyCanteens(token: token)
            }
        }
    }
}
