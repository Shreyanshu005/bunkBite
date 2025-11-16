//
//  Canteen.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

struct CanteenOwner: Codable, Hashable {
    let id: String
    let email: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case email, name
    }
}

struct Canteen: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let place: String
    let owner: CanteenOwner
    let menu: [MenuItem]?
    let createdAt: String?
    let updatedAt: String?

    var ownerId: String {
        return owner.id
    }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, place, owner, menu, createdAt, updatedAt
    }
}

struct CanteenResponse: Codable {
    let success: Bool
    let message: String?
    let canteen: Canteen?
    let canteens: [Canteen]?
    let count: Int?
}

struct CreateCanteenRequest: Codable {
    let name: String
    let place: String
    let ownerId: String
}
