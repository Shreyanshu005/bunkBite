//
//  AddMenuItemSheet.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import SwiftUI

struct AddMenuItemSheet: View {
    let canteen: Canteen
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var price = ""
    @State private var quantity = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item Name", text: $name)

                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)

                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Item Details")
                } footer: {
                    if let error = menuViewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            if let priceValue = Double(price),
                               let quantityValue = Int(quantity),
                               let token = authViewModel.authToken {
                                let success = await menuViewModel.addMenuItem(
                                    canteenId: canteen.id,
                                    name: name,
                                    price: priceValue,
                                    quantity: quantityValue,
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
                            Text("Add Item")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(name.isEmpty || price.isEmpty || quantity.isEmpty || menuViewModel.isLoading)
                }
            }
            .navigationTitle("New Menu Item")
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
    }
}

struct EditMenuItemSheet: View {
    let canteen: Canteen
    let item: MenuItem
    @ObservedObject var menuViewModel: MenuViewModel
    @ObservedObject var authViewModel: AuthViewModel

    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var price = ""
    @State private var quantity = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Item Name", text: $name)

                    TextField("Price", text: $price)
                        .keyboardType(.decimalPad)

                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Item Details")
                } footer: {
                    if let error = menuViewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task {
                            if let priceValue = Double(price),
                               let quantityValue = Int(quantity),
                               let token = authViewModel.authToken {
                                let success = await menuViewModel.updateMenuItem(
                                    canteenId: canteen.id,
                                    itemId: item.id,
                                    name: name,
                                    price: priceValue,
                                    quantity: quantityValue,
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
                            Text("Update Item")
                                .frame(maxWidth: .infinity)
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(name.isEmpty || price.isEmpty || quantity.isEmpty || menuViewModel.isLoading)
                }

                Section {
                    Button(role: .destructive) {
                        Task {
                            if let token = authViewModel.authToken {
                                let success = await menuViewModel.deleteMenuItem(
                                    canteenId: canteen.id,
                                    itemId: item.id,
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
                            Text("Delete Item")
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Edit Menu Item")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            name = item.name
            price = String(item.price)
            quantity = String(item.availableQuantity)
        }
    }
}
