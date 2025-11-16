//
//  InventorySheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView

struct InventorySheet: View {
    let canteen: Canteen
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) var dismiss
    @State private var showAddItem = false
    @State private var showEditItem: MenuItem?
    @State private var searchText = ""

    var filteredItems: [MenuItem] {
        if searchText.isEmpty {
            return menuViewModel.menuItems
        }
        return menuViewModel.menuItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            List {
                // Header Section
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(canteen.name)
                            .font(.title2)
                            .fontWeight(.bold)

                        Label(canteen.place, systemImage: "mappin.circle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("\(menuViewModel.menuItems.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Constants.primaryColor)
                                Text("Items")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()
                                .frame(height: 30)

                            VStack(alignment: .leading) {
                                Text("\(menuViewModel.menuItems.filter { $0.availableQuantity > 0 }.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.green)
                                Text("Available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Divider()
                                .frame(height: 30)

                            VStack(alignment: .leading) {
                                Text("\(menuViewModel.menuItems.filter { $0.availableQuantity == 0 }.count)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.red)
                                Text("Out of Stock")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listRowBackground(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )

                // Menu Items
                if menuViewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if filteredItems.isEmpty {
                    ContentUnavailableView {
                        Label("No Items", systemImage: "tray")
                    } description: {
                        Text("Add items to your menu")
                    } actions: {
                        Button("Add Item") {
                            showAddItem = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Constants.primaryColor)
                    }
                } else {
                    ForEach(filteredItems) { item in
                        InventoryItemRow(item: item) {
                            showEditItem = item
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = filteredItems[index]
                            Task {
                                if let token = authViewModel.authToken {
                                    _ = await menuViewModel.deleteMenuItem(
                                        canteenId: canteen.id,
                                        itemId: item.id,
                                        token: token
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Inventory")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search items")
            .refreshable {
                if let token = authViewModel.authToken {
                    await menuViewModel.fetchMenu(canteenId: canteen.id, token: token)
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddMenuItemSheet(
                    canteen: canteen,
                    menuViewModel: menuViewModel,
                    authViewModel: authViewModel
                )
            }
            .sheet(item: $showEditItem) { item in
                EditMenuItemSheet(
                    canteen: canteen,
                    item: item,
                    menuViewModel: menuViewModel,
                    authViewModel: authViewModel
                )
            }
        }
        .task {
            if let token = authViewModel.authToken {
                await menuViewModel.fetchMenu(canteenId: canteen.id, token: token)
            }
        }
    }
}

struct InventoryItemRow: View {
    let item: MenuItem
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Item image
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .frame(width: 60, height: 60)
                .overlay(
                    Image(systemName: "fork.knife")
                        .foregroundStyle(.secondary)
                )

            // Item details
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .foregroundStyle(.black)

                Text("₹\(Int(item.price))")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Constants.primaryColor)

                HStack {
                    if item.availableQuantity > 0 {
                        Text("\(item.availableQuantity) available")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Text("Out of stock")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            Button(action: onEdit) {
                Image(systemName: "square.and.pencil")
                    .foregroundStyle(Constants.primaryColor)
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
