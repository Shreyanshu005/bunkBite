//
//  OwnerMenuTab.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI
import PopupView

struct OwnerMenuTab: View {
    let canteen: Canteen?
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @ObservedObject var canteenViewModel: CanteenViewModel
    let onSelectCanteen: () -> Void

    @State private var showAddItem = false
    @State private var showEditItem: MenuItem?
    @State private var showQuantityUpdate: MenuItem?
    @State private var showDeleteCanteen = false
    @State private var deleteConfirmationEmail = ""
    @State private var searchText = ""

    var filteredItems: [MenuItem] {
        if searchText.isEmpty {
            return menuViewModel.menuItems
        }
        return menuViewModel.menuItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            if let selectedCanteen = canteen {
                canteenMenuView(for: selectedCanteen)
            } else {
                noCanteenView
            }
        }
    }

    private var noCanteenView: some View {
        List {
            ContentUnavailableView {
                Label("No Canteen Selected", systemImage: "building.2")
            } description: {
                Text("Select a canteen to manage inventory")
            } actions: {
                Button("Select Canteen") {
                    onSelectCanteen()
                }
                .buttonStyle(.borderedProminent)
                .tint(Constants.primaryColor)
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle("Inventory")
    }

    private func canteenMenuView(for selectedCanteen: Canteen) -> some View {
        List {
            // Canteen Header
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(selectedCanteen.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            Label(selectedCanteen.place, systemImage: "mappin.circle")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        VStack(spacing: 8) {
                            Button("Change") {
                                canteenViewModel.selectedCanteen = nil
                                onSelectCanteen()
                            }
                            .buttonStyle(.bordered)
                            .tint(Constants.primaryColor)

                            Button("Delete") {
                                showDeleteCanteen = true
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }

                        // Stats
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
                    }
                    .padding(.vertical, 8)
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
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredItems) { item in
                        HStack {
                            InventoryItemRow(item: item) {
                                showEditItem = item
                            }

                            // Quick quantity buttons
                            Button {
                                showQuantityUpdate = item
                            } label: {
                                Image(systemName: "number.circle")
                                    .foregroundStyle(Constants.primaryColor)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = filteredItems[index]
                            Task {
                                if let token = authViewModel.authToken {
                                    _ = await menuViewModel.deleteMenuItem(
                                        canteenId: selectedCanteen.id,
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
            .toolbar {
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
                    await menuViewModel.fetchMenu(canteenId: selectedCanteen.id, token: token)
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddMenuItemSheet(
                    canteen: selectedCanteen,
                    menuViewModel: menuViewModel,
                    authViewModel: authViewModel
                )
            }
            .sheet(item: $showEditItem) { item in
                EditMenuItemSheet(
                    canteen: selectedCanteen,
                    item: item,
                    menuViewModel: menuViewModel,
                    authViewModel: authViewModel
                )
            }
            .task {
                if let token = authViewModel.authToken {
                    await menuViewModel.fetchMenu(canteenId: selectedCanteen.id, token: token)
                }
            }
            .sheet(item: $showQuantityUpdate) { item in
                QuickQuantityUpdateSheet(
                    item: item,
                    canteen: selectedCanteen,
                    menuViewModel: menuViewModel,
                    authViewModel: authViewModel
                )
            }
            .popup(isPresented: $showDeleteCanteen) {
                DeleteCanteenPopup(
                    canteen: selectedCanteen,
                    canteenViewModel: canteenViewModel,
                    authViewModel: authViewModel,
                    deleteConfirmationEmail: $deleteConfirmationEmail,
                    isPresented: $showDeleteCanteen
                )
            } customize: {
                $0
                    .type(.floater(verticalPadding: 20, useSafeAreaInset: true))
                    .position(.center)
                    .animation(.spring())
                    .closeOnTapOutside(true)
                    .backgroundColor(.black.opacity(0.5))
            }
    }
}

// MARK: - Quick Quantity Update Sheet
struct QuickQuantityUpdateSheet: View {
    let item: MenuItem
    let canteen: Canteen
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) var dismiss
    @State private var newQuantity = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(.headline)
                            .foregroundStyle(.black)

                        Text("₹\(Int(item.price))")
                            .font(.subheadline)
                            .foregroundStyle(Constants.primaryColor)

                        Text("Current: \(item.availableQuantity)")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Item Details")
                }

                Section {
                    TextField("New Quantity", text: $newQuantity)
                        .keyboardType(.numberPad)
                        .font(.title2)
                } header: {
                    Text("Update Quantity")
                } footer: {
                    if let error = menuViewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            if let quantity = Int(newQuantity),
                               let token = authViewModel.authToken {
                                let success = await menuViewModel.updateQuantity(
                                    canteenId: canteen.id,
                                    itemId: item.id,
                                    quantity: quantity,
                                    token: token
                                )
                                if success {
                                    dismiss()
                                }
                            }
                        }
                    } label: {
                        if menuViewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Update Quantity")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Constants.primaryColor)
                    .disabled(newQuantity.isEmpty || menuViewModel.isLoading)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Quick Update")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            newQuantity = String(item.availableQuantity)
        }
    }
}

// MARK: - Delete Canteen Popup
struct DeleteCanteenPopup: View {
    let canteen: Canteen
    @ObservedObject var canteenViewModel: CanteenViewModel
    @ObservedObject var authViewModel: AuthViewModel
    @Binding var deleteConfirmationEmail: String
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            headerView
            Divider()
            warningMessageView
            emailConfirmationView
            actionButtonsView
            statusView
        }
        .padding(24)
        .background(popupBackground)
        .padding(40)
    }

    private var headerView: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundStyle(.red)
            Text("Delete Canteen")
                .font(.title2)
                .fontWeight(.bold)
        }
    }

    private var warningMessageView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("You are about to delete:")
                .font(.subheadline)
                .foregroundStyle(.gray)

            Text(canteen.name)
                .font(.headline)
                .foregroundStyle(.black)

            Text("This action cannot be undone!")
                .font(.caption)
                .foregroundStyle(.red)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emailConfirmationView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Type your email to confirm:")
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField("Email", text: $deleteConfirmationEmail)
                .textFieldStyle(.roundedBorder)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
        }
    }

    private var actionButtonsView: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                deleteConfirmationEmail = ""
                isPresented = false
            }
            .buttonStyle(.bordered)
            .tint(.gray)

            Button("Delete") {
                handleDelete()
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(deleteConfirmationEmail != authViewModel.currentUser?.email || canteenViewModel.isLoading)
        }
    }

    @ViewBuilder
    private var statusView: some View {
        if canteenViewModel.isLoading {
            ProgressView()
        }

        if let error = canteenViewModel.errorMessage {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
        }
    }

    private var popupBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.white)
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
    }

    private func handleDelete() {
        Task {
            if deleteConfirmationEmail == authViewModel.currentUser?.email,
               let token = authViewModel.authToken {
                let success = await canteenViewModel.deleteCanteen(
                    id: canteen.id,
                    token: token
                )
                if success {
                    canteenViewModel.selectedCanteen = nil
                    deleteConfirmationEmail = ""
                    isPresented = false
                }
            }
        }
    }
}
