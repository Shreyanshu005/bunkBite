//
//  Canteen.swift
//  BunkBite
//
//  Created by Shreyanshu on 06/11/25.
//

import Foundation

struct Canteen: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let place: String
    let ownerId: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name, place, ownerId, createdAt, updatedAt
    }
}

struct CanteenResponse: Codable {
    let success: Bool
    let message: String?
    let canteen: Canteen?
    let canteens: [Canteen]?
}

struct CreateCanteenRequest: Codable {
    let name: String
    let place: String
    let ownerId: String
}
