//
//  MenuViewModel.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class MenuViewModel: ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let apiService = APIService.shared

    func fetchMenu(canteenId: String) async {
        isLoading = true
        errorMessage = nil
        // menuItems = [] // REMOVED: keep old items until new ones arrive for a smoother experience

        do {
            menuItems = try await apiService.getMenu(canteenId: canteenId)
        } catch {
            errorMessage = "Failed to fetch menu"
        }

        isLoading = false
    }

    func addMenuItem(canteenId: String, name: String, price: Double, quantity: Int, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let item = try await apiService.addMenuItem(canteenId: canteenId, name: name, price: price, availableQuantity: quantity, token: token)
            menuItems.append(item)
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to add item"
            isLoading = false
            return false
        }
    }

    func updateMenuItem(canteenId: String, itemId: String, name: String, price: Double, quantity: Int, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            let updatedItem = try await apiService.updateMenuItem(canteenId: canteenId, itemId: itemId, name: name, price: price, availableQuantity: quantity, token: token)
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                menuItems[index] = updatedItem
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update item"
            isLoading = false
            return false
        }
    }

    func updateQuantity(canteenId: String, itemId: String, quantity: Int, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.updateMenuItemQuantity(canteenId: canteenId, itemId: itemId, quantity: quantity, token: token)
            if let index = menuItems.firstIndex(where: { $0.id == itemId }) {
                let updatedItem = menuItems[index]
                // Create a new MenuItem with updated quantity (since MenuItem properties are let)
                menuItems[index] = MenuItem(
                    id: updatedItem.id,
                    name: updatedItem.name,
                    image: updatedItem.image,
                    price: updatedItem.price,
                    availableQuantity: quantity,
                    createdAt: updatedItem.createdAt,
                    updatedAt: updatedItem.updatedAt
                )
            }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to update quantity"
            isLoading = false
            return false
        }
    }

    func deleteMenuItem(canteenId: String, itemId: String, token: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await apiService.deleteMenuItem(canteenId: canteenId, itemId: itemId, token: token)
            menuItems.removeAll { $0.id == itemId }
            isLoading = false
            return true
        } catch {
            errorMessage = "Failed to delete item"
            isLoading = false
            return false
        }
    }
}
