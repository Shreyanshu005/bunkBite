//
//  MenuItem.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

struct MenuItem: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let image: String?
    let price: Double
    let availableQuantity: Int
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, image, price, availableQuantity, createdAt, updatedAt
    }
}



struct Menu: Codable {
    let canteenId: String
    let items: [MenuItem]
}

struct CreateMenuItemRequest: Codable {
    let name: String
    let price: Double
    let availableQuantity: Int
}

struct UpdateMenuItemRequest: Codable {
    let name: String
    let price: Double
    let availableQuantity: Int
}
