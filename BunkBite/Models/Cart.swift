//
//  Cart.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation
import Combine

struct CartItem: Identifiable, Hashable {
    var id: String {
        menuItem.id
    }
    let menuItem: MenuItem
    var quantity: Int

    var totalPrice: Double {
        return menuItem.price * Double(quantity)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(menuItem.id)
    }

    static func == (lhs: CartItem, rhs: CartItem) -> Bool {
        return lhs.menuItem.id == rhs.menuItem.id && lhs.quantity == rhs.quantity
    }
}

class Cart: ObservableObject {
    @Published var items: [CartItem] = []

    var totalAmount: Double {
        items.reduce(0) { $0 + $1.totalPrice }
    }

    var totalItems: Int {
        items.reduce(0) { $0 + $1.quantity }
    }

    func addItem(_ menuItem: MenuItem) {
        if let index = items.firstIndex(where: { $0.menuItem.id == menuItem.id }) {
            items[index].quantity += 1
        } else {
            items.append(CartItem(menuItem: menuItem, quantity: 1))
        }
    }

    func removeItem(_ menuItem: MenuItem) {
        if let index = items.firstIndex(where: { $0.menuItem.id == menuItem.id }) {
            if items[index].quantity > 1 {
                items[index].quantity -= 1
            } else {
                items.remove(at: index)
            }
        }
    }

    func updateQuantity(for menuItem: MenuItem, quantity: Int) {
        if let index = items.firstIndex(where: { $0.menuItem.id == menuItem.id }) {
            if quantity > 0 {
                items[index].quantity = quantity
            } else {
                items.remove(at: index)
            }
        }
    }

    func getQuantity(for menuItem: MenuItem) -> Int {
        items.first(where: { $0.menuItem.id == menuItem.id })?.quantity ?? 0
    }

    func clear() {
        items.removeAll()
    }
}
